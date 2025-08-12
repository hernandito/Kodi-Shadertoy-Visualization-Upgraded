// CC0: SlayRadio Fireplace
//  I wanted to do something with the slayradio distance field from the other night
//  and also try it some fire-like using the @XorDev turbulence

// --- GLOBAL PARAMETERS ---
#define ANIM_SPEED 0.50        // Global animation speed multiplier (1.0 = normal, 2.0 = double speed, 0.5 = half speed)
#define BCS_BRIGHTNESS 1.0     // Overall brightness of the animated fire effect
#define BCS_CONTRAST 1.05      // Contrast of the animated fire effect
#define BCS_SATURATION 1.05    // Color saturation of the animated fire effect
// -------------------------

// The Robust Tanh Conversion Method: tanh_approx functions
// For float input
float tanh_approx(float x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}
// For vec3 input (NEW: Added for 'c' in mainImage)
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
#define T iTime // Changed back to iTime
#define R iResolution
vec4 U = vec4(0.0, 1.0, 2.0, 3.0); // Utility vector for swizzling/constants - Explicitly initialized

// SlayRadio logo distance fields
// Distance fields return how far a point is from a shape's surface
// Negative = inside shape, Positive = outside shape, Zero = on surface
//  .x is outer border (the beating circle)
//  .y is the inner "bananas" - This is the "TV Frame" you want back
//  .z is the inner circle (the S-shape or other inner element) - These are the "bananas or parenthesis" you want removed
//  .w is the opaque outline (the main letters)
vec4 S(vec2 p) {
    p = abs(p); // Mirror across both axes (creates 4-way symmetry)
    vec2
        d = p - vec2(0.25, 0.14) // Offset for rounded rectangle
        , s = vec2(cos(0.5),sin(0.5)) // Direction vector for angled cuts
    ;
    // Create rounded rectangle distance field
    float
        O = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - 0.2
        , B = 1.0 - sqrt(fract(T * ANIM_SPEED * 114.0 / max(60.0, 1E-6))); // Adjusted for ANIM_SPEED
    ;
    return vec4(
        length(p) - 0.05 - 0.02 * B // .x: Circle distance field (the beating circle)
        , abs(O) - 0.01 // .y: Hollow rounded rectangle (the "TV Frame")
        , s.x * p.y > s.y * p.x ? length(p - s * 0.25) : abs(length(p) - 0.25) // .z: Conditional circle/ring (the "bananas or parenthesis")
        , O // .w: Solid rounded rectangle (the main letters outline)
    ) - 0.05; // Shrink all shapes by 0.05
}

// The complete logo distance field
// Combines multiple shapes using min() to create union
float D(vec2 p) {
    vec4 d = S(p);
    // Currently returning only d.y (the "TV Frame").
    return d.y; 
}

// The logo height function (computed from distance field)
// Creates 3D surface height from 2D distance field
float H(vec2 p) {
    float
        A = 6.0 * sqrt(2.0) / max(R.y, 1E-6) // Anti-aliasing factor based on pixel size - Division robustness for R.y
        , d = D(p) // Distance to logo edge
    ;
    vec2 pp = 10.0 * p;
    
    // Build height from multiple layers:
    float h = tanh_approx(-400.0 * d) // Sharp falloff at logo edges (tanh smooths it) - Converted tanh
             - 0.2 * (sin(pp.x) * sin(pp.y)) // Creates a wavy look to the logo
             - 1.5E-3 * mix(0.0, (1.0 + sin(p.y * 1E3)), smoothstep(A, -A, d + 0.02)); // Rifled look
    return h / max(8.0, 1E-6); // Scale down the height - Division robustness for 8.
}

// The logo normal function (computed from height function)
// Normals are used for lighting calculations - they point "up" from the surface
vec3 N(vec2 p) {
    vec2 e = vec2(1.41 / max(R.y, 1E-6), 0.0); // Small offset for numerical derivatives - Division robustness for R.y
    
    // Calculate normal using finite differences (calculus: derivative ≈ slope)
    return normalize(vec3(
        H(p - e) - H(p + e) // X component: slope in X direction
        , H(p - e.yx) - H(p + e.yx) // Y component: slope in Y direction 
        , 2.0 * e.x // Z component: constant (surface "steepness")
    ));
}

// The logo lighting and rendering function
vec3 L(vec3 c, vec2 p, vec4 s) {
    float A = 1.41 / max(R.y, 1E-6) // Anti-aliasing factor - Division robustness for R.y
        , d = D(p) // Distance to logo
        , h = H(p) // Height at this point
    ;
    
    // Set up 3D lighting scene
    vec3
        n = N(p) // Surface normal (which way surface faces)
        , q = vec3(p, h) // 3D surface point
        , r = normalize(q - 3.0 * U.xxw) // Ray from camera to surface (camera at (0,0,9))
        , l = normalize((3.0 + U.xzw) * (0.5 + 0.4 * sin(2.0 * p.x + p.y + T * ANIM_SPEED * 0.6)) - q) // Adjusted for ANIM_SPEED
    ; 
    
    // Apply lighting model:
    return mix(
        mix(c, vec3(0.0), smoothstep(A, -A, -s.w)) // Cut out logo shape (black inside)
        , vec3(
            0.5 * pow(max(dot(l, n), 0.0), 6.0) // Diffuse lighting (surface facing light)
            + pow(max(dot(l, reflect(r, n)), 0.0), 12.0)) // Specular highlight (shiny reflection)
        , smoothstep(A, -A, d + 3E-3)); // Blend lighting only on logo surface
}

// The fire/plasma background effect
vec3 F(vec2 q, vec4 s) {
    if (s.w > -0.1) return vec3(0.0); // Explicit float for -0.1
    // Explicit initialization for all variables
    float i = 0.0, j = 0.0, d = 0.0, z = 0.0, x = 0.0, y = 0.0;
    vec4 o = vec4(0.0), p_vec4 = vec4(0.0), r_vec4 = vec4(0.0); // Renamed 'p' and 'r' to avoid conflict with 'p' (vec3)
    
    // Raymarching loop: step through 3D space to create volumetric effect
    for(mat2 m = mat2(cos(0.3 * T * ANIM_SPEED + 11.0 * U.xywx)); // Adjusted for ANIM_SPEED
        ++i < 52.0; // Explicit float for 77.
        z += 0.4 * d) // Explicit float for 0.4
    {
        // Set up 4D point for fractal noise
        p_vec4 = vec4(z * normalize(vec3(q,1.0)), 0.5); // Ray direction in 4D - Explicit float for 1.0 and 0.5
        p_vec4.z -= 4.0; // Offset in Z - Explicit float for 4.
        x = length(p_vec4); // Distance from origin
        y = -1.4 - p_vec4.z; // Ground plane distance - Explicit float for -1.4
        
        // Rotate the 4D point (creates swirling motion)
        p_vec4.yz *= m; p_vec4.xw *= m; p_vec4.wy *= m; p_vec4.zw *= m;
        
        d = 3.0; // Explicit float for 3.
        // @XorDev Turbulence effect - creates flame-like patterns
        // This is fractal noise: multiple octaves of sine waves at different scales
        for(r_vec4 = p_vec4 * 2.0, j = 0.0; ++j < 5.0; d *= 1.7) // 5 octaves, each 1.7x higher frequency - Explicit floats
            r_vec4 += cos(r_vec4.zxwy * d + 4.0 * x) / max(d, 1E-6); // Add cosine wave, swizzle coordinates - Division robustness for d
        
        // --- FIX FOR 'round' ERROR ---
        // Replaced round(r_vec4) with sign(r_vec4) * floor(abs(r_vec4) + 0.5) for wider GLSL compatibility
        r_vec4 = abs(r_vec4 - sign(r_vec4) * floor(abs(r_vec4) + 0.5)); // Domain repetition
        
        // Distance field: how close to the flame surface
        d = abs(min(max(min(min(r_vec4.x, r_vec4.y), min(r_vec4.z, r_vec4.w)) / 2.0, y), x)) + 2E-3; // Explicit float for 2.0
        
        // Accumulate color based on density
        o += U.yzwx * 100.0 / max(pow(dot(p_vec4, p_vec4), 3.0), 1E-6); // Bright core (1/distance³ falloff) - Division robustness for pow
        p_vec4 = 1.0 + sin(-0.25 + 6.0 * length(p_vec4) + U.xyzx); // Color variation - Explicit floats
        o += p_vec4.w / max(d, 1E-6) * p_vec4; // Add colored contribution - Division robustness for d
    }
    // Square to increase color saturation, normalize
    return smoothstep(0.09, 0.2, -s.w) * o.xyz * o.xyz / max(3E8, 1E-6); // Division robustness for 3E8
}

// Main rendering function - called once per pixel
void mainImage(out vec4 O, vec2 C) {
    // Convert pixel coordinates to centered, aspect-corrected coordinates
    vec2 p = (C - 0.5 * R.xy) / max(R.y, 1E-6); // Now p ranges roughly -0.5 to +0.5 - Division robustness for R.y
    
    // Create reflection effect in bottom half
    float s = p.y + 0.3; // Shift coordinate system - Explicit float for 0.3
    p.y = abs(s) - 0.4; // Mirror and offset - Explicit float for 0.4

    vec4 S_val = S(p); // All logo distance fields - Renamed to S_val to avoid conflict with #define S
    
    // Render the raw fire background effect
    vec3 fire_effect_color = min(F(p, S_val), 10.0);

    // --- Apply BCS adjustments ONLY to the fire_effect_color ---
    // 1. Contrast
    fire_effect_color = (fire_effect_color - 0.5) * BCS_CONTRAST + 0.5;
    // 2. Brightness
    fire_effect_color *= BCS_BRIGHTNESS;
    // 3. Saturation
    float grayscale_fire_val = dot(fire_effect_color, vec3(0.2126, 0.7152, 0.0722)); // Get grayscale luminance
    fire_effect_color = mix(vec3(grayscale_fire_val), fire_effect_color, BCS_SATURATION); // Blend with original for saturation
    // -----------------------------------------------------------
    
    // Render the full scene: logo lighting (TV Frame) overlaid on the adjusted fire effect
    vec3 c = L(fire_effect_color, p, S_val); 
    
    // Apply reflection darkening and blue tint
    if (s < 0.0) c = c * 0.1 * smoothstep(0.1, 0.0, s) + 0.2 * vec3(1.0, 2.0, 5.0) * s * s; // Explicit floats
    
    // Final post-processing (gamma correction and fade-in)
    O = vec4(sqrt( // Gamma correction (brighten)
        tanh_approx(c) // Tone mapping (prevent over-bright) - Converted tanh
        * smoothstep(0.0, 6.0, T * ANIM_SPEED) // Fade in over 6 seconds - Adjusted for ANIM_SPEED
    ), 1.0); // Explicit float for 1.0
}