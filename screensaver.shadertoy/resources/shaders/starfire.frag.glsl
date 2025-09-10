// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 1.0
#define CONTRAST   1.10
#define SATURATION 1.0
#define FOV        1.0
#define TURBULENCE_DETAIL 1.50 // New parameter for turbulence scale

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

void mainImage(out vec4 o, vec2 u) {
    // Explicit variable initialization to prevent undefined behavior.
    float i = 0.0;
    float a = 0.0;
    float dist = 0.0; // Separate variable for raymarching distance
    float s = 0.0;
    float t = iTime;
    
    vec3 p = vec3(0.0);
    vec3 r = iResolution;
    
    // Initialize 'o' to vec4(0.0) (black) to ensure a black background.
    o = vec4(0.0);
    
    // The main loop.
    for(i = 0.0; i++ < 1e2;
        // The raymarching distance is now tracked with 'dist'.
        dist += s = 0.005 + abs(s) * 0.5,
        // The color accumulation is now faded by a factor of the distance 'd'.
        o += vec4(11.0, 2.7 - cos(0.5 * t) * 0.6, 0.8, 0.0) / max(s, 1e-6) * (1.0 / (1.0 + dist * 0.1)))
    {
        // Inner loop.
        for (p = vec3(((u - r.xy / 2.0) / max(r.y, 1e-6) / FOV + cos(t * 0.3) * vec2(0.02, 0.03)) * dist, dist - 9.0),
             s = length(p) - 5.8, // 's' is now used exclusively for the inner fractal.
             a = 1.0; a < 24.0; a += a)
        {
            // Apply the TURBULENCE_DETAIL parameter to increase the frequency.
            p += cos(0.15 * t + a + p.yzx * 3.0 * TURBULENCE_DETAIL) * 0.3,
            // Division is made robust.
            s -= abs(dot(sin(0.14 * t + p * a * 6.0 * TURBULENCE_DETAIL), 0.05 + p - p)) / max(a, 1e-6);
        }
    }
    
    // Refined Tanh Application: compute value and apply tanh_approx.
    vec4 tanhValue = o / 1e4;
    o = tanh_approx(tanhValue);
    
    // Apply BCS post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}