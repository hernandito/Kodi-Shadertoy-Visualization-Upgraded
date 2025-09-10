#define BRIGHTNESS -0.20   // Adjusts brightness (-1.0 to 1.0, 0.0 is neutral)
#define CONTRAST 1.0     // Adjusts contrast (0.0 to 2.0, 1.0 is neutral)
#define SATURATION 1.0   // Adjusts saturation (0.0 to 2.0, 1.0 is neutral)

void mainImage(out vec4 o, vec2 u) {
    // Initialize variables
    float i = 0.0, d = 0.0, s = 0.0, t = iTime*.2;
    vec3 p = iResolution;
    o = vec4(0.0);
    
    // Transform coordinates
    u = (u + u - p.xy) / p.y + cos(t * 0.4) * vec2(0.3, 0.2);
    
    // Main loop
    for (o *= i; i++ < 128.; d += s = 0.001 + abs(s) * 0.6, o += d / max(s, 1e-6)) {
        p = vec3(u * d, d + t + t);
        p.xy *= mat2(cos(0.1 * t + p.z / 8. + vec4(0, 33, 11, 0)));
        s = 1. + cos(p.y) - abs(dot(sin(p * 24.), 1. + p - p)) / 480.;
    }
    
    // Original color computation with inlined tanh_approx
    vec4 temp = mix(o *= vec4(32, 6, 2, 0) / 1e7, 
                    o.zyxw, 
                    smoothstep(0., 2., i = length(u))) / max(i, 0.001);
    o = temp / (1.0 + max(abs(temp), 1e-6));
    
    // BCS post-processing
    // Brightness: Add offset
    o.rgb += BRIGHTNESS;
    
    // Contrast: Scale around 0.5
    o.rgb = (o.rgb - 0.5) * CONTRAST + 0.5;
    
    // Saturation: Blend with grayscale
    float luminance = dot(o.rgb, vec3(0.299, 0.587, 0.114));
    o.rgb = mix(vec3(luminance), o.rgb, SATURATION);
    
    // Clamp final color to [0, 1]
    o.rgb = clamp(o.rgb, 0.0, 1.0);
}