#define PI 3.14159265359

// ==== POSITION PARAMETERS ====
#define GLOBAL_Y_OFFSET     -0.4    // Positive moves spirals UP, negative moves them DOWN
#define SPIRAL_SEPARATION   0.30    // Horizontal separation between the two spirals
#define VERTICAL_WRAP_COUNT 3.0     // Number of vertical repetitions (coils visible)
#define PERSPECTIVE_AMPLITUDE 0.10 // Corkscrew twist depth

// ==== Spiral Speed ====
#define SPIRAL_SPEED 0.7
#define SCROLL_SPEED 0.02

// ==== Noise Background ====
#define USE_NOISE_BG 0          // 1 = show noise background, 0 = disable
#define NOISE_SCALE 30.0        // Higher = finer grain noise

// ==== Top Color Enhancement ====
// #define TOP_COLOR_BOOST 1.0     // >1.0 increases saturation/brightness of bright colors (commented out as per original)

// ==== BCS Adjustment Parameters ====
// Adjust these values to control the final look of the shader.
#define BRIGHTNESS_ADJ .9   // Overall brightness (1.0 is neutral; >1.0 brighter, <1.0 darker)
#define CONTRAST_ADJ   1.2   // Contrast (1.0 is neutral; >1.0 more contrast, <1.0 less)
#define SATURATION_ADJ 1.3   // Color saturation (1.0 is neutral; >1.0 more vibrant, <1.0 desaturated)

// ==== Warm White Color Adjustment Parameters ====
// Adjust this vec3 to define the color you want to tint the "warm white" with.
#define WARM_WHITE_TINT_COLOR vec3(1.0, 0.7, 0.0) // Example: A strong orange-yellow.
// Adjust this float (0.0 to 1.0) to control the strength of the tint.
#define WARM_WHITE_TINT_STRENGTH 0.60 // Example: A noticeable tint.
// Adjust these floats (0.0 to 1.0) to define the 't' range where the tint is applied. iTime
// The "warm white" appears when 'b' (the 't' value for paletteEarthy) is closer to 1.0.
#define WARM_WHITE_TINT_START_T 0.6 // Tint starts to apply when 'b' is 0.9
#define WARM_WHITE_TINT_END_T   1.000 // Tint is fully applied when 'b' is 1.0

// Error function approximation
float erf(in float x) {
    return sign(x) * sqrt(1.0 - exp2(-1.787776 * x * x));
}

// Gaussian filtered rectangle
float grect(in vec2 p, in vec2 b, in float w) {
    float u = erf((p.x + b.x) / w) - erf((p.x - b.x) / w);
    float v = erf((p.y + b.y) / w) - erf((p.y - b.y) / w);
    return u * v / 4.0;
}

// Tonemapping
vec3 acesApprox(vec3 v) {
    v *= 0.6;
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((v * (a * v + b)) / (v * (c * v + d) + e), 0.0, 1.0);
}

// IQ palette
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

vec3 paletteEarthy(float t) {
    // Original palette definition.
    // The 'd' parameter controls the phase of each color channel.
    return palette(t, vec3(0.5, 0.5, 0.5),
                      vec3(0.5, 0.5, 0.5),
                      vec3(1.0, 1.0, 1.0),
                      vec3(0.0, 0.10, 0.20)); // Reverted to original phase offsets
}

vec3 screen(vec3 base, vec3 blend) {
    return 1.0 - (1.0 - base) * (1.0 - blend);
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float random2d(vec2 coord) {
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    uv = (uv - 0.5) * vec2(aspect, 1.0) + 0.5;

    // Apply adjustable vertical position offset
    uv.y += GLOBAL_Y_OFFSET;

    float time = -iTime*.4 * SPIRAL_SPEED;
    vec3 col = vec3(0.0);
    float amt = 80.0; // Steps per spiral

    float scroll = fract(time * SCROLL_SPEED);

    for (int spiral = 0; spiral < 2; spiral++) {
        float phaseOffset = float(spiral) * 0.5;
        for (float i = 0.0; i < amt; i++) {
            float n = i / amt;

            float offsetN = fract((n + phaseOffset) * VERTICAL_WRAP_COUNT + scroll);
            float vertPos = offsetN / VERTICAL_WRAP_COUNT;

            vec2 rPos = uv - vec2(0.5, vertPos);

            // Adjustable horizontal separation
            float spiralShift = (spiral == 0 ? -SPIRAL_SEPARATION : SPIRAL_SEPARATION);
            rPos.x += spiralShift;

            float rotTime = time - offsetN * 10.0;
            float angle = rotTime + phaseOffset * 2.0 * PI;

            rPos *= rotate(angle);

            // Adjustable corkscrew perspective
            float verticalTwist = sin(angle * 2.0) * PERSPECTIVE_AMPLITUDE;
            rPos.y += verticalTwist;

            vec2 rSize = vec2(0.04, 0.4);
            rSize = mix(rSize * 0.25,
                        vec2(rSize.x * 0.5, rSize.y),
                        1.0 - offsetN);

            float cyclePhase = fract(offsetN * 2.0);
            float blur = mix(0.0, 0.3, 0.5 + 0.5 * cos(cyclePhase * PI * 2.0));
            float intensity = mix(24.0 / amt, 12.0 / amt, 0.5 + 0.5 * cos(cyclePhase * PI * 2.0));

            float b = mix(0.6, 1.0, offsetN); // 'b' is the 't' value for paletteEarthy
            vec3 rCol = paletteEarthy(b);

            // --- Apply targeted warm white tint ---
            // Calculate a blend factor based on 'b' (t-value) and the defined range.
            float tint_factor = smoothstep(WARM_WHITE_TINT_START_T, WARM_WHITE_TINT_END_T, b);
            // Mix the original color with the tint color based on the tint factor and strength.
            rCol = mix(rCol, WARM_WHITE_TINT_COLOR, tint_factor * WARM_WHITE_TINT_STRENGTH);
            // --- End targeted warm white tint ---

            // Boost bright areas regardless of palette value
            float lum = dot(rCol, vec3(0.299, 0.587, 0.114));
            if (lum > 0.7) {
                #ifdef TOP_COLOR_BOOST
                rCol = mix(rCol, normalize(rCol) * max(length(rCol), 1.0), (lum - 0.7) * TOP_COLOR_BOOST);
                #else
                rCol = mix(rCol, normalize(rCol) * max(length(rCol), 1.0), (lum - 0.7));
                #endif
            }

            float r = grect(rPos, rSize, blur);
            col += r * rCol * intensity;
        }
    }

    col = acesApprox(col);

#if USE_NOISE_BG
    float noise = random2d(fragCoord.xy / iResolution.xy * NOISE_SCALE);
    col = screen(col, vec3(noise) * 0.05);
#endif

    // --- Apply BCS adjustments in post-processing ---
    // 1. Brightness: Directly multiplies the color.
    col *= BRIGHTNESS_ADJ;

    // 2. Contrast: Adjusts contrast around a midpoint (0.5).
    col = (col - 0.5) * CONTRAST_ADJ + 0.5;

    // 3. Saturation:
    // Calculate luminance (grayscale equivalent) of the color.
    // Standard NTSC luminance coefficients are used (0.299, 0.587, 0.114).
    float luminance = dot(col, vec3(0.299, 0.587, 0.114));
    // Linearly interpolate between the grayscale color and the original color based on SATURATION_ADJ.
    col = mix(vec3(luminance), col, SATURATION_ADJ);
    // --- End BCS adjustments ---

    fragColor = vec4(col, 1.0);
}
