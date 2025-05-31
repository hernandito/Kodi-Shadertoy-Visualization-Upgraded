float sdMoon(vec2 p, float d, float ra, float rb)
{
    p.y = abs(p.y);
    float a = (ra * ra - rb * rb + d * d) / (2.0 * d);
    float b = sqrt(max(ra * ra - a * a, 0.0));
    if (d * (p.x * b - p.y * a) > d * d * max(b - p.y, 0.0)) {
        return length(p - vec2(a, b));
    }
    return max(length(p) - ra,
              -(length(p - vec2(d, 0)) - rb));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float scale = 0.5; // Lower = smaller shape; 1.0 = default size

    vec2 uv = fragCoord / iResolution.xy;

    // Scale only the drawing space, not vignette
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    p /= scale;

    float ra = 1.2;
    float rb = 0.9;
    float di = 0.5 * cos(iTime * 0.3);
    float d = sdMoon(p, di, ra, rb);
    d *= scale; // Keep line thickness visually correct after coordinate scaling

    // Colors
    vec3 fillColor = vec3(0.8, 0.1, 0.0);
    vec3 lineColor = vec3(1.0, 0.992, 0.969);
    vec3 col = (d > 0.0) ? lineColor : fillColor;

    // Glow and line shape
    col *= 1.4 - exp2(-12.0 * abs(d));
    col = mix(col, vec3(0.0), 1.0 - smoothstep(0.0, 0.015, abs(d)));

    // Vignette using original UV space (unaffected by shape scale)
    vec2 vUv = uv * (1.0 - uv.yx); // fabriceneyret1's trick
    float vig = vUv.x * vUv.y * 35.0;
    vig = pow(vig, 0.15); // feathering

    col *= vig;

    fragColor = vec4(col, 1.0);
}
