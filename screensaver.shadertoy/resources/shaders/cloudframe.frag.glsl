precision mediump float; // Set default precision for floats

// --- GLOBAL PARAMETERS ---
#define BRIGHTNESS 0.55    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 2.10       // Contrast adjustment (1.0 = neutral)
#define SATURATION .80    // Saturation adjustment (1.0 = neutral)
#define ANIMATION_SPEED 0.10 // Controls the overall animation speed (1.0 = normal speed)

// --- COLOR CYCLING PARAMETERS ---
// Controls the amplitude of the color variation. Higher values mean more intense color shifts.
// Example: 0.03 for moderate variation, 0.05 for more dramatic shifts.
#define COLOR_CYCLE_AMPLITUDE 0.04 
// Controls the base brightness of the accumulated color.
// To prevent colors from lightening too much (approaching white after inversion),
// this value should generally be greater than or equal to COLOR_CYCLE_AMPLITUDE.
// Higher values will result in darker, more saturated overall colors.
// Example: If COLOR_CYCLE_AMPLITUDE is 0.03, try 0.03 to 0.05 for COLOR_CYCLE_OFFSET.
#define COLOR_CYCLE_OFFSET 0.025 

// --- BACKGROUND PARAMETER ---
// Set to 1 to enable a solid black background.
// Set to 0 to use the original magenta/white sun background.
#define USE_BLACK_BACKGROUND 1 

#define T iTime*(1.5*ANIMATION_SPEED)+sin(iTime*ANIMATION_SPEED)

void mainImage(out vec4 o, vec2 u) {
    // Explicit Variable Initialization
    float s = 0.02; // Initialized as in original code
    float i = 0.0;  // Initialized as in original code
    float n = 0.0;  // Explicitly initialized
    float d = 0.0;  // Explicitly initialized, as it's accumulated

    vec3 r = iResolution.xyz; // Explicitly initialize
    
    // Apply screen scale for zooming (removed SCREEN_SCALE define as per instruction)
    u = (u - r.xy / 2.0) / max(r.y, 1e-6); // Robust division
    
    vec3 p = vec3(0.0, sin(T) * 0.125, T); // p is assigned immediately after declaration
    
    o = vec4(0.0); // Initialize o to vec4(0.0)

    for (; i++ < 80.0 && s > 0.01; ) { // Loop condition for s changed to s > 0.01 for robustness
        n = dot(sin(1.35 * p * 0.3) + sin(p), cos(T + p));
        s = 1.5 - length(p.xy) - n * 0.3;
        
        for (n = 0.075; n < 2.0; ) {
            s -= abs(dot(sin(p * n * 65.0), vec3(0.007))) / max(n, 1e-6); // Robust division
            n = ((n + n) + (n * 1.4142)) / 2.0; // This is a specific progression for n, no division issues here
        }
        
        // Adjusted accumulation factors using new parameters
        o.rgb += sin(p * 0.25) * COLOR_CYCLE_AMPLITUDE + COLOR_CYCLE_OFFSET; 
        p += vec3(u, 1.0) * 0.7 * s;
        d += s;
    }
    
    // Final color assignment based on 'd'
    vec3 final_rgb;
    if (d > 20.0) {
        #if USE_BLACK_BACKGROUND
            final_rgb = vec3(0.0); // Solid black background
        #else
            final_rgb = vec3(0.4, 0.1, 0.6) / max(length(u), 1e-6) * 0.75; // Original magenta/white sun background
        #endif
    } else {
        final_rgb = 1.0 - o.rgb;
    }
    
    // Apply gamma correction (pow) after a preliminary clamp to avoid issues with negative values,
    // but before the final output clamp to allow for more range.
    final_rgb = pow(max(final_rgb, 0.0), vec3(0.5)); // Changed pow exponent slightly to 0.5 and added max(final_rgb, 0.0)

    // --- BCS ADJUSTMENT ---
    float luminance = dot(final_rgb, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), final_rgb, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    final_rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

    o.rgb = final_rgb;
    o.a = 1.0; // Ensure alpha is 1.0
    
    // Final clamping to ensure values are within [0, 1] range for display
    o = clamp(o, 0.0, 1.0);
}
