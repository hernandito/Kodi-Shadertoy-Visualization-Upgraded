// Color tip from @Shane, ty!

// Robust Tanh Conversion Method:
// Include the tanh_approx function:
const float EPSILON = 1e-6; // A small epsilon to prevent division by zero or very small numbers
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// apollonian
float fractal(vec3 p) {
    // weight
    float w = 4.0; // Explicitly initialize

    // 6 - 8 iterations is usually the sweet spot
    for (float l = 0.0, i = 0.0; i++ < 6.0; p *= l, w *= l ) // Explicitly initialize l and i
        // sin(p), abs(sin(p))-1., also work,
        // but need to adjust weight(w) and scale(l=2.)
        p  = cos(p - 0.5), // Changed .5 to 0.5
        // low scale for this fractal type, so we just get snowflake-like shape
        // adjust 2. for scaling
        // Enhance General Division Robustness: dot(p,p) can be zero.
        l = 2.0 / max(dot(p,p), EPSILON); // Changed 2. to 2.0
    
    // Enhance General Division Robustness: w can be zero or very small.
    return length(p) / max(w, EPSILON);
}

// --- BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
// Adjust these values to modify the final image appearance.
// BRIGHTNESS: Adds or subtracts from the color (e.g., 0.1 for brighter, -0.1 for darker)
#define BRIGHTNESS 0.015
// CONTRAST: Scales the color around a midpoint of 0.5 (e.g., 1.2 for more contrast, 0.8 for less)
#define CONTRAST 1.30
// SATURATION: Interpolates between grayscale and original color (e.g., 1.5 for more vivid, 0.5 for desaturated)
#define SATURATION 1.0
// -----------------------------------------------------------------------

// --- Global Animation Speed Parameter ---
// GLOBAL_ANIMATION_SPEED: Multiplier for the overall animation speed.
// Default: 1.0 (original speed)
#define GLOBAL_ANIMATION_SPEED 0.250
// ----------------------------------------

// --- FOV Adjustment Parameter ---
// FOV_ADJUSTMENT: Adjusts the Field of View (FOV).
// A higher value will "zoom in" (narrower FOV).
// A lower value will "zoom out" (wider FOV).
// Default: 1.0 (maintains the original FOV based on iResolution.y)
#define FOV_ADJUSTMENT .90
// --------------------------------

void mainImage(out vec4 o, vec2 u) {
    // Explicitly initialize all declared variables
    float i = 0.0; // iterator
    float d = 0.0; // total distance
    float s = 0.0; // signed distance
    float n = 0.0; // noise iterator
    float t = iTime * GLOBAL_ANIMATION_SPEED; // Apply global animation speed

    vec3 p; // Declared here as the raymarch position
    vec3 r_res = iResolution; // Renamed p to r_res to avoid conflict with raymarch position 'p'
    
    // scale coords
    // Enhance General Division Robustness: r_res.y can be zero.
    u = (u - r_res.xy / 2.0) / max(r_res.y * FOV_ADJUSTMENT, EPSILON); // Apply FOV adjustment here

    // clear o, up to 100, accumulate distance, grayscale color
    o = vec4(0.0); // Explicitly clear o
    for( ; i++ < 100.0; ) // Changed 1e2 to 100.0
    {
        // march, equivalent to p = ro + rd * d, p.z += d+t+t
        p = vec3(u * d, d + t + t); // 'p' is now the raymarch position, assigned here

        // spin by t, twist by p.z, equivalent to p.xy *= rot(.05*t+p.z*.2)
        p.xy *= mat2(cos(0.05 * t + p.z * 0.2 + vec4(0.0, 33.0, 11.0, 0.0))); // Changed literals to floats

        // dist to our spiral'ish thing that will be distorted by noise
        s = sin(4.0 + p.y + p.x); // Changed 4. to 4.0

        // start noise at 5., until 16, grow by n+=n
        n = 5.0; // Changed 5. to 5.0
        for (; n < 16.0; n += n) { // Changed 16. to 16.0
            // subtract noise from s
            // Enhance General Division Robustness: n can be very small (though here it starts at 5 and doubles).
            s -= abs(dot(cos(p * n), vec3(1.0))) / max(n, EPSILON); // Changed 1 to 1.0
        }

        // Accumulate distance, grayscale color
        d += s = 0.002 + abs(min(fractal(p), s)) * 0.5; // Changed .002 to 0.002, .5 to 0.5
        // Enhance General Division Robustness: s can be very small.
        o += 1.0 / max(s, EPSILON); // Changed 1. to 1.0
    }
    // divide down brightness and make a light in the center
    // Enhance General Division Robustness: length(u) can be zero at the center.
    o = o / 200000.0 / max(length(u), EPSILON); // Changed 2e5 to 200000.0

    // @Shane depth based color tip :)
    // Colorize
    o = pow(o.xxxx, vec4(1.0, 2.0, 12.0, 0.0)) * 6.0; // Changed literals to floats

    // Depth based color and tanh tone mapping
    // Replace tanh() with tanh_approx()
    o = tanh_approx(mix(o, o.yzxw, length(u)));

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
