precision mediump float; // Set default precision for floats

// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Custom integer modulo function for GLSL ES 1.00 compatibility
// This replaces the '%' operator for integer vectors
ivec2 int_mod(ivec2 a, int b) {
    return a - (a / b) * b;
}

/*
    -55 chars by @FabriceNeyrat2
    -12 chars by me yay

    Thanks! :D

*/

// --- GLOBAL PARAMETERS ---
#define BRIGHTNESS 0.750    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.20       // Contrast adjustment (1.0 = neutral)
#define SATURATION 0.0650   // Saturation adjustment (1.0 = neutral)
#define SCREEN_SCALE 1.0    // Scale factor for zooming the effect (e.g., 0.5 for zoom in, 2.0 for zoom out)
#define WHITE_TINT vec3(1.0, 0.90, 0.80) // RGB color for the white tint (e.g., vec3(1.0, 0.9, 0.8) for warm white)
#define WHITE_TINT_STRENGTH 0.90 // How strongly to apply the tint (0.0 for no tint, 1.0 for full tint)
#define ANIMATION_SPEED 0.30 // Controls the overall animation speed (1.0 = normal speed)
#define DITHER_STRENGTH 0.005 // Strength of the dither effect (e.g., 0.005 for subtle dither)
#define VIGNETTE_INTENSITY 25.0 // Intensity of vignette
#define VIGNETTE_POWER 0.60     // Falloff curve of vignette

void mainImage(out vec4 oColor, vec2 fragCoord_input ) // Renamed 'u' to 'fragCoord_input' for clarity
{
    // Explicit Variable Initialization
    float i = 0.0;
    float s = 0.0;
    float t = iTime * ANIMATION_SPEED; // Apply ANIMATION_SPEED here
    float d = 0.0; // Initialized to 0.0, will be set by texelFetch equivalent

    vec3 p_local_vec3 = vec3(0.0); // Local p for calculations, distinct from iResolution.xyz
    vec3 p_res = iResolution.xyz; // Store iResolution in a variable

    // Use fragCoord_input for texture lookup and dither/vignette later
    vec2 u_for_fractal = fragCoord_input; // This variable will be transformed for fractal calculation

    // Apply SCREEN_SCALE to input coordinates for the fractal part
    vec2 scaled_u_for_fractal = u_for_fractal / SCREEN_SCALE;

    // Convert u to normalized coordinates [0,1] for texture
    // The original `ivec2(u)%1024` suggests pixel-exact lookup with wrapping.
    // For texture, we need normalized coordinates.
    // This attempts to replicate the wrapping behavior for texture.
    ivec2 tex_coords_int = ivec2(fragCoord_input); // Use raw fragCoord_input for texture lookup
    ivec2 wrapped_coords_int = int_mod(tex_coords_int, 1024);
    vec2 wrapped_coords_norm = vec2(wrapped_coords_int) / 1024.0;

    // Replaced texelFetch with texture for GLSL ES 1.00 compatibility
    d = 0.5 * texture(iChannel0, wrapped_coords_norm).a; // Changed texture2D to texture

    // Explicitly initialize o for accumulation
    vec4 o = vec4(0.0);

    // Centered and scaled to fit vertically - apply to u_for_fractal
    // Removed max(p_res.y, 1e-6) as iResolution.y should not be zero.
    u_for_fractal = ( scaled_u_for_fractal - p_res.xy/2.0 ) / p_res.y
      +  cos(t * 0.4) * vec2(0.3, 0.2);

    // Loop structure: o*=i means o starts at 0.0 * 0.0 = 0.0
    for( ; i++ < 100.0 ; o += (1.0 + cos(d + vec4(3,1,0,0))) / max(s, 1e-6) ) // Robust division for s
    {
        p_local_vec3 = vec3(u_for_fractal * d, d + t) - 1.5;
        p_local_vec3.xy *= mat2(cos(p_local_vec3.z * 0.02 + vec4(0,33,11,0)));
        p_local_vec3 += cos(p_local_vec3.z + t + p_local_vec3.yzx * 0.5) * 0.2;
        p_local_vec3.y += sin(t + p_local_vec3.z * 0.3);
        p_local_vec3 = abs(sin(p_local_vec3)) - sin(t) * 0.07 - 0.1;
        d += s = 0.001 + 0.7 * abs(dot(p_local_vec3, p_local_vec3) - 0.5);
    }

    // Final color calculation - Applying tanh_approx and robust division
    // Removed max(1e4, 1e-6) as 1e4 is constant.
    vec4 final_o_vec4 = tanh_approx(o / 1e4);

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = final_o_vec4.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    finalColor = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

    // --- Apply White Tint ---
    // Mix the final color with the WHITE_TINT based on its luminance and the strength parameter.
    // This applies the tint more strongly to brighter areas.
    finalColor = mix(finalColor, WHITE_TINT, luminance * WHITE_TINT_STRENGTH);

    // --- Apply Vignette Effect ---
    // Use the original fragCoord_input for screen-space UV for vignette
    vec2 vignette_uv = fragCoord_input.xy / iResolution.xy; // Use iResolution.xy
    vignette_uv *= 1.0 - vignette_uv.yx; // Transform UV for vignette
    float vig = vignette_uv.x * vignette_uv.y * VIGNETTE_INTENSITY;
    vig = pow(vig, VIGNETTE_POWER);

    // Apply dithering to reduce banding (from vignette directive)
    // Using the global DITHER_STRENGTH and original fragCoord_input
    int x_dither = int(mod(fragCoord_input.x, 2.0));
    int y_dither = int(mod(fragCoord_input.y, 2.0));
    float dither_val = 0.0;
    if (x_dither == 0 && y_dither == 0) dither_val = 0.25 * DITHER_STRENGTH;
    else if (x_dither == 1 && y_dither == 0) dither_val = 0.75 * DITHER_STRENGTH;
    else if (x_dither == 0 && y_dither == 1) dither_val = 0.75 * DITHER_STRENGTH;
    else if (x_dither == 1 && y_dither == 1) dither_val = 0.25 * DITHER_STRENGTH;
    vig = clamp(vig + dither_val, 0.0, 1.0);

    finalColor *= vig; // Apply vignette by multiplying the color

    oColor = vec4(finalColor, 1.0); // Assign to output variable
}
