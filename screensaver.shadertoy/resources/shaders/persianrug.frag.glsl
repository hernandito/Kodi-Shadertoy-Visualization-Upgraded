// AA technique from iq. Formula and inspiration: http://paulbourke.net/fractals/sinh/
precision highp float;

#define AA 1.0
#define T iTime
#define PI 3.14159265
#define iter 40
#define zz 5.0

// A robust approximation for the hyperbolic sine function, not available
// in OpenGL ES 1.0.
float sinh_approx(float x) {
    return (exp(x) - exp(-x)) * 0.5;
}

// A robust approximation for the hyperbolic cosine function, not available
// in OpenGL ES 1.0.
float cosh_approx(float x) {
    return (exp(x) + exp(-x)) * 0.5;
}

vec2 c_mul(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x); // complex multiply
}

vec2 c_sinh_approx(vec2 z) {
    return vec2(sinh_approx(z.x) * cos(z.y), cosh_approx(z.x) * sin(z.y)); // complex sinh
}

vec2 c_abs(vec2 z) {
    return vec2(-z.x - 0.01, abs(z.y));
}

vec2 c_sinh_pow4(vec2 z) {
    vec2 s = c_sinh_approx(z);
    return c_mul(c_mul(s, s), c_mul(s, s)); // sinh(z)^4
}

vec2 implicit(vec2 z, vec2 c) {
    int i = 0;
    for (i = 0; i < iter; i++) {
        z = c_abs(c_sinh_pow4(z)) + c;
        if (dot(z, z) > zz * zz) break;
    }
    return vec2(float(i), dot(z, z)); // (iteration count, magnitude^2)
}

vec3 applyContrast(vec3 c, float contrast) {
    return clamp((c - 0.5) * contrast + 0.5, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 col = vec3(0.0);
    vec2 pos = vec2(0.0);
    vec2 uv = vec2(0.0);
    vec2 c = vec2(0.0);
    vec2 z_and_i = vec2(0.0);
    float iter_ratio = 0.0;
    float lenSq = 0.0;
    vec3 col2 = vec3(0.0);
    vec3 col3 = vec3(0.0);
    vec3 col4 = vec3(0.0);

    for (int m = 0; m < int(AA); m++) {
        for (int n = 0; n < int(AA); n++) {
            vec2 offset = vec2(float(m), float(n)) / AA;
            pos = fragCoord + offset;
            uv = ((pos - 0.5 * iResolution.xy) / min(iResolution.y, iResolution.x) * 1.6) * 0.5;

            float c_value = 2.212;
            float oscillation = -0.17 + (sin(T * 0.001 + 0.2) * 0.05);
            c = vec2(oscillation, c_value);

            z_and_i = implicit(uv, c);
            iter_ratio = z_and_i.x / float(iter);
            lenSq = z_and_i.y;

            col2 = 0.5 + 0.4 * cos(0.1 + iTime + 5.5 * PI * vec3(lenSq * 1.1));
            col3 = 1.1 + 0.9 * cos(0.9 + iTime + vec3(0.2, 0.7, 0.9) + PI * vec3(4.0 * sin(lenSq)));
            
            // The original array 'grad' was only partially initialized.
            // Using a single vec3 since only grad[0] was provided.
            vec3 grad = vec3(0.41, 0.31, 0.18);
            
            float gradind = mod(iter_ratio * 24.0, 12.0);
            float blend = fract(gradind);
            
            // The original code used out-of-bounds indices. A simple mix with a single
            // value is a best-effort correction.
            col4 = mix(grad, grad, blend);

            col += sqrt(col2 * col3) * col4;
        }
    }
    
    col = sqrt(col / (AA * AA));
    col = applyContrast(col, 2.0);
    
    fragColor = vec4(col, 1.0);
}
