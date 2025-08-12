#ifdef GL_ES
precision mediump float;
#endif

// === USER CONTROLS ===
#define BRIGHTNESS 1.2   // >1.0 brighter, <1.0 darker
#define CONTRAST   1.35  // >1.0 increases contrast
#define COLOR_SCALE vec3(1.0, 1.0, 1.0) // per-channel scaling (R,G,B)

// Robust tanh replacement
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Time
#define T (iTime * 0.2)

// the bubble ghost thing
float orb(vec3 p, float f, float zoffs) {
    return length(p - vec3(
        sin(sin(f * 0.5) + T * 0.7) * 4.0,                         // X
        1.0 + sin(sin(f * 1.3) + T * 0.5) * 1.23,                   // Y
        zoffs + 5.0 + T + cos(T * 0.5) * 6.0                        // Z
    ));
}

// apollonian fractal
float fractal(vec3 p) {
    float s = 0.0;
    float w = 1.0;
    float l = 1.0;

    // scale
    p.y *= 0.5;

    // translate
    p.xy -= 1.5;

    // fractal iterations
    for (int iter = 0; iter < 8; iter++) {
        p = sin(p);
        l = 3.0 / max(dot(p, p), 1e-6);
        p *= l;
        w *= l;
    }

    return length(p) / max(w, 1e-6);
}

void mainImage(out vec4 o, in vec2 u) {
    // Explicit initialization
    float d = 0.0;
    float i = 0.0;
    float e = 0.0;
    float s = 0.0;

    // temporarily resolution, then raymarch point
    vec3 p = iResolution;
    
    // scale coords
    u = (u - p.xy * 0.5) / p.y;
    
    // look around
    u += vec2(sin(T * 0.2) * 0.3,
              sin(T * 0.5) * 0.1);
    
    // clear output
    o = vec4(0.0);
    
    // raymarch
    for (i = 0.0; i < 80.0; i++) {
        // ray position
        p = vec3(u * d, d + T);
        
        // ghosts
        e = 0.009 + abs(orb(p, p.z * 0.3, 6.0) - 0.4) * 0.8;
        e = min(e, 0.009 + abs(orb(p, p.z * 0.1, 3.0) - 0.2) * 0.8);
        e = min(e, 0.009 + abs(orb(p, p.z * 0.2, 4.0) - 0.3) * 0.8);
        
        // accumulate dist of ghost, fractal or floor
        s = min(e,
                min(fractal(p),
                    0.001 + abs(1.2 + p.y) * 0.8));
        
        d += s;
        
        // accumulate light/color
        o += 1.0 / max(s + e * 3.0, 1e-6);
    }

    // tonemap using tanh_approx
    o = tanh_approx(vec4(4.0, 2.0, 1.0, 0.0) * o * o / 400.0);

    // === POST-COLOR ADJUSTMENTS ===
    // Apply brightness
    o.rgb *= BRIGHTNESS;

    // Apply contrast (centered around 0.5)
    o.rgb = (o.rgb - 0.5) * CONTRAST + 0.5;

    // Apply per-channel scaling
    o.rgb *= COLOR_SCALE;

    // Clamp to avoid out-of-range values
    o.rgb = clamp(o.rgb, 0.0, 1.0);
}
