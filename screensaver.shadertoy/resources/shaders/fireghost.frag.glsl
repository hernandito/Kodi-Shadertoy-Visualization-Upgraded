/*
    Playing with turbulence and translucency from
    @Xor's recent shaders, e.g.
        https://www.shadertoy.com/view/wXjSRt
        https://www.shadertoy.com/view/wXSXzV
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
float post_brightness = .9; // Increase for brighter image, decrease for darker
float post_contrast = 1.9;   // Increase for more contrast, decrease for less
float post_saturation = 1.10; // Increase for more saturated colors, decrease for less
// ----------------------------------------

// --- Animation Speed Parameter ---
// Adjust this value to control the overall speed of the animation.
// Increase for faster animation, decrease for slower animation.
float animation_speed = 0.1; // Adjust this value for overall animation speed
// ---------------------------------


void mainImage(out vec4 o, vec2 u) {
    // Raymarch iterator, step distance, accumulated distance (d), step size (s), and Time
    float i;
    float d = 0.0; // Accumulated distance - Initialize to 0.0
    float s;     // Step size
    // --- Scaled time based on animation_speed ---
    float t = iTime * animation_speed; // Scaled time by animation_speed parameter
    // --------------------------------------------

    // Declare variables used in the loop before the loop
    vec4 o_accumulated = vec4(0.0); // Accumulated color - Initialize to 0.0
    vec3  p_res = iResolution.xyz; // Resolution - Use .xyz for clarity
    vec3  p; // Position vector used in the inner loop

    // Normalize UV coordinates
    u = (u - p_res.xy / 2.0) / p_res.y; // Use 2.0 for clarity

    // Raymarch loop (standardized structure)
    // Step through the scene, up to 100 steps
    for (i = 0.0; i < 100.0; i += 1.0) // Converted to standard for loop
    {
        // --- Inner loop for turbulence and translucency ---
        // Initialize step size 's' and position 'p' at the beginning of the inner loop
        s = 0.05; // Use 0.05 for clarity
        p = vec3(u * d, d + t);

        // Inner loop condition: s < 1.0
        for ( ; s < 1.0; s += s) // Standardized inner loop
        {
            // Apply transformations and turbulence
            // Rotate yz plane - Uses scaled time 't'
            float angle = t * 0.01; // Uses scaled time 't'
            mat2 rot_mat = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
            p.yz = rot_mat * p.yz;

            // Apply cosine-based turbulence - Uses scaled time 't'
            p += cos(t + p.yzx * 2.0) * 0.3; // Uses scaled time 't'
            // ----------------------------------------------------------------------

            // Apply dot product based turbulence - Uses scaled time 't'
            // Use explicit float for 6.0 and 32.0
            p += abs(dot(sin(6.0 * t + p.z + p * s * 32.0), vec3(0.006))) / (s * 0.4); // Uses scaled time 't'
            // -----------------------------------------------------------------------------
        }
        // --- End of Inner loop ---

        // Calculate step size 's' after the inner loop completes
        s = 0.03 + abs(0.4 - abs(p.x)) * 0.3; // Use 0.03, 0.4, 0.3 for clarity

        // Advance along the ray by the step size
        d += s; // Accumulate distance

        // Accumulate color based on the step size
        // Add a small epsilon to 's' to prevent division by zero if s is very small
        o_accumulated += 1.0 / max(s, 0.0001); // Use 1.0, 0.0001 for clarity and max for safety
    }
    // --- End of Raymarch loop ---

    // Apply color mixing based on UV.x
    // Use explicit float for 0.3 and -0.3
    // Corrected variable name from O to o_accumulated and applied mix to accumulated color
    o_accumulated *= mix(vec4(1.0, 2.0, 4.0, 0.0), vec4(4.0, 2.0, 1.0, 0.0),
                         smoothstep(0.3, -0.3, u.x)); // Corrected variable name
    // -----------------------------------------------------------------------------

    // Apply tanh for soft tone mapping
    // Replaced tanh with tanh_approx and adjusted the divisor
    // Use explicit float for 1e7 (10,000,000)
    o = tanh_approx(o_accumulated * o_accumulated / 10000000.0); // Use 10000000.0 for clarity

    // --- Apply Post-processing (BCS) ---
    o = applyPostProcessing(o, post_brightness, post_contrast, post_saturation);
    // -----------------------------------

    // Final clamp to ensure valid output range
    o = clamp(o, 0.0, 1.0); // Use 0.0, 1.0 for clarity
}
