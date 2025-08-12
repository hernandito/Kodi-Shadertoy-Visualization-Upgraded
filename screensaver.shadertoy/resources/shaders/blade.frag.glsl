/*
    "Runner" by @XorDev
    
    More fun with fractals
    
    Dust:
    https://www.shadertoy.com/view/cdG3Wd
    Radioactive:
    https://www.shadertoy.com/view/mdG3Wy
    Sector:
    https://www.shadertoy.com/view/mdXfDS
    Runner:
    https://www.shadertoy.com/view/wfGXDh
    
    Tweet version:
    https://x.com/XorDev/status/1933624066776445381
    <512 Char playlist:
    https://www.shadertoy.com/playlist/N3SyzR
*/

// Robust Tanh Conversion Method:
// Added robust tanh approximation function
const float EPSILON = 1e-6; // Moved EPSILON to global scope for broader visibility

// --- Custom Parameters (using #define for compatibility) ---
#define GLOBAL_SPEED .20 // Global speed multiplier for animation
#define BRIGHTNESS   1.0 // Adjust overall brightness (1.0 is neutral, >1 increases, <1 decreases)
#define CONTRAST     1.0 // Adjust contrast (1.0 is neutral, >1 increases, <1 decreases)
#define SATURATION   1.0 // Adjust color saturation (1.0 is neutral, >1 increases, <1 decreases)
#define OFFSET_X     0.0 // X position offset (-1.0 to 1.0, where 1.0 is full screen width)
#define OFFSET_Y     0.0 // Y position offset (-1.0 to 1.0, where 1.0 is full screen height)
#define ZOOM_FACTOR  1.0 // Zoom level (1.0 is normal, <1.0 zooms out, >1.0 zooms in)
#define USE_ALT_PALETTE 0 // Toggle for alternative color palette (0 = off, 1 = on)

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


void mainImage(out vec4 O, vec2 I)
{
    // Explicitly initialize variables as per Robust Tanh Conversion Directive
    vec3 p = vec3(0.0);
    vec3 v = vec3(0.0);
    float z = 0.0;
    float d = 0.0;
    float i = 0.0;
    float j = 0.0;

    // Get screen resolution
    vec2 R = iResolution.xy;

    // Apply X and Y offsets to screen coordinates for the effect's position
    vec2 I_offset = I + vec2(OFFSET_X * R.x, OFFSET_Y * R.y);

    // Clear fragColor and raymarch 30 steps
    // O*=i; is replaced by explicit initialization and then accumulation
    O = vec4(0.0); // Explicitly clear output color

    for(i = 0.0; i < 30.0; ++i) // Raymarch 30 steps
    {
        // Step forward
        z += d;

        // Coloring and fog (try +2. for more ground fog)
        // Ensure explicit floats and robustness if d*d approaches zero
        O += 0.1 * pow(max(EPSILON, d*d) * exp(p.yyyy), vec4(0.7, 0.6, 0.5, 1.0));

        // Raymarch sample point with camera offset
        // Original: p = z * normalize(vec3(I+I,0)-iResolution.xyy);
        // Corrected to handle I_offset and ZOOM_FACTOR while maintaining vec3 types
        vec3 ray_dir_unscaled = vec3(I_offset + I_offset, 0.0) - iResolution.xyy;
        p = z * normalize(ray_dir_unscaled / ZOOM_FACTOR);


        // Scroll forward and right
        // Converted iTime to iChannelTime[0] and applied GLOBAL_SPEED
        p.z -= iChannelTime[0] * GLOBAL_SPEED;

        // Fractal loop
        for(v = ++p, j = 4.0, d = -j; j > 0.01; j *= 0.3)
        {
            // Subtract cubes
            // Add robustness to division: d = max(d, min(min(v=j*.7-abs(mod(v+j,j+j)-j),v.y).x,v.z))/(1.+z/3e1),
            vec3 temp_v_mod_val = j*0.7 - abs(mod(v+j,j+j)-j); // Result of j*.7-abs(mod(v+j,j+j)-j)
            d = max(d, min(min(temp_v_mod_val.x, temp_v_mod_val.y), temp_v_mod_val.z)) / (1.0 + z / 30.0 + EPSILON); // Added EPSILON for robustness
            v = temp_v_mod_val; // Update v after d calculation if it's meant to be modified for next iteration

            // Rotate 9 radians
            // The vec4(2,13,35,2) is likely a specific set of constants for cos components in mat2
            // It does not appear to be tied to iTime or animation speed, so no GLOBAL_SPEED applied here.
            v.zy *= mat2(cos(vec4(2.0, 13.0, 35.0, 2.0))); // Explicit floats for clarity
        }
    }
    // Tonemap
    // O = tanh(O*O);
    O = tanh_approx(O * O); // Replaced tanh() with tanh_approx()

    // --- Post-processing: Apply Alternative Color Palette (Hue Shift) ---
    #if USE_ALT_PALETTE == 1
        vec3 hsv_color = rgb2hsv(O.rgb);
        hsv_color.x = fract(hsv_color.x + 0.5); // Add 0.5 to hue (180 degrees) and wrap
        O.rgb = hsv2rgb(hsv_color);
    #endif

    // --- Post-processing: Apply BCS (Brightness, Contrast, Saturation) Adjustments ---
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
