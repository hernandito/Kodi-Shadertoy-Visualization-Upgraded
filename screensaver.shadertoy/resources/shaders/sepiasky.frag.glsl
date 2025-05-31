precision highp float; // Required for GLSL ES 1.0

// --- OpenGL ES 1.0 Compatible tanh approximation ---
// This function approximates the hyperbolic tangent, which is not directly
// supported in GLSL ES 1.0. It provides a similar S-shaped curve for tone mapping.
vec4 tanh_approx(vec4 x) {
    // Approximation of tanh(x) = x / (1.0 + abs(x))
    return x / (1.0 + abs(x)); // Use 1.0 for clarity
}

void mainImage(out vec4 o, vec2 u) {
    float i;  // Loop iterator
    float d;  // Accumulated distance for raymarching
    float s;  // Step size / signed distance
    float n;  // Noise loop iterator
    float t = iTime * 2.0; // Time uniform, scaled by 2.0

    vec3 q; // Temporary position vector
    vec3 p_res = iResolution.xyz; // Resolution vector (using .xyz for clarity)

    // Normalize UV coordinates: scale to -aspect_ratio to aspect_ratio in x, and -1 to 1 in y
    u = (u - p_res.xy / 2.0) / p_res.y; // Use 2.0 for clarity

    // Initialize accumulated color to black
    o = vec4(0.0); // Explicitly initialize output color to 0.0

    // Initialize raymarch accumulated distance to 0.0
    d = 0.0;

    // Main Raymarch loop (standardized structure)
    // Loop 100 times (1e2 = 100.0)
    for (i = 0.0; i < 100.0; i += 1.0) { // Converted to standard for loop
        // March the ray: current sample point in 3D space
        // 'q' and 'p' are both set to this new sample point
        q = vec3(u * d, d + t); // Current raymarch position based on accumulated distance 'd' and time 't'
        vec3 p = q; // 'p' is used for noise perturbation

        // Start noise loop
        // 'n' starts at 0.03 and doubles each iteration, up to 2.0
        for (n = 0.03; n < 2.0; n += n) { // Converted to standard for loop
            // Modify 'p' (our ground plane/low detail) with noise
            // This adds turbulence and texture to the scene's geometry
            p += abs(dot(sin(p * n * 4.0), vec3(0.035))) / n; // Use 4.0, 0.035 for clarity
            // 'q' could also be modified here for sky effects, but is not in this shader
        }

        // Calculate step size 's' based on two planes
        // 2.5 - p.y: distance to a horizontal plane at y=2.5, affected by p's noise
        // 2.5 + q.y: distance to another horizontal plane at y=-2.5, affected by q (less noisy)
        // min() combines these, and abs() makes it a thickness
        // 0.04 is a base step, 0.6 is a scaling factor for the thickness
        s = 0.04 + abs(min(2.5 - q.y - (cos(p.x) * 0.2), 2.5 + p.y)) * 0.6; // Use 2.5, 0.2, 0.04, 0.6 for clarity

        // Accumulate raymarch distance 'd'
        d += s;

        // Accumulate color 'o'
        // Brighter where 's' (step size/thickness) is smaller
        // Added max(s, 0.0001) to prevent division by zero if 's' becomes too small
        o += 1.0 / max(s, 0.0001); // Use 1.0 for clarity, added epsilon for safety
    }

    // Apply tone mapping using the GLSL ES 1.0 compatible tanh_approx function.
    // The original scaling is `vec4(4,2,1,1) * o / 4e3 / length(u-=.1)`.
    // We need to ensure the input to `tanh_approx` is in a reasonable range.
    // `4e3` is 4000.0.
    // `u-=.1` modifies `u` in place, then `length()` is called.
    // Added `max(length(u), 0.0001)` to prevent division by zero if `length(u)` is very small.
    o = tanh_approx(vec4(4.0, 2.0, 1.0, 1.0) * o / 4000.0 / max(length(u -= 0.1), 0.0001)); // Use 4.0, 2.0, 1.0, 1.0, 4000.0, 0.1, 0.0001 for clarity

    // Final clamp to ensure valid output range (0.0 to 1.0) for display
    o = clamp(o, 0.0, 1.0); // Use 0.0, 1.0 for clarity
}
