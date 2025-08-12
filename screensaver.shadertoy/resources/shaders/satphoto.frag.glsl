// --- GLSL Version and Precision Directives for Kodi Compatibility (GLSL ES 1.0) ---
precision highp float;
precision highp int;
precision lowp sampler2D;

#define PI 3.14159265359

// --- Custom Color Parameters ---
#define DARK_HALFTNE_COLOR  vec3(0.0, 0.2, 0.0) // Defines the "dark" color of the halftone effect
#define LIGHT_HALFTONE_COLOR vec3(0.58, 0.78, 0.58) // Defines the "light" color of the halftone effect


// Helper function to equalize value for halftone thresholding.
float equaliseValue(float value)
{
    float sign_val = step(0.5, value) * 2.0 - 1.0; // Use float literal
    
    return (
        sign_val * pow(
            sign_val * (2.0 * value - 1.0), // Use float literal
            1.462
        )
    ) * 0.5 + 0.5; // Use float literal
}

// Macros for linear/sRGB color space conversion.
#define TO_LINEAR(value) pow(value, 2.2)
#define FROM_LINEAR(value) pow(value, 1.0/2.2) // Use float literal
#define TO_LINEAR3(value) pow(value, vec3(2.2))
#define FROM_LINEAR3(value) pow(value, vec3(1.0/2.2)) // Use float literal
#define TO_LINEAR3_MONO(value) dot(TO_LINEAR3(value.xyz), vec3(0.2126, 0.7152, 0.0722)) // Use float literal

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Vary the halftone scale over time.
    // 'scale' ranges from 50.0 (larger dots) to 200.0 (smaller dots).
    float scale = pow(2.0, cos(iTime * 0.45)) * 100.0; // Use float literals
    
    // Map UV origin to center of viewport, correct aspect ratio, and apply scale.
    vec2 pos = (fragCoord - iResolution.xy / 2.0) / iResolution.x * scale;
    
    // Calculate the halftone dot pattern (a grid of circles/ovals).
    // The `product` will be a value from 0.0 to 1.0, representing the intensity of the pattern.
    float product = (cos(pos.x * 2.0 * PI) * cos(pos.y * 2.0 * PI) + 1.0) / 2.0; // Use float literals
    
    // Get original background image color and convert to linear grayscale.
    vec4 colour = texture(iChannel0, fragCoord / iResolution.xy);
    float value_linear = TO_LINEAR3_MONO(colour); // Linear grayscale value of the original image pixel.
    
    // Calculate anti-aliasing range for smooth halftone transitions.
    float aaRange = 1.0 / iResolution.x * scale; // Use float literal
    
    // Calculate thresholds for smoothstep based on linear grayscale value and AA range.
    float threshold1 = equaliseValue(value_linear - aaRange);
    float threshold2 = equaliseValue(value_linear + aaRange);
    
    // Calculate the halftone effect: maps the dot pattern to a grayscale value.
    // `1.0 - smoothstep(...)` creates dots where dark areas are represented by larger "holes".
    float halftone = FROM_LINEAR(1.0 - smoothstep(threshold1, threshold2, product)); // Use float literal

    // --- NEW LOGIC: Blend halftone with original image based on scale ---
    // When 'scale' is large (dots are visually small), we want to blend more towards the original image.
    // When 'scale' is small (dots are visually large), we want to show the full halftone effect.
    // `smoothstep` creates a smooth transition for the blend factor.
    // It will be 0.0 when scale is <= 50.0 (full halftone) and 1.0 when scale is >= 200.0 (original image).
    float blend_factor = smoothstep(50.0, 200.0, scale); // Defined based on the 50-200 range of 'scale'.
    
    // Mix the halftone effect with the original linear grayscale value.
    vec3 mixed_halftone_with_original = mix(vec3(halftone), vec3(value_linear), blend_factor);

    // --- COLOR CUSTOMIZATION: Change black and white to custom colors ---
    // Define your desired 'dark' color and 'light' color for the halftone effect.
    // vec3 dark_green = vec3(0.0, 0.2, 0.0); // Now controlled by DARK_HALFTNE_COLOR define
    // vec3 light_green = vec3(0.0, 0.8, 0.0); // Now controlled by LIGHT_HALFTONE_COLOR define

    // Mix between the dark and light colors using the mixed halftone/original value.
    // The 'mixed_halftone_with_original' value acts as a new grayscale factor for your custom colors.
    vec3 final_color_rgb = mix(DARK_HALFTNE_COLOR, LIGHT_HALFTONE_COLOR, mixed_halftone_with_original);
    
    // Set the final fragment color, with full alpha.
    fragColor = vec4(final_color_rgb, 1.0); // Use float literal
}
