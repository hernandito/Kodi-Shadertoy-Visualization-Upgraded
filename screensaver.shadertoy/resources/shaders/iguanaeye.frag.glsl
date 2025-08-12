// went through soooo many variations,
// little tweaks can make a big difference

// Robust Tanh Conversion Method:
// Include the tanh_approx function:
const float EPSILON = 1e-6; // A small epsilon to prevent division by zero or very small numbers
vec4 tanh_approx(vec4 x) {
    // This approximation handles large values by approaching sign(x), similar to true tanh
    return x / (1.0 + abs(x));
}

// --- BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
// Adjust these values to modify the final image appearance.
// BRIGHTNESS: Adds or subtracts from the color (e.g., 0.1 for brighter, -0.1 for darker)
#define BRIGHTNESS 0.10
// CONTRAST: Scales the color around a midpoint of 0.5 (e.g., 1.2 for more contrast, 0.8 for less)
#define CONTRAST 1.30
// SATURATION: Interpolates between grayscale and original color (e.g., 1.5 for more vivid, 0.5 for desaturated)
#define SATURATION 1.0
// -----------------------------------------------------------------------

void mainImage(out vec4 o, vec2 u) {
    // Ensure Explicit Variable Initialization:
    float i = 0.0; // Raymarch iterator
    float d = 0.0; // Step distance (accumulated)
    float s = 0.0; // Signed distance (used in inner calculations, re-assigned in loop)
    float t = iTime*.2; // Animation time

    vec3 p = vec3(0.0); // Point in 3D space, initialized.
    vec3 r_res = iResolution; // Use a separate variable for iResolution to avoid confusion with 'p'

    // Normalize UV coordinates based on resolution.
    // Enhance General Division Robustness: `r_res.y` could be zero.
    u = (u - r_res.xy / 2.0) / max(r_res.y, EPSILON);

    // Explicitly initialize 'o' to vec4(0.0) as `o*=i` would clear it only on the first iteration.
    o = vec4(0.0);

    // Main raymarching loop
    // `i++ < 80.` means 80 iterations. `s > 0.02` is the termination condition.
    // `o += ...` accumulates brightness.
    for ( ; i++ < 80.0; // Changed 80. to 80.0 for float literal
        // Accumulate brightness 'o'. `max(s, 0.02)` already provides robustness.
        o += (1.0 + cos(0.3 * p.z + vec4(6.0, 2.0, 3.0, 1.0))) / max(s, 0.02)) // Changed literals to floats
    {
        // Update 'd' (total distance traveled) and 's' (step size for next iteration).
        d += s = 0.4 * abs(s) + 0.003; // Changed literal to float

        // Calculate current 3D point 'p' along the ray.
        p = vec3(u * d, d + t);

        // Apply twist and spin rotation to p.xy.
        p.xy *= mat2(cos(0.1 * t + p.z * 0.2 + vec4(0.0, 33.0, 11.0, 0.0))); // Changed literals to floats

        // Apply cosine-based displacement.
        p += cos(0.2 * t + p.yzx) * 0.6; // Changed literal to float

        // Calculate 's' (signed distance/noise value) for the next iteration.
        // `dot(sin(p * 9.0), ...)` ensures dot product operates on floats.
        s = cos(p.x + p.y) + abs(dot(sin(p * 9.0), vec3(0.05) + p - p)); // Changed literal to float
    }

    // Apply tanh tonemapping as a post-processing step to the accumulated color.
    // Replaced `tanh` with `tanh_approx` for Kodi compatibility.
    // The division `o / 3e3` is robust as `3e3` is a large constant.
    o = tanh_approx(o / 3000.0); // Changed 3e3 to 3000.0 for clarity

    // --- Apply BCS (Brightness, Contrast, Saturation) adjustments ---
    // Brightness
    o.rgb += BRIGHTNESS;

    // Contrast (pivot around 0.5)
    o.rgb = (o.rgb - 0.5) * CONTRAST + 0.5;

    // Saturation
    float luma = dot(o.rgb, vec3(0.299, 0.587, 0.114)); // Calculate luminance
    o.rgb = mix(vec3(luma), o.rgb, SATURATION); // Mix between grayscale and original color

    // Ensure color values remain within valid range [0, 1] after adjustments
    o = clamp(o, 0.0, 1.0);
    // -----------------------------------------------------------------
}
