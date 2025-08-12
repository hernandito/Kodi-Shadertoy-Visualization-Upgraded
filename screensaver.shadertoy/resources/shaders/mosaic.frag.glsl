// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

/*
    "Mosaic" by @XorDev

    A series of lightweight shaders made for easy learning and high-performance applications:
    https://www.shadertoy.com/playlist/ccffz7

    MIT license
    Credit is appreciated, but not required!
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Explicit Variable Initialization
    vec2 r = vec2(0.0);
    vec2 p = vec2(0.0);
    vec2 v = vec2(0.0);
    vec4 color = vec4(0.0);

    // --- PARAMETERS ---
    #define BRIGHTNESS 1.10    // Brightness adjustment (1.0 = neutral)
    #define CONTRAST 1.35      // Contrast adjustment (1.0 = neutral)
    #define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)
    #define SCREEN_SCALE .700  // Scale factor for zooming the effect (e.g., 0.5 for zoom in, 2.0 for zoom out)
    #define WHITE_TINT vec3(1.0, 1.0, 1.0) // RGB color for the white tint (e.g., vec3(1.0, 0.9, 0.8) for warm white)
    #define WHITE_TINT_STRENGTH 0.0 // How strongly to apply the tint (0.0 for no tint, 1.0 for full tint)

    r = iResolution.xy;

    // Apply screen scale for zooming to fragCoord before centering and scaling
    vec2 scaledFragCoord = fragCoord / SCREEN_SCALE;

    // Centered and scaled to fit vertically [-3, +3]
    p = 3. * (scaledFragCoord * 2. - r / SCREEN_SCALE) / max(r.y / SCREEN_SCALE, 1e-6); // Robust division

    // Doubled coordinates
    v = p + p +
    // Shift over time with random blocks
    (iTime + r.x) * cos(r.x + ceil(p + sin(p * 5.0))).yx; // Using r.x for scalar operations

    // Tanh tonemapping - Applying tanh_approx and robust division
    // Original: tanh(.1 * (cos(.6*p.x+.4*sin(v.y)+vec4(0,1,2,3))+1.) / length(.9+sin(v)))
    vec4 numerator = 0.1 * (cos(0.6 * p.x + 0.4 * sin(v.y) + vec4(0, 1, 2, 3)) + 1.0);
    float denominator = length(0.9 + sin(v));

    color = tanh_approx(numerator / max(denominator, 1e-6)); // Robust division

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = color.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    finalColor = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

    // --- Apply White Tint ---
    // Mix the final color with the WHITE_TINT based on its luminance and the strength parameter.
    // This applies the tint more strongly to brighter areas.
    finalColor = mix(finalColor, WHITE_TINT, luminance * WHITE_TINT_STRENGTH);

    fragColor = vec4(finalColor, 1.0);
}
