#ifdef GL_ES
precision mediump float;
#endif

// Robust Tanh Approximation
const float EPSILON = 1e-6; // A small epsilon to prevent division by zero or very small numbers
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
// Adjust these values to modify the final image appearance.
// BRIGHTNESS: Adds or subtracts from the color (e.g., 0.1 for brighter, -0.1 for darker)
#define BRIGHTNESS 0.10
// CONTRAST: Scales the color around a midpoint of 0.5 (e.g., 1.2 for more contrast, 0.8 for less)
#define CONTRAST 1.60
// SATURATION: Interpolates between grayscale and original color (e.g., 1.5 for more vivid, 0.5 for desaturated)
#define SATURATION 1.0
// -----------------------------------------------------------------------

// --- FOV Adjustment Parameter ---
// FOV_ADJUSTMENT: Adjusts the Field of View (FOV).
// A higher value will "zoom in" (narrower FOV).
// A lower value will "zoom out" (wider FOV).
// Default: 1.0 (original FOV)
#define FOV_ADJUSTMENT 1.10
// --------------------------------

/*
    Sound from an @msm01 comment in this shader:
        https://www.shadertoy.com/view/wfdGWM

    Playing with turbulence and translucency from
    @Xor's recent shaders, e.g.
        https://www.shadertoy.com/view/wXjSRt
        https://www.shadertoy.com/view/wXSXzV
*/

void mainImage(out vec4 o, vec2 u) {
    // Explicitly initialize all declared variables
    float i = 0.0;
    float d = 0.0;
    float s = 0.0; // Will be set to 0.05 in inner loop
    float t = iTime*.5;
    vec3 p = iResolution; // Renamed to avoid conflict with 'p' in inner loop

    // Normalize UV coordinates
    u = (u - p.xy / 2.0) / max(p.y, EPSILON); // Added robust division

    // Initialize output color 'o' before the loop
    o = vec4(0.0);

    // Main raymarching loop
    for( ; i++ < 100.0; // Changed 1e2 to 100.0 for clarity
        // Accumulate distance and update 's'
        d += s = 0.03 + abs(2.0 - abs(p.y)) * 0.2, // Changed .03 to 0.03, .2 to 0.2
        // Accumulate brightness 'o'
        o += 1.0 / max(s, EPSILON)) // Added robust division
    {
        // Inner loop: turbulence and twisting
        // 'p' is re-purposed here as the current point in 3D space
        for (p = vec3(u * d, d + t), s = 0.05; s < 1.0; // Changed .05 to 0.05, 1. to 1.0
             p += cos(p.z + p.yzx * 0.02) * 0.1, // Changed .02 to 0.02, .1 to 0.1
             p += abs(dot(sin(t + p.z + p * s * 16.0), vec3(0.01))) / max(s, EPSILON), // Changed .01 to 0.01, added robust division
             s += s) // Double 's' for next iteration
        {
            // Empty loop body, all operations are in the for-loop header
        }
    }
    
    // Apply color mixing based on UV y-coordinate
    o *= mix(pow(vec4(4.0, 2.3, 1.0, 0.0), vec4(1.5)), // Changed literals to floats
             vec4(1.0, 2.3, 6.0, 0.0), // Changed literals to floats
             smoothstep(0.2, -0.5, u.y)); // Changed .2 to 0.2, -.5 to -0.5 iTime
    
    // Adjust UV for final tonemapping
    u -= vec2(0.6, 0.25); // Changed .6 to 0.6, .25 to 0.25
    
    // Apply tanh tonemapping (using robust approximation)
    // Added robust division for length(u)
    o = tanh_approx(o / (6000.0 / max(length(u) * FOV_ADJUSTMENT, EPSILON))); // Apply FOV_ADJUSTMENT here // Changed 6e3 to 6000.0

    // --- Apply BCS (Brightness, Contrast, Saturation) adjustments ---
    // Brightness
    o.rgb += BRIGHTNESS;

    // Contrast (pivot around 0.5)
    o.rgb = (o.rgb - 0.5) * CONTRAST + 0.5;

    // Saturation
    float luma = dot(o.rgb, vec3(0.299, 0.587, 0.114)); // Calculate luminance
    o.rgb = mix(vec3(luma), o.rgb, SATURATION); // Mix between grayscale and original color

    // Ensure color values remain within valid range [0, 1] after adjustments
    o = clamp(o, 0.0, 1.0);
    // -----------------------------------------------------------------
}
