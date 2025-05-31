vec4 tanh_approx(vec4 x) {
    // Approximation of tanh(x) = x / (1 + |x|)
    return x / (1.0 + abs(x));
}

vec4 saturate(vec4 color, float sat) {
    // Adjusts color saturation
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    // Applies brightness, contrast, and saturation adjustments
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    color.rgb *= brightness;
    return saturate(color, saturation);
}

void mainImage(out vec4 o, vec2 u) {
    // Raymarch iterator, step distance, depth
    float i, d, s, t = iTime;
    vec3  p_res = iResolution; // Renamed to avoid conflict with 'p' in the loop

    // Normalize UV coordinates
    u = (u - p_res.xy / 3.0) / p_res.y;

    // Initialize output color
    o = vec4(0.0);

    // Initialize raymarch depth and step distance
    float z = 0.0;
    d = 0.0;

    // --- Camera Position Offset ---
    // Add an offset to the raymarch point to simulate moving the camera backward
    // Increase the 'camera_offset_z' value to move the camera further back
    float camera_offset_z = .0010; // Increased starting offset along the Z-axis significantly
    // ------------------------------

    // Raymarch loop (standardized structure)
    // Increased steps slightly for potentially better quality
    for (i = 0.0; i < 100.0; i += 1.0) { // Reverted steps to 100 for now
        //Compute raymarch point from raymarch distance and ray direction
        // Assuming camera is at origin looking along +Z
        vec3 p = vec3(u * d, d + t);

        // Apply camera offset to the raymarch point
        p.z += camera_offset_z;

        // Inner loop for additional detail/complexity (standardized structure)
        float s_inner = 0.15; // Renamed to avoid conflict with outer 's'
        // Use a fixed number of iterations for better compatibility
        for (int j = 0; j < 7; ++j) { // Fixed iterations
             // Apply complex position updates - TWEAK TURBULENCE HERE
             // Adjust multipliers and constants in these lines to change the shape and movement of the waves
             p += cos(t + p.yzx * 0.6) * sin(p.z * 0.1) * 0.1; // Affects wave shape and interaction
             p.y += sin(t + p.x) * 0.03; // Affects vertical displacement

             // Accumulate into p based on dot product and scaling - TWEAK TURBULENCE HERE
             // Adjust the vector (0.1, 0.1, 0.1), the multiplier (24.0), and the divisor (5.0)
             // to change the scale and intensity of the finer noise/turbulence
             p += abs(dot(sin(p * s_inner * 24.0), vec3(0.1, 0.1, 0.1))) / (s_inner * 5.0); // Affects finer details/noise
             s_inner *= 2.25; // Controls how the noise scale changes with each inner iteration - TWEAK HERE
        }

        // Calculate step size
        // Simplified calculation
        s = 0.03 + abs(2.0 + p.y) * 0.7; // Calculate step size

        // Accumulate raymarch depth
        d += s;

        // Accumulate color - Reverted scaling divisor
        o += vec4(1.0, 2.0, 4.0, 0.0) / (s * 8.0); // Reverted divisor from 200.0 to 8.0

        // Optional: Early exit if far away (can improve performance)
        // if (d > 100.0) break; // Using accumulated distance 'd' for check
    }

    // Tanh tonemapping with linear scaling
    // Reverted constant for scaling
    o = tanh_approx(o / 40.0); // Reverted divisor from 1.0 to 40.0

    // Apply post-processing (adjust values as needed)
    // brightness, contrast, saturation
    o = applyPostProcessing(o, .2, 2.8, 0.80); // Reverted to neutral post-processing

    // Final clamp to ensure valid output range
    o = clamp(o, 0.0, 1.0);
}
