precision highp float;

// Robust Tanh Conversion: Define tanh_approx (even if not used, per directive)
vec4 tanh_approx(vec4 x) { 
    const float EPSILON = 1e-6; 
    return x / (1.0 + max(abs(x), EPSILON)); 
}

void mainImage(out vec4 o, vec2 C) {
    vec2 n = vec2(0.0);  // Explicit initialization
    float S = 3.0, a = 0.0, c = 0.74, s = 0.70;
    mat2 m = mat2(c, -s, s, c);

    // Normalize coordinates with safe division
    o.xy = (C + C - iResolution.xy) / max(iResolution.y, 1e-6);

    // "neural noise": inspiration from: https://x.com/zozuar/status/1625182758745128981
    for (float j = 0.0; j < 33.0; j += 1.0) {
        o.xy *= m; 
        n *= m;
        vec2 q = o.xy * S + n - iTime * 0.3;
        a += dot(cos(q), vec2(1.8)) / max(S, 1e-6);
        n += sin(q);
        S *= 1.2;
    }

    float l = length(o.xy);
    o = vec4((0.5 + 0.5 * cos(a + a + vec3(1.0))) / max(1.0 + l * 0.5, 1e-6) * (1.0 - l * l * 0.1), 1.0);
}