// 天之大手机// 202506271812
// 画板论坛上的分形

#ifdef GL_ES
precision mediump float; // Added for broader compatibility
#endif

// --- Fractal Base Color Parameter ---
#define FRACTAL_BASE_COLOR vec3(0.859, 0.525, 0.373)

// --- Screen Scaling Parameter ---
#define SCREEN_SCALE 1.2

// --- Animation Parameters for Fractal Morphing ---

// NEW: Global control for animation speed.
// Adjust this value to make the entire animation faster or slower.
// Values less than 1.0 (e.g., 0.5, 0.25) will slow down the animation.
// Values greater than 1.0 (e.g., 2.0) will speed it up.
#define GLOBAL_ANIMATION_SPEED_FACTOR .150 // Set to 1.0 for current speed. Adjust as desired.

#define FRACTAL_ANIM_SPEED_X    0.15
#define FRACTAL_ANIM_AMPLITUDE_X 0.06
#define FRACTAL_ANIM_SPEED_Y    0.07
#define FRACTAL_ANIM_AMPLITUDE_Y 0.09


// --- NEW: Post-Processing Parameters ---
// These parameters are designed to replicate your Photoshop adjustments.
// You can tweak these #define values to fine-tune the final look.

// 1) Color Overlay (Photoshop "Normal" Blend Mode)
// Convert hex #db865f to RGB (0.0-1.0):
// R: db (219) / 255 = 0.8588
// G: 86 (134) / 255 = 0.5255
// B: 5f (95) / 255 = 0.3725
#define POST_OVERLAY_COLOR vec3(0.8588, 0.5255, 0.3725)
#define POST_OVERLAY_OPACITY 0.77 // Photoshop Opacity 77% (mapped 0.0-1.0)

// 2) Brightness/Contrast Adjustments
// Brightness: Photoshop range -150 to +150, mapped to GLSL -1.0 to +1.0.
// (-32 / 150 = -0.2133)
#define POST_BRIGHTNESS_ADJUST (-0.2133) 

// Contrast: Photoshop range -100 to +100, mapped to GLSL 0.0 to 1.0.
// (90 / 100 = 0.75) - This factor is used in a standard contrast formula.
#define POST_CONTRAST_ADJUST 0.75 


void mainImage(out vec4 O, vec2 U)
{
    // Explicit initialization for all variables
    vec2 R = iResolution.xy;
    vec2 z = (U + U - R) / R.y / SCREEN_SCALE; 
    
    float r = 0.0;
    float d = 0.5;
    float d2 = 5e7;
    float em = 5e8;
    float color_component = 0.0; 

    // Calculate the animated constant 'c' for the fractal iteration
    // MODIFIED: Apply GLOBAL_ANIMATION_SPEED_FACTOR to iTime
    vec2 fractal_constant_animated = vec2(
        -0.73 + sin(iTime * GLOBAL_ANIMATION_SPEED_FACTOR * FRACTAL_ANIM_SPEED_X) * FRACTAL_ANIM_AMPLITUDE_X,
        0.15 + cos(iTime * GLOBAL_ANIMATION_SPEED_FACTOR * FRACTAL_ANIM_SPEED_Y) * FRACTAL_ANIM_AMPLITUDE_Y
    );

    for(int i = 0; i < 999; i++){
        // Apply the animated constant to the fractal iteration
        z = mat2(z, -z.y, z.x) * z + fractal_constant_animated;
        
        r = pow(dot(z,z), 1.5); // r=length(z);

        // Optimized conditional logic for finding smallest 'd' and second smallest 'd2'
        if (r < d) {
            d2 = d;
            d = r;
        } else if (r < d2) {
            d2 = r;
        }
        
        if (r > em) break; // Break early if value escapes to avoid excessive calculations
    }

    // Calculate the color component based on the distance values (from your base code)
    color_component = 1.0 - d / max(d2, 1e-6); 
    color_component = pow(color_component, 0.25);
    color_component = 3.0 * abs(color_component - 0.7); 
    
    // Apply the FRACTAL_BASE_COLOR to the final output
    O.rgb = color_component * FRACTAL_BASE_COLOR;

    // --- NEW: Apply Post-Processing Effects to O.rgb ---

    // 1) Apply Color Overlay (Photoshop "Normal" Blend Mode: C_final = C_overlay * alpha + C_orig * (1.0 - alpha))
    O.rgb = mix(O.rgb, POST_OVERLAY_COLOR, POST_OVERLAY_OPACITY);

    // 2) Apply Brightness Adjustment
    O.rgb += POST_BRIGHTNESS_ADJUST;

    // 3) Apply Contrast Adjustment
    O.rgb = (O.rgb - 0.5) * (1.0 + POST_CONTRAST_ADJUST) + 0.5;

    // Clamp values to ensure they stay within the valid 0.0-1.0 RGB range after adjustments
    O.rgb = clamp(O.rgb, 0.0, 1.0);

    O.a = 1.0; // Ensure alpha is set to 1.0 (fully opaque)
}