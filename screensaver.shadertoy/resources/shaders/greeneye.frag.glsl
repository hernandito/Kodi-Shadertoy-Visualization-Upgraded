// Influenced by @XoRDev, ref: https://www.shadertoy.com/view/3fKSzc

// The Robust Tanh Conversion Method: tanh_approx function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- Global Animation Speed Control (Unified - same for both modes) ---
// Adjust this value to speed up or slow down all animations in the shader.
// 1.0 is normal speed. Increase for faster, decrease for slower.
#define ANIMATION_SPEED_MULTIPLIER 0.80

// --- Post-processing BCS Parameters - Defined for each mode ---
// SUNFLOWER OPTION
#define BRIGHTNESS_SUNFLOWER 0.10
#define CONTRAST_SUNFLOWER 1.50
#define SATURATION_SUNFLOWER 1.30

// GREEN EYE OPTION
#define BRIGHTNESS_GREEN_EYE 0.10
#define CONTRAST_GREEN_EYE 1.90
#define SATURATION_GREEN_EYE 0.110

// --- Screen Scale (Zoom) and Center Shift Controls - Defined for each mode ---
// SUNFLOWER OPTION
#define ZOOM_FACTOR_SUNFLOWER 1.90
#define CENTER_OFFSET_X_SUNFLOWER 0.0
#define CENTER_OFFSET_Y_SUNFLOWER -0.220

// GREEN EYE OPTION
#define ZOOM_FACTOR_GREEN_EYE 1.90
#define CENTER_OFFSET_X_GREEN_EYE 0.0
#define CENTER_OFFSET_Y_GREEN_EYE 0.0 // Adjusted from -0.0 to 0.0

// --- Color Palette Control ---
// Set to 0 for the "Sunflower" palette (default yellow/orange)
// Set to 1 for the "Green Eye" palette
#define COLOR_MODE 1

// Define the base phase offsets for different color modes
// These vec4s represent (RedPhase, GreenPhase, BluePhase, AlphaPhase)
#define COLOR_PHASES_SUNFLOWER vec4(0.0, 7.1, 7.7, 0.0)
// Using previous green phases, as no new ones were provided with "great results" for the color phases specifically.
#define COLOR_PHASES_GREEN_EYE vec4(3.0, 0.0, 3.0, 0.0)


void mainImage(out vec4 O, vec2 I)
{
    // Explicit Variable Initialization
    float z = 0.0;
    float d = 0.0;
    float i = 0.0;
    
    // --- Dynamic Parameter Selection based on COLOR_MODE ---
    float activeBrightness;
    float activeContrast;
    float activeSaturation;
    float activeZoomFactor;
    float activeCenterX;
    float activeCenterY;
    vec4 activeColorPhases;

    #if COLOR_MODE == 1 // Green Eye Option selected
        activeBrightness = BRIGHTNESS_GREEN_EYE;
        activeContrast = CONTRAST_GREEN_EYE;
        activeSaturation = SATURATION_GREEN_EYE;
        activeZoomFactor = ZOOM_FACTOR_GREEN_EYE;
        activeCenterX = CENTER_OFFSET_X_GREEN_EYE;
        activeCenterY = CENTER_OFFSET_Y_GREEN_EYE;
        activeColorPhases = COLOR_PHASES_GREEN_EYE;
    #else // COLOR_MODE == 0 (Sunflower Option selected)
        activeBrightness = BRIGHTNESS_SUNFLOWER;
        activeContrast = CONTRAST_SUNFLOWER;
        activeSaturation = SATURATION_SUNFLOWER;
        activeZoomFactor = ZOOM_FACTOR_SUNFLOWER;
        activeCenterX = CENTER_OFFSET_X_SUNFLOWER;
        activeCenterY = CENTER_OFFSET_Y_SUNFLOWER;
        activeColorPhases = COLOR_PHASES_SUNFLOWER;
    #endif

    // Convert iTime to iChannelTime[0] and apply animation speed (unified)
    float t = iTime * ANIMATION_SPEED_MULTIPLIER;
    
    // Explicit Variable Initialization for 'O'
    O = vec4(0.0); 

    // Apply zoom and center shift to the input fragment coordinates (I) using active parameters
    vec2 centered_I = I - 0.5 * iResolution.xy; // 1. Center coordinates
    centered_I /= activeZoomFactor;              // 2. Apply zoom
    // 3. Apply shift: Convert normalized offset to pixel offset using iResolution.y for consistent scaling
    centered_I += vec2(activeCenterX * iResolution.y, activeCenterY * iResolution.y); 
    vec2 transformed_I = centered_I + 0.5 * iResolution.xy; // 4. Decenter

    // The loop structure is re-written for clarity and robustness.
    // 'i' increments BEFORE its use in the loop body, similar to original `i++`.
    for(i = 0.0; i++ < 100.0; ) 
    {
        // Use transformed_I instead of the original I for ray direction calculation
        vec3 p = z * normalize(vec3(2.0 * transformed_I, 0.0) - iResolution.xyx);
        
        p = vec3(atan(p.y, p.x) * 12.0, p.z / 2.0, (length(p.xy) - 6.0));
        
        // Explicit Variable Initialization for inner loop 'd'
        float inner_d = 0.0; 
        for(inner_d = 0.0; inner_d++ < 3.0; ) // inner_d goes from 1.0 to 3.0
            // Enhance General Division Robustness for inner_d
            p += sin(p.yzx * inner_d - t + 0.92 * i) / max(inner_d, 1E-6);
            
        z += d = 0.2 * length(vec4(p.z, 0.1 * cos(p * 3.0) - 0.1));

        // Accumulation step, formerly in the 'for' loop's increment part.
        // Apply the selected active color phases here
        O += (1.0 + cos(0.013 * i + activeColorPhases)) / max(d, 1E-6) / max(i, 1E-6);
    }

    // Replace tanh() with tanh_approx()
    O = tanh_approx(O * O / 800.0); // 8e2 is 800.0

    // --- Apply Post-processing BCS adjustments using active parameters ---
    // Apply Brightness
    O.rgb += activeBrightness;

    // Apply Contrast (around 0.5 gray point)
    O.rgb = (O.rgb - 0.5) * activeContrast + 0.5;

    // Apply Saturation
    float luma = dot(O.rgb, vec3(0.2126, 0.7152, 0.0722)); // Standard luminance calculation
    O.rgb = mix(vec3(luma), O.rgb, activeSaturation);

    // Ensure final color values are within a valid range
    O = clamp(O, 0.0, 1.0);
}