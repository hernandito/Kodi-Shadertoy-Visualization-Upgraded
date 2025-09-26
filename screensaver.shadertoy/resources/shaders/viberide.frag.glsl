// Robust Tanh Conversion Method
// This is a custom approximation for the tanh function, which is not
// supported in OpenGL ES 1.0. It's safe and prevents artifacts.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// ---------------- USER PARAMETERS ----------------
#define BRIGHTNESS 0.95
#define CONTRAST   1.30
#define SATURATION 1.0
#define FOV .85
// -------------------------------------------------

#define T (iTime * 0.15 * 0.5)
#define P(z) (vec3(cos((z) * 0.12) * 16.0, cos((z) * 0.1) * 16.0, (z)))
#define R(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize

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

float tunnel(vec3 p) {
    p.xy -= P(p.z).xy;
    return cos(p.z*0.2)*0.45+0.6 - length(p.xy);
}

float fractal(vec3 p) {
    float s = 0.0, w = 1.0, l = 0.0;
    
    p.z *= 0.3;
    p.x -= 1.25;
    p += cos(p.yzx*6.0)*0.3;
    for (s=0.0; s++ < 8.0; p *= l, w *= l ) {
        p = abs(sin(p))-1.0;
        l = 1.25/max(dot(p,p), 1e-6);
    }
    
    return length(p)/w;
}

float map(vec3 p) {
    return max(fractal(p), tunnel(p));
}

void mainImage(out vec4 o, in vec2 u) {
    float s = 0.0, d = 0.0, i = 0.0;
    vec3  r = iResolution;
    u = (u-r.xy/2.0)/r.y / FOV;
    vec3  e = vec3(0.001,0.0,0.0);
    vec3  p = P(T),ro=p;
    vec3  Z = N( P(T+1.0) - p);
    vec3  X = N(vec3(Z.z,0.0,-Z.x));
    vec3  D = vec3(R(sin(T*0.2)*0.4)*u, 1.0)
             * mat3(-X, cross(X, Z), Z);
    
    o = vec4(0.0);
    for(;i++ < 128.0;) {
        p = ro + D * d * 0.5;
        d += s = map(p);
        o += 2.0*vec4(16.0,2.0,1.0,0.0) + 0.03*vec4(1.0,2.0,5.0,4.0)/max(0.001+abs(s), 1e-6);
    }
    
    o *= o;
    
    // Convert tanh
    vec4 temp_val = o / 1e9 * exp(d/2.0);
    o = tanh_approx(sqrt(temp_val));

    // Apply BCS post-processing adjustments
    o = bcs_final(o, BRIGHTNESS, CONTRAST, SATURATION);
}
