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
    // Animation speed (1.0 = normal speed, <1.0 slows down, >1.0 speeds up)
    // - Set to 0.5 for half speed (slower animation)
    // - Set to 0.1 for very slow animation
    // - Set to 2.0 for double speed (faster animation)
    float speed = 0.5;

    // Palette selection (0.0 = vibrant colors, 1.0 = antique white background with swirling black smoke)
    // - Set to 0.0 for the original vibrant, shifting colors
    // - Set to 1.0 for an antique white background (#FAEBD7) with swirling black smoke effect
    float palette = 0.0;

    // Apply speed scaling to time
    float t = iTime * speed, i = 0.0, z = 0.0, d;

    // Zoom out factor (1.0 = normal, >1.0 zooms out)
    float zoom = 1.8;

    O = vec4(0.0);

    for (; i++ < 100.0;
         O += (cos(z + t + (palette == 0.0 ? vec4(6,1,2,3) : vec4(0.0))) + 1.0) / d)
    {
        // Corrected ray direction with zoom
        vec2 screenPos = (I - 0.5 * iResolution.xy) / iResolution.y;
        vec3 rayDir = normalize(vec3(screenPos * zoom * 2.0, 1.0));
        vec3 p = z * rayDir;
        p.z -= t;

        for(d = 1.0; d < 9.0; d /= 0.7)
            p += cos(p.yzx * d + z * 0.2) / d;

        z += d = 0.02 + 0.1 * abs(3.0 - length(p.xy));
    }

    // Replace tanh(O/3e3) with tanh_approx
    O = tanh_approx(O / 3000.0);

    // Set background and apply smoke for palette 1.0
    if (palette == 1.0) {
        // Use smoke color with O.a controlling opacity over antique white background
        vec3 background = vec3(250.0, 235.0, 215.0) / 255.0; // Antique white
        vec3 smoke = vec3(0.0); // Smoke color (currently black)
        // To change the smoke color, modify the vec3 above with RGB values in [0, 1]
        // - Example: vec3(0.2, 0.0, 0.0) for dark red smoke
        // - Example: vec3(0.0, 0.2, 0.0) for dark green smoke
        // - Example: vec3(0.5) for medium gray smoke
        O.rgb = mix(background, smoke, O.a); // Smoke overlays background based on transparency
    }

    // Apply post-processing
    O = applyPostProcessing(O, 0.90, 1.8, 1.1);
}