const float EPSILON = 1e-6; // Epsilon for robust division and tanh_approx

// Robust tanh approximation function
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
// Adjust these values to modify the final image appearance.
// BRIGHTNESS: Adds or subtracts from the color (e.g., 0.1 for brighter, -0.1 for darker)
#define BRIGHTNESS 0.1
// CONTRAST: Scales the color around a midpoint of 0.5 (e.g., 1.2 for more contrast, 0.8 for less)
#define CONTRAST 1.3
// SATURATION: Interpolates between grayscale and original color (e.g., 1.5 for more vivid, 0.5 for desaturated)
#define SATURATION 1.3
// -----------------------------------------------------------------------

// Function to apply Brightness, Contrast, and Saturation adjustments
vec4 adjustBCS(vec4 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color.rgb += brightness;
    // Apply contrast (pivot around 0.5)
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    // Apply saturation (mix with grayscale)
    float gray_val = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722)); // Standard luminance coefficients
    color.rgb = mix(vec3(gray_val), color.rgb, saturation);
    return color;
}

//fork of https://www.shadertoy.com/user/moka 's
//https://www.shadertoy.com/view/wXcSD7

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float a = iResolution.y;

    // Shift flame 150 pixels right and 10 pixels down
    vec2 shiftedCoord = vec2(fragCoord.x / 1.8, fragCoord.y / 0.9);

    vec2 f = shiftedCoord;
    f = 2.0 * f / max(a, EPSILON) - 1.0;  // normalize coords [-1..1], robust division

    float z = -a;
    float d = 0.0; // Explicitly initialized
    vec3 p = vec3(0.0); // Explicitly initialized
    vec4 o = vec4(2.0);

    float baseRadius = 0.6;

    for(float i = 0.0; i < 45.0; i++) {
        p = vec3(f.x, f.y, z);

        float flicker = 0.06 * cos(10.0 * p.x  + iTime * 0.4 * 15.0 + z * 5.0); // Explicitly initialized, user's change applied
        float distortionFactor = clamp(-p.x * 1.0, 0.55, 0.6); // Explicitly initialized
        flicker = flicker / max(distortionFactor, EPSILON); // Robust division

        float dist = length(p.xy) - (baseRadius + flicker); // Explicitly initialized

        d = 0.01 + 0.33 * abs(length(vec3(dist, p.x, p.z)) - 0.28);

        z += d;

        o += 1.6 * (sin(p.x / 0.2 + z / 0.1 + vec4(0.0,1.0,2.0,3.0)) + 1.0) / max(d, EPSILON); // Robust division
    }

    vec4 flameColor = tanh_approx(o * o / 7e6); // Replaced tanh with tanh_approx

    // Sharp black gradient fade on lower part of screen
    float coverStart = 38.49;
    float coverEnd = iResolution.y * 5.0;  // quick fade zone (~12% of screen height)

    float alpha = smoothstep(coverStart, coverEnd, fragCoord.y); // Explicitly initialized
    alpha = 1.0 - alpha;          // invert for black at bottom, transparent at coverEnd
    alpha = pow(alpha, 33.0);      // sharpen the gradient curve (higher = sharper)

    // Blend flame with black overlay controlled by alpha gradient
    fragColor = mix(flameColor, vec4(0.0, 0.0, 0.0, 1.0), alpha);

    // --- Apply BCS (Brightness, Contrast, Saturation) adjustments ---
    fragColor = adjustBCS(fragColor, BRIGHTNESS, CONTRAST, SATURATION);
    // -----------------------------------------------------------------
}
