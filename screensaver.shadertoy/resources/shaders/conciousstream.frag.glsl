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
#define BRIGHTNESS 0.1
// CONTRAST: Scales the color around a midpoint of 0.5 (e.g., 1.2 for more contrast, 0.8 for less)
#define CONTRAST 1.7
// SATURATION: Interpolates between grayscale and original color (e.g., 1.5 for more vivid, 0.5 for desaturated)iTime
#define SATURATION 1.0
// -----------------------------------------------------------------------

/*
    Inspired by Xor's recent raymarchers with comments!
    https://www.shadertoy.com/view/tXlXDX
*/

void mainImage(out vec4 o, vec2 u) {
    // Explicitly initialize all declared variables
    float i = 0.0;
    float d = 0.0;
    float s = 0.0; // Initialized to 0.0, will be set to 0.1 in inner loop
    
    vec3 p; // Declared here, initialized inside loop
    vec3 r_res = iResolution; // Renamed to avoid conflict with 'r' in other shaders

    // Initialize output color 'o' before the loop
    o = vec4(0.0);

    // Main raymarching loop
    // Ensure `r_res.y` is not zero for robust division
    vec3 normalized_u_vec = normalize(vec3(u + u, 0.0) - r_res.xyx);
    
    for( ; i++ < 100.0; ) { // Changed 1e2 to 100.0 for clarity
        // Calculate point 'p' along the ray
        p = d * normalized_u_vec;

        // Inner loop for noise and twisting
        for (s = 0.1; s < 1.0; // Changed .1 to 0.1, 1. to 1.0
             // Noise application
             p -= dot(sin(p * s * 16.0), vec3(0.01)) / max(s, EPSILON), // Changed .01 to 0.01, added robust division
             // Twist and spin
             p.xz *= mat2(cos(0.3 * iTime*.2 + vec4(0.0, 33.0, 11.0, 0.0))), // Changed literals to floats
             s += s) // Double 's' for next iteration
        {
            // Empty loop body, all operations are in the for-loop header
        }
        
        // Accumulate distance and update 's'
        d += s = 0.01 + abs(p.y); // Changed .01 to 0.01
        
        // Accumulate brightness 'o'
        o += (1.0 + cos(d + vec4(4.0, 2.0, 1.0, 0.0))) / max(s, EPSILON); // Changed literals to floats, added robust division
    }
    
    // Apply tanh tonemapping (using robust approximation)
    o = tanh_approx(o / 6000.0); // Changed 6e3 to 6000.0 for clarity

    // --- Apply BCS (Brightness, Contrast, Saturation) adjustments ---
    // Brightness
    o.rgb += BRIGHTNESS;

    // Contrast (pivot around 0.5)
    o.rgb = (o.rgb - 0.5) * CONTRAST + 0.5; // Changed .5 to 0.5

    // Saturation
    float luma = dot(o.rgb, vec3(0.299, 0.587, 0.114)); // Calculate luminance
    o.rgb = mix(vec3(luma), o.rgb, SATURATION); // Mix between grayscale and original color

    // Ensure color values remain within valid range [0, 1] after adjustments
    o = clamp(o, 0.0, 1.0); // Changed 0. to 0.0, 1. to 1.0
    // -----------------------------------------------------------------
}
