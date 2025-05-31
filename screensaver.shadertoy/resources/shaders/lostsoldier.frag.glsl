/*
    "3D Fire" modified by ChatGPT based on @XorDev

    - Corkscrew motion randomized
    - Lower magenta color shifted to realistic blue
    - Modified by Grok to replace tanh tonemapping with Reinhard tonemapping for Kodi compatibility
    - Added post-processing for brightness, contrast, and saturation adjustments
    - Adjusted color gradient to create an artistic transition (blue -> pale lilac -> orange)
    - Eliminated remaining green and embraced lilac/pink hues as an artistic choice
    - Reintroduced detailed notes on brightness, contrast, and saturation adjustments
    - Added notes on controlling strength and transparency of color fills
*/

// Helper functions for saturation adjustment (RGB to HSV and HSV to RGB conversion)
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

precision highp float;

void mainImage(out vec4 O, in vec2 I)
{
    // Time for animation
    float t = iTime,
          i,
          z = 0.0, // Initialize z to avoid uninitialized variable warning
          d;

    // Initialize output color
    O = vec4(0.0);

    // Raymarching loop
    for (i = 0.0; i < 50.0; i++) // Controls transparency: fewer iterations (e.g., 30.0) = more transparent; more iterations (e.g., 70.0) = more opaque
    {
        // Compute raymarch sample point
        vec3 p = z * normalize(vec3(I + I, 0.0) - iResolution.xyy);

        // Shift back and animate forward motion
        p.z += 5.0 + cos(t * 0.5 + sin(p.y * 0.5)); // Slightly irregular forward motion

        // Add randomized twist and rotation
        float twist = p.y * 0.5 + sin(p.y * 0.5 + t * 0.8) * 0.3; // Added sine-based irregularity
        p.xz *= mat2(cos(twist), sin(twist),
                    -sin(twist), cos(twist));

        // Expand upward
        p.xz /= max(p.y * 0.1 + 0.80, 0.1);

        // Turbulence loop (increase frequency)
        for (d = 2.0; d < 15.0; d /= 0.6)
            p += cos((p.yzx - vec3(t * 0.1, t, d)) * d) / d;

        // Sample approximate distance to hollow cone
        z += d = 0.01 + abs(length(p.xz) + p.y * 0.3 - 0.5) / 7.0;
        // Controls transparency: '0.01' is the base step size; increase (e.g., 0.02) for more transparency, decrease (e.g., 0.005) for more opacity

        // Calculate basic color and glow
        vec4 col = (sin(z / 3.0 + vec4(7.0, 2.0, 3.0, 0.0)) + 1.0) * 0.8 / d;
        // Controls strength: '+ 1.1' shifts brightness (increase to 1.5 for brighter, decrease to 0.8 for dimmer)
        // '* 0.8' scales intensity (increase to 1.0 for stronger colors, decrease to 0.6 for fainter colors)

        // Adjust colors: create an artistic gradient (blue -> pale lilac -> orange)
        float heightFactor = clamp(p.y * 0.25 + 0.5, 0.0, 1.0);
        // Define the colors
        vec3 baseColor = vec3(0.15, 0.35, 0.7); // Slightly adjusted blue base for smoother transition
        vec3 midColor = vec3(1.0, 0.7, 0.5);   // Pinkish tone to embrace lilac/pink hues
        vec3 topColor = vec3(1.0, 0.7, 0.0);   // Orange-yellow top
        // Controls strength: Reducing these color values (e.g., halving them) makes fills fainter; increasing them makes fills stronger
        // Piecewise interpolation to control the transition
        vec3 flameColor;
        float transitionPoint = 0.3; // Quick transition from blue to lilac
        if (heightFactor < transitionPoint) {
            // First segment: blue to pale lilac
            float t = heightFactor / transitionPoint;
            flameColor = mix(baseColor, midColor, t);
            // Further suppress green to eliminate any remaining green hues
            flameColor.g = mix(baseColor.g, midColor.g * 0.5, t);
        } else {
            // Second segment: pale lilac to orange-yellow
            float t = (heightFactor - transitionPoint) / (1.0 - transitionPoint);
            flameColor = mix(midColor, topColor, t);
        }
        col.rgb *= flameColor;

        O += col; // Accumulates color; transparency can be modified by using col.a if desired (e.g., O.rgb += col.rgb * col.a)
    }

    // Adjusted tonemapping for brighter, more vibrant colors
    O = max(O, 0.0); // Ensure no negative values
    O *= 3.5; // Controls strength: Increase (e.g., 6.0) for more intense colors, decrease (e.g., 2.0) for fainter colors
    O = O / (O + 800.0); // Slightly reduced Reinhard constant for more brightness

    // Post-processing: Brightness, Contrast, and Saturation adjustments
    // These adjustments mimic the Photoshop edits (Brightness: -28, Contrast: 100, Saturation: +12)
    // to reduce glow, darken the background, and enhance color vibrancy.

    // 1. Brightness Adjustment
    // - Purpose: Slightly darkens the image to reduce glow and overall intensity.
    // - Original Photoshop Setting: Brightness: -28 (range -150 to +150)
    // - Implementation: Scale the RGB values by a factor that corresponds to the brightness change.
    //   - Photoshop brightness range of -150 to +150 means 0 is neutral.
    //   - -28 / 150 = -0.1867 (fraction of the range).
    //   - Convert to a scaling factor: 1.0 + (-0.1867) = 0.8133.
    //   - User fine-tuned to 0.9133 for a slightly brighter output.
    // - Example:
    //   - Input color: O.rgb = vec3(0.8, 0.5, 0.2)
    //   - After brightness adjustment: O.rgb *= 0.9133
    //   - New color: vec3(0.8 * 0.9133, 0.5 * 0.9133, 0.2 * 0.9133) = vec3(0.7306, 0.4567, 0.1827)
    //   - Result: The color is slightly darker, reducing the glow while preserving the hue.
    // - Why This Helps: Reducing brightness lowers the intensity of the glow around the shapes,
    //   making the core more defined and darkening the background slightly.
    // - Fine-Tuning: Increase to 1.0 for no brightness reduction, decrease to 0.8 for darker output.
    O.rgb *= 0.8;

    // 2. Contrast Adjustment
    // - Purpose: Increases contrast to make bright areas brighter and dark areas darker,
    //   reducing glow and enhancing the shapes' details.
    // - Original Photoshop Setting: Contrast: 100 (range -100 to +100)
    // - Implementation: Use the contrast formula: O.rgb = (O.rgb - 0.5) * contrast + 0.5
    //   - Pivot at 0.5: Values above 0.5 get brighter, values below 0.5 get darker.
    //   - Contrast factor: In Photoshop, a contrast of 100 (max) typically maps to a shader contrast factor
    //     of around 2.0 to 3.0. Originally used 2.5, user fine-tuned to 1.4 for less aggressive contrast.
    //   - Clamp the result to [0, 1] to avoid invalid color values.
    // - Example:
    //   - Input color (after brightness): O.rgb = vec3(0.7306, 0.4567, 0.1827)
    //   - Contrast factor: 1.4
    //   - Compute: (O.rgb - 0.5) * 1.4 + 0.5
    //     - R: (0.7306 - 0.5) * 1.4 + 0.5 = 0.2306 * 1.4 + 0.5 = 0.3228 + 0.5 = 0.8228
    //     - G: (0.4567 - 0.5) * 1.4 + 0.5 = -0.0433 * 1.4 + 0.5 = -0.0606 + 0.5 = 0.4394
    //     - B: (0.1827 - 0.5) * 1.4 + 0.5 = -0.3173 * 1.4 + 0.5 = -0.4442 + 0.5 = 0.0558
    //   - New color: vec3(0.8228, 0.4394, 0.0558)
    //   - Result: The bright red channel gets brighter, the mid-range green channel adjusts slightly,
    //     and the low blue channel gets darker, enhancing contrast.
    // - Why This Helps: Moderate contrast reduces glow by darkening low-intensity areas while
    //   making the bright areas stand out, matching the user's desired look.
    // - Fine-Tuning: Increase to 2.0 for more contrast, decrease to 1.0 for no contrast adjustment.
    float contrast = 2.1; // Reduced for less aggressive contrast
    O.rgb = (O.rgb - 0.5) * contrast + 0.5;
    O.rgb = clamp(O.rgb, 0.0, 1.0); // Ensure values stay in [0, 1]

    // 3. Saturation Adjustment
    // - Purpose: Increases the intensity of the colors to make the blue, lilac, and orange tones more vibrant.
    // - Original Photoshop Setting: Saturation: +12 (range -100 to +100)
    // - Implementation: Convert RGB to HSV, scale the saturation component, and convert back to RGB.
    //   - Photoshop saturation range of -100 to +100 means 0 is neutral.
    //   - +12 / 100 = 0.12 (fraction of the range).
    //   - Convert to a scaling factor: 1.0 + 0.12 = 1.12.
    //   - User fine-tuned to 1.08 to soften the blue base.
    //   - Multiply the saturation component by 1.08.
    //   - Clamp the saturation to [0, 1] to avoid invalid values.
    // - Example:
    //   - Input color (after contrast): O.rgb = vec3(0.8228, 0.4394, 0.0558)
    //   - Convert to HSV: rgb2hsv(vec3(0.8228, 0.4394, 0.0558))
    //     - Hue: ~0.083 (orange hue)
    //     - Saturation: ~0.932 (highly saturated)
    //     - Value: 0.8228 (brightness of the brightest channel)
    //   - Increase saturation: 0.932 * 1.08 = 1.006, clamped to 1.0
    //   - New HSV: vec3(0.083, 1.0, 0.8228)
    //   - Convert back to RGB: hsv2rgb(vec3(0.083, 1.0, 0.8228)) = vec3(0.8228, 0.4394, 0.0)
    //   - Result: The color becomes fully saturated, enhancing vibrancy.
    //   - Another example with a less saturated color:
    //     - Input: O.rgb = vec3(0.5, 0.4, 0.3)
    //     - HSV: ~0.083 (orange hue), ~0.4 (saturation), 0.5 (value)
    //     - New saturation: 0.4 * 1.08 = 0.432
    //     - New HSV: vec3(0.083, 0.432, 0.5)
    //     - New RGB: ~vec3(0.522, 0.394, 0.284)
    //     - Result: The color becomes more vibrant, with the same hue but more intense.
    // - Why This Helps: Increasing saturation makes the colors (blue, lilac, orange) more vivid,
    //   enhancing the artistic effect.
    // - Fine-Tuning: Increase to 1.2 for more vibrant colors, decrease to 1.0 for no saturation adjustment.
    vec3 hsv = rgb2hsv(O.rgb);
    hsv.y *= .900; // Reduced to avoid over-saturating the blue base
    hsv.y = clamp(hsv.y, 0.0, 1.0); // Ensure saturation stays in [0, 1]
    O.rgb = hsv2rgb(hsv);

    O.a = 1.0; // Ensure alpha is 1.0 for Kodi
}

/** SHADERDATA
{
    "title": "3D Fire (Kodi Compatible)",
    "description": "Renders a 3D flame effect with corkscrew motion and an artistic blue-to-lilac-to-orange color gradient, modified for Kodi compatibility",
    "model": "person"
}
*/