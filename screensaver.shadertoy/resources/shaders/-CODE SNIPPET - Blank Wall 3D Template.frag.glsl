// Blank Canvas Template: Background, vignette, and camera setup for future shaders
// Removed central blobs to create a reusable base

// Adjustable Parameters
// Background Colors
const vec3 zenithColor = vec3(0.08, 0.15, 0.35);  // Dark sky overhead
// - Change to vec3(0.1, 0.2, 0.5) for a lighter blue zenith
// - Increase values (e.g., vec3(0.2, 0.3, 0.6)) to brighten the top of the sky

const vec3 horizonColor = vec3(0.4, 0.90, 1.1);   // Brighter blue near horizon
// - Change to vec3(0.5, 0.7, 0.9) for a softer blue horizon
// - Decrease values (e.g., vec3(0.2, 0.5, 0.8)) to darken the horizon

const vec3 sunColor = vec3(1.0);                  // Sun color (white)
// - Change to vec3(1.0, 0.9, 0.8) for a warmer sun (slightly yellow)
// - Decrease values (e.g., vec3(0.8)) to dim the sun

const float sunRadius = 0.1;                      // Sun size
// - Increase (e.g., 0.2) to make the sun larger
// - Decrease (e.g., 0.05) to make the sun smaller

// Vignette and Postprocessing
const float vignetteStrength = 0.13;              // Strength of vignette effect
// - Increase (e.g., 0.2) to darken the edges more
// - Decrease (e.g., 0.05) to reduce the vignette effect

const float noiseIntensity = 0.02;                // Intensity of noise in postprocessing
// - Increase (e.g., 0.05) to add more noise (grainier look)
// - Decrease (e.g., 0.01) to reduce noise for a cleaner look

const float brightnessFactor = 0.85;              // Overall brightness
// - Increase (e.g., 1.0) to make the scene brighter
// - Decrease (e.g., 0.7) to darken the scene

const float saturationBoost = 0.3;                // Saturation boost in postprocessing
// - Increase (e.g., 0.5) to make colors more vibrant
// - Decrease (e.g., 0.1) to reduce color intensity

const float colorCorrectionFactor = 0.5;          // Color correction factor
// - Increase (e.g., 0.7) to shift colors more toward grayscale
// - Decrease (e.g., 0.3) to preserve more of the original color

const float colorCorrectionWeight = 0.6;          // Color correction weight
// - Increase (e.g., 0.8) to intensify the color correction effect
// - Decrease (e.g., 0.4) to reduce the color correction effect

// Camera Settings
const float defaultCameraAngleX = 4.6;            // Default camera angle (X-axis rotation)
// - Adjust (e.g., 4.0 or 5.0) to change the default vertical orientation

const float defaultCameraAngleY = 4.7;            // Default camera angle (Y-axis rotation)
// - Adjust (e.g., 4.0 or 5.0) to change the default horizontal orientation

// Utility Functions
float hash(float x) {
    return fract(sin(x * 0.0127863) * 17143.321);
}

float hash(vec2 x) {
    return fract(cos(dot(x.xy, vec2(2.31, 53.21)) * 124.123) * 412.0);
}

vec3 cc(vec3 color, float factor, float factor2) {
    float w = color.x + color.y + color.z;
    return mix(color, vec3(w) * factor, w * factor2);
}

vec3 rotate_y(vec3 v, float angle) {
    float ca = cos(angle);
    float sa = sin(angle);
    return v * mat3(ca, 0.0, -sa,
                    0.0, 1.0, 0.0,
                    sa, 0.0, ca);
}

vec3 rotate_x(vec3 v, float angle) {
    float ca = cos(angle);
    float sa = sin(angle);
    return v * mat3(1.0, 0.0, 0.0,
                    0.0, ca, -sa,
                    0.0, sa, ca);
}

// Background Function: Generates sky color based on direction
vec3 background(vec3 d) {
    float y = d.y;
    float t = clamp(y * 0.23 + 0.5, 0.0, 1.0);  // [-1, 1] → [0, 1]

    // Sun disk at zenith
    vec3 sunDir = vec3(0.0, 1.0, 0.0);             // Straight up
    float dToSun = distance(d, sunDir);
    float sunIntensity = smoothstep(sunRadius, sunRadius * 0.5, dToSun); // Softer edge

    // Composite zenith + sun
    vec3 zenithWithSun = mix(zenithColor, sunColor, sunIntensity);

    // Interpolate from zenith to horizon (top to edge)
    float f = smoothstep(0.0, 1.0, pow(1.0 - t, 1.5));
    vec3 skyTop = mix(horizonColor, zenithWithSun, f);

    // Final blend depending on view angle
    return mix(horizonColor, skyTop, smoothstep(0.0, 1.0, t));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalize coordinates
    vec2 uv = fragCoord.xy / iResolution.xy - 0.5;
    uv.x *= iResolution.x / iResolution.y;

    // Camera control via mouse
    vec3 mouse = vec3(iMouse.xy / iResolution.xy - 0.5, iMouse.z - 0.5);

    // Camera setup
    vec3 ro = vec3(0.0, 0.0, -4.0);
    vec3 rd = normalize(vec3(uv, 0.5));
    
    float mx = mouse.x * 9.0 + defaultCameraAngleY;
    float my = mouse.y * 9.0 + defaultCameraAngleX;

    ro = rotate_y(rotate_x(ro, my), mx);
    rd = rotate_y(rotate_x(rd, my), mx);

    // Set color to background (no objects to render)
    vec3 color = background(rd);

    // Postprocessing
    color *= brightnessFactor;                   // Adjust brightness
    color = mix(color, color * color, saturationBoost); // Boost saturation
    color -= hash(color.xy + uv.xy) * noiseIntensity; // Add noise
    color -= length(uv) * vignetteStrength;      // Apply vignette
    color = cc(color, colorCorrectionFactor, colorCorrectionWeight); // Color correction

    fragColor = vec4(color, 1.0);
}

// Notes:
// - This template provides a blank canvas with a sky-like background, vignette effect, and camera control.
// - The central blobs have been removed, leaving a base for adding new effects.
// - Use this as a starting point for future shaders by adding new effects in the mainImage function.
// - The background is a gradient from horizon to zenith with a sun effect, adjustable via parameters.
// - The camera allows mouse control; default angles can be adjusted via parameters.
// - Postprocessing includes brightness, saturation, noise, vignette, and color correction, all adjustable.