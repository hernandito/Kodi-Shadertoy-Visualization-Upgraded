// fractais: https://www.shadertoy.com/playlist/dcjXDc
// shaders lindos ♥ https://www.shadertoy.com/playlist/cXBGzV

// The Robust Tanh Conversion Method: tanh_approx function
float tanh_approx(float x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- Global Animation Speed Control ---
// Adjust this value to speed up or slow down all animations in the shader.
// 1.0 is normal speed. Increase for faster, decrease for slower.
#define ANIMATION_SPEED_MULTIPLIER 1.0

// --- Post-processing BCS Parameters ---
// Adjust these values to control Brightness, Contrast, and Saturation.
// BRIGHTNESS: Additive value. Positive makes brighter, negative makes darker. (Default: 0.0)
#define BRIGHTNESS 0.0
// CONTRAST: Multiplicative value around 0.5 gray. >1.0 increases, <1.0 decreases. (Default: 1.0)
#define CONTRAST 1.0
// SATURATION: Mixes color with its luminance. >1.0 increases, <1.0 decreases (0.0 is grayscale). (Default: 1.0)
#define SATURATION 1.0

#define rot(r) mat2(cos(r + vec4(0.0, 33.0, 11.0, 0.0)))
// Use iTime directly and apply animation speed multiplier
#define t (iTime * ANIMATION_SPEED_MULTIPLIER * 0.2 * 0.4) // Combined: iTime * ANIMATION_SPEED_MULTIPLIER * 0.08

#define pi acos(-1.0)

float cyl(vec3 q, float j) {
    q *= pow(0.83, j);
    float d = max(length(q.zx) - 0.02, abs(q.y) - 0.2) * 0.5;
    return d;
}

float tree(vec3 p){
    p.xy *= rot( cos(t * 0.3) * 0.002
                 * dot(cos(t * 40.0 + vec2(0.0, 11.0)), p.yx) );
               
    // Explicit Variable Initialization
    vec3 q = p; // q is initialized from p for each call to tree
    float e = 0.0;
    float j = 0.0;
    float d = 1.0; // Initialized as in original shader
    
    while(j++ < 14.0){
        e = cyl(q, j);
        
        d = min(d, e);
        // Replace tanh() with tanh_approx()
        q.xz *= rot(j * (2.12 + tanh_approx(cos(t * 15.0) * 3.0) * 0.03) + pi );
        
        q.x = abs(q.x) - 0.3;
        q.y -= 0.9;
        q.xy *= rot(3.14 / 6.0);
        q *= 1.3;
    }
    
    return d;
}


void mainImage(out vec4 o, vec2 u) {
    // Explicit Variable Initialization
    vec2 grid = vec2(0.0);
    vec2 r = iResolution.xy;
    
    // Enhance General Division Robustness
    u = (u - r / 2.0) / max(r.y, 1E-6);
    grid = fract(u * 16.0);
    
    // Explicit initialization for 'o'
    o = step(0.9, max(grid.x, grid.y)) * vec4(0.05);
            
    // Explicit Variable Initialization
    vec3 p = vec3(0.0, 1.8, -4.8);
    vec3 D = normalize(vec3(u, 1.0)); // Ensure 1.0 for float literal
    
    // Explicit Variable Initialization
    float s = 1.0;
    float i = 0.0;
    // Replace tanh() with tanh_approx()
    float xRot = cos(t + tanh_approx(cos(t) * 7.0)) * 0.5 - 0.25;

    D.zy *= rot(xRot);
    p.zy *= rot(xRot);

    while(i++ < 28.0){
        s = tree(p);
        // Enhance General Division Robustness
        o += vec4(0.0, 1.0, 0.0, 0.0) * exp(-s * 30.0) / max(70.0 + xRot * 50.0, 1E-6);
        p += s * D;
    }
    
    // --- Apply Post-processing BCS adjustments ---
    // Apply Brightness
    o.rgb += BRIGHTNESS;

    // Apply Contrast (around 0.5 gray point)
    o.rgb = (o.rgb - 0.5) * CONTRAST + 0.5;

    // Apply Saturation
    float luma = dot(o.rgb, vec3(0.2126, 0.7152, 0.0722)); // Standard luminance calculation
    o.rgb = mix(vec3(luma), o.rgb, SATURATION);

    // Ensure final color values are within a valid range
    o = clamp(o, 0.0, 1.0);
}