/*
    "Rollin" by @XorDev

    https://x.com/XorDev/status/1920935494591844367
*/

// --- OpenGL ES 1.0 Compatible tanh approximation ---
vec4 tanh_approx(vec4 x) {
    // Approximation of tanh(x) = x / (1.0 + abs(x))
    return x / (1.0 + abs(x)); // Use 1.0 for clarity
}

// --- Post-processing functions for better output control (BCS) ---
vec4 saturate(vec4 color, float sat) {
    // Adjusts color saturation
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    // Applies brightness, contrast, and saturation adjustments
    color.rgb = (color.rgb - 0.5) * contrast + 0.5; // Use 0.5 for clarity
    color.rgb *= brightness;
    return saturate(color, saturation);
}
// -----------------------------------------------------------------

// --- Post-processing Parameters (BCS) ---
// Adjust these values to fine-tune the final image appearance AFTER tone mapping
float post_brightness = 1.1; // Increase for brighter image, decrease for darker
float post_contrast = 1.6;   // Increase for more contrast, decrease for less
float post_saturation = 0.90; // Increase for more saturated colors, decrease for less
// ----------------------------------------

// --- Animation Speed Parameter ---
// Adjust this value to control the overall speed of the animation.
float animation_speed = 0.5; // Adjust this value for overall animation speed
// ---------------------------------


void mainImage(out vec4 O, vec2 I)
{
    // Declare variables used throughout the shader
    float i;  // Iterator
    float z = 0.0; // Raymarch depth - Initialize to 0.0
    float d;  // Raymarch step distance

    // Declare variables used in the loop before the loop
    vec4 o_accumulated = vec4(0.0); // Accumulated color - Initialize to 0.0
    vec3  p; // Raymarch sample point
    vec3  p_res = iResolution.xyz; // Resolution - Use .xyz for clarity
    float t = iTime; // Time uniform

    // Define the fire palette
    vec4 fire_palette = vec4(3.0, 1.5, 0.5, 0.0); // Orange-yellowish

    // Clear fragColor and raymarch loop (standardized structure)
    // Raymarch 50 steps
    for (i = 0.0; i < 50.0; i += 1.0) // Converted to standard for loop (5e1 = 50.0)
    {
        // Calculate raymarch sample point
        // Normalize screen coordinates and scale by raymarch depth 'z'
        p = z * normalize(vec3(I+I, 0.0) - p_res.xyy); // Use 0.0 for clarity, p_res for resolution

        // Move camera back 8 units
        p.z += 8.0; // Use 8.0 for clarity

        // Rotate about x axis - Animation speed applied here
        p.yz *= mat2(cos(t * animation_speed + vec4(0.0, 11.0, 33.0, 0.0)));

        // Step forward and compute gyroid distance
        // Use explicit floats for constants
        z += d = 0.2 * max(0.2 + abs(dot(cos(p), cos(p.yzx / 0.6))), length(p) - 4.0);

        // Color and glow - Using the fire palette
        o_accumulated += (cos(p.y * 0.5 + vec4(2.0, 1.0, 0.5, 0.0)) + 1.5) * fire_palette / max(d, 0.0001);
    }
    // --- End of Raymarch loop ---

    // Tanh tonemapping
    // Replaced tanh with tanh_approx and applied scaling
    // The original scaling is O / 1e3 which is O / 1000.0
    // Use explicit float for 1e3 (1000.0)
    O = tanh_approx(o_accumulated / 1000.0); // Use 1000.0 for clarity

    // --- Apply Post-processing (BCS) ---
    O = applyPostProcessing(O, post_brightness, post_contrast, post_saturation);
    // -----------------------------------

    // Final clamp to ensure valid output range
    O = clamp(O, 0.0, 1.0); // Use 0.0, 1.0 for clarity
}