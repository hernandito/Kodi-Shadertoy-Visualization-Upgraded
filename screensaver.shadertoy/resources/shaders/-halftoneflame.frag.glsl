// Candle Flame Shader (Red-Orange Flickering Version)

const float BAYER_DIVISION_SCALAR = 8.0;
const float dither_interpolation_weight = 0.65;

// Hash and noise functions
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = smoothstep(0.0, 1.0, f);

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float value = -0.10;
    float amplitude = 0.95;
    for (int i = 0; i < 1; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.25;
    }
    return value;
}

// Adjusted flame color: Yellow to Orange to Red, no blue
vec3 flameColor(float y, float edgeGlow) {
    vec3 yellow = vec3(1.0, 0.80, 0.0);
    vec3 orange = vec3(1.0, 0.5, 0.0);
    vec3 red = vec3(1.0, 0.1, 0.0);

    vec3 core = mix(yellow, orange, smoothstep(-0.1, 0.7, y));
    vec3 tip = mix(core, red, smoothstep(0.4, 0.80, y));

    // Add red-orange edge glow
    vec3 edge = mix(tip, red + vec3(0.1, 0.0, 0.0), edgeGlow * 0.8);

    return edge;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float t = iTime;

    vec2 uv = fragCoord.xy / iResolution.yy;
    vec2 center = vec2(0.92, 0.35);
    vec2 pos = (uv - center);

    pos.x /= 0.15;
    pos.y /= 0.4;

    float flicker = fbm(vec2(pos.y * 3.0, t * 2.0));
    pos.x += 0.15 * (flicker - 0.5);

    float shapeNoise = fbm(pos + t);
    float flameShape = 1.0 - length(pos) * (1.0 + 0.3 * shapeNoise);
    flameShape = clamp(flameShape, 0.0, 1.30);

    float yCoord = clamp((uv.y - center.y) / 0.4, 0.0, 1.0);
    float alpha = smoothstep(0.0, 0.7, flameShape) * smoothstep(1.0, 0.6, pos.y);

    // Edge glow based on how close to edge (stronger at thin flame borders)
    float edgeGlow = smoothstep(0.3, 0.0, flameShape);

    vec3 col = flameColor(yCoord, edgeGlow);

    // Bayer dithering
    float bayer = texture(iChannel0, fragCoord / BAYER_DIVISION_SCALAR).r;
    float dither = step(bayer, alpha);
    float finalAlpha = mix(alpha, dither, dither_interpolation_weight);

    fragColor = vec4(col * finalAlpha, finalAlpha);
}
