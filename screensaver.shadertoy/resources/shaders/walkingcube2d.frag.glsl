// reference: https://x.com/higgsasxyz/status/1934633364222296246
//
// 3D versions by FabriceNeyret2
//    cube walk 1 - https://www.shadertoy.com/view/wcVXDW
//    cube walk 2b - https://www.shadertoy.com/view/3cKSRc
//
// Fixes:
//    - Roll that does not drift over time.
//    - Lipschitz (Marching always makes progress and never oversteps).

// --- GLOBAL PARAMETERS ---
#define ANIM_SPEED 0.30       // Global animation speed multiplier (1.0 = normal, 2.0 = double speed, 0.5 = half speed)
#define ZOOM_FACTOR 0.60      // Screen zoom factor (1.0 = default. <1.0 zooms out, >1.0 zooms in)
#define LINE_DENSITY 290.0    // Controls the density/thickness of the radiating lines. Increase for thinner/more lines.
#define BCS_BRIGHTNESS 1.0    // Overall brightness (1.0 = normal, >1.0 brighter, <1.0 darker)
#define BCS_CONTRAST 1.0      // Image contrast (1.0 = normal, >1.0 more contrast, <1.0 less contrast)
#define BCS_SATURATION 1.0    // Color saturation (1.0 = normal, >1.0 more saturated, <1.0 desaturated)
// -------------------------

float r, a, d; // radius, angle, distance

float cusp(vec2 U)
{
    U = abs(U - r); // (U - r) places the origin at the bottom left corner of the cusp when it touches both standoffs.
    return min(length(U) - r * 1.2, max(U.x, U.y) - r);
}

float map(vec2 U)
{
    U -= iResolution.xy * vec2(0.6, 0.1); // Explicit float literals
    r = iResolution.y * 0.3; // Explicit float literal
    a = mod(iTime * ANIM_SPEED, 1.57); // wrap time to give rotation (1.57 = pi/2) - Adjusted for ANIM_SPEED
    U.x += a * r / 0.78; // horizontal motion (.78 = pi/4) - Explicit float literal
    d = max(U.y, -cusp(vec2(mod(U.x, r+r), min(U.y, 0.0) + 0.1 * r))); // floor - Explicit float literal
    U *= mat2(sin(a + vec4(0.0, 33.0, 11.0, 0.0))); // rotate around corner - Explicit float literals
    return min(d, cusp(U));
}

void mainImage(out vec4 Q, vec2 U)
{
    // Apply zoom factor to the input coordinates
    vec2 centered_U = U - 0.5 * iResolution.xy; // Center coordinates
    centered_U /= ZOOM_FACTOR;                 // Apply zoom
    vec2 zoomed_U = centered_U + 0.5 * iResolution.xy; // Re-center

    d = map(zoomed_U) / r / 2.0; // Pass zoomed_U to map
    
    // iq coloring
    vec3 col = (d > 0.0) ? vec3(0.929, 0.8, 0.439) : vec3(0.553, 0.71, 0.569); // Explicit float literals
    col *= 1.0 - exp(-6.0*abs(d)); // Explicit float literal
    col *= 0.8 + 0.2*cos(LINE_DENSITY * d); // Explicit float literals - Adjusted for LINE_DENSITY
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.01,abs(d)) ); // Explicit float literals
    
    // Vignette effect
    vec2 uv = U.xy / iResolution.xy; // Use U for fragCoord, iResolution for RESOLUTION
    uv *= 1.0 - uv.yx; // Transform UV for vignette
    float vignetteIntensity = 25.0; // Intensity of vignette
    float vignettePower = 0.60; // Falloff curve of vignette
    float vig = uv.x * uv.y * vignetteIntensity;
    vig = pow(vig, vignettePower);

    // Apply dithering to reduce banding
    const float ditherStrength = 0.05; // Strength of dithering (0.0 to 1.0)
    int x = int(mod(U.x, 2.0)); // Use U.x
    int y = int(mod(U.y, 2.0)); // Use U.y
    float dither = 0.0;
    if (x == 0 && y == 0) dither = 0.25 * ditherStrength;
    else if (x == 1 && y == 0) dither = 0.75 * ditherStrength;
    else if (x == 0 && y == 1) dither = 0.75 * ditherStrength;
    else if (x == 1 && y == 1) dither = 0.25 * ditherStrength;
    vig = clamp(vig + dither, 0.0, 1.0);

    col *= vig; // Apply vignette by multiplying the color
    
    // --- Apply BCS adjustments ---
    // 1. Contrast
    col.rgb = (col.rgb - 0.5) * BCS_CONTRAST + 0.5;
    // 2. Brightness
    col.rgb *= BCS_BRIGHTNESS;
    // 3. Saturation
    float grayscale_val = dot(col.rgb, vec3(0.2126, 0.7152, 0.0722)); // Get grayscale luminance
    col.rgb = mix(vec3(grayscale_val), col.rgb, BCS_SATURATION); // Blend with original for saturation
    // -----------------------------
    
    Q = vec4(col, 1.0); // Explicit float literal
}