#ifdef GL_ES
precision mediump float;
#endif

// === Robust Tanh Approximation ===
// Include the tanh_approx function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// === Post-processing parameters for Brightness, Contrast, Saturation (BCS) ===
// Adjust these values to fine-tune the final look.
#define BRIGHTNESS_ADJUST 0.0   // Controls overall lightness/darkness. Range typically -1.0 (darkest) to 1.0 (brightest). 0.0 is no change.
#define CONTRAST_ADJUST 1.50     // Controls the difference between light and dark areas. Range typically 0.0 (flat/gray) to 2.0 (high contrast). 1.0 is no change.
#define SATURATION_ADJUST 1.10   // Controls color intensity. Range typically 0.0 (grayscale) to 2.0 (super saturated). 1.0 is no change.

void mainImage(out vec4 O, vec2 I)
{
    // Raymarch depth
    float z = 0.0; // Ensure Explicit Variable Initialization
    // Step distance
    float d = 0.0; // Ensure Explicit Variable Initialization
    // Raymarch iterator
    float i = 0.0; // Ensure Explicit Variable Initialization
    // Time for animation
    float t = iTime*.15;
    
    O = vec4(0.0); // Ensure Explicit Variable Initialization
    
    // Clear fragColor and raymarch 100 steps (2e1 is 20 steps)
    for(O *= i; i++ < 20.0; ) // Original loop structure. O*=i sets O to 0 for i=0, then loop starts with i=1.
    {
        // Sample point (from ray direction)
        vec3 p = z * normalize(vec3(I+I,0) - iResolution.xyx) + 0.1;
        
        // Polar coordinates and additional transformations
        p = vec3(atan(p.z += 9.0, p.x + 0.1) * 2.0, 0.6 * p.y + t + t, length(p.xz) - 3.0);
        
        // Apply turbulence and refraction effect
        // Corrected loop to prevent division by zero (d starts at 0, d++ means it's 1 on first iteration)
        // Original: for(d=0.; d++<7.;) p += sin(p.yzx*d+t+.5*i)/d;
        float d_turb_divisor = 1.0; // Use a new variable for the divisor in this loop to clarify intent and avoid conflict with 'd' used for step distance later.
        for(d_turb_divisor = 1.0; d_turb_divisor <= 7.0; d_turb_divisor += 1.0) // Loop from 1.0 to 7.0
        {
            // Enhance General Division Robustness
            p += sin(p.yzx * d_turb_divisor + t + 0.5 * i) / max(d_turb_divisor, 1E-6); 
        }
            
        // Distance to cylinder and waves with refraction
        z += d = 0.4 * length(vec4(0.3 * cos(p) - 0.3, p.z));
        
        // Coloring and brightness
        // Enhance General Division Robustness
        O += (1.0 + cos(p.y + i * 0.4 + vec4(6.0, 1.0, 2.0, 0.0))) / max(d, 1E-6); 
    }
    // Tanh tonemap
    // Replace tanh() calls
    O = tanh_approx(O * O / 6000.0); 

    // === Apply BCS Post-processing Adjustments ===
    // Clamp values to [0,1] range before applying adjustments to prevent issues.
    O.rgb = clamp(O.rgb, 0.0, 1.0); 

    // 1. Apply Contrast: Pivots the colors around 0.5 (mid-gray).
    O.rgb = (O.rgb - 0.5) * CONTRAST_ADJUST + 0.5;

    // 2. Apply Brightness: Simply adds to the RGB channels.
    O.rgb += BRIGHTNESS_ADJUST;

    // 3. Apply Saturation: Mixes the current color with its grayscale equivalent.
    // Using standard sRGB luminance weights for grayscale conversion.
    vec3 luma = vec3(dot(O.rgb, vec3(0.2126, 0.7152, 0.0722))); 
    O.rgb = mix(luma, O.rgb, SATURATION_ADJUST);

    // Final clamp to ensure output color values remain within the valid [0,1] range.
    O.rgb = clamp(O.rgb, 0.0, 1.0);
}