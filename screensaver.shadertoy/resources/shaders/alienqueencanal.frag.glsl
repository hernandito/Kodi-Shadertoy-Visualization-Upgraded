// === Global Macros & Helpers ===
// Time offset and speed factor
#define T (iTime * 0.05 * 5.0 + 50.0)

// Ray origin placeholder
#define P(z) vec3(0.0, 0.0, 0.0)

// Set to 1 to show the central sphere, 0 to hide it
#define SHOW_CENTER_SPHERE 0

// Scaling factors for the X and Y axes
#define X_SCALE 1.50
#define Y_SCALE 0.9

// Post-processing color adjustments
#define BRIGHTNESS -0.0
#define CONTRAST 1.0
#define SATURATION 1.0

// A robust approximation for the round function
float round_approx(float x) {
    return floor(x + 0.5);
}

// Procedural noise function to replace texture-based blue noise
float value_noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    fp = fp * fp * (3.0 - 2.0 * fp); // smoothstep
    vec2 hash = ip + vec2(15.543, 22.843) + vec2(iTime*0.2, 0.0);
    vec2 f = mod(sin(hash * 12.9898) * 43758.5453, 1.0);
    return mix(mix(f.x, fract(sin(f.y) * 43758.5453), fp.x),
               mix(fract(sin(f.y + 10.0) * 43758.5453), fract(sin(f.y + 20.0) * 43758.5453), fp.x),
               fp.y);
}

// === Distance Functions ===

// Sphere SDF
// Reference: standard SDF sphere definition
float sphere(vec3 p, vec3 center, float radius) {
    return length(p - center) - radius;
}

// Repeating cylinder with rotation and mirroring
// Inspired by: custom implementation
float cylinder(vec3 p, float spacing) {
    p.z = mod(p.z - 0.5 * spacing, spacing) - 0.5 * spacing;
    p.x = abs(p.x * 0.4);
    return length(p.xz - vec2(2.0, 0.0)) - 0.5;
}

// A function to create the rotation matrix based on an angle
mat2 get_rotation_matrix(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

// === Main Render Function ===
void mainImage(out vec4 fragColor, in vec2 u) {
    float s = 1.0;          // Step size before raymarching
    float d = 0.0;          // Total distance traveled along ray
    float i = 0.0;          // Iteration counter
    
    float sd = 0.0;         // Distance to sphere
    float sd2 = 0.0;        // Distance to second sphere
    
    vec3 r = iResolution;   // Screen resolution
    vec3 ro = P(T);         // Ray origin
    vec3 p = ro;            // Current point on ray
    vec3 sp = vec3(0.0);    // Positions for sphere SDFs
    vec3 sp2 = vec3(0.0);   // Positions for second sphere SDF

    // Ray direction from screen coordinates, normalized and scaled
    vec3 D = vec3((u - r.xy * 0.5) / r.y * vec2(X_SCALE, Y_SCALE), 1.0) * 0.5;

    vec4 o = vec4(0.0);     // Accumulated color

    // === Raymarching Loop ===
    for (; i++ < 100.0 && s > 0.00099;) {
        p = ro + D * d;
    
        // Optional zero multiplier on Z (can enable for effect)
        p.z = p.z + T * 0.0;
        sp2 = p;

        p.x = -abs(p.x);

        // Apply rotation with subtle sin/cos distortions
        p.xy *= get_rotation_matrix(p.z * 0.1 + sin(p.y * 0.001 + cos(p.x * 0.1) * 0.015));

        // Translate along Z with time for animation
        p.z += T;
        sp = p;

        // Rounded Z bands for offsetting positions in a repeating pattern
        float bandSize = 1.0;
        float q = round_approx(p.z / bandSize) * bandSize;

        // Offset example per band with time modulation
        p.y += cos(q * 0.5 + iTime * 0.6) * 0.05;

        // Sphere distances with animated positions and radius
        sd = sphere(sp, vec3(-2.0, -5.0, T + 30.0 ), 2.0);
        sd2 = sphere(sp2, vec3(0.0, 0.0, 25.0 + sin(T * 0.1) * 10.0), 2.3 + sin(T * 0.1) * 1.0 + 1.0);

        // Static blue noise offsets for sd2 sphere
        float n2 = value_noise(sp2.xy + sin(p.z * 0.25) * 5.0 + T * 0.25 - vec2(3.0, 5.0)); // Sphere 2 noise

        // Compose scene distance: min of cylinders and side spheres (always present)
        float sceneDist = min(sqrt(pow(cylinder(p.xyz, 0.05), 2.0) + pow(cylinder(p.xyz, 1.5), 2.0)), sd);

        // Conditionally add the central sphere based on the toggle
        float centerSphereDist = sd2 + n2 * 0.1;
        sceneDist = (SHOW_CENTER_SPHERE == 1) ? min(sceneDist, centerSphereDist) : sceneDist;

        s = sceneDist;
        d += s;

        // Soft fade-in based on proximity to surface
        float fade = smoothstep(0.0002, 0.001, s);

        // Procedural coloring using cosine & sine mix; modulated by sd for subtle effect
        vec3 col = (cos(d * 1e-8 + 1.1)) * sin(length(p.xy*2.0) + vec3(0.0, 0.1, 0.1)) * 0.2 - 0.03;

        // Accumulate color
        o.rgb += col * fade;
    }

    // === Post-Processing ===

    // Fog/falloff based on depth
    o.rgb = (0.9 - o.rgb) * exp(-d / 14.0);

    // Apply sepia tone
    vec3 sepiaColor = vec3(1.0, 0.76, 0.5);
    o.rgb = dot(o.rgb, vec3(0.299, 0.587, 0.114)) * sepiaColor;

    // Adjust Brightness, Contrast, and Saturation
    // Contrast
    o.rgb = (o.rgb - 0.5) * CONTRAST + 0.5;
    // Brightness
    o.rgb += BRIGHTNESS;
    // Saturation
    vec3 gray = vec3(dot(o.rgb, vec3(0.2126, 0.7152, 0.0722)));
    o.rgb = mix(gray, o.rgb, SATURATION);

    // Gamma correction
    o.rgb = pow(o.rgb, vec3(1.0 / 2.2));

    // Blue noise dithering
    float dither = value_noise(u) - 0.5; // Map to [-0.5, 0.5]
    float quantum = 1.0 / 255.0;         // 8-bit quantization step
    o.rgb += dither * quantum;          // Apply dithering

    // Clamp final color to [0,1]
    o.rgb = clamp(o.rgb, 0.0, 1.0);

    fragColor = vec4(o.rgb, 1.0);
}
