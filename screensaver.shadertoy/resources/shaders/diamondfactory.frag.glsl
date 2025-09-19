// === Global Macros & Helpers ===
#define ANIMATION_SPEED 0.25
#define BRIGHTNESS -0.10
#define CONTRAST 1.450
#define SATURATION 1.0

#define X_OFFSET 100.50
#define Y_OFFSET -10.0

#define T (iTime * ANIMATION_SPEED * 0.1 * 5.0 + 50.0)

// A robust approximation for the round function
float round_approx(float x) {
    return floor(x + 0.5);
}

// Procedural noise function to replace texture-based blue noise
float value_noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    fp = fp * fp * (3.0 - 2.0 * fp); // smoothstep
    vec2 hash = ip + vec2(15.543, 22.843) + vec2(iTime*ANIMATION_SPEED*0.2, 0.0);
    vec2 f = mod(sin(hash * 12.9898) * 43758.5453, 1.0);
    return mix(mix(f.x, fract(sin(f.y) * 43758.5453), fp.x),
               mix(fract(sin(f.y + 10.0) * 43758.5453), fract(sin(f.y + 20.0) * 43758.5453), fp.x),
               fp.y);
}

// === Distance Functions ===

// Folding function for complex shapes
vec3 fold(vec3 p) {
    vec3 nc = vec3(-0.5, -0.809017, 0.309017);
    for (int i = 0; i < 5; i++) {
        p.xy = abs(p.xy);
        p -= 2.0 * min(0.0, dot(p, nc)) * nc;
    }
    return p - vec3(0.0, 0.0, 1.275);
}

// A function to create a standard rotation matrix based on an angle
mat2 get_rotation_matrix(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

// === Main Render Function ===
void mainImage(out vec4 fragColor, in vec2 u) {
    float s = 0.001;
    float d = 0.0;
    float i = 0.0;

    vec3 r = iResolution;
    vec3 ro = vec3(0.0, 0.0, iTime * ANIMATION_SPEED);
    vec3 p = ro;

    // Camera setup
    vec3 D = vec3(((u + vec2(X_OFFSET, Y_OFFSET)) - r.xy * 0.5) / r.y, 1.0) * 0.5;

    vec4 o = vec4(0.0);
    
    // === Raymarch loop ===
    for (; i++ < 125.0 && s > 0.0009;) {
        p = ro + D * d;

        // Temporal twisting and translation
        p.xy *= get_rotation_matrix(-p.z * 0.1 + sin(iTime * ANIMATION_SPEED*.2 * 0.55));
        
        // Layered folding and modulation
        p = fold(p) - vec3(0.5) + cos(p.z) * 0.01;
        p = fold(p) - vec3(0.8) + sin(p.z) * 0.6;
        p.y += 0.5;
        p = fold(p) - vec3(0.08) + sin(p.z) * 0.15;
        p = fold(p) - vec3(0.2) + sin(p.z) * 0.36;
        p.x -= 0.5 + sin(p.y * 0.5 + cos(p.z * 2.0 + iTime * ANIMATION_SPEED));

        vec3 pc = p;

        // Additional modulation
        p = abs(p * 0.95) * 0.35 + abs(sin(p.z * 0.5) * 0.7);

        // Gyroid distance field
        float gyroidDist = length(p.xy - vec3(0.0).xy) - 1.5;
        s = abs(gyroidDist);
        d += s;

        // Fade based on step size
        float fade = smoothstep(0.0002, 0.001, s);

        // Procedural color
        vec3 col = cos(d * 1e-8 + 2.0) *
                   sin(vec3(p.xy, 7.0) * 0.5 -
                   vec3(cos(pc.x - sin(p.x) * 3.0) * 1.5, 3.115, 5.9)) * 0.05 - 0.02;

        // Accumulate color
        o.rgb += col * fade;
    }

    // === Post-processing ===

    // Exponential fog/fade and gamma correction
    o.rgb = (0.2 - o.rgb) * exp(-d / 15.0);
    o.rgb = pow(o.rgb, vec3(1.0 / 2.2));

    // Adjust Brightness, Contrast, and Saturation
    vec3 gray = vec3(dot(o.rgb, vec3(0.2126, 0.7152, 0.0722)));
    o.rgb = mix(gray, o.rgb, SATURATION);
    o.rgb = (o.rgb - 0.5) * CONTRAST + 0.5;
    o.rgb += BRIGHTNESS;

    // Dithering for banding reduction (8-bit display)
    float dither = value_noise(u) - 0.5;  // Convert to [-0.5, 0.5]
    float quantum = 1.0 / 255.0;          // 8-bit quantization step
    o.rgb += dither * quantum;

    // Clamp to valid output range
    o.rgb = clamp(o.rgb, 0.0, 1.0);

    fragColor = vec4(o.rgb, 1.0);
}
