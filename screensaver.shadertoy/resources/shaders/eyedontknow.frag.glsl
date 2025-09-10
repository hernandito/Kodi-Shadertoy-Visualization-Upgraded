// Kodi does not support #version statements.
// Kodi does not support uniform statements.

// The Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 1.06
#define CONTRAST   1.3
#define SATURATION 1.0

vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    // Brightness
    color += brightness - 1.0;
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    // Saturation
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

void mainImage(out vec4 o, vec2 u) {
    // Variable declarations and explicit initialization iTime
    float i = 0.0;
    float a = 0.0;
    float d = 0.0;
    float s = 0.0;
    float t = iTime;
    
    // `tanh` is not supported, so it is replaced with `tanh_approx`.
    // The `.x` component is used because `tanh_approx` returns a vec4.
    float f = (tanh_approx(vec4(cos(t*.5 * 0.3) * 23.0)).x * 0.3) * 16.0;
    
    vec3 p = iResolution;
    
    // Scale coords
    u = (u + u - p.xy) / max(p.y, 1e-6);

    // Main raymarch loop
    for (o = vec4(0.0); i++ < 64.0;
        d += s = 0.001 + abs(s),
        o += (1.0 + cos(0.3 * p.z + vec4(3, 1, 0, 0))) / max(s, 1e-6))
    {
        // Noise loop nested in the initializer of the main loop
        for (
            p = vec3(u * d, d),
            s = max(cos(p.z * 0.3), f + 0.1 - length(p.xy * sin(p.y * 0.1))),
            a = 0.2; a < 16.0; a += a)
        {
            s += abs(dot(sin(0.3 * t*.3 + p * a), 0.1 + p - p)) / max(a, 1e-6);
        }
    }

    // Tanh tonemapping with robust conversion method
    // Clamping the divisor to prevent the image from becoming too dark
    float length_u = length(u *= 1.5);
    float divisor = max(f > 1.0 ? f * dot(u, u) : 1.0, 0.001);
    
    // Final division and robust tanh
    vec4 tanhValue = (o / 1e4) / max(divisor, 1e-6);
    o = tanh_approx(tanhValue);

    // Apply post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}