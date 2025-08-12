precision mediump float; // Added for GLSL ES 1.00 compatibility

// Define a very small epsilon for robustness in numerical operations
const float ROBUST_EPSILON = 1e-6; 

// Robust tanh approximation for float values (more stable for large inputs)
float tanh_approx(float x) {
    return x / (1.0 + max(abs(x), ROBUST_EPSILON));
}

// Robust tanh approximation for vec4 values (applied component-wise, more stable)
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), ROBUST_EPSILON));
}

// --- Post-Processing BCS Parameters ---
// Adjust these values to control the final look of the output.
// Brightness: Additive adjustment. Range typically -1.0 to 1.0. 0.0 for no change.
#define POST_BRIGHTNESS -0.20 
// Contrast: Multiplicative adjustment. Range typically 0.0 to 2.0+. 1.0 for no change.
#define POST_CONTRAST   1.7 
// Saturation: Blends between grayscale (0.0) and original color (1.0). >1.0 for oversaturated.
#define POST_SATURATION 1.0 

// --- Drop Shadow Parameters ---
// Offset of the shadow from the object. Tweak these values for position.
// Positive X is right, Negative Y is down (as in common screen coordinates).
#define SHADOW_OFFSET vec2(-0.01, 0.01) // Adjust for desired offset
// Maximum darkness of the shadow (0.0 for no shadow, 1.0 for black).
#define SHADOW_MAX_DARKNESS 0.1 // Adjust for desired darkness
// How far the shadow blurs/fades. Larger values mean softer, wider shadow.
// This is critical for the soft gradient effect shown in your screenshot.
#define SHADOW_BLUR_RADIUS 0.26 // Adjust for desired softness (smaller values for sharper)

// --- Logo Overlay Parameters ---
// Scale of the logo relative to the screen's height. 1.0 means it fills screen height.
// e.g., 0.25 makes it 25% of screen height.
#define LOGO_SCALE 0.35 
// Overall opacity of the logo, layered on top (0.0 for invisible, 1.0 for full opacity).
#define LOGO_OPACITY 0.90 

/*
    "Squircle" by @XorDev
    
    A series of lightweight shaders made for easy learning and high-performance applications:
    https://www.shadertoy.com/playlist/ccffz7
    
    MIT license
    Credit is appreciated, but not required!
    
    Here's the overview:
    1) Center the coordinates and scale to fit vertically
    2) Compute the distance to the squircle edge
    3) Calculate lighting with a rotating vector
    4) Filter the edges and intensify the edge
    5) Color with normalized coordinates
    6) Tonemap with tanh
        Intro to tonemapping: https://mini.gmshaders.com/p/tonemaps
    
*/

// Helper function to calculate distance to the squircle edge for a given 'p' coordinate
float getSquircleDistance(vec2 p_coords) {
    return length(p_coords*p_coords) - .4;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Centered and scaled coordinates for the current pixel
    vec2 p_main = (fragCoord*2.-iResolution.xy)/iResolution.y;
    // Distance to the squircle edge for the current pixel (main object)
    float d_main = getSquircleDistance(p_main);
    
    // --- Calculate the base color for the entire animated scene (squircle + background) ---
    // This value represents what the pixel's color would be *without* any shadow.
    float l_base = dot(p_main*p_main*p_main, cos(iTime + vec2(0,11)));
    l_base *= (1.-tanh_approx(.5*d_main*iResolution.y)); 
    vec4 current_pixel_raw_color = tanh_approx(l_base+1.+vec4(p_main,-p_main))*.5+.5; 

    // --- Drop Shadow Calculation (Integrated into rendering) ---
    // 1. Calculate the 'p' coordinates for the shadow sample, offset from the current pixel.
    // Scale shadow offset by iResolution.y to make it resolution-independent
    vec2 p_shadow_sample = (fragCoord + SHADOW_OFFSET * iResolution.y) * 2. - iResolution.xy;
    p_shadow_sample /= iResolution.y;

    // 2. Get the squircle distance at this offset position.
    // If d_shadow_sample is negative, the offset point is *inside* the squircle.
    float d_shadow_sample = getSquircleDistance(p_shadow_sample);

    // 3. Calculate the shadow's strength at the current pixel.
    // This creates a mask that is 1.0 where the offset squircle is present (shadow source)
    // and smoothly fades to 0.0 over SHADOW_BLUR_RADIUS as d_shadow_sample increases (moving away from source).
    float shadow_mask_value = 1.0 - smoothstep(0.0, SHADOW_BLUR_RADIUS, d_shadow_sample);
    shadow_mask_value = clamp(shadow_mask_value, 0.0, 1.0); // Ensure value is between 0 and 1
    
    // Apply the maximum darkness to the mask
    float final_shadow_factor = shadow_mask_value * SHADOW_MAX_DARKNESS;

    // --- Determine Final Pixel Color based on squircle's presence ---
    if (d_main < 0.0) { // If the current pixel is *inside* the main squircle
        fragColor = current_pixel_raw_color; // Render the squircle's color directly (no shadow on itself)
    } else { // If the current pixel is in the background
        // Darken the animated background color based on the calculated shadow factor.
        // This makes the shadow appear on the background, smoothly blending.
        fragColor.rgb = current_pixel_raw_color.rgb * (1.0 - final_shadow_factor);
        fragColor.a = 1.0; // Ensure full opacity
    }

    // --- Apply Logo Overlay ---
    // Coordinates for logo, centered and scaled relative to screen height
    // p_main is already centered and scaled by iResolution.y. We use it as a base.
    vec2 logo_uv_normalized = p_main / LOGO_SCALE; // Scale the logo's effective UV space

    // Now, map the logo_uv_normalized from its potentially larger range (e.g., [-2*aspect, 2*aspect])
    // to the [0,1] range expected by texture() for proper sampling.
    vec2 logo_uv = logo_uv_normalized * 0.5 + 0.5; 

    // Check if the current fragment is within the logo's visible bounds (normalized [0,1])
    if (logo_uv.x >= 0.0 && logo_uv.x <= 1.0 && logo_uv.y >= 0.0 && logo_uv.y <= 1.0) {
        // Accessing iChannel0 without explicit uniform declaration for Shadertoy compatibility
        vec4 logo_color_raw = texture(iChannel0, logo_uv);
        // Apply overall logo opacity, respecting its own alpha channel
        logo_color_raw.a *= LOGO_OPACITY;

        // Blend the logo with the current scene color (squircle + shadow + background)
        // mix(background_color, foreground_color, foreground_alpha)
        fragColor.rgb = mix(fragColor.rgb, logo_color_raw.rgb, logo_color_raw.a);
    }

    // --- Apply Post-Processing BCS (Brightness, Contrast, Saturation) ---
    // Extract RGB from fragColor for post-processing
    vec3 final_output_color_rgb = fragColor.rgb;

    // Brightness adjustment
    final_output_color_rgb += POST_BRIGHTNESS;

    // Contrast adjustment
    final_output_color_rgb = (final_output_color_rgb - 0.5) * POST_CONTRAST + 0.5;

    // Saturation adjustment
    // Calculate luminance (grayscale equivalent) using standard ITU-R BT.709 weights
    vec3 grayscale = vec3(dot(final_output_color_rgb, vec3(0.2126, 0.7152, 0.0722)));
    final_output_color_rgb = mix(grayscale, final_output_color_rgb, POST_SATURATION);

    // Reassign the processed RGB back to fragColor, preserving alpha
    fragColor.rgb = final_output_color_rgb;
}