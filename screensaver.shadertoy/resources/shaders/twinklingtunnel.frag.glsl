// CC0: Trailing the Twinkling Tunnelwisp
// Adapted for Kodi GLSL ES 1.00 compatibility with BCS adjustments

// Robust Tanh Approximation
vec4 tanh_approx(vec4 x) { const float EPSILON = 1e-6; return x / (1.0 + max(abs(x), EPSILON)); }

// BCS Adjustment Parameters
#define BRIGHTNESS 1.10    // Adjust brightness (1.0 is neutral, >1 increases, <1 decreases)
#define CONTRAST 1.3      // Adjust contrast (1.0 is neutral, >1 increases, <1 decreases)
#define SATURATION 1.0    // Adjust saturation (1.0 is neutral, >1 increases, <1 decreases)

// Gyroid distance field
float g(vec4 p, float s) {
    return abs(dot(sin(p *= s), cos(p.zxwy)) - 1.0) / s;
}

void mainImage(out vec4 O, vec2 C) {
    // Initialize variables
    float i = 0.0, d = 0.0, z = 0.0, s = 0.0, T = 0.0;
    vec4 o = vec4(0.0), q = vec4(0.0), p = vec4(0.0), U = vec4(2.0, 1.0, 0.0, 3.0);
    vec2 r = vec2(0.0);

    // Store resolution
    r = iResolution.xy;

    // Raymarch loop
    T = iTime;
    for (i = 0.0; i < 79.0; i += 1.0) {
        z += d + 5e-4; // Advance with epsilon for translucency
        q = vec4(normalize(vec3(C - 0.5 * r, r.y)) * z, 0.2);
        q.z += T / 30.0; // Traverse cave
        s = q.y + 0.1; // Save sign
        q.y = abs(s); // Mirror for water effect
        p = q;
        p.y -= 0.11;
        // Corrected twist matrix
        float angle = 11.0 * dot(U.zywz, vec4(1.0)) - 2.0 * p.z;
        p.xy *= mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
        p.y -= 0.2;
        // Combine gyroid fields
        d = abs(g(p, 8.0) - g(p, 24.0)) / 4.0;
        // Base glow color
        p = 1.0 + cos(0.7 * U + 5.0 * q.z);
        // Accumulate glow
        o += (s > 0.0 ? 1.0 : 0.1) * p.w * p / max(max(s > 0.0 ? d : d * d * d, 5e-4), 1e-6);
    }

    // Add pulsing glow
    o += (1.4 + sin(T) * sin(1.7 * T) * sin(2.3 * T)) * 1000.0 * U / max(length(q.xy), 1e-6);

    // BCS Adjustments
    vec4 color = tanh_approx(o / max(1e5, 1e-6));
    vec3 grayscale = vec3(dot(color.rgb, vec3(0.299, 0.587, 0.114))); // Luminance
    color.rgb = mix(grayscale, color.rgb, SATURATION); // Saturation
    color.rgb = (color.rgb - 0.5) * CONTRAST + 0.5; // Contrast
    color.rgb += vec3(BRIGHTNESS - 1.0); // Brightness
    O = vec4(clamp(color.rgb, 0.0, 1.0), color.a); // Clamp to valid range
}