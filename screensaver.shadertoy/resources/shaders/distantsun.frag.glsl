// GLSL ES 1.00 compatibility header
precision mediump float; // Required for GLSL ES 1.00

// Robust Tanh Conversion Method: tanh_approx function for vec4
// The 1.0 + abs(x) in the denominator inherently provides robustness against division by zero.
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + abs(x));
}

// Scalar version for float inputs (if needed, though not strictly required for this shader)
float tanh_approx_scalar(float x) {
    return x / (1.0 + abs(x));
}

// --------------------------------------
// Robust Tanh Conversion Parameters
// Adjust these to fine-tune the approximation's behavior and prevent artifacts.
// --------------------------------------
// Denominator for the final tonemaping tanh_approx (originally 4e3 or 4000.0).
// Adjust this value to control the overall brightness/contrast of the final image.
// A larger value will make the image darker and more compressed.
// A smaller value will make it brighter and less compressed.
#define FINAL_TANH_DENOMINATOR 4000.0 

// Epsilon value to prevent division by zero or near-zero for `length(u)`
// in the final tonemaping step. This prevents extreme values and artifacts
// especially near the center of the screen.
#define TONEMAP_LEN_U_EPSILON 0.000001 // A small positive number like 1e-6


// --------------------------------------
// Dither Effect Parameters
// --------------------------------------
// Pseudo-random number generator for dithering
float hash22(vec2 p) {
    p = fract(p * vec2(123.45, 678.90));
    p += dot(p, p + 45.67);
    return fract(p.x * p.y);
}

// Strength of the dither effect.
// Typical values for 8-bit displays are 1.0/255.0 to 4.0/255.0.
// Adjust this to reduce banding without introducing excessive noise.
#define DITHER_STRENGTH (2.0 / 255.0) // A good starting point, adjust as needed

// --------------------------------------
// Custom Color & Post-Processing Parameters
// --------------------------------------
// Defines the base color multiplier used in the final tonemapping.
// Original value was vec4(3.0, 1.0, 7.0, 1.0), which contributes to the purplish/blue hue.
// You can adjust these R, G, B, A components to shift the overall color.
#define OUTPUT_COLOR_MULTIPLIER vec4(7.0, 2.0, 0.0, 1.0) 

// Brightness, Contrast, Saturation (BCS) Adjustments
// Adjust these values to modify the final look of the shader.
#define BRIGHTNESS_ADJ 0.90 // Adjust overall brightness (e.g., 0.5 for dimmer, 1.5 for brighter)
#define CONTRAST_ADJ 1.20   // Adjust contrast (e.g., 0.5 for lower, 1.5 for higher)
#define SATURATION_ADJ 1.0 // Adjust color saturation (e.g., 0.0 for grayscale, 1.5 for oversaturated)


void mainImage(out vec4 o, vec2 u_fragcoord) { // Renamed 'u' to 'u_fragcoord' for clarity
    // Time for animation
    float t = iTime * 0.05; // Explicit float
    
    // iResolution as vec3 for consistent operations
    vec3 iRes_xyz = iResolution.xyz; 
    
    // Normalize coordinates, center them, and correct aspect ratio
    // Original: u = (u-p.xy/2.)/p.y;
    vec2 u_normalized = (u_fragcoord - iRes_xyz.xy / 2.0) / iRes_xyz.y; // Explicit floats
    
    // Raymarched distance accumulation (initialized to 0.0)
    float d_total = 0.0;
    
    // Output color accumulation (initialized to black)
    o = vec4(0.0);

    // Main raymarch loop (90 steps)
    // Original loop was very compact: for(o*=i; i++<90.; d += s = .025 + abs(min(l,s))*.175, o += 1. / s)
    // Expanded for GLSL ES 1.00 robustness and clarity.
    for(int i_ray = 0; i_ray < 90; ++i_ray) {
        // p_inner_coord represents the current 3D ray position
        vec3 p_inner_coord = vec3(u_normalized * d_total, d_total); 
        
        // Variables for inner turbulence calculation
        float s_inner_calc;  // Renamed to avoid confusion with s_outer_step_size
        vec3 q_inner_val;    // Renamed to avoid confusion with main q
        float l_inner_val;   // Renamed to avoid confusion with main l

        // Initialize these based on p_inner_coord and other factors for the inner loop context
        s_inner_calc = 0.3 + p_inner_coord.y; // Explicit float 0.3
        q_inner_val = cos(4.0 * t + p_inner_coord.zxy * p_inner_coord.yzz); // Explicit floats
        l_inner_val = dot(abs(q_inner_val - floor(q_inner_val) - 0.5), vec3(1.0)); // Explicit floats

        // Inner turbulence loop (n_turb doubles, up to 32.0)
        // Original: n = 2.; n < 32.; n += n
        for(float n_turb = 2.0; n_turb < 32.0; n_turb += n_turb) { // Explicit floats
            s_inner_calc += abs(dot(sin(3.0 * t + p_inner_coord * n_turb), vec3(0.5))) / n_turb; // Explicit floats
        }
        
        // Calculate the step size for this iteration (s from the original outer loop increment)
        // This 's' is based on the 'l' and 's' values derived from the turbulence calculation of this iteration.
        float s_outer_step_size = 0.025 + abs(min(l_inner_val, s_inner_calc)) * 0.175; // Explicit floats

        // Accumulate total distance and color based on the calculated step size
        d_total += s_outer_step_size;
        o += 1.0 / s_outer_step_size; // Accumulate color based on inverse of step size
    }
    
    // Final Tanh tonemapping
    // Replaced tanh() with tanh_approx().
    // Applied FINAL_TANH_DENOMINATOR for scaling.
    // Used max(length(u_normalized), TONEMAP_LEN_U_EPSILON) for robustness against division by zero.
    // Now uses OUTPUT_COLOR_MULTIPLIER for the color base.
    vec4 tanh_input_value = OUTPUT_COLOR_MULTIPLIER * o / d_total / FINAL_TANH_DENOMINATOR / max(length(u_normalized), TONEMAP_LEN_U_EPSILON);
    o = tanh_approx(tanh_input_value);

    // --------------------------------------
    // Apply Brightness, Contrast, Saturation (BCS) Adjustments
    // --------------------------------------
    vec3 final_rgb_bcs = o.rgb; // Get the color before BCS

    // Saturation Adjustment
    float luma = dot(final_rgb_bcs, vec3(0.2126, 0.7152, 0.0722));
    final_rgb_bcs = mix(vec3(luma), final_rgb_bcs, SATURATION_ADJ);

    // Contrast Adjustment
    final_rgb_bcs = ((final_rgb_bcs - 0.5) * CONTRAST_ADJ) + 0.5;

    // Brightness Adjustment
    final_rgb_bcs *= BRIGHTNESS_ADJ;

    // Update 'o' with BCS adjusted color
    o.rgb = final_rgb_bcs;
    
    // --------------------------------------
    // Apply Dither Effect
    // --------------------------------------
    // Generate pseudo-random noise based on pixel coordinates and time
    // Time component ensures the dither pattern slowly animates, preventing static noise artifacts.
    // Using u_fragcoord.xy (original un-normalized screen coordinates) for dither noise
    float dither_value = (hash22(u_fragcoord.xy + iTime * 0.01) - 0.5) * DITHER_STRENGTH;
    o.rgb += dither_value; // Add dither to the RGB channels
    
    // Final output color, clamped to 0-1 range to prevent over-exposure/under-exposure after dither
    o = vec4(clamp(o.rgb, 0.0, 1.0), 1.0); // 'o' is the output variable, so assign to it directly.
}