/*
    "Nebula 3" by @XorDev
    
    Based on my tweet shader:
    https://x.com/XorDev/status/1918766627828515190

    Modifications for Kodi Shadertoy compatibility:
    - Replaced tanh with tanh_approx (adapted from Sunset shader)
    - Added post-processing for brightness, contrast, and saturation control
    - Explicitly initialized variables to avoid undefined behavior
    - Added final clamp to ensure valid output range
    - Added cameraDistance parameter to control camera position (move back for panorama effect)
    - Modified color palette to shift green tones to cream, removed residual green tones
    - Added slight reddish tones to the cream palette with dynamic variation
    - Restored vibrancy by adjusting tone mapping and post-processing
*/

// Camera distance parameter
// Controls the camera's position along the z-axis (positive values move the camera back)
// cameraDistance = 0.0: Original position (no movement)
// cameraDistance > 0.0: Moves camera back (e.g., 5.0 for a slight panorama effect)
// cameraDistance < 0.0: Moves camera forward (e.g., -5.0 to move closer)
// Fine-tuning: Adjust in small increments (e.g., 3.0, 7.0) to find the desired panorama effect
const float cameraDistance = 9.0; // Slight move back for panorama effect

// Approximate tanh function for Kodi compatibility
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + abs(x));
}

// Saturation adjustment
vec4 saturate(vec4 color, float sat) {
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

// Post-processing to adjust brightness, contrast, and saturation
vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    color.rgb *= brightness;
    return saturate(color, saturation);
}

void mainImage(out vec4 O, in vec2 I)
{
    float t = iTime, i = 0.0, z = cameraDistance, d = 0.0, s = 0.0;
    O = vec4(0.0); // Explicitly initialize O

    for(; i++<1e2;)
    {
        vec3 p = z * normalize(vec3(I+I,0) - iResolution.xyy);
        p.z -= t;
        for(d = 1.0; d < 64.0; d += d)
            p += 0.7 * cos(p.yzx*d) / d;
        p.xy *= mat2(cos(z*.2 + vec4(0,11,33,0)));
        z += d = 0.03 + 0.1 * max(s=3.0-abs(p.x), -s*0.2);
        // Adjusted phase offsets and color bias to favor cream with slight reddish tones
        vec4 color = (cos(s+s-vec4(4.5, 5.5, 7.5, 0.0)) + 1.4);
        color.rgb += vec3(0.3, -0.05, -0.15); // Bias toward cream: more red, less green/blue
        color.r += sin(t + p.x) * 0.1; // Dynamic red shift for subtle reddish highlights
        O += color / d / z;
    }

    // Restored quadratic scaling in tone mapping to increase vibrancy
    O = tanh_approx(O*O/1e5); // Adjusted from O/2000.0 to O*O/1e5 to match original brightness

    // Post-processing parameters:
    // brightness = 1.5: Controls overall brightness (1.0 = neutral, >1.0 brightens, <1.0 darkens)
    // contrast = 1.4: Controls contrast (1.0 = neutral, >1.0 increases contrast, <1.0 decreases contrast)
    // saturation = 1.05: Controls color intensity (1.0 = neutral, >1.0 enhances colors, <1.0 desaturates toward grayscale)
    // Fine-tuning: Adjust in small increments (e.g., brightness: 1.4 to 1.6, contrast: 1.3 to 1.5, saturation: 1.0 to 1.1)
    O = applyPostProcessing(O, 1.8, 1.1, 0.75);

    // Final clamp to ensure output is in valid range
    O = clamp(O, 0.0, 1.0);
}