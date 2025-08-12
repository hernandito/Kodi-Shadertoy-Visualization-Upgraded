#ifdef GL_ES
precision mediump float;
#endif

// --- User-defined Parameters ---
#define ANIMATION_SPEED 0.1
#define BRIGHTNESS 0.20
#define CONTRAST 1.40
#define SATURATION 1.75

// --- Robust Tanh Conversion Method ---
// This function provides a numerically stable approximation of the hyperbolic tangent.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

void mainImage(out vec4 O, vec2 C) {
    // 3. Ensure Explicit Variable Initialization
    O = vec4(0.0);
    vec3 p = vec3(0.0);
    vec4 P = vec4(0.0);
    
    // Main raymarching loop - cast a ray from camera into the scene
    for (
        float i = 0.0, d = 0.0, z = 0.0; // Initialized loop variables
        ++i < 77.0;                       // Iteration counter
        z += 0.6 * d                      // March forward along ray by 60% of distance to nearest surface
    )
        
    p = z * normalize(vec3(C + C, 0) - iResolution.xyy),
    
    // Use the global animation speed parameter
    p.xy *= mat2(cos((p.z -= ANIMATION_SPEED * iTime) + vec4(0.0, 11.0, 33.0, 0.0))),
    
    // Generate procedural color based on position
    P = 1.0 + sin(5.0 * p.x + p.z + vec4(2.0, 1.0, 0.0, 2.0)),
    
    // Calculate distance to nearest surface and accumulate color
    d = abs(length(fract(p) - 0.5) - 0.5) + 1e-3,
    
    // Add color contribution: brighter when closer to surface (smaller d)
    O += P.w / d * P
    ;
    
    // The key change: We apply the tone mapping *first* to bring the colors
    // into a proper display range, and then we apply the BCS adjustments.
    O = tanh_approx(O / 2e4);

    // --- Post-processing: BCS adjustments ---
    // 1. Contrast: Adjusts the difference between light and dark areas.
    O.rgb = (O.rgb - 0.5) * CONTRAST + 0.5;

    // 2. Saturation: Adjusts the intensity of colors.
    vec3 luma = vec3(dot(vec3(0.2126, 0.7152, 0.0722), O.rgb));
    O.rgb = mix(luma, O.rgb, SATURATION);

    // 3. Brightness: Shifts the overall lightness of the image.
    O.rgb += BRIGHTNESS;
}
