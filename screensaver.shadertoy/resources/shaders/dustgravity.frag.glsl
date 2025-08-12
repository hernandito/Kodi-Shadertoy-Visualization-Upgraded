

// Robust Tanh Conversion Method:
// Include the tanh_approx function:
const float EPSILON = 1e-6; // A small epsilon to prevent division by zero or very small numbers
vec4 tanh_approx(vec4 x) { 
    return x / (1.0 + max(abs(x), EPSILON)); 
}

// --- BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
// Adjust these values to modify the final image appearance.
// BRIGHTNESS: Adds or subtracts from the color (e.g., 0.1 for brighter, -0.1 for darker)
#define BRIGHTNESS 0.0
// CONTRAST: Scales the color around a midpoint of 0.5 (e.g., 1.2 for more contrast, 0.8 for less)
#define CONTRAST 1.05
// SATURATION: Interpolates between grayscale and original color (e.g., 1.5 for more vivid, 0.5 for desaturated)
#define SATURATION 1.0
// -----------------------------------------------------------------------

// --- FOV Adjustment Parameter ---
// FOV_Z_SCALE: Adjusts the Field of View (FOV).
// A higher value will "zoom in" (narrower FOV).
// A lower value will "zoom out" (wider FOV).
// Default: 1.0 (maintains the original FOV)
#define FOV_Z_SCALE .85
// --------------------------------


// --- Dither Effect Parameter ---
// DITHER_STRENGTH: Controls the intensity of the dither effect.
// Higher values introduce more noise, which can help break up banding,
// but too high can make the image look grainy.
// Default: 0.005 (a subtle amount)
#define DITHER_STRENGTH 0.005
// -------------------------------

void mainImage(out vec4 O, in vec2 I)
{
    vec2 r = iResolution.xy;

    // Explicitly initialize all declared variables to prevent undefined behavior.
    float t = iTime*.75; // Animation time
    float z = 0.0;   // Raymarch depth
    float d = 0.0;   // Step distance (reused for density/distance calculation)
    float s = 0.0;   // Signed distance (reused for turbulence calculation)
    float i = 0.0;   // Raymarch iterator
    
    vec3 p = vec3(0.0); // Sample point in 3D space
    vec3 a = vec3(0.0); // Rotation axis / Rotated coordinates / Turbulence accumulator
    
    vec4 o_accum = vec4(0.0); // Accumulator for the final output color.
                              // Renamed from 'O' to 'o_accum' to avoid conflict with 'out vec4 O'.
    
    // Raymarch loop (80 steps)
    // The loop condition `i++ < 8e1` means 'i' is incremented after each iteration,
    // and the loop continues as long as 'i' (before increment) is less than 80.
    for( ; i++ < 80.0; // Changed 8e1 to 80.0 for clarity
        // Coloring and brightness accumulation for the current step.
        // Enhanced general division robustness: `max(d, EPSILON)` prevents division by zero if 'd' becomes very small.
        o_accum += (cos(s + vec4(0.0, 1.0, 2.0, 0.0)) + 1.0) / max(d, EPSILON) * z) 
    {
        // Calculate the sample point 'p' along the ray.
        // The Z-component of the ray direction is now scaled by FOV_Z_SCALE.
        p = z * normalize(vec3(2.0 * I.x - iResolution.x, 2.0 * I.y - iResolution.y, -iResolution.y * FOV_Z_SCALE)); 
        
        // Calculate the rotation axis 'a'.
        // 'd' here is the float step distance from the previous iteration, used for animation.
        a = normalize(cos(vec3(1.0, 2.0, 0.0) + t - d * 8.0)); 
        
        // Move the camera back 5 units along the Z-axis.
        p.z += 5.0; 
        
        // Apply rotation to 'p' using 'a' as a temporary variable for the rotated point.
        a = a * dot(a, p) - cross(a, p);
        
        // Turbulence loop: adds fractal detail to 'a'.
        // The inner loop variable 'd' starts at 1.0 and increases, so division by zero is not an issue here.
        for(d = 1.0; d++ < 9.0; ) 
            a += sin(a * d + t).yzx / d;
        
        // Update 'z' (raymarch depth) and 'd' (step distance) for the next iteration.
        // 's' (signed distance/turbulence value) is also updated here.
        z += d = 0.1 * abs(length(p) - 3.0) + 0.04 * abs(s = a.y); 
    }
    
    // Apply Tanh tonemapping as a post-processing step to the accumulated color.
    // Replaced `tanh` with `tanh_approx` for Kodi compatibility.
    // The division `o_accum / 3e4` is robust as `3e4` is a large constant.
    O = tanh_approx(o_accum / 30000.0); // Changed 3e4 to 30000.0 for clarity

    // --- Apply BCS (Brightness, Contrast, Saturation) adjustments ---
    // Brightness
    O.rgb += BRIGHTNESS;

    // Contrast (pivot around 0.5)
    O.rgb = (O.rgb - 0.5) * CONTRAST + 0.5;

    // Saturation
    float luma = dot(O.rgb, vec3(0.299, 0.587, 0.114)); // Calculate luminance
    O.rgb = mix(vec3(luma), O.rgb, SATURATION); // Mix between grayscale and original color
    // -----------------------------------------------------------------

    // --- Apply Dither Effect ---
    // Simple pseudo-random dither based on pixel coordinates
    float dither = fract(sin(dot(I.xy, vec2(12.9898, 78.233))) * 43758.5453);
    O.rgb += (dither - 0.5) * DITHER_STRENGTH; // Add dither, centered around 0
    // ---------------------------

    // Ensure color values remain within valid range [0, 1] after all adjustments
    O = clamp(O, 0.0, 1.0);
}
