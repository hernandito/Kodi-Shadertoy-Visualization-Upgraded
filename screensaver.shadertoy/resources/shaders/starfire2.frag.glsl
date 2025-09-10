// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define FOV .9
#define BRIGHTNESS .7
#define CONTRAST   1.40
#define SATURATION .9

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
    // Explicitly initialize variables to prevent undefined behavior.
    float i = 0.0;
    float a = 0.0;
    float d = 0.0;
    float s = 0.0;
    float t = iTime;
    vec3 p = iResolution;
    
    // Scale coords using the FOV parameter
    u = (u - p.xy / 1.80) / p.y / FOV;
    
    // Initialize output color to black
    o = vec4(0.0);
    
    for(i=0.0; i++ < 100.0;
        d += s = 0.01 + abs(s) * 0.6,
        o += vec4(14.0, 2.7 - cos(0.5 * t) * 0.6, 0.8, 0.0) / max(s, 1e-6))
        for (p = vec3(u * d, d - 9.0),
            p.z *= 0.3,
            p.xy *= mat2(cos(0.01 * t + p.z * d * 0.005 + vec4(0.0, 33.0, 11.0, 0.0))),
            s = max(6.0 - length(p.xy), length(p) - 16.0),
            a = 1.0; a < 8.0; a += a)
            p += cos(0.2 * t + a + p.yzx) * 0.3,
            s -= abs(dot(sin(t + p * a * 6.0), 0.03 + p - p)) / max(a, 1e-6);
            
    // Refined Tanh Application: compute value and apply tanh_approx.
    vec4 tanhValue = o / (10000.0 * max(dot(u + u.yx * 2.0, u), 0.1));
    o = tanh_approx(tanhValue);
    
    // Apply BCS post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}