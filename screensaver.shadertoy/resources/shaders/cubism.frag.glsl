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

void mainImage(out vec4 O, vec2 I)
{
    //Iterator, raymarch depth and step distance
    float i, z, d;
    // Initialize output color
    O = vec4(0.0);

    // Normalize UV coordinates and compute ray direction
    vec2 uv = (I - iResolution.xy / 1.30) / iResolution.y;
    vec3 rayDir = normalize(vec3(uv, 1.0)); // Assuming camera is at origin looking along +Z

    // Raymarch depth (start slightly away from origin)
    z = 0.1; // Starting depth

    // Raymarch loop (standardized structure)
    // Raymarch 50 steps
    for(i = 0.0; i < 50.0; i += 1.0)
    {
        //Compute raymarch point from raymarch distance and ray direction
        vec3 p = z * rayDir;

        //Temporary vector for sine waves
        vec3 v;

        //Scroll forward
        p.z -= iTime;

        //Compute distance for sine pattern
        // Simplified step size calculation
        float step_pattern_dist = length(max(v = cos(p) - sin(p).yzx, v.yzx * 0.2));
        d = 0.0001 + 0.5 * step_pattern_dist; // Calculate step size

        // Accumulate raymarch depth
        z += d;

        // Use position for coloring
        // Scale down the color accumulation slightly
        O.rgb += (cos(p) + 1.2) / (d * 5.0); // Added a scaling factor (5.0)

        // Optional: Early exit if far away (can improve performance)
        // if (z > 100.0) break;
    }

    //Tonemapping
    O /= (O + 1000.0); // Adjusted 1e3 to 1000.0 for clarity

    // Apply post-processing (adjust values as needed)
    // brightness, contrast, saturation
    O = applyPostProcessing(O, 1.0, 1.0, 1.0); // Start with neutral values

    // Final clamp to ensure valid output range
    O = clamp(O, 0.0, 1.0);
}
