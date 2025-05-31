#define PI 3.14159265359
#define TAU 6.28318530718

// User-adjustable post-processing parameters
float BRIGHTNESS = 0.70;    // Brightness (1.0 is neutral, increase to 1.2 to make brighter, decrease to 0.5 to make darker)
float CONTRAST = 1.8;      // Contrast (1.0 is neutral, increase to 2.0 for more contrast, decrease to 0.8 for less contrast)
float SATURATION = 1.1;    // Saturation (1.0 is neutral, increase to 1.5 for more saturation, decrease to 0.7 for less saturation)

// Smoky turbulence enhancement parameters
float SMOKY_TRANSPARENCY = 0.2;  // Transparency of the smoky effect (0.0 to 1.0, lower values make it more transparent, higher values make it more opaque)
float SMOKY_NOISE_STRENGTH = 0.6;  // Strength of the noise for the smoky effect (increase to 0.8 for more noise, decrease to 0.4 for less noise)
float SMOKY_NOISE_SCALE = 3.0;     // Scale of the noise for the smoky effect (increase to 4.0 for larger patterns, decrease to 3.0 for smaller patterns)

// Dithering parameters
float DITHER_STRENGTH = 0.005;  // Strength of dithering (increase to 0.01 for more dithering, decrease to 0.002 for less dithering)

// Animation speed parameter
float ANIMATION_SPEED = .30;    // Animation speed (1.0 is original speed, decrease to 0.5 to slow down by half, increase to 2.0 to double speed)

// Hash function for dithering and noise
float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, float scale) {
    float sum = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < 6; i++) {
        sum += noise(p * freq * scale) * amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    return sum;
}

// Post-processing functions
vec3 adjustContrast(vec3 color, float contrast) {
    return (color - 0.5) * contrast + 0.5;
}

vec3 adjustBrightness(vec3 color, float brightness) {
    return color * brightness;
}

vec3 adjustSaturation(vec3 color, float saturation) {
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(luminance), color, saturation);
}

// Dithering function
float dither(vec2 uv) {
    return hash21(uv * 1000.0 + iTime * 0.1) * 2.0 - 1.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 aspect = vec2(iResolution.x / iResolution.y, 1.0);
    uv = (uv - 0.5) * aspect;

    vec2 mouse = (iMouse.xy / iResolution.xy - 0.5) * aspect;
    float mouseDist = length(uv - mouse);

    vec3 col = vec3(0.0);

    float radius = 0.3 + sin(iTime * 0.5 * ANIMATION_SPEED) * 0.02;
    float d = length(uv);

    float angle = atan(uv.y, uv.x);
    float wave = sin(angle * 3.0 + iTime * ANIMATION_SPEED) * 0.1;
    float wave2 = cos(angle * 5.0 - iTime * 1.3 * ANIMATION_SPEED) * 0.08;

    // Enhanced smoky turbulence effect
    float smokyNoise = fbm(uv * SMOKY_NOISE_SCALE + iTime * 0.1 * ANIMATION_SPEED, SMOKY_NOISE_SCALE);
    smokyNoise = (smokyNoise * 2.0 - 1.0) * SMOKY_NOISE_STRENGTH;
    vec3 smokyColor = vec3(0.2, 0.4, 0.6) * abs(smokyNoise);
    float smokyAlpha = smoothstep(0.0, 1.0, abs(smokyNoise)) * SMOKY_TRANSPARENCY;

    vec3 orbColor = vec3(0.165, 0.459, 0.749);
    float orb = smoothstep(radius + wave + wave2, radius - 0.1 + wave + wave2, d);

    vec3 gradient1 = vec3(0.878, 0.345, 0.149) * sin(angle + iTime * ANIMATION_SPEED);
    vec3 gradient2 = vec3(0.208, 0.427, 0.78) * cos(angle - iTime * 0.7 * ANIMATION_SPEED);

    float particles = 0.0;
    for (float i = 0.0; i < 2.0; i++) {
        vec2 particlePos = vec2(
            sin(iTime * (0.5 + i * 0.2) * ANIMATION_SPEED) * 0.5,
            cos(iTime * (0.3 + i * 0.2) * ANIMATION_SPEED) * 0.5
        );
        particles += smoothstep(0.05, 0.0, length(uv - particlePos));
    }

    col += orb * mix(orbColor, gradient1, smokyNoise);
    col += orb * mix(gradient2, orbColor, smokyNoise) * 0.5;
    col += particles * vec3(0.5, 0.8, 1.0);
    col += exp(-d * 4.0) * vec3(0.2, 0.4, 0.8) * 0.5;
    col += exp(-mouseDist * 8.0) * vec3(0.5, 0.7, 1.0) * 0.2;

    // Apply smoky effect
    col = mix(col, smokyColor, smokyAlpha);

    // Apply post-processing
    col = adjustBrightness(col, BRIGHTNESS);
    col = adjustContrast(col, CONTRAST);
    col = adjustSaturation(col, SATURATION);

    // Apply dithering to reduce banding
    float ditherValue = dither(fragCoord) * DITHER_STRENGTH;
    col += ditherValue;

    fragColor = vec4(col, 1.0);
}