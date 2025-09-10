// The Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 1.10
#define CONTRAST   1.30
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

// Pseudo-random noise function for improved dithering
float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Refined dithering function
vec3 dither(vec3 color, vec2 fragCoord) {
    float d = (random(fragCoord) - 0.5) / 255.0;
    return color + d;
}

void mainImage(out vec4 o, vec2 u) {
    // Variable declarations and explicit initialization
    float i = 0.0;
    float a = 0.0;
    float d = 0.0;
    float s = 0.0;
    float t = 0.4 * iTime;
    
    vec3 p = iResolution;
    
    // Scale coords. Division is made robust.
    u = (u + u - p.xy) / max(p.y, 1e-6);
    
    // Clear o, march up to 64 steps
    for (o = vec4(0.0); i++ < 64.0;
        // The s variable is guaranteed to be positive, so it's already robust
        d += s = 0.01 + abs(s) * 0.4,
        o += s * d,
        o.r += d / max(s, 1e-6))
    {
        // Noise start
        for (
            p = vec3(u * d, d + t),
            s = min(cos(p.z), 6.0 - length(p.xy * sin(p.y * 0.6))),
            a = 0.8; a < 16.0; a += a)
        {
            p += cos(t + p.yzx) * 0.1,
            // Division is made robust. `a` increases so it won't be zero.
            s += abs(dot(sin(t + 0.2 * p.z + p * a), 0.6 + p - p)) / max(a, 1e-6);
        }
    }

    // Tanh tonemapping with robust conversion method
    // The tanh argument is calculated in a temporary variable first.
    vec4 tanhValue = (o / 2e4) * max(length(u), 1e-6);
    o = tanh_approx(tanhValue);
    
    // Apply post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
    
    // Apply the new, improved dithering
    o.rgb = dither(o.rgb, gl_FragCoord.xy);
}