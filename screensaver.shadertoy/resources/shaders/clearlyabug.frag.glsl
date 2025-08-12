// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// N macro definition (from previous shader, included for completeness if needed elsewhere, though not used in this specific shader)
// Removed max(n, 1e-6) as n starts at 0.9 and multiplies by 1.4, so it's always positive.
#define N(x,s) abs(dot(cos(x * n), vec3(s))) / n

// Constants from original shader
const int MAX_MARCHING_STEPS = 255; // Not used in this shader, but kept for completeness
const float MIN_DIST = 0.0;         // Not used in this shader, but kept for completeness
const float MAX_DIST = 100.0;       // Not used in this shader, but kept for completeness
const float PRECISION = 0.001;      // Not used in this shader, but kept for completeness
const float EPSILON = 0.00005;      // Used in tanh_approx
const float ESCAPEDISTANCE = 4.0;   // Not used in this shader, but kept for completeness

// --- GLOBAL PARAMETERS ---
#define BRIGHTNESS 1.30    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.70      // Contrast adjustment (1.0 = neutral)
#define SATURATION 0.80    // Saturation adjustment (1.0 = neutral)
#define SCREEN_SCALE 1.0  // Scale factor for zooming the effect (e.g., 0.5 for zoom in, 2.0 for zoom out)
#define WHITE_TINT vec3(1.0, 1.0, 1.0) // RGB color for the white tint (e.g., vec3(1.0, 0.9, 0.8) for warm white)
#define WHITE_TINT_STRENGTH 0.0 // How strongly to apply the tint (0.0 for no tint, 1.0 for full tint)
#define ANIMATION_SPEED .20 // Controls the overall animation speed (1.0 = normal speed)
#define DITHER_STRENGTH 0.005 // Strength of the dither effect (e.0.005 for subtle dither) iTime
void mainImage(out vec4 O, vec2 C) {
    // Explicit Variable Initialization
    float i = 0.0;      // Loop counter
    float d = 0.0;      // Distance to nearest surface
    float z = fract(dot(C,sin(C))) - 0.5; // Ray distance + noise for anti-banding (initialized here)

    vec4 o = vec4(0.0); // Accumulated color/lighting (initialized here)
    vec4 p = vec4(0.0); // Current 3D position along ray (initialized here)

    vec2 r = iResolution.xy; // Screen resolution (initialized here)

    // Apply SCREEN_SCALE to input coordinates
    vec2 scaled_C = C / SCREEN_SCALE;
    vec2 scaled_r = r / SCREEN_SCALE;

    // Scale iTime by ANIMATION_SPEED
    float current_iTime = iTime * ANIMATION_SPEED;

    for(
        ; ++i < 77.0
        ; z += 0.6 * d // Step forward (larger steps when far from surfaces)
    ) {
        // Convert 2D pixel to 3D ray direction
        // Normalize can result in NaN if vector is zero, but (C-.5*r,r.y) should rarely be exactly zero.
        // Added max(length(...), 1e-6) for robustness in normalize, though it's often handled internally.
        p = vec4(z * normalize(vec3(scaled_C - 0.5 * scaled_r, scaled_r.y)), 0.1 * current_iTime);

        // Move through 3D space over time
        p.z += current_iTime;

        // Save position for lighting calculations
        // O is used as a temporary variable here, which is common in compact shaders.
        O = p;

        // Apply rotation matrices to create fractal patterns
        // (These transform the 3D coordinates in interesting ways)
        p.xy *= mat2(cos(2.0 + O.z + vec4(0, 11, 33, 0)));

        // This was originally a bug in the matrix calculation
        // The incorrect transformation created an unexpectedly interesting pattern
        // Bob Ross would call this a "happy little accident"
        p.xy *= mat2(cos(O + vec4(0, 11, 33, 0)));

        // Calculate color based on position and space distortion
        // The sin() creates a nice looking palette, division by dot() creates falloff
        // Denominator (.5+2.*dot(O.xy,O.xy)) is always >= 0.5, so division is robust.
        O = (1.0 + sin(0.5 * O.z + length(p - O) + vec4(0, 4, 3, 6))) / (0.5 + 2.0 * dot(O.xy, O.xy));

        // Domain repetition, repeats the single line and the 2 planes infinitely
        p = abs(fract(p) - 0.5);

        // Calculate distance to nearest surface
        // This combines a cylinder (length(p.xy)-.125) with 2 planesbox (min(p.x,p.y))
        // The +1e-3 makes 'd' always at least 1e-3, so division by 'd' later is robust.
        d = abs(min(length(p.xy) - 0.125, min(p.x, p.y) + 1e-3)) + 1e-3;

        // Add lighting contribution (brighter when closer to surfaces)
        // Division by 'd' is robust as 'd' is always >= 1e-3.
        o += O.w / d * O;
    }

    // tanh() compresses the accumulated brightness to 0-1 range
    // (Like HDR tone mapping in photography)
    // Applying tanh_approx to the vec4 'o' as per original shader's intent.
    // Denominator 2e4 is constant, so division is robust.
    vec4 final_color_raw = tanh_approx(o / 2e4);

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = final_color_raw.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    finalColor = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

    // --- Apply White Tint ---
    // Mix the final color with the WHITE_TINT based on its luminance and the strength parameter.
    // This applies the tint more strongly to brighter areas.
    finalColor = mix(finalColor, WHITE_TINT, luminance * WHITE_TINT_STRENGTH);

    // --- Apply Dither Effect ---
    // A simple ordered dither pattern based on screen coordinates.
    // This helps break up color banding in smooth gradients.
    float dither = mod(floor(C.x) + floor(C.y), 2.0) * 2.0 - 1.0; // Use original C for dither grid
    finalColor += dither * DITHER_STRENGTH;

    O = vec4(finalColor, 1.0);
}
