// Playing with https://www.shadertoy.com/view/33VGzW

// Robust Tanh Conversion Method:
// Include the tanh_approx function:
const float EPSILON = 1e-6; // A small epsilon to prevent division by zero or very small numbers
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
// Adjust these values to modify the final image appearance.
// BRIGHTNESS: Adds or subtracts from the color (e.g., 0.1 for brighter, -0.1 for darker)
#define BRIGHTNESS 0.10
// CONTRAST: Scales the color around a midpoint of 0.5 (e.g., 1.2 for more contrast, 0.8 for less)
#define CONTRAST 1.25
// SATURATION: Interpolates between grayscale and original color (e.g., 1.5 for more vivid, 0.5 for desaturated)
#define SATURATION 1.0
// -----------------------------------------------------------------------

// --- Blue Tint Parameters ---
// BLUE_TINT_RED_FACTOR: Multiplier for the red channel's contribution to the blue channel.
#define BLUE_TINT_RED_FACTOR 1.5
// BLUE_TINT_GREEN_FACTOR: Multiplier for the green channel's contribution to the blue channel.
#define BLUE_TINT_GREEN_FACTOR 0.7
// BLUE_TINT_OVERALL_STRENGTH: Overall multiplier for the blue channel's final value.
#define BLUE_TINT_OVERALL_STRENGTH 0.3
// ----------------------------

void mainImage(out vec4 o, vec2 fragCoord) {
    // Explicitly initialize all declared variables
    float t = iTime*.2;
    vec2 u = (fragCoord - iResolution.xy * 0.35) / max(iResolution.y, EPSILON); // Robust division
    
    o = vec4(0.0); // Explicitly initialize o
    float d = 0.0; // Explicitly initialize d
    
    // Raymarch!
    for (int i = 0; i < 70; i++) { // Changed 70 to 70 for clarity
        vec3 p = vec3(u * d, d + t + t);

        // Spiral twist - rotate around Z axis
        float angle = p.z * 0.1; // Changed .1 to 0.1
        float ca = cos(angle + t / 5.0); // Changed .5 to 0.5
        float sa = sin(angle + t / 5.0); // Changed .5 to 0.5
        mat2 rot = mat2(ca, -sa, sa, ca);
        vec2 twistCenter = 0.7 * vec2(sin(t * 1.5 + 1.0), sin(t * 2.3)); // Changed .7 to 0.7, 1.5 to 1.5, 1. to 1.0, 2.3 to 2.3

        p.xy *= (2.0 + sin(t + 2.0 * cos(t)) / 2.0); // Changed 2. to 2.0, 2. to 2.0, 2. to 2.0
        p.xy = rot * p.xy;
        p.xy -= twistCenter;

        // starting 'signed distance'
        float s = 0.8 * sin(p.x + p.y); // Changed .8 to 0.8

        // Add distraction
        float n = 1.0; // Explicitly initialize n
        while (n < 6.0) { // Changed 6. to 6.0
            vec3 noiseInput = (vec3(1.1, 0.8, 0.8) * p) * mod(n, 2.0); // Changed .8 to 0.8, .8 to 0.8, 2. to 2.0
            float noise = abs(dot(cos(noiseInput), vec3(0.3))) / max(n, EPSILON); // Robust division, changed .3 to 0.3
            s -= (0.99 + p.z / 2000.0) * noise; // Changed 2000. to 2000.0
            n += 0.38 * n; // Changed .38 to 0.38
        }

        // Distance and color accumulation over Z axis (ray marching loop)
        float eps = 0.01 + abs(s) * 0.5; // Changed .01 to 0.01, .5 to 0.5
        d += eps;
        o += vec4(1.0 / max(eps, EPSILON)); // Robust division
    }

    // Tanh tonemap
    o = tanh_approx(o / (18000.0 * max(length(u), EPSILON))); // Robust division, changed 18000. to 18000.0

    // o.y = d / 100.; // Original commented out line
    // Apply blue tint parameters here
    o.z = BLUE_TINT_OVERALL_STRENGTH * (o.x * BLUE_TINT_RED_FACTOR + o.y * BLUE_TINT_GREEN_FACTOR);

    // --- Apply BCS (Brightness, Contrast, Saturation) adjustments ---
    // Brightness
    o.rgb += BRIGHTNESS;

    // Contrast (pivot around 0.5)
    o.rgb = (o.rgb - 0.5) * CONTRAST + 0.5;

    // Saturation
    float luma = dot(o.rgb, vec3(0.299, 0.587, 0.114)); // Calculate luminance
    o.rgb = mix(vec3(luma), o.rgb, SATURATION); // Mix between grayscale and original color

    // Ensure color values remain within valid range [0, 1] after adjustments
    o = clamp(o, 0.0, 1.0);
    // -----------------------------------------------------------------
}
