void mainImage(out vec4 O, in vec2 F) {
    // USER-ADJUSTABLE PARAMETERS
    // SATURATION: Controls the vibrancy of colors in the accretion disk (red/blue gradient)
    //   Purpose: Adjusts how intense or muted the colors appear
    //   Default: 1.0 (matches the original colors of the provided shader)
    //   Increase (>1.0): Makes colors more vibrant (e.g., stronger red/blue, vivid clouds)
    //   Decrease (<1.0): Makes colors less vibrant (e.g., muted, grayer clouds)
    //   Example values:
    //     0.5: Muted colors, red/blue gradient appears grayer, clouds less vivid
    //     1.0: Default, exact colors of the provided shader
    //     1.5: Vibrant colors, intense red/blue gradient, clouds pop more
    // For Kodi: Replace with `uniform float saturation;` to adjust via addon settings
    const float saturation = 1.0;
    // Alternative settings (uncomment one to test):
    // const float saturation = 0.5; // Muted colors
    // const float saturation = 1.5; // Vibrant colors

    // CONTRAST: Controls the distinction between bright and dark areas (clouds vs. blackhole)
    //   Purpose: Adjusts how sharp or flat the brightness differences appear
    //   Default: 1.0 (matches the original contrast of the provided shader)
    //   Increase (>1.0): Increases contrast, making clouds brighter and blackhole center darker
    //   Decrease (<1.0): Decreases contrast, making clouds and center less distinct, flatter look
    //   Example values:
    //     0.5: Low contrast, clouds and blackhole center blend more, flatter appearance
    //     1.0: Default, exact contrast of the provided shader
    //     1.5: High contrast, sharper clouds, very dark blackhole center
    // For Kodi: Replace with `uniform float contrast;` to adjust via addon settings
    const float contrast = 1.0;
    // Alternative settings (uncomment one to test):
    // const float contrast = 0.5; // Low contrast
    // const float contrast = 1.5; // High contrast

    // Iterator and attenuation (distance-squared)
    float i = 0.2, a;
    // Resolution for scaling and centering
    vec2 r = iResolution.xy;
    // Centered ratio-corrected coordinates
    vec2 p = (F + F - r) / r.y / 0.7;
    // Diagonal vector for skewing
    vec2 d = vec2(-1.0, 1.0);
    // Blackhole center
    vec2 b = p - i * d;
    // Rotate and apply perspective
    vec2 c = p * mat2(1.0, 1.0, d.x / (0.1 + i / dot(b, b)), d.y / (0.1 + i / dot(b, b)));
    // Compute attenuation for spiral
    a = dot(c, c);
    // Rotate into spiraling coordinates with subtle phase offset
    float angle = 0.5 * log(a) + iTime * i + 11.0;
    float ca = cos(angle), sa = sin(angle);
    vec2 v = c * mat2(ca, sa, -sa, ca) / i;
    // Waves cumulative total for coloring
    float w = 0.0;
    
    // Loop through waves (15 iterations for enhanced detail)
    for (; i < 15.0; i += 1.0) {
        v += 0.7 * sin(v.yx * i + iTime) / i + 0.5;
        w += 1.0 + 0.5 * sin(v.x); // Reduced sin contribution for lighter clouds
    }
    // Accretion disk radius
    i = length(sin(v / 0.3) * 0.4 + c * (3.0 + d));
    // Red/blue gradient with brighter clouds
    O = 1.0 - exp(-exp(c.x * vec4(0.6, -0.4, -1.0, 0.0))
                  / vec4(w * 1.2, w * 1.2, w * 1.2, 1.0) // Scale w to brighten clouds
                  / (2.0 + i * i / 4.0 - i)
                  / (0.7 + 1.0 / a) // Increased center darkness
                  / (0.03 + abs(length(p) - 0.7)));
    
    // Apply saturation
    vec3 color = O.rgb;
    // RGB to HSV
    vec3 hsv;
    float minVal = min(min(color.r, color.g), color.b);
    float maxVal = max(max(color.r, color.g), color.b);
    float delta = maxVal - minVal;
    hsv.z = maxVal; // Value
    if (delta == 0.0) {
        hsv.x = 0.0; // Hue undefined
        hsv.y = 0.0; // Saturation
    } else {
        hsv.y = delta / maxVal; // Saturation
        if (color.r == maxVal) {
            hsv.x = (color.g - color.b) / delta; // Hue
        } else if (color.g == maxVal) {
            hsv.x = 2.0 + (color.b - color.r) / delta;
        } else {
            hsv.x = 4.0 + (color.r - color.g) / delta;
        }
        hsv.x *= 60.0;
        if (hsv.x < 0.0) hsv.x += 360.0;
    }
    // Scale saturation
    hsv.y = clamp(hsv.y * saturation, 0.0, 1.0);
    // HSV to RGB
    if (hsv.y == 0.0) {
        color = vec3(hsv.z);
    } else {
        hsv.x /= 60.0;
        int i = int(hsv.x);
        float f = hsv.x - float(i);
        float p = hsv.z * (1.0 - hsv.y);
        float q = hsv.z * (1.0 - hsv.y * f);
        float t = hsv.z * (1.0 - hsv.y * (1.0 - f));
        if (i == 0) color = vec3(hsv.z, t, p);
        else if (i == 1) color = vec3(q, hsv.z, p);
        else if (i == 2) color = vec3(p, hsv.z, t);
        else if (i == 3) color = vec3(p, q, hsv.z);
        else if (i == 4) color = vec3(t, p, hsv.z);
        else color = vec3(hsv.z, p, q);
    }
    
    // Apply contrast
    color = (color - 0.5) * contrast + 0.5;
    color = clamp(color, 0.0, 1.0); // Clamp to prevent artifacts
    
    O = vec4(color, O.a);
}