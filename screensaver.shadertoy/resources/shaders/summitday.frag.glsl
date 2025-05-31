#define F sin(p.x*.03+1.5 + sin(p.x*.06) + sin(p.z*.03)) * \
             8. + sin(p.z*.014) *15. + abs(p.x*.07)

void mainImage( out vec4 o, in vec2 u )
{
    float s = 0.002, d = 0.0, i;
    vec3 r = vec3(iResolution.xy, 0.0);
    u = (u - r.xy / 2.0) / r.y;

    // --- Camera ---
    vec3 p = vec3(0.0, 0.0, iTime * 10.0), ro = p;

    // Tilted camera slightly down (Y: 0.70 instead of 0.50)
    vec3 D = vec3(u, 1.0)
           - vec3(
               sin(p.z * 0.002) * 0.2,
               sin(p.z * 0.009) * 0.04 + 0.70,
               0.0
             );

    vec3 col = vec3(0.0);

    for(i = 0.0; i++ < 120.0 && s > 0.001; ) {
        p = ro + D * d;
        p.x += sin(p.z * 0.04) * 6.0;

        s = (sin(p.z * 0.005) * 64.0 + 96.0) + p.y - F * 8.0;

        for (float a = 0.05; a < 1.0;
             s += abs(dot(sin(p * a * 2.0), vec3(0.3))) / a * 0.2,
             a *= 1.4);

        col += clamp(s * 0.0005 + 0.035, 0.0, 1.0);
        d += s * 0.55;
    }

    if (d > 2000.0) {
        col = vec3(0.02, 0.04, 0.12) / (length(0.5 * u - 0.23) * 0.6);
    }

    // Darken distant peaks
    float fade = smoothstep(800.0, 1600.0, d);
    col *= mix(1.0, 0.5, fade);

    // Global brightness tweak
    col *= 0.85;

    // 🔧 Dithering (subtle noise) — placed BEFORE tone mapping
    float noise = fract(sin(dot(u * iResolution.xy, vec2(12.9898,78.233))) * 43758.5453);
    col += (noise - 0.5) * 0.002;  // range: -0.001 to +0.001

    // Reinhard tone mapping
    col *= 0.75;
    col = col / (col + vec3(1.0));

    // Gamma correction
    col = pow(col, vec3(0.45));

    // Boost contrast
    col = (col - 0.5) * 2.25 + 0.2;

    // Clamp so TVs don’t blow out
    col = clamp(col, 0.0, 0.85);

    o = vec4(col, 1.0);
}

