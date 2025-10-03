// Kodi/Shadertoy standard variables (implicitly defined):
// vec3 iResolution (viewport resolution)
// float iTime (shader playback time in seconds)
// sampler2D iChannel0 (texture sampler for channel 0 - for the noise texture)

// --- USER CONTROL DEFINES ---
#define BRIGHTNESS 0.80
#define CONTRAST 1.6
#define SATURATION 1.6
#define FIELD_OF_VIEW 0.850     // 1.0 is default. < 1.0 zooms in.
#define ANIMATION_SPEED 0.150   // Global factor for all time-based motion.

// --- FIXED CONSTANTS ---
#define EPSILON 1e-6
#define ONE_OVER_2E5 0.000005 // 1.0 / 200000.0

// Unified time factor using the new speed control
#define GLOBAL_TIME_FACTOR (iTime * ANIMATION_SPEED)

// --- UTILITIES ---

// Robust Tanh Conversion Method: Included for GLSL ES 1.0 compatibility
// We use 'max(abs(x), EPSILON)' to ensure the denominator is never zero.
vec4 tanh_approx(vec4 x) {
    // Returns x / (1 + |x|), which approximates tanh(x) well around 0.
    return x / (1.0 + max(abs(x), EPSILON));
}

// Brightness, Contrast, Saturation Adjustment
vec3 adjust_bcs(vec3 color, float b, float c, float s) {
    // Contrast
    color = (color - 0.5) * c + 0.5;
    // Saturation (Using standard luminance constants for accurate conversion)
    vec3 gray = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(gray, color, s);
    // Brightness
    color *= b;
    return color;
}

// Fire effect calculation function
vec4 fire(vec3 p) {
    // Explicit Variable Initialization
    float s = 0.0; 
    float n = 0.0;
    float T = GLOBAL_TIME_FACTOR; // Use controlled time
    
    vec4 o = vec4(0.0);

    p += cos(p.z + T + p.yzx * 0.5) * 0.6;
    
    s = 6.0 - length(p.xy);
    
    // 2D Rotation matrix calculation
    mat2 rot_mat = mat2(cos(0.3 * T + vec4(0.0, 33.0, 11.0, 0.0)));
    p.xy *= rot_mat;

    // Volumetric noise loop
    for (n = 1.6; n < 32.0; n += n ) {
        s -= abs(dot(sin( p.z + T + p * n ), vec3(1.12))) / n;
    }
    
    s = (0.01 + abs(s) * 0.15);
    o += 1.0 / s;
    
    return (vec4(7.0, 2.0, 1.0, 1.0) * o * o );
}

void mainImage(out vec4 o, in vec2 u) {

    // Explicit Variable Initialization
    float d = 0.0;
    float i = 0.0;
    float s = 0.0;
    float w = 0.0;
    float l = 0.0;
    
    // Main time factor (0.3 of the global time factor)
    float T = GLOBAL_TIME_FACTOR * 0.3;
    
    vec3 q = vec3(0.0); 
    vec3 p = iResolution.xyz; 
    
    // Tiling UV calculation
    vec2 tiled_uv = mod(u, 1024.0) / 1024.0;
    
    // FIX FOR WEB COMPILATION: Replaced texture2D with texture for wider compatibility.
    // Start distance 'd' using the noise texture
    d = 4.0 * texture(iChannel0, tiled_uv).a;
    
    // Normalize coordinates, applying FIELD_OF_VIEW control
    u = ( u - p.xy / 2.0 ) / (p.y * FIELD_OF_VIEW);
    
    o = vec4(0.0); 
    
    // Main Raymarch loop
    for(; i++ < 64.0;) {
        
        q = p = vec3( u * d, d + T * 4.0);
        
        // Apply 2D rotation
        mat2 rot_mat = mat2(cos(0.001 * T + p.z * 0.1 + vec4(0.0, 33.0, 11.0, 0.0)));
        p.xy *= rot_mat;
        
        p *= 0.3;
        w = 0.25; 
        p.x -= 1.5;
        p += cos(T + p.yzx);
        
        // Inner Fractal loop
        for (int j = 0; j < 7; j++) {
            p = abs(sin(p)) - 1.0;
            
            // Robustness: Division by dot(p, p)
            l = 1.25 / max(dot(p, p), EPSILON); 
            p *= l;
            w *= l; 
        }
        
        d += s = 0.002 + 0.5 * abs(length(p) / max(w, EPSILON));
        
        // Robustness: Division by 's' in the accumulation step
        o += d / max(s, EPSILON) + 4.0 * fire(q);
    }
    
    // --- POST PROCESSING ---
    
    // Refined Tanh Application
    vec4 tanh_input = o * ONE_OVER_2E5;
    o = tanh_approx(tanh_input);
    
    // Apply Brightness, Contrast, Saturation controls
    o.rgb = adjust_bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}
