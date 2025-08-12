// CC0: 4D Swiss cheese
//  Some random shader coding while lurking during https://www.twitch.tv/fieldfxdemo
//  Every monday there's DJ:ing and live coding jams (shader or tic80). Go there.

// --- GLOBAL PARAMETERS ---
#define ANIM_SPEED .30        // Global animation speed multiplier (1.0 = normal, 2.0 = double speed, 0.5 = half speed)
#define BCS_BRIGHTNESS 1.0    // Overall brightness (1.0 = normal, >1.0 brighter, <1.0 darker)
#define BCS_CONTRAST 1.25      // Image contrast (1.0 = normal, >1.0 more contrast, <1.0 less contrast)
#define BCS_SATURATION 1.0    // Color saturation (1.0 = normal, >1.0 more saturated, <1.0 desaturated)
#define MAX_STEPS 55.0        // Maximum raymarching steps.
#define SCREEN_ZOOM_SCALE .70 // Screen zoom scale (1.0 = default, >1.0 zooms out for wider view, <1.0 zooms in)
// -------------------------

// The Robust Tanh Conversion Method: tanh_approx functions
// For float input
float tanh_approx(float x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}
// For vec3 input
vec3 tanh_approx(vec3 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}
// For vec4 input
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Common shader constants and utilities
// Shorthand for screen resolution
#define R iResolution
// Using iTime directly, multiplied by ANIM_SPEED
#define T (iTime * ANIM_SPEED)

vec4 U = vec4(1.0, 2.0, 3.0, 0.0); // Utility vector for swizzling/constants - Explicitly initialized


// Shader entry point: O = output color, C = pixel coordinates
void mainImage(out vec4 O, vec2 C) {
    // Explicit Variable Initialization
    float i = 0.0;
    float d = 0.0;
    float z = 0.0; // Depth along ray

    vec4 o = vec4(0.0); // Accumulated color
    vec4 p = vec4(0.0); // Ray position
    vec4 P = vec4(0.0); // Temp storage for p*p*p*p
    vec4 Y = vec4(0.0); // Original position for lighting

    // 2D rotation matrices that change over time (for animation)
    mat2 R0 = mat2(cos(0.23 * T + 11.0 * U.wxzw));
    mat2 R1 = mat2(cos(0.13 * T + 11.0 * U.wxzw));
    
    vec2 r_res = iResolution.xy; // Store iResolution.xy in a local variable for clarity

    // Create ray from camera through current pixel, scaled by ZOOM_SCALE
    vec3 ray_dir = normalize(vec3((C - 0.5 * r_res) / SCREEN_ZOOM_SCALE, r_res.y)); // Apply zoom here
    
    // Raymarching loop
    for( ; ++i < MAX_STEPS; z += 0.7 * d) { // Explicit float literals, using MAX_STEPS
        // Use the scaled ray direction for ray position calculation
        p = vec4(z * ray_dir, 0.9); // Explicit float literals
        p.z -= 2.0; // Move camera back - Explicit float literal
        
        // Apply rotations to create spinning/tumbling effect
        p.xz *= R0 * R1;
        p.xw *= R1;
        Y = p; // Save original position for lighting
        p.wy *= R0;
        p.zw *= R1 * R0;
        
        // Distance to fractal surface using 8th root of 8th power
        // This creates a smooth rounded cube-like shape
        // P = p*p*p*p for clarity, then dot(P,P)
        P = p * p * p * p;
        d = pow(dot(P, P), 0.125) - 1.0; // Explicit float literals
        
        // Animation: move the fractal pattern over time
        p -= 0.2 * T; // Explicit float literal
        
        // Create repeating cells by rounding to grid
        // Kodi fix: Replace round() with equivalent for GLSL ES 1.00
        vec4 p_times_4 = p * 4.0;
        p -= sign(p_times_4) * floor(abs(p_times_4) + 0.5) * 0.25; // Explicit float literals
        
        // Calculate color based on position and distance
        P = 1.0 + sin(6.0 * length(Y.xy) + 6.0 * d + U.wxyw - T); // Explicit float literals
        
        // Subtract holes (negative space) - creates tunnels/cavities
        // Division robustness for 0.25 (sin(T) can be -1, making 0.5-0.2 small)
        d = max(d, -(length(p) - (0.5 + 0.2 * sin(T)) * 0.25)); // Explicit float literals
        
        // Ensure minimum distance to make translucent
        d = abs(d) + 1E-3; // Explicit float literal
        
        // Accumulate color: closer surfaces contribute more
        // First term: main coloring, Second term: bright glow effect
        // Now, the glow term is multiplied by smoothstep, ensuring it fades quickly when far from the surface (d is large)
        // Division robustness for d and pow(dot(Y,Y), 8.0)
        o += P.w / max(d, 1E-6) * P + 300.0 * U / max(pow(dot(Y,Y), 8.0), 1E-6) * smoothstep(1.0, 0.0, abs(d) * 10.0); // Explicit float literals
    }
    
    // Tone mapping: compress bright values to displayable range
    // Converted tanh to tanh_approx and division robustness for 20000.0
    vec4 final_color = tanh_approx(o / max(20000.0, 1E-6));
    
    // --- Apply BCS adjustments ---
    // 1. Contrast
    final_color.rgb = (final_color.rgb - 0.5) * BCS_CONTRAST + 0.5;
    // 2. Brightness
    final_color.rgb *= BCS_BRIGHTNESS;
    // 3. Saturation
    float grayscale_val = dot(final_color.rgb, vec3(0.2126, 0.7152, 0.0722)); // Get grayscale luminance
    final_color.rgb = mix(vec3(grayscale_val), final_color.rgb, BCS_SATURATION); // Blend with original for saturation
    // -----------------------------

    O = clamp(final_color, 0.0, 1.0); // Clamp final output to [0,1] range
}