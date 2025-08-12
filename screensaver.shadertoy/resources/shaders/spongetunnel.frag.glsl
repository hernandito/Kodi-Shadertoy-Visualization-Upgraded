// GLSL ES 1.00 compatibility header
precision mediump float; // Required for GLSL ES 1.00

// --------------------------------------
// Post-Processing: Brightness, Contrast, Saturation (BCS)
// Adjust these values to modify the final look of the shader.
// --------------------------------------
#define BRIGHTNESS_ADJ 0.60 // Adjust overall brightness (e.5 for dimmer, 1.5 for brighter)
#define CONTRAST_ADJ 1.60   // Adjust contrast (e.5 for lower, 1.5 for higher)
#define SATURATION_ADJ 1.0 // Adjust color saturation (e.g., 0.0 for grayscale, 1.5 for oversaturated)

float de(vec3 p) {
    p = fract(p); // equivalent to mod(p, 1.0) for positive p, but more common in fractals
    float s = 1.;
    float d = 0.;
    // Loop initialization fixed for GLSL ES 1.00
    for(int i = 0; i < 16; ++i) { // Ensures i is initialized and loop iterates correctly
        vec3 h = abs(p * 4. - 3.);
        vec3 m = (1. - max(h.yzx,h.zxy)) / 4. * s;
        d = max(d,max(max(m.x,m.y),m.z));
        s /= 3.;
        p = fract(p * 3.);
    }
    return d;
}

void mainImage(out vec4 c,vec2 p) {
    vec2 r = iResolution.xy;
    vec3 raypos = vec3(1.0, 1.0, iTime * 0.1) * 0.75; // Explicit floats
    vec3 raydir = normalize(vec3((p / r - 0.5) * sqrt(r / r.yx), 0.5)); // Explicit floats
    c = vec4(1.0); // Explicit float
    float tdist = 0.;

    // Maximum raymarching steps significantly reduced for stability on embedded systems.
    // Adjust this value higher if performance allows, but be cautious.
    const int MAX_RAYMARCH_STEPS = 128; // Start here, can be increased to 256, 512, etc. if stable

    // Loop initialization fixed for GLSL ES 1.00
    for(int n = 0; n < MAX_RAYMARCH_STEPS; ++n) { // Ensures n is initialized and loop iterates correctly
        float distest = de(raypos);
        tdist += distest;
        c /= 1.03; // Explicit float
        
        // More robust early exit condition: break if distance to surface is very small
        // The original `tdist / iResolution.x * .4` could become extremely small.
        if(distest < 0.001) { // Adjusted for more stable behavior
            break;
        }
        raypos += raydir * distest;
    }

    // --------------------------------------
    // Post-Processing: Brightness, Contrast, Saturation (BCS) Adjustments
    // --------------------------------------
    vec3 final_rgb = c.rgb; // Get the color from the raymarcher

    // Saturation Adjustment
    // Calculate luminance to desaturate towards gray
    float luma = dot(final_rgb, vec3(0.2126, 0.7152, 0.0722));
    final_rgb = mix(vec3(luma), final_rgb, SATURATION_ADJ);

    // Contrast Adjustment
    // Adjusts mid-point (0.5)
    final_rgb = ((final_rgb - 0.5) * CONTRAST_ADJ) + 0.5;

    // Brightness Adjustment
    final_rgb *= BRIGHTNESS_ADJ;

    // Final output color, clamped to 0-1 range to prevent over-exposure artifacts
    c = vec4(clamp(final_rgb, 0.0, 1.0), 1.0); // CHANGED from fragColor to c
}