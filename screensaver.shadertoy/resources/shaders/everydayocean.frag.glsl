// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 1.0
#define CONTRAST   1.20
#define SATURATION 1.0
#define COLOR_TINT vec3(1.0, 1.5, 1.0)
#define CLOUD_SCALE 0.4

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

#define PI 3.14159265359
#define res iResolution.xy
#define density 1.00
#define brightness 0.03

// Noise functions.
float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 34.0);
    return fract(sin(p.x + p.y) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float a = 1.0;
    float f = 0.5;
    float r = 0.0;
    
    for(int i = 0; i < 5; i++) {
        r += f * noise(p * a);
        
        a *= 2.0;
        f *= 0.5;
    }
    
    return r;
}

// Volume.
float volume(vec3 p) {
    // Waves.
    p.y += cos(iTime + p.z) * 0.2;
    p.y += cos(iTime + p.x) * 0.2;
    
    // Noise.
    // Use the new CLOUD_SCALE parameter
    float v = abs(p.y - 4.0 * fbm(p.xz * CLOUD_SCALE)) * 0.5 + 0.2;

    return v / max(density, 1e-6);
}

void mainImage(out vec4 O, vec2 I) {
    vec2 p = (I - 0.5 * res) / res.y * 4.0;
    
    vec3 camPos = vec3(0.0, 8.0, -iTime);
    vec3 camDir = normalize(vec3(0.0, -0.5, -0.5));
    
    // Replace radians() with manual conversion
    float fov = 45.0 * (PI / 180.0);
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 camRight = normalize(cross(camDir, worldUp));
    vec3 camUp = cross(camRight, camDir);

    vec3 rayPos = camPos;
    float t_tan = tan(fov * 0.5);
    vec3 rayDir = normalize(camDir + p.x * camRight * t_tan + p.y * camUp * t_tan);
    
    const int maxSteps = 50;    
    vec3 col = vec3(0.0);
    float f = 0.5;
        
    for(int i = 0; i < maxSteps; i++) {
        float v = volume(rayPos);
        
        rayPos += rayDir * v * f;        
        
        // Coloring. Corrected to the original vec3(1.0, 1.3, 1.8)
        vec3 color = vec3(1.0, 1.3, 1.8);
        
        float t_val = (1.0 / max(v, 1e-6)) * f / (length(rayPos - camPos) * 0.3);
        col += color * t_val;
    }
    
    vec4 temp_col = vec4(col * brightness, 0.0);
    col = tanh_approx(temp_col).rgb;
    
    // Apply BCS post-processing
    col = bcs(col, BRIGHTNESS, CONTRAST, SATURATION);
    
    // Apply the new color tint parameter
    O = vec4(col * COLOR_TINT, 1.0);
}