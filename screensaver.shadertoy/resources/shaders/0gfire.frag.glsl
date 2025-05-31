/*
    "Ionize" by @XorDev

     https://x.com/XorDev/status/1921224922166104360
*/

// --- OpenGL ES 1.0 Compatible tanh approximation ---
vec4 tanh_approx(vec4 x) {
    // Approximation of tanh(x) = x / (1.0 + abs(x))
    return x / (1.0 + abs(x)); // Use 1.0 for clarity
}

// --- Post-processing functions for better output control (BCS) ---
vec4 saturate(vec4 color, float sat) {
    // Adjusts color saturation
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    // Applies brightness, contrast, and saturation adjustments
    color.rgb = (color.rgb - 0.5) * contrast + 0.5; // Use 0.5 for clarity
    color.rgb *= brightness;
    return saturate(color, saturation);
}
// -----------------------------------------------------------------

// --- Post-processing Parameters (BCS) ---
// Adjust these values to fine-tune the final image appearance AFTER tone mapping
float post_brightness = 1.20; // Increase for brighter image, decrease for darker
float post_contrast = 1.05;   // Increase for more contrast, decrease for less
float post_saturation = 1.30; // Increase for more saturated colors, decrease for less
// ----------------------------------------


void mainImage(out vec4 O, in vec2 I)
{
    // Declare variables used throughout the shader
    float t = iTime; // Time for waves and coloring
    float i;  // Raymarch iterator
    float z = 0.0; // Raymarch depth - Initialize to 0.0
    float d;  // Raymarch step distance
    float s;  // Signed distance for coloring

    // Declare variables used in the loop before the loop
    vec4 o_accumulated = vec4(0.0); // Accumulated color - Initialize to 0.0
    vec3  p; // Raymarch sample point
    vec3  v; // Vector for undistorted coordinates
    vec3  p_res = iResolution.xyz; // Resolution - Use .xyz for clarity

    // Clear fragcolor and main raymarch loop (standardized structure)
    // Loop 100 times
    for (i = 0.0; i < 100.0; i += 1.0) // Converted to standard for loop (1e2 = 100.0)
    {
        // Raymarch sample point
        // Normalize screen coordinates and scale by raymarch depth 'z'
        p = z * normalize(vec3(I+I, 0.0) - p_res.xyy); // Use 0.0 for clarity, p_res for resolution

        // Shift camera back 9 units
        p.z += 9.0; // Use 9.0 for clarity

        // Save coordinates
        v = p;

        // Apply turbulence waves (standardized structure)
        // https://mini.gmshaders.com/p/turbulence
        // Loop condition: d < 9.0
        for (d = 1.0; d < 9.0; d += d) // Converted to standard for loop (1.0, 9.0 for clarity)
        {
            // Apply sine-based position modification
            // Use explicit float for 0.5
            p += 0.5 * sin(p.yzx * d + t) / d;
        }
        // --- End of Inner loop ---

        // Distance to gyroid and spherical boundary calculation
        // This is a compound assignment in the original loop header
        // Use explicit floats for constants
        d = 0.2 * (0.01 + abs(s = dot(cos(p), sin(p / 0.7).yzx)) // Use 0.2, 0.01, 0.7 for clarity
        // Spherical boundary
        - min(d = 6.0 - length(v), -d * 0.1)); // Use 6.0, 0.1 for clarity

        // Update raymarch depth
        z += d; // Accumulate raymarch depth

        // Coloring and glow attenuation
        // Use explicit floats for color vector and constants
        // Add a small epsilon to 'd' and 'z' to prevent division by zero if they are very small
        o_accumulated += (cos(s / 0.1 + z + t + vec4(2.0, 4.0, 5.0, 0.0)) + 1.2) / max(d, 0.0001) / max(z, 0.0001); // Use 0.1, 2.0, 4.0, 5.0, 0.0, 1.2, 0.0001 for clarity and max for safety
    }
    // --- End of Main Raymarch loop ---

    // Tanh tonemapping
    // https://www.shadertoy.com/view/ms3BD7
    // Replaced tanh with tanh_approx and applied scaling
    // The original scaling is O / 2e3 which is O / 2000.0
    // Use explicit float for 2e3 (2000.0)
    O = tanh_approx(o_accumulated / 2000.0); // Use 2000.0 for clarity

    // --- Apply Post-processing (BCS) ---
    O = applyPostProcessing(O, post_brightness, post_contrast, post_saturation);
    // -----------------------------------

    // Final clamp to ensure valid output range
    O = clamp(O, 0.0, 1.0); // Use 0.0, 1.0 for clarity
}
