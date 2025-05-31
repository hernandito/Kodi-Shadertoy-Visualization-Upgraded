#define T iTime
#define R iResolution

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 6; i++) {
        f += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return f;
}

float softSpark(vec2 uv) {
    float n = noise(uv * 8.0 + T * 0.5);
    float flicker = smoothstep(0.8, 1.0, n);
    return flicker * 0.3;
}

vec3 nebulaPalette(float t) {
    return vec3(
        0.6 + 0.3 * sin(t + 0.0),
        0.4 + 0.4 * sin(t + 1.5),
        0.7 + 0.3 * sin(t + 3.0)
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / R.xy;
    uv = (uv - 0.5) * vec2(R.x / R.y, 1.0) * 2.0;
    vec2 p = uv;

    // Scaled up flow1 to shrink blotches (from 1.5x to 4.5x)
    vec2 flow1 = p * 4.5 + vec2(0.1 * T, 0.05 * T); 
    vec2 flow2 = p * 2.5 - vec2(0.05 * T, 0.1 * T);
    vec2 flow3 = p * 4.0 + vec2(0.02 * T, -0.04 * T);

    float f1 = fbm(flow1); // finer now
    float f2 = fbm(flow2);
    float f3 = fbm(flow3);

    float combined = f1 * 0.5 + f2 * 0.3 + f3 * 0.2;
    float edgeSoft = smoothstep(1.5, 0.2, length(p));

    vec3 nebula = nebulaPalette(T * 0.1 + combined * 2.0);
    nebula *= combined * edgeSoft;

    // Optional sparkle (comment out to remove)
//    float sparkle = softSpark(p);
//    nebula += sparkle;

    // Filmic exposure curve
    nebula = pow(nebula, vec3(1.4)) * 1.5;
    nebula *= exp(-length(p) * 1.5); // central glow falloff

    fragColor = vec4(nebula, 1.0);
}
