// A robust tanh function for compatibility with OpenGL ES 1.0.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 0.9
#define CONTRAST   1.40
#define SATURATION 0.80
#define FOV 0.750

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

// Noise function from original shader.
#define N(p)sin(p.x*2.0+sin(p.y*3.0))*cos(p.y*2.0+cos(p.x*3.0))

void mainImage(out vec4 O, vec2 P) {
    // Explicitly declare and initialize all variables
    vec3 c = vec3(0.0);
    vec3 p = vec3(0.0);
    vec3 K = vec3(3.0, 1.0, 0.0);
    vec3 R = iResolution;

    float a = 0.0;
    float g = 0.0;
    float t = 0.0;
    float i = 0.0;
    float h = 0.0;
    float d = 0.0;
    float w = 0.0;
    float k = 0.15;
    
    // Add 180.0 seconds to iTime to start the animation at a more stable point (3 minutes).
    float T = (iTime + 240.0) * 0.1;

    // Main raymarch loop
    for(i = 0.0; i < 100.0; i++) {
        // Update p for each iteration, now with an adjustable FOV parameter
        p = normalize(vec3(P + P - R.xy, -R.y * FOV)) * t;
        
        // Corrected matrix rotation for better precision and compatibility
        float rotation_angle = sin(T * 0.2) + K.z * 11.0; 
        float rot_sin = sin(rotation_angle);
        float rot_cos = cos(rotation_angle);
        mat2 rotation_matrix = mat2(rot_cos, -rot_sin, rot_sin, rot_cos);
        p.xz = p.xz * rotation_matrix;
        
        p.z -= T * 0.5;

        // Inner loop for fractal noise calculation
        h = (d = p.y) + 0.5;
        for(a = 0.01; a < 1.0; a += a) {
            p.xz *= mat2(8.0, 6.0, -6.0, 8.0) * 0.1;
            d += abs(dot(sin((p / a + T) * 0.3), sign(p))) * a;
            h += abs(dot(sin(p.xz * 0.6 / a), K.yy)) * a;
        }

        // The complex update logic from the original for loop header
        d = max(max(-d, d - 3.0), 0.0) * k;
        a = h < 0.001 ? 0.0 : 1.0;
        w = 1.0 - g;
        w *= 1.0 - exp(a == 0.0 ? -h * 300.0 : -d * 2.5);
        g += w * a;
        c += w * a * d * 8.0 + (d == 0.0 ? K * 0.01 * h * a : K.zzz);
        a = clamp(p.y + 2.0, 0.0, 1.0);
        c.r += a * a * 0.2 * w;
        t += min(h * 0.2, k *= 1.015);
    }
    
    // Apply tanh approximation
    vec4 temp_c = vec4(c * 0.5, 0.0);
    c = tanh_approx(temp_c).rgb;

    // Apply BCS post-processing
    c = bcs(c, BRIGHTNESS, CONTRAST, SATURATION);

    // Assign final color to output
    O = vec4(c, 1.0);
}