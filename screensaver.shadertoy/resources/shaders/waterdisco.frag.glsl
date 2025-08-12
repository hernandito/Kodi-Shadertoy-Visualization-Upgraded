#ifdef GL_ES
precision mediump float;
#endif

// Robust Tanh Approximation
vec4 tanh_approx(vec4 x) { const float EPSILON = 1e-6; return x / (1.0 + max(abs(x), EPSILON)); }

// --- BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
// BRIGHTNESS: Adjusts overall brightness (-1.0 to 1.0). Default: 0.0
#define BRIGHTNESS -0.10
// CONTRAST: Adjusts contrast (0.0 for no contrast, >1.0 for more). Default: 1.0
#define CONTRAST 1.40
// SATURATION: Adjusts color saturation (0.0 for grayscale, >1.0 for more vivid). Default: 1.0
#define SATURATION 1.0
// -----------------------------------------------------------------------

// Function to apply Brightness, Contrast, and Saturation adjustments
vec4 postProcessBCS(vec4 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color.rgb += brightness;
    // Apply contrast (pivot around 0.5)
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    // Apply saturation (mix with grayscale)
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // Calculate luminance
    color.rgb = mix(vec3(luma), color.rgb, saturation); // Mix between grayscale and original color
    // Clamp to ensure values stay within [0, 1] range
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    return color;
}

void mainImage(out vec4 O, vec2 I) {
    // Initialize variables
    float t = 0.0, z = 0.0, d = 1.0, i = 0.0;
    vec3 s = vec3(0.0), p = vec3(0.0), c = vec3(0.0);
    O = vec4(0.0);

    // Animation time
    t = iTime*.2;
    // Ray direction
    s = normalize(vec3(2.1 * I, 0.0) - iResolution.xyy);
    // Floor coordinates
    c.z -= t;

    // Clear fragColor and raymarch 30 steps
    for (i = 0.0; i < 30.0; i += 1.0) {
        // Sample point (from ray direction)
        p = z * s + c;
        // Reflect vertically
        d = p.y; // Store p.y before modification for use in mod
        p.y = abs(mod((d = p.y + 1.0) - 2.0, 4.0) - 2.0);
        // Distance to rings with reflection distortion
        z += d = 0.6 * abs(length(cos(p + 0.03 * sin((s / max(abs(s.y), 1e-6) + c) / 0.04) * (p.y - d)).xz) - 0.4)
             + 0.1 * abs(cos(p.y + z));
        // Coloring and brightness
        O.rgb += (1.1 - sin(p)) / max(d, 1e-6);
    }
    // Tanh tonemap
    O = tanh_approx(O / max(4e2, 1e-6));

    // Apply BCS adjustments in post-processing
    O = postProcessBCS(O, BRIGHTNESS, CONTRAST, SATURATION);
}
