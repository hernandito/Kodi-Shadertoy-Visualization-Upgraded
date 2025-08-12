// Global constant for robustness
const float EPSILON = 1e-6;

// Robust tanh approximation function
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// Define for controlling global animation speed
// Adjust this value to control speed: 1.0 for normal, 0.5 for half, 2.0 for double.
#define ANIMATION_SPEED .30 

// Define for controlling screen zoom scale
// Set to 1.0 for normal zoom. Values > 1.0 will zoom OUT (show more of the scene).
// Values < 1.0 will zoom IN (magnify the scene).
#define SCREEN_SCALE 1.5

// Define parameters for Brightness, Contrast, and Saturation
// Adjust these values to control the final look of the shader.
#define BRIGHTNESS -0.10    // Range typically -1.0 (darker) to 1.0 (brighter)
#define CONTRAST   1.5    // Range typically 0.0 (no contrast) to 2.0+ (high contrast)
#define SATURATION 1.0    // Range typically 0.0 (grayscale) to 2.0+ (highly saturated)

void mainImage(out vec4 o, vec2 u) {
    // Explicitly initialize all declared variables
    float i = 0.0;
    float d = 0.0;
    float s = 0.0;
    // Applied global animation speed using a #define
    float t = iChannelTime[0] * ANIMATION_SPEED; 

    vec3 p = iResolution;

    // Explicitly initialize output 'o' to prevent undefined behavior
    o = vec4(0.0);

    // Normalize UVs and apply aspect ratio correction
    u = (u - p.xy / 2.0) / max(p.y, EPSILON);

    // Apply screen scale for view zoom
    u *= SCREEN_SCALE;

    // Main loop
    // Note: 'o *= i' will initialize 'o' to zero on the first iteration since 'i' is 0.0
    for (o *= i; i++ < 80.0;
        // The snow is just cos(p.z) with some modifiers (pass time to move)
        // *1.6 to scale, etc..
        // using the translucency abs() trick seen in @Xor and @mrange shaders
        // attenuate with A + abs(signed_distance) * B,
        // where A and B are found through experimentation, but are generally
        // between .001 and 1.
        d += s = 0.01 + min(0.03 + abs(cos(2.0 * t + p.z) * 1.6) * 0.4,
                             0.01 + abs(0.5 + p.y) * 0.6),
        // grayscale color based on distance
        // Apply robustness to division by s
        o += 1.0 / max(s, EPSILON)) {
         
        // we're in the body of the above for loop now
        // first line is the march, set s to .01 (our noise start)
        // go up to s < 2. (noise end)
        // the march translates to a standard: p = ro + rd *d then p.z += t *4.
        for (p = vec3(u * d, d + t * 4.0), s = 0.01; s < 2.0;
             // add noise to our plane (used as .5+p.y above a few lines)
             // so it looks like mountains...
             // Ensure dot product is with a vec3 and apply robustness to division by s
             p += abs(dot(sin(p * s * 18.0), vec3(0.01))) / max(s, EPSILON),
             s += s);
    }
    // tanh for tone mapping, / 6e2 to divide down brightness,
    // length(--u) makes our light off screen
    // Replace tanh() with tanh_approx() and apply robustness to division by length(--u)
    // --u is interpreted as u - vec2(1.0)
    o = tanh_approx(o / (6e2 * max(length(u - vec2(1.0)), EPSILON)));

    // --- Post-processing: Apply Brightness, Contrast, Saturation (BCS) ---
    // Extract RGB components for manipulation
    vec3 finalColor = o.rgb;

    // Apply Brightness
    finalColor += BRIGHTNESS;

    // Apply Contrast (pivoting around a mid-gray value of 0.5)
    finalColor = (finalColor - 0.5) * CONTRAST + 0.5;

    // Apply Saturation (mix between grayscale and original color)
    // Calculate luminance (perceptual grayscale conversion)
    vec3 luminance = vec3(dot(finalColor, vec3(0.299, 0.587, 0.114)));
    finalColor = mix(luminance, finalColor, SATURATION);

    // Clamp values to ensure they stay within the valid [0,1] range
    finalColor = clamp(finalColor, 0.0, 1.0);

    // Assign the processed color back to the output, preserving original alpha
    o.rgb = finalColor;
}