// Tendril Protocol — Broadcast Dreamform
// Orange sky seeded with slow, forked green lightning tendrils
// Inspired by microwave-transmitted visions

#define BRIGHTNESS 1.0  // Adjust brightness (1.0 = no change, >1.0 brighter, <1.0 darker)
#define CONTRAST 1.5    // Adjust contrast (1.0 = no change, >1.0 more contrast, <1.0 less)
#define SATURATION .950  // Adjust saturation (1.0 = no change, >1.0 more vivid, <1.0 less)

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float fbm(vec2 p) {
    float val = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        val += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return val;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Sky base turbulence
    float angle = iTime * 0.03;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 ruv = rot * (uv - 0.5) + 0.5;
    float skyBase = pow(fbm(ruv * 4.0), 1.6);

    // Orange glow wash
    float glow = smoothstep(0.1, 0.9, uv.y);
    vec3 orangeSky = mix(vec3(1.0, 0.4, 0.15), vec3(0.2, 0.1, 0.05), glow);

    // Forked lightning filaments
    vec2 fork1UV = uv * vec2(12.0, 2.5) + vec2(iTime * 0.1, sin(iTime * 0.5) * 0.2);
    float fork1 = smoothstep(0.4, 1.0, fbm(fork1UV));

    vec2 fork2UV = uv * vec2(12.0, 2.5) + vec2(iTime * 0.07 + 1.3, cos(uv.y * 10.0 + iTime));
    float fork2 = smoothstep(0.6, .750, fbm(fork2UV));

    float tendrilMask = clamp(fork1 + 0.5 * fork2, 0.0, 1.0);

    // Sky reaction — warm glow burst + green lightning aura
    float reactionFalloff = exp(-8.0 * abs(uv.y - 0.25));
    vec3 warmFlash = vec3(1.0, 0.5, 0.2) * tendrilMask * reactionFalloff * 0.4;
    vec3 lightningAura = vec3(0.0, 1.0, 0.6) * tendrilMask * reactionFalloff * 0.7;

    // Final blend
    vec3 baseColor = mix(vec3(skyBase), orangeSky, 0.6);
    vec3 finalColor = baseColor + warmFlash + lightningAura;

    // Apply BCS adjustments
    vec3 color = finalColor * BRIGHTNESS; // Brightness
    color = mix(vec3(0.5), color, CONTRAST); // Contrast
    color = mix(vec3(dot(vec3(0.299, 0.587, 0.114), color)), color, SATURATION); // Saturation

    fragColor = vec4(color, 1.0);
}