precision highp float; // Added precision directive for GLSL ES 1.0

// --- OpenGL ES 1.0 Compatible tanh approximation ---
// This function approximates the hyperbolic tangent, which is not directly
// supported in GLSL ES 1.0. It provides a similar S-shaped curve for tone mapping.
vec4 tanh_approx(vec4 x) {
    // Approximation of tanh(x) = x / (1.0 + abs(x))
    // This provides a smooth, S-shaped curve that maps values from (-inf, inf) to (-1, 1).
    // For color values (which are usually positive), it maps (0, inf) to (0, 1).
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
float post_brightness = 1.40; // Increase for brighter image, decrease for darker
float post_contrast = 1.10;   // Increase for more contrast, decrease for less
float post_saturation = 1.0; // Increase for more saturated colors, decrease for less
// ----------------------------------------


// --- Overall Effect Transformation Parameters ---
// These parameters apply to the entire rendered effect.
// effect_offset_x/y: Shifts the entire effect horizontally/vertically.
//                    Positive values shift right/up, negative values left/down.
// effect_rotation_speed: Controls how fast the entire effect rotates around the screen center.
//                        Smaller values for slower rotation, larger for faster.
float effect_offset_x = 0.03;     // Adjust this value to shift the effect horizontally (e.g., 0.1 for slight right shift)
float effect_offset_y = 0.0;     // Adjust this value to shift the effect vertically (e.g., 0.1 for slight up shift)
float effect_rotation_speed = 0.05; // Adjust this value for overall effect rotation speed (e.g., 0.01 for very slow)
// ------------------------------------------------

void mainImage(out vec4 o, vec2 u)
{
    float
    // loop iterator
    i = 0.0, // Explicitly initialize i to 0.0
    // total distance
    d = 0.0, // Explicitly initialize d to 0.0
    // signed distance to tunnel
    s,
    // noise iterator
    n,
    // time (very slow)
    t=iTime*.05; // Use 0.05 for clarity

    // raymarch position, temporarily resolution
    vec3 p_res = iResolution; // Renamed to avoid conflict with 'p' in loop

    // scale coords to viewport
    u = (u-p_res.xy/2.0)/p_res.y; // Use 2.0 for clarity

    // --- Apply Overall Effect Rotation and Offset ---
    // First, apply rotation around the screen center (0,0)
    float overall_angle = iTime * effect_rotation_speed;
    mat2 rotation_matrix = mat2(cos(overall_angle), sin(overall_angle), -sin(overall_angle), cos(overall_angle));
    u = u * rotation_matrix;

    // Second, apply the overall offset to the rotated coordinates
    u += vec2(effect_offset_x, effect_offset_y);
    // ------------------------------------------------


    // zero out o (accumulated color)
    o = vec4(0.0); // Explicitly initialize o to vec4(0.0)

    // Main raymarching loop
    // Loop until 100 iterations (1e2 = 100.0)
    for(; i < 100.0; i += 1.0) { // Converted 1e2 to 100.0 for clarity

        // Calculate raymarch sample point 'p'
        vec3 p = vec3(u * d, d + t*4.0); // Use 4.0 for clarity

        // Perturb 'p' to add turbulence/texture
        p += cos(p.z+t+p.yzx*.5)*.5; // Use 0.5 for clarity

        // Calculate signed distance 's' to the tunnel
        s = 5.0-length(p.xy); // Use 5.0 for clarity

        // Inner loop for noise accumulation
        // 'n' starts at 0.06 and doubles each iteration, up to 2.0
        for (n = .06; n < 2.0; n += n) { // Converted 2. to 2.0 for clarity
            // Rotate p.xy for visual effect
            p.xy *= mat2(cos(t*.1+vec4(0.0,33.0,11.0,0.0))); // Use 0.0 for clarity

            // Subtract noise from 's' to create cloud-like shapes
            // The dot product is a compact way to sum scaled components
            s -= abs(dot(sin(p.z+t+p * n * 20.0), vec3( .05))) / n; // Use 20.0, 0.05 for clarity
        }

        // Accumulate total distance 'd' and update 's' for translucency
        // This is a common pattern for volumetric rendering
        d += s = .02 + abs(s)*.1; // Use 0.02, 0.1 for clarity

        // Accumulate color 'o'
        // Divide by 's' to make closer/thinner areas brighter
        // Added max(s, 0.0001) to prevent division by zero if 's' becomes too small
        o += 1.0 / max(s, 0.0001); // Use 1.0 for clarity, added epsilon for safety
    }

    // Apply tone mapping using the GLSL ES 1.0 compatible tanh_approx function.
    // The original scaling was `o / d / 9e2 / length(u)`.
    // We need to ensure the input to `tanh_approx` is in a reasonable range (e.g., 0-50).
    // The working examples show that the final divisor is typically in the range of 20-2000.
    // Let's use a divisor that is a bit larger than the original 9e2 (900.0)
    // to compensate for potentially large accumulated 'o' values and ensure a good visual range.
    // Added max(d, 0.0001) and max(length(u), 0.0001) for robustness against division by zero.
    o = tanh_approx(
        o / max(d, 0.0001) / // Divide by accumulated distance 'd'
        2000.0 / // Adjusted scaling factor (similar to Ionize and Rollin's final divisors)
        max(length(u), 0.0001) // Use u here as light drift is removed
    );

    // --- Apply Post-processing (BCS) ---
    o = applyPostProcessing(o, post_brightness, post_contrast, post_saturation);
    // -----------------------------------

    // Final clamp to ensure valid output range (0.0 to 1.0) for display
    o = clamp(o, 0.0, 1.0); // Use 0.0, 1.0 for clarity
}
