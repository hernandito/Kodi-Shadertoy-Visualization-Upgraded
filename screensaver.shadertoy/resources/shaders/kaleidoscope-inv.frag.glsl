// Change this to select palette 0–7
int paletteIndex = 7;

// iq palette selector with 8 themes (0–5 animated, 6 is golden glow, 7 is black on yellow)
vec3 palette(float t, int paletteIndex) {
    vec3 a, b, c, d;

    if (paletteIndex == 0) {
        a = vec3(0.1, 0.1, 0.1);
        b = vec3(0.5, 0.5, 0.5);
        c = vec3(1.0, 1.0, 1.0);
        d = vec3(0.263, 0.416, 0.557);
    } else if (paletteIndex == 1) {
        a = vec3(0.1, 0.12, 0.05);
        b = vec3(0.4, 0.3, 0.1);
        c = vec3(0.8, 0.8, 0.6);
        d = vec3(0.3, 0.4, 0.1);
    } else if (paletteIndex == 2) {
        a = vec3(0.08, 0.06, 0.01);
        b = vec3(0.4, 0.3, 0.1);
        c = vec3(0.8, 0.6, 0.2);
        d = vec3(0.3, 0.4, 0.2);
    } else if (paletteIndex == 3) {
        a = vec3(0.1, 0.08, 0.01);
        b = vec3(0.5, 0.4, 0.1);
        c = vec3(1.0, 0.9, 0.3);
        d = vec3(0.2, 0.2, 0.0);
    } else if (paletteIndex == 4) {
        a = vec3(0.02, 0.01, 0.005);
        b = vec3(0.4, 0.25, 0.15);
        c = vec3(0.8, 0.5, 0.3);
        d = vec3(0.2, 0.1, 0.05);
    } else if (paletteIndex == 5) {
        float t_mod = mod(t, 1.0);
        if (t_mod < 0.33)
            return vec3(1.0, 0.84, 0.0); // yellow
        else if (t_mod < 0.66)
            return vec3(0.17, 0.08, 1.0); // blue
        else
            return vec3(0.92, 0.0, 0.0);  // red
    } else if (paletteIndex == 6) {
        return vec3(1.0, 0.80, 0.0); // flat golden glow
    } else if (paletteIndex == 7) {
        return vec3(0.0); // black (used for tendrils)
    }

    return a + b * cos(6.28318 * (c * t + d));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;

    // Rotate view slowly
    float angle = 0.05 * iTime;
    float s = sin(angle), c = cos(angle);
    uv = mat2(c, -s, s, c) * uv;

    vec2 uv0 = uv;
    vec3 finalColor = vec3(0.0);

    if (paletteIndex == 6) {
        // Palette 6: golden glow
        float glowSharpness = 1.2;
        float baseGlowStrength = 0.008;
        float layers = 3.0;

        for (float i = 0.0; i < layers; i++) {
            uv = fract(uv * 1.5) - 0.5;
            float d = length(uv) * exp(-length(uv0));
            vec3 col = palette(length(uv0) + i * 0.4 + iTime * 0.4, paletteIndex);

            d = sin(d * 38.0 + iTime) / 8.0;
            d = abs(d);
            d = pow(baseGlowStrength / d, glowSharpness);

            finalColor += col * d;
        }

    } else if (paletteIndex == 7) {
        // Palette 7: black tendrils on yellow background (no flickering, no color cycling)
        float glowSharpness = 1.2;
        float baseGlowStrength = 0.008;
        float layers = 3.0;

        finalColor = vec3(1.0, 0.80, 0.0); // solid yellow background

        for (float i = 0.0; i < layers; i++) {
            uv = fract(uv * 1.5) - 0.5;
            float d = length(uv) * exp(-length(uv0));
            float pulse = sin(d * 38.0 + iTime * 0.8) / 8.0;
            pulse = abs(pulse);
            pulse = pow(baseGlowStrength / (pulse + 1e-4), glowSharpness);

            finalColor -= vec3(pulse); // subtract black-only glow (no palette used)
        }

        finalColor = clamp(finalColor, 0.0, 1.0);

    } else {
        // Palettes 0–5: animated glows
        for (float i = 0.0; i < 4.0; i++) {
            uv = fract(uv * 1.5) - 0.5;
            float d = length(uv) * exp(-length(uv0));
            vec3 col = palette(length(uv0) + i * 0.4 + iTime * 0.4, paletteIndex);

            d = sin(d * 38.0 + iTime) / 8.0;
            d = abs(d);
            d = pow(0.03 / d, 0.4);

            finalColor += col * d;
        }
    }

    fragColor = vec4(finalColor, 1.0);
}
