// Robust Tanh Conversion Method
// This is a custom approximation for the tanh function, which is not
// supported in OpenGL ES 1.0. It's safe and prevents artifacts.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// ---------------- USER PARAMETERS ----------------
#define BRIGHTNESS 1.10
#define CONTRAST   1.3
#define SATURATION 1.40

#define ANIMATION_SPEED .2
#define FOV .95
// -------------------------------------------------

#define T (iTime * ANIMATION_SPEED)

// A robust BCS function
vec4 bcs_final(vec4 color, float brightness, float contrast, float saturation) {
    color.rgb += brightness - 1.0;
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    
    // Using a luminance formula that is more robust for saturation
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color.rgb = mix(grayscale, color.rgb, saturation);
    
    return color;
}

vec4 blood(vec2 u) {
    float i=0.0, a=0.0, d=0.0, s=0.0, t=.4*T;
    vec3  p;
    vec4 o = vec4(0.0);
    for(; i++<64.0;
        d += s = 0.01 + abs(s) * 0.4,
        o.r+=d/max(s, 1e-6))
        for (p = vec3(u * d, d + t),
            s = min(cos(p.z), 6.0 - length(p.xy)),
            a = 0.8; a < 16.0; a += a)
            p += cos(t+p.yzx)*0.2,
            s += abs(dot(sin(t+.2*p.z+p * a), 0.6+p-p)) / max(a, 1e-6);
    return o * 20.0;
}

vec4 fire(vec2 u) {
    float i=0.0, d=0.0, s=0.0, n=0.0;
    vec3 p;
    vec4 o = vec4(0.0);
    for(; i++<100.0; ) {
        p = vec3(u * d, d);
        p += cos(p.z+T+p.yzx*0.5)*0.6;
        s = 6.0-length(p.xy);
        p.xy *= mat2(cos(0.3*T+vec4(0,33,11,0)));
        for (n = 1.6; n < 32.0; n += n )
            s -= abs(dot(sin( p.z + T + p*n ), vec3(1.12))) / max(n, 1e-6);
        d += s = 0.01 + abs(s)*0.1;
        o += 1.0 / max(s, 1e-6);
    }
    return (vec4(5.0,2.0,1.0,1.0) * o * o / d);
}

void mainImage(out vec4 o, in vec2 u) {
    float s=0.0, d=0.0, i=0.0;
    vec3 p = iResolution;
    u = (u-p.xy/2.0)/p.y / FOV;

    vec4 temp_val = mix(fire(u), blood(u), 0.9);
    o = tanh_approx(temp_val / 500000.0);
    
    o = bcs_final(o, BRIGHTNESS, CONTRAST, SATURATION);
}