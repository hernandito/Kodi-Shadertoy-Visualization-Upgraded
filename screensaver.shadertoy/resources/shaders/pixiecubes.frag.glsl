
/* --- Custom Parameters (using #define for compatibility) ---
// --- Custom Parameters (using #define for compatibility) ---
#define GLOBAL_SPEED .40 // Global speed multiplier for animation
#define BRIGHTNESS   1.0 // Adjust overall brightness (1.0 is neutral, >1 increases, <1 decreases)
#define CONTRAST     1.20 // Adjust contrast (1.0 is neutral, >1 increases, <1 decreases)
#define SATURATION   1.0 // Adjust color saturation (1.0 is neutral, >1 increases, <1 decreases)
#define OFFSET_X     0.00 // X position offset (-1.0 to 1.0, where 1.0 is full screen width)
#define OFFSET_Y     0.00 // Y position offset (-1.0 to 1.0, where 1.0 is full screen height)
#define ZOOM_FACTOR  0.40 // Zoom level (1.0 is normal, <1.0 zooms out, >1.0 zooms in)


*/

// CC0: Nothing complicated
//  I had this lying around after doing some experiments
//  Thought it's neat in its simplicity

// Robust Tanh Conversion Method:
// Added robust tanh approximation function
const float EPSILON = 1e-6; // Moved EPSILON to global scope for broader visibility

// --- Custom Parameters (using #define for compatibility) ---
#define GLOBAL_SPEED .30 // Global speed multiplier for animation
#define BRIGHTNESS   1.0 // Adjust overall brightness (1.0 is neutral, >1 increases, <1 decreases)
#define CONTRAST     1.250 // Adjust contrast (1.0 is neutral, >1 increases, <1 decreases)
#define SATURATION   1.0 // Adjust color saturation (1.0 is neutral, >1 increases, <1 decreases)
#define OFFSET_X     -0.1500 // X position offset (-1.0 to 1.0, where 1.0 is full screen width)
#define OFFSET_Y     0.00 // Y position offset (-1.0 to 1.0, where 1.0 is full screen height)
#define ZOOM_FACTOR  0.40 // Zoom level (1.0 is normal, <1.0 zooms out, >1.0 zooms in)
#define USE_ALT_PALETTE 1 // Toggle for alternative color palette (0 = off, 1 = on)

vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// Function to convert RGB to HSV color space
// c.r, c.g, c.b are R, G, B values (0-1)
// Returns vec3 where x=Hue (0-1), y=Saturation (0-1), z=Value (0-1)
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10; // Small epsilon to prevent division by zero
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Function to convert HSV to RGB color space
// c.x=Hue (0-1), c.y=Saturation (0-1), c.z=Value (0-1)
// Returns vec3 where x=R, y=G, z=B values (0-1)
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void mainImage(out vec4 O, vec2 C) {
    // Initialize output color to black
    O = vec4(0.0); // Explicit initialization for clarity and robustness

    // p = current ray position in 3D space
    // X = snapshot of ray position for lighting calculations
    // r = screen resolution (iResolution is built-in Shadertoy uniform)
    // Explicitly initialize variables
    vec3 p = vec3(0.0);
    vec3 X = vec3(0.0);
    vec3 r = iResolution.xyz; // iResolution is vec3, but only .xy needed for screen coords

    // Apply X and Y offsets to screen coordinates for the effect's position
    vec2 C_offset = C + vec2(OFFSET_X * r.x, OFFSET_Y * r.y);

    // Raymarching loop
    for (
        float i = 0.0, // Explicitly initialized step counter
              d = 0.0, // Explicitly initialized distance to surface
              z = 0.0  // Explicitly initialized total distance traveled
        ; ++i < 66.0;
        // Step 70% of distance
        z += 0.6 * d
    ) {
        // Convert screen coords (with offset and zoom) to 3D ray direction and step forward by distance z
        // Apply ZOOM_FACTOR to the centered screen coordinates
        p = z * normalize(vec3((C_offset - 0.5 * r.xy) / ZOOM_FACTOR, r.y));

        // Move ray forward in Z based on time for animation, applied GLOBAL_SPEED
        p.z += iChannelTime[0] * GLOBAL_SPEED;

        // Store ray position before transformations for lighting calc
        X = p;

        // Rotate XY plane based on Z position - creates swirling tunnel effect
        // Apply GLOBAL_SPEED to rotation as well
        float angle = 0.4 * p.z + iChannelTime[0] * GLOBAL_SPEED * 0.1;
        p.xy *= mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

        // This repeats the super sphere using domain repetition
        p -= floor(p) + 0.5;

        // Calculate distance to the super sphere of 8th power. Looks like a box
        vec3 p_temp = p * p * p * p; // p becomes p^4 (element-wise)
        d = abs(pow(dot(p_temp, p_temp), 0.125) - 0.3) + 1e-3;

        // Accumulate color: lighting calculation divided by distance
        O += (1.1 + sin(2.0 * length(X.xy) + 0.5 * X.z + vec4(2.0, 1.0, 0.0, 0.0))) / d;
    } // End of for loop

    // Apply tone mapping to convert accumulated brightness to displayable range FIRST
    O = tanh_approx(O / max(1e4, EPSILON));

    // --- Post-processing: Apply Alternative Color Palette (Hue Shift) ---
    #if USE_ALT_PALETTE == 1
        vec3 hsv_color = rgb2hsv(O.rgb);
        hsv_color.x = fract(hsv_color.x + 0.5); // Add 0.5 to hue (180 degrees) and wrap
        O.rgb = hsv2rgb(hsv_color);
    #endif

    // --- Post-processing: Apply BCS (Brightness, Contrast, Saturation) Adjustments ---
    // These adjustments are applied to the tone-mapped color output.
    vec3 final_rgb = O.rgb; // Get the tone-mapped color

    // 1. Brightness Adjustment
    final_rgb *= BRIGHTNESS;

    // 2. Contrast Adjustment
    final_rgb = (final_rgb - 0.5) * CONTRAST + 0.5;

    // 3. Saturation Adjustment
    float luminance = dot(final_rgb, vec3(0.299, 0.587, 0.114));
    final_rgb = mix(vec3(luminance), final_rgb, SATURATION);

    // Apply final color to output, clamped to 0-1 range to prevent over-exposure artifacts
    O.rgb = clamp(final_rgb, 0.0, 1.0);
}
