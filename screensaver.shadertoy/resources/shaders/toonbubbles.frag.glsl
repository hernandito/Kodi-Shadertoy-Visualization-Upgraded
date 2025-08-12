// --- GLSL Version and Precision Directives for Kodi Compatibility (GLSL ES 1.0) ---
precision highp float;
precision highp int;
precision lowp sampler2D;

// Define a small epsilon for numerical stability in divisions.
const float EPSILON = 1e-6; // 0.000001

// The Robust Tanh Conversion Method: tanh_approx function
// Ensures numerical stability for tanh, especially near zero.
// Expects a vec4 input for consistency with common use cases, takes .x for scalar results.
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// Global time variable, reverted to iTime for web compatibility.
#define T iTime

// --- Custom Parameters ---
#define SCREEN_ZOOM     1.0 // Adjusts zoom level: >1.0 zooms in, <1.0 zooms out (to see more)
#define ANIMATION_SPEED 0.20 // Global multiplier for animation speed: >1.0 faster, <1.0 slower

// --- Post-processing Parameters (Brightness, Contrast, Saturation) ---
#define BRIGHTNESS -0.20    // Adjust brightness: 0.0 for no change, positive for brighter, negative for darker
#define CONTRAST   1.30    // Adjust contrast: 1.0 for no change, >1.0 for more contrast, <1.0 for less
#define SATURATION 1.0    // Adjust saturation: 1.0 for no change, >1.0 for more saturated, <1.0 for desaturated


// Standard 2D rotation matrix function.
// This replaces the problematic `rot` macro.
mat2 rotate(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

// Main SDF function for the scene.
float map(vec3 p) {
    // Explicitly initialize variables.
    float e = 0.0;
    float s = 1.0;
    float d = 1e9; // Large initial distance.
    float r_temp = 0.0; // Temporary 'r' variable for calculations within map, explicitly initialized.
    
    // Apply rotation using the fixed `rotate` function.
    // Ensure float literals.
    p.xy *= rotate(cos(T * 0.15 * ANIMATION_SPEED) * 0.25); // Apply ANIMATION_SPEED
    // Replaced tanh() with tanh_approx() and ensured vec4 conversion for float input, then take .x.
    // Apply animation speed to iTime.
    p.xz *= rotate(tanh_approx(vec4(cos(T * 0.4 * ANIMATION_SPEED) * 5.0 + 3.0, 0.0, 0.0, 0.0)).x); // Apply ANIMATION_SPEED
    
    // Explicitly initialized loop variable 'i'.
    for(int i = 0; i < 7; i++) {
        p.y = sqrt(max(0.0, p.y)); // Ensure float literal for 0.0.
        
        e = p.y < 0.5 // Ensure float literal for 0.5.
            ? length(p.xz) - 0.005 // Ensure float literal for 0.005.
            : abs(p.y - 0.3); // Ensure float literal for 0.3.
            
        d = min(d, e * s);
        p.y -= 0.5; // Ensure float literal for 0.5.
        
        if(abs(p.z) > abs(p.x))
            p.xz = p.zx;
        
        p.xy *= rotate(sign(p.x)); // Use fixed rotate function.
        
        p *= 2.0; // Ensure float literal for 2.0.
        s /= 2.0; // Ensure float literal for 2.0.
    }
    
    return d;
}

void mainImage(out vec4 o, vec2 u) {
    vec3 R = iResolution.xyz; // Use vec3 for iResolution for consistency.
    // Explicitly initialize uv, ensure float literals and robustness in division.
    // Apply SCREEN_ZOOM to uv calculation.
    vec2 uv = 2.0 * (u - R.xy / 2.0) / R.y / SCREEN_ZOOM; // Apply SCREEN_ZOOM

    // Explicitly initialize output color.
    o = vec4(0.0);
    
    // Explicitly initialize p, r, s, d, n, t for this scope (mainImage)
    // t is already defined by #define T iChannelTime[0]
    float r_val = 0.0; // Renamed to avoid conflict with R (iResolution)
    float s_val = 0.0; // Renamed to avoid conflict with s in map()
    float d_val = 0.0; // Renamed to avoid conflict with d in map()
    float n_val = 0.0; // Renamed to avoid conflict with n in inner loop
    
    vec3 p_main = vec3(1.0, 0.82, 0.0); // Renamed to avoid conflict with p in map()

    // Explicitly initialized loop variable 'i'.
    // The original `o*=i` was a golfed style for initialization, replaced by `o = vec4(0.0);` above.
    for(float i = 0.0; i < 90.0; ++i) { // Changed 9e1 to 90.0
        // Inner loop's variables declared here to ensure scope and initialization for each outer loop iteration.
        // Also ensure float literals and robustness in division.
        p_main = vec3(uv * d_val, d_val + T * 16.0 * ANIMATION_SPEED); // Apply ANIMATION_SPEED
        r_val = 50.0 - abs(p_main.y) + cos(T * ANIMATION_SPEED - dot(uv,uv) * 6.0) * 3.3; // Apply ANIMATION_SPEED
        n_val = 0.08;
        
        for(; n_val < 0.8; n_val *= 1.4) {
            // Ensure float literals and robustness in division.
            // p_main-p_main is vec3(0.0), so 0.7 + p_main - p_main simplifies to vec3(0.7).
            r_val -= abs(dot(sin(0.3 * T * ANIMATION_SPEED + 0.8 * p_main * n_val), vec3(0.7))) / max(n_val, EPSILON); // Apply ANIMATION_SPEED
        }
        
        // This part needs careful handling. The original code's structure for d and o accumulation is:
        // for (o*=i;i++<9e1; d += s = .005 + abs(r)*.2, o += (1.+cos(.1*p.z+vec4(3,1,0,0))) / s)
        // This means 'd' and 's' update, then 'o' accumulates, all in the loop's third part.
        // We'll move them inside the loop body for clarity and GLSL ES 1.0 compatibility.
        s_val = 0.005 + abs(r_val) * 0.2; // s calculation.
        d_val += s_val; // d accumulation.

        // Accumulate color 'o'.
        // Ensure float literals and robust division.
        // Original: (1.+cos(.1*p.z+vec4(3,1,0,0))) / s)
        // Fixed: Use vec4 for 1.0 and cos to match type, ensure vec4 output.
        o += (vec4(1.0) + cos(0.1 * p_main.z + vec4(3.0, 1.0, 0.0, 0.0))) / max(s_val, EPSILON);
    }
    
    // Apply tanh_approx to the final output color 'o'.
    // Ensure robustness in division.
    // Original: o = tanh(o / 2e3);
    o = tanh_approx(o / max(2000.0, EPSILON)); // Changed 2e3 to 2000.0 for clarity.

    // --- Post-processing: Apply BCS (Brightness, Contrast, Saturation) Adjustments ---
    vec3 final_rgb = o.rgb; // Get the tone-mapped color

    // 1. Brightness Adjustment
    final_rgb += BRIGHTNESS;

    // 2. Contrast Adjustment
    final_rgb = (final_rgb - 0.5) * CONTRAST + 0.5;

    // 3. Saturation Adjustment
    float luminance = dot(final_rgb, vec3(0.299, 0.587, 0.114));
    final_rgb = mix(vec3(luminance), final_rgb, SATURATION);

    // Apply final color to output, clamped to 0-1 range to prevent over-exposure artifacts
    o.rgb = clamp(final_rgb, 0.0, 1.0);
}
