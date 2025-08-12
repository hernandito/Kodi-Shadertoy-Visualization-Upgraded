precision mediump float; // Set default precision for floats

// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- GLOBAL PARAMETERS ---
#define BRIGHTNESS 1.0    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.20      // Contrast adjustment (1.0 = neutral)
#define SATURATION 2.00    // Saturation adjustment (1.0 = neutral)
#define ANIMATION_SPEED 0.2 // Controls the overall animation speed (1.0 = normal speed)

// --- COLOR PALETTE PARAMETERS ---
// Selects the active color palette:
// 0: Original shader's coloring
// 1: First custom palette (#264653, #2a9d8f, etc.)
// 2: Second custom palette (#153b2c, #1c5c42, etc.)
#define COLOR_PALETTE_MODE 1 
#define NUM_PALETTE_COLORS 6 // Number of colors in the new palettes

// Controls the overall brightness of the colors sampled from the palette before accumulation.
// A value of 2.0 would roughly match the maximum intensity of the original `(1.0 + cos(...))` component.
// Increase for brighter colors, decrease for darker.
#define PALETTE_BRIGHTNESS_SCALE 1.0 
// Controls how rapidly the colors cycle through space (i.e., how many color bands are visible).
// Higher values create more frequent color changes.
// Example: 0.1 for a slower cycle, 0.5 for a faster, more banded cycle.
#define PALETTE_DENSITY_SCALE 0.05 

// --- TRANSPARENCY PARAMETER ---
// Controls the transparency of the rendered geometry/objects.
// Higher values make objects more transparent/fainter.
// Lower values make objects more opaque/solid.
// Example: 1000.0 for more opaque, 5000.0 for more transparent. Current effective value is 2000.0.
#define TRANSPARENCY_SCALE 3000.0 

#define T iTime*(1.5*ANIMATION_SPEED)+sin(iTime*ANIMATION_SPEED) // T now directly uses ANIMATION_SPEED

void mainImage(out vec4 fragColor, vec2 u) // Renamed 'o' to 'fragColor' for clarity
{
    // Explicit Variable Initialization
    float i = 0.0; // Loop counter
    float r_val = 0.0; // Intermediate calculation variable (renamed from 'r' to avoid conflict with 'r' in 'p_res')
    float s = 0.0; // Step size / distance
    float d = 0.0; // Accumulated distance
    float n = 0.0; // Inner loop counter / multiplier

    vec3 p_res = iResolution.xyz; // Store iResolution in a separate variable
    vec3 p_local = vec3(0.0); // Local position vector, explicitly initialized

    vec4 o_accum = vec4(0.0); // Explicitly initialize accumulated output color

    // Define the first new color palette
    vec3 newPaletteColors1[NUM_PALETTE_COLORS];
    newPaletteColors1[0] = vec3(0.14902, 0.27451, 0.32549); // #264653
    newPaletteColors1[1] = vec3(0.16471, 0.61569, 0.56078); // #2a9d8f
    newPaletteColors1[2] = vec3(0.93333, 0.53725, 0.34902); // #ee8959
    newPaletteColors1[3] = vec3(0.91373, 0.76863, 0.41569); // #e9c46a
    newPaletteColors1[4] = vec3(0.95686, 0.63529, 0.38039); // #f4a261
    newPaletteColors1[5] = vec3(0.90588, 0.43529, 0.31765); // #e76f51

    // Define the second new color palette
    vec3 newPaletteColors2[NUM_PALETTE_COLORS];
    newPaletteColors2[0] = vec3(0.08235, 0.23137, 0.17255); // #153b2c
    newPaletteColors2[1] = vec3(0.10980, 0.36078, 0.25882); // #1c5c42
    newPaletteColors2[2] = vec3(0.59608, 0.63922, 0.59216); // #97a397
    newPaletteColors2[3] = vec3(0.83137, 0.84314, 0.76863); // #d4d7c4
    newPaletteColors2[4] = vec3(0.89020, 0.74118, 0.41569); // #e3bd6a
    newPaletteColors2[5] = vec3(0.86275, 0.77647, 0.58431); // #dcc695

    // Normalize UV coordinates based on resolution, with robust division
    u = (u - p_res.xy / 2.0) / max(p_res.y, 1e-6);

    // Outer loop for raymarching/accumulation
    for (; i++ < 90.0; // Loop 90 times
         d += s = 0.005 + abs(r_val) * 0.2, // Accumulate distance `d`, update step size `s`
         // Accumulate color `o_accum` with robust division by `s`
         o_accum += 
         #if COLOR_PALETTE_MODE == 1
             // First custom palette
             vec4(mix(
                 newPaletteColors1[int(mod(floor(p_local.z * PALETTE_DENSITY_SCALE), float(NUM_PALETTE_COLORS)))],
                 newPaletteColors1[int(mod(ceil(p_local.z * PALETTE_DENSITY_SCALE), float(NUM_PALETTE_COLORS)))],
                 fract(p_local.z * PALETTE_DENSITY_SCALE)
             ) * PALETTE_BRIGHTNESS_SCALE, 0.0)
         #elif COLOR_PALETTE_MODE == 2
             // Second custom palette
             vec4(mix(
                 newPaletteColors2[int(mod(floor(p_local.z * PALETTE_DENSITY_SCALE), float(NUM_PALETTE_COLORS)))],
                 newPaletteColors2[int(mod(ceil(p_local.z * PALETTE_DENSITY_SCALE), float(NUM_PALETTE_COLORS)))],
                 fract(p_local.z * PALETTE_DENSITY_SCALE)
             ) * PALETTE_BRIGHTNESS_SCALE, 0.0)
         #else
             // Original color generation
             (1.0 + cos(0.1 * p_local.z + vec4(3.0, 1.0, 0.0, 0.0)))
         #endif
         / max(s, 1e-6)
        )
    {
        // Update local position vector `p_local` based on accumulated distance `d` and time `T`
        p_local = vec3(u * d, d + T * 16.0); // Use T here

        // Calculate `r_val` based on `p_local` and time `T`
        r_val = 50.0 - abs(p_local.y) + cos(T - dot(u, u) * 6.0) * 3.3; // Use T here

        // Inner loop for fractal-like noise
        for (n = 0.08; // Initialize inner loop counter `n`
             n < 0.8; // Loop condition
             n *= 1.4) // Increment `n`
        {
            // Subtract from `r_val` based on sine and dot products, with robust division by `n`
            r_val -= abs(dot(sin(0.3 * T + 0.8 * p_local * n), vec3(0.7))) / max(n, 1e-6); // Use T here
        }
    }

    // Apply tanh_approx for tone mapping, with robust division
    // Now using TRANSPARENCY_SCALE
    vec4 final_color_raw = tanh_approx(o_accum / TRANSPARENCY_SCALE);

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = final_color_raw.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    finalColor = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

    fragColor = vec4(finalColor, 1.0);
}
