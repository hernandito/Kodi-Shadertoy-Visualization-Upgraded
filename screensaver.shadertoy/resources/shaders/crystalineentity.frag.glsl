precision highp float;

#define R(a) mat2(cos(a), -sin(a), sin(a), cos(a))

// Robust Tanh Conversion: Define tanh_approx
vec4 tanh_approx(vec4 x) { 
    const float EPSILON = 1e-6; 
    return x / (1.0 + max(abs(x), EPSILON)); 
}

// Define parameters for post-processing BCS
#define BRIGHTNESS 1.0
#define CONTRAST 1.3
#define SATURATION 1.20

vec3 adjustBCS(vec3 color, float brightness, float contrast, float saturation) {
    color = color * brightness;
    color = (color - 0.5) * contrast + 0.5;
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(gray), color, saturation);
    return color;
}

void mainImage(out vec4 o, vec2 I) {
    float d = 0.0, i = 0.0, s = 0.0, w = 0.0, l = 0.0, t = iTime * 0.3;
    vec3 p = vec3(0.0), q = vec3(0.0), r = iResolution;

    o = vec4(0.0);  // Explicit initialization

    for (; i < 200.0; i += 1.0) {
    
        q = p = vec3((I - r.xy * 0.5) / max(r.y, 1e-6) * d, d - 0.5);
        p.yz *= R(t * 0.1);
        p.xz *= R(t * 0.1);
        
        w = 8.0;
        for (int j = 0; j < 5; j += 1) {  // Initialize loop counter
            p = sin(p);
            l = 1.8 / max(dot(p, p), 1e-6);  // Safe division
            p *= l;
            w *= l;
        }

        d += s = max(length(q) - 0.35, length(p.xz) / max(w, 1e-6));  // Safe division
       
        o += 18.0 * d / max(s, 1e-6);
    } 

    // Robust Tanh Conversion: Compute tanh argument in a temporary variable
    vec4 tanh_input = (vec4(1.0, 2.0, 3.0, 1.0) * o) / 2e7;
    o = tanh_approx(tanh_input);
    
    // Apply BCS adjustment
    o.rgb = adjustBCS(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
    
    // Clamp output to avoid invalid colors
    o = clamp(o, 0.0, 1.0);
}