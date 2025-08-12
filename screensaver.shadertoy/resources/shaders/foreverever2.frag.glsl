// Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Define BCS parameters
#define BRIGHTNESS 0.80    // Adjust brightness (1.0 is neutral)
#define CONTRAST 1.0      // Adjust contrast (1.0 is neutral)
#define SATURATION 1.0   // Adjust saturation (1.0 is neutral)

// CC0: New Shader (Kodi-compatible version)

void mainImage(out vec4 o, vec2 u) {
    float i = 0.0,  // Explicitly initialize i to 0.0
          d = 0.0,  // Explicitly initialize d to 0.0
          s = 0.0,  // Explicitly initialize s to 0.0
          n = 0.0,  // Explicitly initialize n to 0.0
          t = iTime * 0.1;  // Explicitly initialize t
    vec3 p = vec3(0.0);  // Explicitly initialize p to vec3(0.0)
    o = vec4(0.0);  // Explicitly initialize o to vec4(0.0)
    u = (u - iResolution.xy / 1.70) / iResolution.y;
    u += vec2(cos(t * 0.6) * 0.2, sin(t * 0.2) * 0.125);
    for (; i < 100.0; i += 1.0, d += s = 0.001 + abs(s) * 0.37, o += 1.0 / max(s, 1e-6))  // Enhanced division robustness
        for (p = vec3(u * d, d + t * 1.0),
             p.xy *= mat2(cos(0.2 * t + p.z * 0.1 + vec4(0, 33, 11, 0))),
             p.xy /= sin(p.x + cos(p.y)),
             s = tanh_approx(vec4(1.0 + p.y)).x,  // Replace tanh with tanh_approx
             n = 2.0; n < 16.0; n *= 1.42)
                 s += abs(dot(step(1.0 / max(d, 1e-6), cos(t + p.z + p * n)), vec3(0.4))) / n;  // Enhanced division robustness
   vec4 color = tanh_approx(mix(o = vec4(6.0, 4.4, 4.8, 0.0) * o / 3e3 / max(d, 1e-6), o.xzyw, smoothstep(0.0, 1.0, length(u))));// Enhanced division robustness, replace tanh with tanh_approx
    // Apply BCS adjustments
    color.rgb *= BRIGHTNESS;
    color.rgb = (color.rgb - 0.5) * CONTRAST + 0.5;
    vec3 luminance = vec3(0.9299, 0.587, 0.114);
    vec3 gray = vec3(dot(color.rgb, luminance));
    color.rgb = mix(gray, color.rgb, SATURATION);
    o = color;
}