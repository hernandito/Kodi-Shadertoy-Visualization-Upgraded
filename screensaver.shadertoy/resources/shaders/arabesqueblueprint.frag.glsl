vec3 palette(float t) {
    float blue = mix(0.6, 1.0, 0.5 + 0.5 * cos(6.28318 * (t + 0.3))); 
    return vec3(0.0, 0.0, .2);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec2 uv0 = uv;
    vec3 baseColor = vec3(1.0);
    for (float i = 0.0; i < 4.0; i++) {
        uv = fract(uv * 1.5) - 0.5;
        float d = length(uv) * exp(-length(uv0));
        vec3 col = palette(length(uv0) + i * 0.4 + iTime * 0.15);
        d = sin(d * 8.0 + iTime * 0.5) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.2);
        float alpha = clamp(d * 0.35, 0.0, 1.0);
        baseColor = mix(baseColor, col, alpha);
    }
    fragColor = vec4(baseColor, 1.0);
}
