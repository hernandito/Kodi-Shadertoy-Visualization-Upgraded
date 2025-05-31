/*
    "Nebula 2" by @XorDev
    
    Based on my tweet shader:
    https://x.com/XorDev/status/1918666116869575076

    Modifications for Kodi Shadertoy compatibility:
    - Replaced tanh with tanh_approx (adapted from Sunset shader)
    - Added post-processing for brightness, contrast, and saturation control
    - Improved ray direction calculation with zoom factor
    - Explicitly initialized variables to avoid undefined behavior
    - Added final clamp to ensure valid output range
    - Added cameraDistance parameter to control camera position (move back for panorama effect)
    - Adjusted color accumulation to preserve brightness when moving camera
    - Modified color palette to shift green tones to cream, removed residual green tones
    - Added slight reddish tones to the cream palette with dynamic variation
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
    float t = iTime;
    
    // Zoom factor (1.0 = normal, >1.0 zooms out)
    float zoom = 1.0; // Restored to original value to avoid FOV changes

    // Initialize variables
    float i = 0.0;
    float z = cameraDistance; // Start raymarching from cameraDistance
    float d = 0.0;
    O = vec4(0.0);

    for(; i++<80.;)
    {
        // Improved ray direction calculation with zoom
        vec2 screenPos = (I - 0.5 * iResolution.xy) / iResolution.y;
        vec3 rayDir = normalize(vec3(screenPos * zoom * 2.0, 1.0));
        vec3 p = z * rayDir;

        p.y = length(cos(p*0.2 + z*0.2)) * 4.0 - abs(p.y);
        
        for(d=1.4; d<1e2; d/=.5)
            p += cos(p.yzx*d - vec3(3.0, d*t, t/3.0)) / d;
            
        z += d = 0.01 + 0.1 * max(p, -p*0.3).y;
        // Adjusted phase offsets and color bias to favor cream with slight reddish tones
        vec4 color = (cos(vec4(4.5, 5.5, 7.5, 0.0) - p.y*2.0) + 1.4);
        color.rgb += vec3(0.3, -0.05, -0.15); // Adjusted bias: more red, less suppression of green/blue
        color.r += sin(t + p.y) * 0.1; // Dynamic red shift for subtle reddish highlights
        O += color / z / d; // Restored original color accumulation to preserve vibrancy
    }

    // Tone mapping
    O = tanh_approx(O / 1100.0); // Restored original denominator

    // Post-processing parameters:
    // brightness = 1.3: Controls overall brightness (1.0 = neutral, >1.0 brightens, <1.0 darkens)
    // contrast = 1.3: Controls contrast (1.0 = neutral, >1.0 increases contrast, <1.0 decreases contrast)
    // saturation = 1.05: Controls color intensity (1.0 = neutral, >1.0 enhances colors, <1.0 desaturates toward grayscale)
    // Fine-tuning: Adjust in small increments (e.g., brightness: 1.2 to 1.4, contrast: 1.2 to 1.4, saturation: 1.0 to 1.1)
    O = applyPostProcessing(O, 1.3, 1.3, 1.05);

    // Final clamp to ensure output is in valid range
    O = clamp(O, 0.0, 1.0);
}

/*
    "Nebula 2" by @XorDev
    
    Based on my tweet shader:
    https://x.com/XorDev/status/1918666116869575076

    Modifications for Kodi Shadertoy compatibility:
    - Replaced tanh with tanh_approx (adapted from Sunset shader)
    - Added post-processing for brightness, contrast, and saturation control
    - Improved ray direction calculation with zoom factor
    - Explicitly initialized variables to avoid undefined behavior
    - Added final clamp to ensure valid output range
    - Added cameraDistance parameter to control camera position (move back for panorama effect)
    - Adjusted color accumulation to preserve brightness when moving camera
add a /* here to restore this code.

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
    float t = iTime;
    
    // Zoom factor (1.0 = normal, >1.0 zooms out)
    float zoom = 1.0; // Restored to original value to avoid FOV changes

    // Initialize variables
    float i = 0.0;
    float z = cameraDistance; // Start raymarching from cameraDistance
    float d = 0.0;
    O = vec4(0.0);

    for(; i++<80.;)
    {
        // Improved ray direction calculation with zoom
        vec2 screenPos = (I - 0.5 * iResolution.xy) / iResolution.y;
        vec3 rayDir = normalize(vec3(screenPos * zoom * 2.0, 1.0));
        vec3 p = z * rayDir;

        p.y = length(cos(p*0.2 + z*0.2)) * 4.0 - abs(p.y);
        
        for(d=1.4; d<1e2; d/=.5)
            p += cos(p.yzx*d - vec3(3.0, d*t, t/3.0)) / d;
            
        z += d = 0.01 + 0.1 * max(p, -p*0.3).y;
        O += (cos(vec4(5.0, 7.0, 9.0, 0.0) - p.y*2.0) + 1.4) / z / d; // Restored original color accumulation
    }

    // Replaced tanh with tanh_approx, adjusted denominator to compensate for brightness
    O = tanh_approx(O / 1200.0); // Increased from 900.0 to reduce overall brightness

    // Apply post-processing to match original visual effect
    O = applyPostProcessing(O, 1.4, 1.3, 1.1);

    // Final clamp to ensure output is in valid range
    O = clamp(O, 0.0, 1.0);
}

/*
    "Nebula 2" by @XorDev
    
    Based on my tweet shader:
    https://x.com/XorDev/status/1918666116869575076

    Modifications for Kodi Shadertoy compatibility:
    - Replaced tanh with tanh_approx (adapted from Sunset shader)
    - Added post-processing for brightness, contrast, and saturation control
    - Improved ray direction calculation with zoom factor
    - Explicitly initialized variables to avoid undefined behavior
    - Added final clamp to ensure valid output range


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
    float t = iTime;
    
    // Zoom factor (1.0 = normal, >1.0 zooms out)
    float zoom = 1.0; // Adjust zoom to frame the effect as needed

    // Initialize variables
    float i = 0.0;
    float z = 0.0;
    float d = 0.0;
    O = vec4(0.0);

    for(; i++<80.;) // Replaced 8e1 with 80. for clarity
    {
        // Improved ray direction calculation with zoom
        vec2 screenPos = (I - 0.5 * iResolution.xy) / iResolution.y;
        vec3 rayDir = normalize(vec3(screenPos * zoom * 2.0, 1.0));
        vec3 p = z * rayDir;

        p.y = length(cos(p*0.2 + z*0.2)) * 4.0 - abs(p.y);
        
        for(d=1.4; d<1e2; d/=.5)
            p += cos(p.yzx*d - vec3(3.0, d*t, t/3.0)) / d;
            
        z += d = 0.01 + 0.1 * max(p, -p*0.3).y;
        O += (cos(vec4(5.0, 7.0, 9.0, 0.0) - p.y*2.0) + 1.4) / z / d;
    }

    // Replaced tanh with tanh_approx
    O = tanh_approx(O / 900.0); // Replaced 9e2 with 900.0 for clarity

    // Apply post-processing to match original visual effect
    O = applyPostProcessing(O, 1.2, 1.2, 1.1);

    // Final clamp to ensure output is in valid range
    O = clamp(O, 0.0, 1.0);
}

*/