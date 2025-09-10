// 😎
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 1.0
#define CONTRAST   1.10
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
    // Explicit variable initialization
    float i = 0.0;
    float d = 0.0;
    float s = 0.0;
    float n = 0.0;
    float t = iTime * 0.1;
    
    vec3 p = iResolution * 0.6;
    
    // Make division robust
    u = (u - p.xy / 2.0) / max(p.y, 1e-6);
    
    for(o = vec4(0.0); i++ < 160.0;
        d += s = 0.005 + abs(s) * 0.6, 
        // Divisions are made robust
        o += vec4(5, 2, s, 0) / max(s, 1e-6) / max(d, 1e-6))
    {
        for (p = vec3(u * d, d + t + t),
             p.xy *= mat2(cos(p.z * 0.23 + vec4(0, 33, 11, 0))),
             s = 1.0 + sin(p.y - p.x),
             n = 8.0; n < 32.0; n += n)
        {
            // Division is made robust
            s -= abs(dot(cos(p * s * n), sin(p * 2.0))) / max(n, 1e-6);
        }
    }
    
    // Apply refined tanh conversion. The inner `mix` value is stored in a temporary variable first.
    vec4 tanhValue = mix(o, o.yzxw, i = length(u));
    o = tanh_approx(tanhValue / 2e4 / max(i, 1e-6));
    
    // Apply post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}