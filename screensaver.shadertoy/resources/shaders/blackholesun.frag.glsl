void mainImage(out vec4 O, vec2 F)
{
    float i = 0.2, a;
    float speed = 0.4; // lower = slower, higher = faster
    vec2 r = iResolution.xy;

    // Centered and scaled coordinates
    vec2 p = (F + F - r) / r.y / 0.7;

    // === Animated center drift ===
    vec2 centerOffset = 0.15 * vec2(
        sin(iTime * 0.2),
        cos(iTime * 0.14)
    );
    p += centerOffset;

    vec2 d = vec2(-1.0, 1.0);
    vec2 b = p - i * d;
    float bDot = dot(b, b);
    float denom = 0.1 + i / bDot;

    vec2 c;
    c.x = p.x + p.y * (d.x / denom);
    c.y = p.x * (d.y / denom) + p.y;

    a = dot(c, c);
    float angle = 0.5 * log(a) + iTime * speed * i;

    float cs = cos(angle);
    float sn = sin(angle);
    vec2 v;
    v.x = c.x * cs - c.y * sn;
    v.y = c.x * sn + c.y * cs;
    v /= i;

    vec2 w = vec2(0.0);

    for (; i < 12.0; i += 1.0)
    {
        vec2 sinv = sin(vec2(v.y, v.x) * i + iTime * speed);
        v += 0.7 * sinv / i + 0.5;
        w += 1.0 + sin(v);
    }

    float iDisk = length(sin(v / 0.3) * 0.4 + c * (3.0 + d.x));

    vec4 colorExp;
    colorExp.r = exp(c.x * 0.6);
    colorExp.g = exp(c.x * -0.4);
    colorExp.b = exp(c.x * -1.0);
    colorExp.a = 0.0;

    float waveSum = w.x + w.y;
    float brightness = 2.2 + iDisk * iDisk / 4.0 - iDisk;
    float centerDark = 0.5 + 1.0 / a;
    float rim = 0.03 + abs(length(p) - 0.7);

    vec4 col = colorExp / (waveSum + 0.001) / brightness / centerDark / rim;
    O = vec4(1.0) - exp(-col);
}
