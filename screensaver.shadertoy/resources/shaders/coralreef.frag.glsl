/*
    "Cloud Compute" by @XorDev

    Based on my tweet shader:
    https://x.com/XorDev/status/1918680610127659112
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
float post_brightness = 1.10; // Increase for brighter image, decrease for darker
float post_contrast = 1.3;   // Increase for more contrast, decrease for less
float post_saturation = 1.10; // Increase for more saturated colors, decrease for less
// ----------------------------------------

// --- Animation Speed Parameter ---
// Adjust this value to control the overall speed of the animation.
// Increase for faster animation, decrease for slower animation.
float animation_speed = 0.20; // Adjust this value for overall animation speed
// ---------------------------------


void mainImage(out vec4 O, vec2 I)
{
    // Declare variables used throughout the shader
    // --- Scaled time based on animation_speed ---
    float t = iTime * animation_speed; // Scaled time by animation_speed parameter
    // --------------------------------------------
    float i;  // Main loop iterator
    float z = 0.0; // Accumulated distance - Initialize to 0.0
    float d;  // Step size / distance variable

    // Declare variables used in the loop before the loop
    vec4 o_accumulated = vec4(0.0); // Accumulated color - Initialize to 0.0
    vec3  p; // Position vector used in the loops
    vec3  p_res = iResolution.xyz; // Resolution - Use .xyz for clarity

    // Main Raymarch loop (standardized structure)
    // Step through the scene, up to 80 steps
    for (i = 0.0; i < 80.0; i += 1.0) // Converted to standard for loop (8e1 = 80.0)
    {
        // Compute position vector
        // Normalize screen coordinates and scale by accumulated distance 'z'
        p = z * normalize( vec3(I+I, 0.0) - p_res.xxy ); // Use 0.0 for clarity, p_res for resolution

        // Apply time-based translation in xz plane - Uses scaled time 't'
        p.xz -= t; // Uses scaled time 't'
        // ------------------------------------------------------------

        // Reflect y-coordinate around y=4.0
        p.y = 4.0 - abs(p.y); // Use 4.0 for clarity

        // Inner loop for turbulence/noise (standardized structure)
        // Loop condition: d < 20.0
        for (d = 0.7; d < 20.0; d += d) // Converted to standard for loop (0.7, 20.0 for clarity, 2e1 = 20.0)
        {
            // Apply cosine-based position modification - Uses scaled time 't'
            // Use explicit floats for constants
            // --- Replaced round() with floor() + 0.5 for GLSL ES 1.0 compatibility ---
            p += cos(floor(p.yzx * d + 0.5) - 0.2 * t) / d; // Replaced round() with floor() + 0.5, Uses scaled time 't'
            // -------------------------------------------------------------------------
        }
        // --- End of Inner loop ---

        // Update accumulated distance 'z' and calculate step size 'd'
        // This is a compound assignment in the original loop header
        d = 0.01 + abs(p.y) / 15.0; // Use 0.01, 15.0 for clarity
        z += d; // Accumulate distance

        // Accumulate color based on position and distances - Uses scaled time 't' indirectly
        // Use explicit floats for color vector and constants
        // Add a small epsilon to 'z' and 'd' to prevent division by zero if they are very small
        o_accumulated += (cos(vec4(0.0, 1.0, 2.0, 0.0) - p.y * 2.0) + 1.1) / max(z, 0.0001) / max(d, 0.0001); // Use 0.0, 1.0, 2.0, 0.0, 2.0, 1.1, 0.0001 for clarity and max for safety
    }
    // --- End of Main Raymarch loop ---

    // Apply tanh for soft tone mapping
    // Replaced tanh with tanh_approx and applied scaling
    // The original scaling is O / 8e2 which is O / 800.0
    // Use explicit float for 8e2 (800.0)
    O = tanh_approx(o_accumulated / 800.0); // Use 800.0 for clarity

    // --- Apply Post-processing (BCS) ---
    O = applyPostProcessing(O, post_brightness, post_contrast, post_saturation);
    // -----------------------------------

    // Final clamp to ensure valid output range
    O = clamp(O, 0.0, 1.0); // Use 0.0, 1.0 for clarity
}
