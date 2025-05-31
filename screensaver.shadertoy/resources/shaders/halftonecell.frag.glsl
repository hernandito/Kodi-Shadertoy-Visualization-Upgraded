const float scale = 2.0;
const vec2 tileSize = vec2(1.0) / scale;

const vec2 targetTile = vec2(0.0, 0.0);
const vec2 moveTile = vec2(1.33, 0.5);

const vec2 origin = (targetTile + moveTile) * tileSize;

float BAYER_DIVISION_SCALAR = 8.0;
float dither_interpolation_weight = 0.85;

// Hash & Noise Utilities
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
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 6; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.65;
    }
    return value;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float t = iTime;
    vec2 uv = fragCoord / iResolution.yy;
    vec2 local = (uv - origin) * scale;

    // Distortion based on noise
    float dx = 0.03 * fbm(local.yx * 3.0 + t * 0.2);
    float dy = 0.08 * fbm(local.xy * 3.0 + t * 0.3);
    local.x += dx;
    local.y += dy;

    // Subtle turbulence
    local.xy += (fbm(local.yx + t * 0.5) - 0.5) * 0.4;

    // Shape center wanders across screen
    vec2 wander = vec2(
        fbm(vec2(t * 0.07, 13.4)),
        fbm(vec2(t * 0.09, 7.1))
    );
    vec2 shapeCenter = 0.5 + (wander - 0.5) * 0.9;

    // Shape radius: 25% larger + randomized fluctuation
    float rNoise = fbm(vec2(t * 0.3, t * 0.1));
    float radiusBase = 0.3 * 1.25; // 25% larger
    float radiusMod = 1.0 + 0.15 * (fbm(vec2(t * 0.6, rNoise * 3.0)) - 0.5);
    float radius = radiusBase * radiusMod;

    // Shape skew morphing
    float skewX = 1.0 + 0.3 * fbm(local * 1.5 + t * 0.2);
    float skewY = 1.0 + 0.3 * fbm(local.yx * 1.2 - t * 0.3);
    vec2 warped = (local - shapeCenter) * vec2(skewX, skewY);
    float dShape = length(warped);
    float mask = smoothstep(radius, radius - 0.01, dShape);

    // Lighting
    vec2 lightPos = shapeCenter + vec2(-radius / 2.5, -radius / 1.0);
    float lo = length(local - lightPos);
    float shade = smoothstep(0.1, radius * 1.0, lo / 2.0);

    // === CHANGE COLOR HERE ===
    vec3 baseColor = vec3(0.851, 0.373, 0);  // white — change to your desired RGB value
    // e.g., vec3(0.3, 0.9, 0.5) for mint green

    // Apply dither and output
    float bayer_threshold = texture(iChannel0, fragCoord / BAYER_DIVISION_SCALAR).r;
    float finalValue = mask * shade;
    float dither = step(bayer_threshold, finalValue);
    float mixed = mix(finalValue, dither, dither_interpolation_weight);
    vec3 finalColor = baseColor * mixed;

    fragColor = vec4(finalColor, 1.0);
}
