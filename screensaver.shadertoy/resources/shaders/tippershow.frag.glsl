// Shadertoy uniforms: iTime, iResolution
precision highp float;

// ---------------- USER PARAMETERS ----------------
#define BRIGHTNESS 1.0
#define CONTRAST   1.10
#define SATURATION 1.0
#define FOV        0.8550 // Field of View adjustment (1.0 = default)
// -------------------------------------------------

// Robust Tanh Conversion Method
// This is a custom approximation for the tanh function, which is not
// supported in OpenGL ES 1.0. It's safe and prevents artifacts.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// ============================================================================
// Utility Functions
// ============================================================================

// Contrast adjustment
// Source: Common GLSL post-processing technique
// >1.0 = increases contrast, <1.0 = decreases contrast
vec3 applyContrast(vec3 c, float contrast) {
    return clamp((c - 0.5) * contrast + 0.5, 0.0, 1.0);
}

// A robust BCS function
vec3 bcs_final(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    
    // Using a luminance formula that is more robust for saturation
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color = mix(grayscale, color, saturation);
    
    return color;
}

// ============================================================================
// Main Image Shader
// ============================================================================

void mainImage(out vec4 o, vec2 u) {
    // --- Screen Setup ---
    vec3 r = iResolution;
    // Apply FOV adjustment
    vec2 uv = (u - 0.5 * r.xy) / r.y / FOV;

    // Output color accumulator
    o = vec4(0.0);

    // --- Raymarch Variables ---
    float d = 0.0;
    float s = 0.0;
    float fd = 0.0;
    vec3 p = vec3(0.0);

    // --- Raymarch Loop ---
    for (float i = 0.0; i++ < 150.0;) {
        s = 0.006 + abs(s) * 0.09;
        d += s;

        // Fog / glow accumulation
        o += sin(d * 0.1 + vec4(1.9, 0.1, p.y * 0.1, 0.1)) / max(abs(s) + 1e-9, 1e-6);

        // Compute 3D ray position
        p = vec3((uv * d) * 3.5, d + iTime*0.1 * 2.0);
        p.x = -0.3 - p.x;

        // --- Turbulence Distortion ---
        vec3 b = p;
        for (float j = 1.0; j <= 2.0; j++) {
            b += sin(b * j + iTime * 0.5).yzx / j;
        }
        p += b * 0.1;

        // --- Rotational Warp ---
        float a = 2.0 + sin(p.x * 0.5 + 9.5);
        mat2 rot = mat2(cos(a), sin(a), -sin(a), cos(a));
        p.xy *= rot;
        
        s = 0.0;

        for (float n = 1.0; n <= 10.0; n *= 4.0) {
            vec3 freq = p * n;

            vec3 timeMod = vec3(
                0.0,
                length(p.xy) * 0.5 + sin(p.z),
                tanh_approx(vec4(p.x - 2.0)).x * 1.25
            );

            fd = 0.5 * length(vec2(p.x + 4.0, p.y - 4.0) * 0.6) * 1.5
                 + sin(p.z - 0.5);

            // FIX: Correctly construct the vec4 from the vec3
            s += abs(min(dot(tanh_approx(vec4(freq * 4.0, 1.0)).xyz, timeMod), fd * 0.75)) / n;
        }
    }

    // --- Post-Processing ---
    vec4 temp_o = o * o / 8e7;
    o = pow(tanh_approx(temp_o), vec4(0.4545));

    o.rgb = applyContrast(o.rgb, 1.5);
    
    // Apply BCS post-processing adjustments
    o.rgb = bcs_final(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}
