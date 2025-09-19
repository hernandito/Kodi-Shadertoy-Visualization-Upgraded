// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters for color adjustment
#define BRIGHTNESS 0.950
#define CONTRAST   1.80
#define SATURATION 1.0
#define COLOR_TINT vec3(1.0, 1.0, 1.0)

// New parameter to control the color of the animated surface element
#define SURFACE_COLOR vec3(4.0, 4.0, 4.0)

// New parameter to adjust the strength of the turbulence effect
#define TURBULENCE_STRENGTH 0.03

// Function for Brightness, Contrast, and Saturation adjustments
vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

void mainImage(out vec4 o, vec2 u) {
    // Explicitly declare and initialize variables
    float d = 0.0, a = 0.0, i = 0.0, s = 0.0;
    float t = iTime;
    vec3 p = iResolution.xyz;
    vec2 f = vec2(cos(t * 0.1) * 0.3, cos(t * 0.3) * 0.1);
    
    // scale coords
    u = (u + u - p.xy) / p.y;
    
    // camera movement
    u += f;
    
    // Initialize output color to zero
    o = vec4(0.0);
    
    // Main for loop, separated for readability and compatibility
    for (i = 0.0; i < 100.0; i++) {
        
        // This is the core logic from the original compact loop header
        d += s = 0.03 + 0.5 * abs(s);
        
        // Accumulate color
        o += vec4(SURFACE_COLOR, 0.0) / max(s, 1e-6)
           + vec4(1.0, 2.0, 8.0, 0.0) / max(length(u), 1e-6)
           + 3.0 * vec4(5.0, 2.0, 1.0, 0.0) / max(length(vec2(u.x - 1.5, u.y - 0.7) - f), 1e-6);
        
        // Inner loop
        vec3 p_inner = vec3(u * d, d + t);
        s = mix(p_inner.y - 4.0, 6.0 + p_inner.y, dot(u, u));
        
        for (a = 0.5; a < 8.0; a += a) {
            // Apply turbulence using the new parameter
            p_inner += cos(0.7 * t + p_inner.yzx) * TURBULENCE_STRENGTH;
            s -= abs(dot(sin(0.1 * t + p_inner / max(a, 1e-6)), 0.1 + p_inner - p_inner)) * a;
        }
    }
    
    // tanh tonemap, made robust with max and tanh_approx
    o = tanh_approx(o / max(3e3, 1e-6));
    
    // Apply BCS and color tint
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
    o.rgb *= COLOR_TINT;
}