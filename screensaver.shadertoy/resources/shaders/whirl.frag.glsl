/*
    "Whirl" by @XorDev

    The deconstructed version of my Whirl shader:
    x.com/XorDev/status/1913305183179727250

    Modified on 04/23/2025 to:
    - Revert supersampling and adjust distance field for sharper edges on 4K displays
    - Add overall rotation around the center point (vanishing point) with adjustable speed
    - Add multiple color palettes (organic and natural) with manual selection
    - Redesign palettes to include four distinct, complementary natural colors
    - Add saturation parameter for new palettes
    - Preserve original look of the shader
*/

// *** Palette Selection ***
// Type a value here to select the palette:
// 0: Original (Red/Green/Blue) - Vibrant, slightly neon
// 1: Forest Canopy (Moss Green, Bark Brown, Fern Yellow-Green, Pine Teal)
// 2: Coastal Dunes (Sandy Beige, Ocean Blue, Coral Pink, Seafoam Green)
// 3: Autumn Harvest (Leaf Green, Pumpkin Orange, Golden Yellow, Crimson Red)
#define PALETTE 0

// *** Saturation Control ***
// Adjust saturation for new palettes (1, 2, 3). Range: [0.0, 2.0]
// 1.0 = Original saturation, >1.0 = More saturated, <1.0 = Less saturated
#define SATURATION 2.5

// Color wave frequency for the original palette
#define COL_FREQ 1.0
// Red, green and blue phase shifts for the original palette
#define RGB_SHIFT vec3(0, 1, 2)
// Opaqueness (lower = more density)
#define OPACITY 0.1

// Camera perspective (ratio from tan(fov_y/2))
#define PERSPECTIVE 1.0
// Raymarch steps (higher = slower)
#define STEPS 50.0

// Z scroll speed
#define Z_SPEED .4
// Twist rate (radians per z unit)
#define TWIST 0.06
// Overall rotation speed (radians per second)
#define ROTATION_SPEED 0.2

// RGB to HSL conversion (inspired by web ID 2)
vec3 rgbToHsl(vec3 color)
{
    float maxVal = max(max(color.r, color.g), color.b);
    float minVal = min(min(color.r, color.g), color.b);
    float h, s, l = (maxVal + minVal) / 2.0;

    if (maxVal == minVal) {
        h = s = 0.0; // Achromatic
    } else {
        float d = maxVal - minVal;
        s = l > 0.5 ? d / (2.0 - maxVal - minVal) : d / (maxVal + minVal);
        if (maxVal == color.r) h = (color.g - color.b) / d + (color.g < color.b ? 6.0 : 0.0);
        else if (maxVal == color.g) h = (color.b - color.r) / d + 2.0;
        else h = (color.r - color.g) / d + 4.0;
        h /= 6.0;
    }
    return vec3(h, s, l);
}

// HSL to RGB conversion (inspired by web ID 2)
vec3 hslToRgb(vec3 hsl)
{
    float h = hsl.x, s = hsl.y, l = hsl.z;
    vec3 color;

    if (s == 0.0) {
        color = vec3(l); // Achromatic
    } else {
        float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
        float p = 2.0 * l - q;
        float r = h + 1.0 / 3.0;
        float g = h;
        float b = h - 1.0 / 3.0;

        r = r < 0.0 ? r + 1.0 : r > 1.0 ? r - 1.0 : r;
        g = g < 0.0 ? g + 1.0 : g > 1.0 ? g - 1.0 : g;
        b = b < 0.0 ? b + 1.0 : b > 1.0 ? b - 1.0 : b;

        if (r < 1.0 / 6.0) color.r = p + (q - p) * 6.0 * r;
        else if (r < 0.5) color.r = q;
        else if (r < 2.0 / 3.0) color.r = p + (q - p) * (2.0 / 3.0 - r) * 6.0;
        else color.r = p;

        if (g < 1.0 / 6.0) color.g = p + (q - p) * 6.0 * g;
        else if (g < 0.5) color.g = q;
        else if (g < 2.0 / 3.0) color.g = p + (q - p) * (2.0 / 3.0 - g) * 6.0;
        else color.g = p;

        if (b < 1.0 / 6.0) color.b = p + (q - p) * 6.0 * b;
        else if (b < 0.5) color.b = q;
        else if (b < 2.0 / 3.0) color.b = p + (q - p) * (2.0 / 3.0 - b) * 6.0;
        else color.b = p;
    }
    return color;
}

// Adjust saturation of a color
vec3 adjustSaturation(vec3 color, float saturation)
{
    vec3 hsl = rgbToHsl(color);
    hsl.y *= saturation; // Adjust saturation
    hsl.y = clamp(hsl.y, 0.0, 1.0);
    return hslToRgb(hsl);
}

// Function to get the color based on the selected palette and Z-depth
vec3 getPaletteColor(float z, int paletteId)
{
    if (paletteId == 0) {
        // Original palette: cosine-based red/green/blue hues (no saturation adjustment)
        return (cos(COL_FREQ * z + RGB_SHIFT) + 1.0);
    }
    
    // Use Z-depth to interpolate between four colors
    float t = fract(z * 0.1); // Scale Z for smooth transitions
    vec3 color0, color1, color2, color3;
    
    if (paletteId == 1) {
        // Palette 1: Forest Canopy
        color0 = vec3(0.3, 0.5, 0.2);  // Deep Moss Green
        color1 = vec3(0.6, 0.4, 0.2);  // Warm Bark Brown
        color2 = vec3(0.5, 0.6, 0.2);  // Fern Yellow-Green
        color3 = vec3(0.2, 0.5, 0.4);  // Pine Teal
    }
    else if (paletteId == 2) {
        // Palette 2: Coastal Dunes
        color0 = vec3(0.85, 0.75, 0.55); // Sandy Beige
        color1 = vec3(0.3, 0.5, 0.7);   // Ocean Blue
        color2 = vec3(0.8, 0.5, 0.4);   // Coral Pink
        color3 = vec3(0.4, 0.7, 0.6);   // Seafoam Green
    }
    else {
        // Palette 3: Autumn Harvest
        color0 = vec3(0.4, 0.6, 0.3);  // Leaf Green
        color1 = vec3(0.9, 0.5, 0.2);  // Pumpkin Orange
        color2 = vec3(0.9, 0.7, 0.3);  // Bright Golden Yellow
        color3 = vec3(0.7, 0.3, 0.2);  // Crimson Red
    }
    
    // Interpolate between the four colors based on Z-depth
    vec3 color;
    if (t < 0.25) {
        color = mix(color0, color1, t * 4.0);
    } else if (t < 0.5) {
        color = mix(color1, color2, (t - 0.25) * 4.0);
    } else if (t < 0.75) {
        color = mix(color2, color3, (t - 0.5) * 4.0);
    } else {
        color = mix(color3, color0, (t - 0.75) * 4.0);
    }
    
    // Apply saturation adjustment for new palettes
    return adjustSaturation(color, SATURATION);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Centered, ratio-corrected screen uvs [-1, 1]
    vec2 res = iResolution.xy;
    vec2 uv = (1.8 * fragCoord - res) / res.y;
    
    // Apply overall rotation around the center point
    float angle = ROTATION_SPEED * iTime;
    uv *= mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    
    // Ray direction for raymarching
    vec3 dir = normalize(vec3(uv, -PERSPECTIVE));
    
    // Output color
    vec3 col = vec3(0.0);
    
    // Raymarch depth
    float z = 0.0;
    // Distance field step size
    float d = 0.0;
    
    // Raymarching loop
    for (float i = 0.0; i < STEPS; i++)
    {
        // Compute raymarch sample point
        vec3 p = z * dir;
        p.z -= Z_SPEED * iTime;
        // Per-point twist rotation
        float angle = p.z * TWIST;
        p.xy *= mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
        // Distorted cubes
        vec3 v = cos(p + sin(p.yzx / 0.3));
        // Add cube SDF with translucency
        z += d = length(max(v, v.zxy * OPACITY)) / 4.0;
        // Set coloring with glow attenuation using selected palette
        col += getPaletteColor(p.z, PALETTE) / d;
    }
    
    // Exponential tonemapping
    col = 0.9 - exp(-col / STEPS / 5e1);
    fragColor = vec4(col, 1.0);
}