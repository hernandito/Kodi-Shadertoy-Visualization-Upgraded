// --- OpenGL ES 1.0 Compatible tanh approximation ---
vec4 tanh_approx(vec4 x) {
    // Approximation of tanh(x) = x / (1.0 + abs(x))
    return x / (1.0 + abs(x)); // Use 1.0 for clarity
}

void mainImage(out vec4 o, vec2 u) {
    // Declare variables used throughout the shader
    float od; // Distance variable
    float i;  // Main loop iterator
    float a;  // Inner loop iterator
    float d = 0.0; // Accumulated distance - Initialize to 0.0
    float s;  // Step size / distance variable
    float t = iTime; // Time uniform

    // Declare variables used in the loop before the loop
    vec4 o_accumulated = vec4(0.0); // Accumulated color - Initialize to 0.0
    vec3  p_res = iResolution.xyz; // Resolution - Use .xyz for clarity
    vec3  p; // Position vector used in the loops

    // Normalize UV coordinates
    u = (u - p_res.xy / 2.5) / p_res.y; // Use 2.0 for clarity

    // Main Raymarch loop (standardized structure)
    // Step through the scene, up to 100 steps
    for (i = 0.0; i < 100.0; i += 1.0) // Converted to standard for loop (1e2 = 100.0)
    {
        // Compute position vector
        p = vec3(u * d, d);

        // Calculate distance 'od'
        // Use explicit floats for constants and handle nested sin calls
        od = length(p - vec3(sin(sin(t)+sin(t*0.1))*d/2.0, // Use 0.1, 2.0 for clarity
                             sin(sin(t*1.7) + sin(t*0.1))*d/4.0, // Use 1.7, 0.1, 4.0 for clarity
                             sin(t*0.5)*5.0+7.0)) - 0.8; // Use 0.5, 5.0, 7.0, 0.8 for clarity

        // Calculate step size 's' based on 'od' and 'p.y'
        s = min(od, 4.0 - abs(p.y)); // Use 4.0 for clarity

        // Inner loop for additional detail/complexity (standardized structure)
        // Loop condition: a < 2.0
        for (a = 0.1; a < 2.0; a += a) // Converted to standard for loop (0.1, 2.0 for clarity)
        {
            // Apply cosine-based position modification
            p += cos(t + p.yzx) * 0.03; // Use 0.03 for clarity

            // Modify 's' based on dot product and scaling
            // Use explicit floats for constants
            s -= abs(dot(sin(p * a * 8.0), vec3(0.05))) / a; // Use 8.0, 0.05 for clarity
        }
        // --- End of Inner loop ---

        // Update accumulated distance 'd' and step size 's'
        // This is a compound assignment in the original loop header
        s = 0.02 + abs(s) * 0.1; // Use 0.02, 0.1 for clarity
        d += s; // Accumulate distance

        // Accumulate color based on the step size
        // Use explicit floats for color vector
        // Add a small epsilon to 's' to prevent division by zero if s is very small
        o_accumulated += vec4(4.0, 3.0, 2.0, 0.0) / max(s, 0.0001); // Use 4.0, 3.0, 2.0, 0.0, 0.0001 for clarity and max for safety
    }
    // --- End of Main Raymarch loop ---

    // Apply tanh for soft tone mapping
    // Replaced tanh with tanh_approx and applied scaling
    // The original scaling is o / 2e3 / abs(od) which is o / (2000.0 * abs(od))
    // Need to be careful with abs(od) being zero or very small.
    // Let's use a small epsilon for abs(od) as well.
    float scaling_factor = 2000.0 * max(abs(od), 0.0001); // Use 2000.0, 0.0001 for clarity and max for safety
    o = tanh_approx(o_accumulated / scaling_factor); // Apply scaling before tanh_approx

    // Final clamp to ensure valid output range
    o = clamp(o, 0.0, 1.0); // Use 0.0, 1.0 for clarity
}
