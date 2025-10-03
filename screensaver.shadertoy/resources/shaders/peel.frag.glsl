// Kodi/Shadertoy standard variables (implicitly defined):
// vec3 iResolution (viewport resolution)
// float iTime (shader playback time in seconds)
// sampler2D iChannel0 (texture sampler for channel 0)

// --- USER CONTROL DEFINES ---

// 1. FIELD OF VIEW (FOV): Controls the zoom level (perspective).
//    < 1.0 zooms IN (narrower FOV), > 1.0 zooms OUT (wider FOV). 1.0 is default.
#define FIELD_OF_VIEW .850

// 2. COLOR CONTROLS (BCS)
#define BRIGHTNESS 1.0
#define CONTRAST 1.40
#define SATURATION 1.0

// --- UTILITIES ---

#define T (iTime * 0.2 * 0.2) // Time variable
#define P(z) (vec3(cos((z) * 0.6) * 4.0, cos((z) * 0.7) * 8.0, (z))) // Camera path
#define R(a) mat2(cos(a), -sin(a), sin(a), cos(a)) // 2D Rotation matrix
#define N normalize

// Robust Tanh Conversion Method: Included for GLSL ES 1.0 compatibility
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    // Returns x / (1 + |x|), which approximates tanh(x) well around 0.
    return x / (1.0 + max(abs(x), EPSILON));
}

// Brightness, Contrast, Saturation Adjustment
vec3 adjust_bcs(vec3 color, float b, float c, float s) {
    // Contrast
    color = (color - 0.5) * c + 0.5;
    // Saturation (Using luminance constants)
    vec3 gray = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(gray, color, s);
    // Brightness
    color *= b;
    return color;
}

// --- SHADER CORE ---

float fractal(vec3 p) {
    // Explicit Variable Initialization
    float s = 0.0;
    float w = 1.0;
    float l = 0.0;
    const float EPSILON = 1e-6; // For robust division

    p += cos(3.0 * T + p.yzx * 2.0) * 0.3;
    p.y -= 1.5;
    
    // Loop must use explicit float constants (1.0, 8.0)
    for (s = 0.0, w = 1.0; s++ < 8.0; p *= l, w *= l ) {
         p = abs(sin(p)) - 1.0;
         // Enhance General Division Robustness: Prevent division by zero/near-zero
         l = 1.5 / max(dot(p, p), EPSILON); 
    }
    
    // Final return uses robustness
    return length(p) / max(w, EPSILON);
}

float map(vec3 p) {
    return fractal(p);
}

void mainImage(out vec4 o, in vec2 u) {

    // Explicit Variable Initialization
    float s = 0.0;
    float i = 0.0;
    float d = 0.0;
    
    vec3 r = iResolution;
    
    // Tiling Fix: Replaces texelFetch(iChannel0, ivec2(u)%1024, 0).a
    // This samples the noise texture in a tiled 1024x1024 pattern, 
    // using the screen pixel coordinate 'u', which should fix the grid artifacts.
    vec2 tiled_uv = mod(u, 1024.0) / 1024.0;
    
    // start d at a large'ish random distance to skip ahead
    d = 2.0 * texture2D(iChannel0, tiled_uv).a;
    
    // Apply FOV and normalize coordinates
    vec2 uv_normalized = (u - r.xy * 0.5) / (r.y * FIELD_OF_VIEW);
    
    // Explicit initialization for other complex vectors
    vec3 e = vec3(0.001, 0.0, 0.0);
    vec3 p = P(T);
    vec3 ro = p; // Ray Origin

    // Camera direction Z (Forward)
    vec3 Z = N( P(T + 1.0) - p);
    
    // Camera direction X (Right) - Corrected the previous illegal vector definition
    vec3 X = N(vec3(Z.z, 0.0, -Z.x)); 

    // Camera direction Y (Up) - Standard cross product for basis consistency
    vec3 Y = cross(X, Z);
    
    // Ray direction D: uses rotation, normalized UV, and camera basis vectors
    // Using the original mat3 construction from the previous working attempts
    vec3 D = vec3(R(sin(T * 0.2) * 0.4) * uv_normalized, 1.0)
             * mat3(-X, cross(X, Z), Z); // Original construction: -X, cross(X, Z), Z
             
    o = vec4(0.0);
    
    // Raymarch loop
    for(; i++ < 128.0;) {
        p = ro + D * d;
        d += s = map(p);
        
        // Accumulation: Division is inherently robust here (.005+abs(s) > 0)
        o += vec4(16.0, 2.0, 1.0, 0.0) + 0.2 / (0.005 + abs(s));
    }
    
    // --- POST PROCESSING: Tanh Conversion and BCS ---
    
    // Refined Tanh Application: Compute the complex argument first
    // 2e8 converted to explicit float: 200000000.0
    vec4 tanh_input = o * o / 200000000.0 * exp(d / 2.0);
    
    // Apply the robust tanh approximation
    o = tanh_approx(tanh_input);
    
    // Apply Brightness, Contrast, Saturation controls
    o.rgb = adjust_bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}
