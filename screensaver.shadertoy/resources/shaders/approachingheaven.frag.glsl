/*
    "Sunset" by @XorDev, adapted by Grok + brightness/contrast/saturation controls
    + panoramic zoom fix (adjust zoom to frame more sky or pull back effect).
*/

vec4 tanh_approx(vec4 x) {
    return x / (1.0 + abs(x));
}

vec4 saturate(vec4 color, float sat) {
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    color.rgb *= brightness;
    return saturate(color, saturation);
}

void mainImage(out vec4 O, in vec2 I)
{
    float t = iTime;

    // ---------------------
    // 🔭 Zoom out factor (1.0 = normal, >1.0 zooms out)
    float zoom = 1.8;
    // ---------------------

    float i = 0.0;
    float z = 0.0;
    float d;
    float s;

    O = vec4(0.0);

    for (; i++ < 1e2; )
    {
        // ✅ CORRECTED RAY DIRECTION WITH ZOOM
        vec2 screenPos = (I - 0.5 * iResolution.xy) / iResolution.y;
        vec3 rayDir = normalize(vec3(screenPos * zoom * 2.0, 1.0));
        vec3 p = z * rayDir;

        for (d = 5.0; d < 2e2; d += d)
        {
            p += 0.6 * sin(p.yzx * d - 0.2 * t) / d;
        }

        z += d = 0.005 + max(s = 0.3 - abs(p.y), -s * 0.2) / 4.0;

        O += (cos(s / 0.07 + p.x + 0.5 * t - vec4(0, 1, 2, 3) - 3.0) + 1.5) * exp(s / 0.1) / d;
    }

    O = tanh_approx(O * O / 4e8);

    // 🎛 Fine-tune brightness, contrast, and saturation here
    O = applyPostProcessing(O, 1.2, 1.2, 1.1);
}
