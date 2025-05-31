

precision mediump float; // Crucial for precision in GLSL ES 1.00

/*
    Inspired by Xor's recent raymarchers with comments!
    https://www.shadertoy.com/view/tXlXDX
*/

// --- Post-Processing BCS Parameters (Adjust these for final image look) ---
#define BRIGHTNESS 0.0     // Adjusts the overall brightness. 0.0 is no change, positive values brighten, negative values darken.
#define CONTRAST 1.20       // Adjusts the overall contrast. 1.0 is no change, values > 1.0 increase contrast, < 1.0 decrease.
#define SATURATION 1.0     // Adjusts the overall saturation. 1.0 is no change, values > 1.0 increase saturation, < 1.0 decrease.

// --- Animation Speed Control ---
#define ANIMATION_SPEED 0.2 // Adjusts the overall animation speed. Lower values slow down.

// --- Screen Scale Control ---
// Adjusts the overall zoom level of the effect.
// 1.0 is normal zoom.
// Values > 1.0 will zoom out, showing a more panoramic view.
// Values < 1.0 will zoom in.
#define SCREEN_SCALE 2.5

// --- Dithering Control ---
#define DITHERING 1        // Set to 1 to enable dithering, 0 to disable

// Robust Tanh Conversion Method
// Approximation of tanh(x)
// The denominator 1.0 + abs(x) ensures robustness against division by zero.
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + abs(x) + 1e-6); // Added epsilon for robustness
}

/**
 * @brief Applies Brightness, Contrast, and Saturation adjustments to a color.
 *
 * @param color The input RGB color.
 * @param brightness The brightness adjustment.
 * @param contrast The contrast adjustment.
 * @param saturation The saturation adjustment.
 * @return The adjusted RGB color.
 */
vec4 applyBCS(vec4 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color.rgb += brightness;

    // Apply contrast
    // Midpoint for contrast adjustment is 0.5 (gray).
    color.rgb = ((color.rgb - 0.5) * contrast) + 0.5;

    // Apply saturation
    // Convert to grayscale (luminance)
    float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    // Interpolate between grayscale and original color based on saturation
    color.rgb = mix(vec3(luminance), color.rgb, saturation);

    return color;
}

// Random function for dithering
float random(vec2 p) {
    vec2 nf = floor(p);
    return fract(sin(dot(nf, vec2(12.9898, 78.233))) * 43758.5453);
}

void mainImage(out vec4 o, in vec2 u) { // Output variable is 'o' as per original code and your preference
    float i = 0.0; // Loop counter
    float d = 0.0; // Distance accumulator for raymarching
    float s;     // Step size / temporary variable
    float t = iTime * ANIMATION_SPEED; // Time variable, scaled by ANIMATION_SPEED

    o = vec4(0.0); // Initialize 'o' explicitly to zero, as per original's 'o*=i' with i=0

    // Calculate normalized screen coordinates for ray direction
    // u is fragCoord, so u * 2.0 - iResolution.xy maps to [-res.x, res.x] for x, [-res.y, res.y] for y
    // Dividing by iResolution.y normalizes the y-component to [-aspect_ratio, aspect_ratio] and x to [-aspect_ratio, aspect_ratio]
    vec2 screen_uv = (u * 2.0 - iResolution.xy) / iResolution.y;

    // Apply the screen scale to the normalized screen UVs
    screen_uv *= SCREEN_SCALE;

    // Construct the ray direction. The third component (-1.0) points the ray into the screen.
    // The aspect ratio correction ensures the view is not stretched.
    vec3 ray_dir = normalize(vec3(screen_uv.x * (iResolution.x / iResolution.y), screen_uv.y, -1.0));


    // Original loop: for(o*=i; i++<1e2; )
    // Reinterpreted for clarity and GLSL ES 1.00 compatibility:
    // Initialize o to 0, then loop while i is less than 100.
    for(; i < 100.0; i++ ) { // Loop for raymarching steps (100 iterations)
        // Calculate current point 'p' in 3D space based on distance 'd' and ray direction
        vec3 p = d * ray_dir; // Use the newly calculated ray_dir
        p.z -= t; // Translate along Z-axis based on time

        // Inner loop for fractal noise/distortion
        // Original: for (s = .1; s < 2.; p -= dot(cos(t+p * s* 16.), vec3(.01)) / s, p += sin(p.yzx*.9)*.3, s *= 1.42);
        // Rewritten as a standard for loop for clarity and compatibility:
        for (s = 0.1; s < 2.0; s *= 1.42) { // Loop for detail levels
            // Apply a cosine-based displacement
            p -= dot(cos(t + p * s * 16.0), vec3(0.01)) / s;
            // Apply a sine-based displacement
            p += sin(p.yzx * 0.9) * 0.3;
        }

        // Calculate step size 's' based on distance from origin in XY plane
        // Ensure float literals have decimal points.
        s = 0.02 + abs(3.0 - length(p.yx)) * 0.1;
        d += s; // Accumulate distance for next raymarch step

        // Accumulate color 'o' based on distance and cosine wave
        // Ensure float literals have decimal points.
        o += (1.0 + cos(d + vec4(4.0, 2.0, 1.0, 0.0))) / s;
    }

    // Apply the Robust Tanh Conversion Method to the final accumulated color
    // Ensure float literal has decimal point.
    o = tanh_approx(o / 2000.0); // Scale 'o' before applying tanh approximation

    // Apply Brightness, Contrast, and Saturation after the final tanh approximation
    o = applyBCS(o, BRIGHTNESS, CONTRAST, SATURATION);

    // Apply Dithering
    if (DITHERING == 1) {
        // Add a small random offset to each color channel based on pixel coordinates
        // This helps break up smooth gradients and reduce banding.
        o.rgb += (random(u) - 0.5) / 255.0; // Divide by 255.0 for 8-bit color depth
    }
}
