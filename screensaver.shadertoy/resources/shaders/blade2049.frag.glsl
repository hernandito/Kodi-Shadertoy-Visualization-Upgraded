/*
    "Runner" by @XorDev
    
    Loosely inspired by Blade Runner 2049
    
    Dust:
    https://www.shadertoy.com/view/cdG3Wd
    Radioactive:
    https://www.shadertoy.com/view/mdG3Wy
    Sector:
    https://www.shadertoy.com/view/mdXfDS
    
    Tweet version:
    https://x.com/XorDev/status/1933624066776445381
    <512 Char playlist:
    https://www.shadertoy.com/playlist/N3SyzR
*/

// Robust Tanh Conversion Method:
// Added robust tanh approximation function
const float EPSILON = 1e-6; // Moved EPSILON to global scope for broader visibility

// --- Custom Parameters (using #define for compatibility) ---
#define GLOBAL_SPEED 0.30 // Global speed multiplier for animation
#define BRIGHTNESS   1.0 // Adjust overall brightness (1.0 is neutral, >1 increases, <1 decreases)
#define CONTRAST     1.0 // Adjust contrast (1.0 is neutral, >1 increases, <1 decreases)
#define SATURATION   1.0 // Adjust color saturation (1.0 is neutral, >1 increases, <1 decreases)

vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

void mainImage(out vec4 O, vec2 I)
{
    // Explicitly initialize variables as per Robust Tanh Conversion Directive
    vec3 p = vec3(0.0);
    vec3 v = vec3(0.0);
    float z = 0.0;
    float d = 0.0;
    float i = 0.0;
    float j = 0.0;

    // Clear fragColor and raymarch 30 steps
    // O*=i; is replaced by explicit initialization and then accumulation
    O = vec4(0.0); // Explicitly clear output color

    // Get screen resolution (needed for normalize and p calculation)
    vec2 R = iResolution.xy;

    for(i = 0.0; i < 30.0; ++i) // Raymarch 30 steps
    {
        // Step forward
        z += d;

        // Coloring and fog (try +2. for more ground fog)
        // Original: O+=.1*(vec4(4,2,1,0) - tanh(p.y+3.))*d/(1.+z)
        // Replaced tanh() with tanh_approx() and added robustness to division.
        O += 0.1 * (vec4(4.0, 2.0, 1.0, 0.0) - tanh_approx(vec4(p.y + 3.0))) * d / (1.0 + z + EPSILON);

        // Raymarch sample point with camera offset
        // Original: p = z*normalize(vec3(I+I,0)-iResolution.xyy) - 2.;
        p = z * normalize(vec3(I + I, 0.0) - iResolution.xyy) - 2.0; // Explicit floats for consistency

        // Scroll forward and right
        // Original: p.xz-=iTime+3.;
        // Converted iTime to iChannelTime[0] and applied GLOBAL_SPEED
        p.xz -= (iChannelTime[0] * GLOBAL_SPEED) + 3.0;

        // Fractal loop
        for(v = p, d = p.y, j = 40.0; j > 0.01; j *= 0.2) // Explicit float for 4e1
        {
            // Subtract cubes
            // Original: d=max(d,min(min(v=j*.9-abs(mod(v,j+j)-j),v.y).x,v.z)),
            // Explicitly calculate `temp_v_mod_val` to avoid reassigning `v` mid-expression.
            vec3 temp_v_mod_val = j * 0.9 - abs(mod(v, j + j) - j);
            d = max(d, min(min(temp_v_mod_val.x, temp_v_mod_val.y), temp_v_mod_val.z)); // No division here, so no EPSILON needed.
            v = temp_v_mod_val; // Update v for next iteration

            // Rotate 9 radians
            // Original: v.xz *= mat2(cos(vec4(9,42,20,9)));
            v.xz *= mat2(cos(vec4(9.0, 42.0, 20.0, 9.0))); // Explicit floats for clarity
        }
    }
    // Tonemap
    // Original: O = tanh(O*O);
    O = tanh_approx(O * O); // Replaced tanh() with tanh_approx()

    // --- Post-processing: Apply BCS (Brightness, Contrast, Saturation) Adjustments ---
    vec3 final_rgb = O.rgb; // Get the tone-mapped color

    // 1. Brightness Adjustment
    final_rgb *= BRIGHTNESS;

    // 2. Contrast Adjustment
    final_rgb = (final_rgb - 0.5) * CONTRAST + 0.5;

    // 3. Saturation Adjustment
    float luminance = dot(final_rgb, vec3(0.299, 0.587, 0.114));
    final_rgb = mix(vec3(luminance), final_rgb, SATURATION);

    // Apply final color to output, clamped to 0-1 range to prevent over-exposure artifacts
    O.rgb = clamp(final_rgb, 0.0, 1.0);
}
