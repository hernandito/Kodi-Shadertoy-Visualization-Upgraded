precision mediump float; // Required for ES 2.0 (ES 1.0 compatible subset)

#define T iTime*.3
#define PI 3.141596
#define S smoothstep

#define BRIGHTNESS 1.10  // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.30    // Contrast adjustment (1.0 = neutral)
#define SATURATION 2.50  // Saturation adjustment (1.0 = neutral)
#define USE_CUSTOM_PALETTE 1  // 0 for rainbow, 1 for custom palette
#define CYCLE_DURATION 2.0  // Duration in seconds for one full cycle (adjustable)

vec4 tanh_approx(vec4 x) { const float EPSILON = 1e-6; return x / (1.0 + max(abs(x), EPSILON)); }

// https://iquilezles.org/articles/distfunctions/
float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    float d = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
    return d;
}

mat2 rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

void mainImage(out vec4 O, in vec2 I) {
    vec2 R = vec2(0.0); // Initialize resolution
    vec2 uv = vec2(0.0); // Initialize UV coordinates
    vec3 ro = vec3(0.0); // Initialize ray origin
    vec3 rd = vec3(0.0); // Initialize ray direction
    vec3 p = vec3(0.0); // Initialize current ray position
    vec3 q = vec3(0.0); // Initialize stored position
    float z = 0.0; // Initialize depth
    float d = 0.0; // Initialize distance
    O = vec4(0.0, 0.0, 0.0, 1.0); // Initialize output with alpha 1.0

    R = iResolution.xy; // Assign resolution
    uv = (I * 2.0 - R) / R.y; // Calculate UV coordinates

    ro = vec3(0.0, 0.0, -11.0); // Set ray origin
    rd = normalize(vec3(uv, 1.0)); // Set ray direction

    // RAYMARCHING LOOP
    for (float i = 0.0; i < 100.0; i += 1.0) {
        p = ro + rd * z; // Current ray position
        p.xy *= rotate(T * 0.3); // Rotate XY plane
        p.xz *= rotate(T * 0.3); // Rotate XZ plane

        q = p; // Store position for cube calculation

        float h = S(-10.0, 10.0, p.y); // Height smoothstep
        p.x += cos(h * 10.0) * h * 2.0; // Horizontal displacement
        p.z += sin(h * 10.0) * h * 2.0; // Vertical displacement

        // TURBULENCE LOOP
        for (float x = 1.0; x < 5.0; x += 1.0) {
            p += sin((p.zxy + i + T) * x) / x; // Add turbulence
        }

        float r = S(-1.0, 1.0, p.y) * 2.5; // Radius based on height
        float line = length(p.xz) - r; // Line distance
        line = max(0.01, line * 0.1); // Clamp line distance

        float cube = sdBox(q, vec3(4.0)); // Box distance
        cube = abs(cube * 0.6) + 0.1; // Adjust cube distance

        d = max(cube, line); // Combine distances
        // Custom palette or rainbow based on USE_CUSTOM_PALETTE
        vec3 color;
        if (USE_CUSTOM_PALETTE == 1) {
            // Custom palette colors (teal, white, peach, orange)
            vec3 color0 = vec3(89.0, 139.0, 139.0) / 255.0; // #588b8b
            vec3 color1 = vec3(255.0, 255.0, 255.0) / 255.0; // #ffffff
            vec3 color2 = vec3(255.0, 213.0, 194.0) / 255.0; // #ffd5c2
            vec3 color3 = vec3(242.0, 143.0, 59.0) / 255.0;   // #f28f3b
            // Local interpolation based on height (p.y) and time
            float phase = (p.y * 0.1 + T) / CYCLE_DURATION; // Position and time-based phase
            float cycle = fract(phase); // Cycle from 0 to 1
            int idx = int(cycle * 4.0); // Index into colors (0 to 3)
            float t = fract(cycle * 4.0); // Interpolation factor
            // Manual modulo replacement
            vec3 nextColor;
            if (idx == 0) nextColor = color1;
            else if (idx == 1) nextColor = color2;
            else if (idx == 2) nextColor = color3;
            else nextColor = color0; // Wrap around to color0 after color3
            color = mix((idx == 0 ? color0 : idx == 1 ? color1 : idx == 2 ? color2 : color3), nextColor, t);
        } else {
            color = 1.1 + sin(vec3(4.0, 0.0, 2.0) + (p.y * 0.3 + q.y * 0.1 + T)); // Original rainbow
        }
        O.rgb += color / max(d * d, 1e-6); // Accumulate color with robust division
        z += max(d, 1e-6); // Step forward with robust division
        if (z > 20.0 || d < 1e-4) break; // Exit condition
    }

    // TONE MAPPING and BCS ADJUSTMENT
    vec3 color = tanh_approx(vec4(O.rgb, 0.0) / 2e2).rgb; // Compress bright values
    // Luminance calculation
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    // Apply saturation
    vec3 saturated = mix(vec3(luminance), color, SATURATION);
    // Apply contrast
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    // Apply brightness
    O.rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0); // Final RGB with clamping
    O.a = 1.0; // Preserve alpha
}