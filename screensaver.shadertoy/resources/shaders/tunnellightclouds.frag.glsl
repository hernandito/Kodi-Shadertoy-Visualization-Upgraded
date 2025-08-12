// --- GLSL Version and Precision Directives for Kodi Compatibility (GLSL ES 1.0) ---
precision highp float;
precision highp int;
precision lowp sampler2D;

// Define a small epsilon for numerical stability in divisions.
const float EPSILON = 1e-6; // 0.000001

// The Robust Tanh Conversion Method: tanh_approx function
// Ensures numerical stability for tanh, especially near zero.
// Expects a vec4 input for consistency with common use cases.
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

const float PI = 3.14159265359;

// --- Custom Parameters ---
#define GLOBAL_ANIMATION_SPEED .30 // Global multiplier for animation speed: >1.0 faster, <1.0 slower

// --- Post-processing Parameters (Brightness, Contrast, Saturation) ---
#define BRIGHTNESS 0.05    // Adjust brightness: 0.0 for no change, positive for brighter, negative for darker
#define CONTRAST   1.20    // Adjust contrast: 1.0 for no change, >1.0 for more contrast, <1.0 for less
#define SATURATION 1.0    // Adjust saturation: 1.0 for no change, >1.0 for more saturated, <1.0 for desaturated iTime


// Standard 2D rotation matrix function.
mat2 rotate(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

// Преобразование UV в сферическое направление
vec3 _uv_to_sphere(in vec2 uv, in float angle)
{
    float dist = length(uv);
    if (dist > 1.0) return vec3(0.0); // Explicit float literal
    float theta = dist * PI * angle / 360.0, phi = atan(uv.y, uv.x); // Explicit float literal
    return vec3(sin(theta) * cos(phi), sin(theta) * sin(phi), -cos(theta));
}

// Настройка камеры
mat3 setCamera(in vec3 ro, in vec3 ta, float cr)
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0); // Explicit float literal
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, -cw);
}

// REMOVED: sdfPaperAirplane function - no longer needed for this effect.

void frag(out vec4 fragColor, in vec2 fragCoord, in vec3 sphereDir)
{
    // Анимация для камеры
    // Applied GLOBAL_ANIMATION_SPEED
    float swayX = 0.15 * sin(iTime * 0.5 * GLOBAL_ANIMATION_SPEED); // Changed iChannelTime[0] to iTime
    float swayY = 0.15 * sin(iTime * 0.7 * GLOBAL_ANIMATION_SPEED); // Changed iChannelTime[0] to iTime
    
    // Камера
    // Applied GLOBAL_ANIMATION_SPEED
    float t_frag = iTime * 0.4 * GLOBAL_ANIMATION_SPEED; // Changed iChannelTime[0] to iTime
    vec3 ro = vec3(0.0, -2.4, 0.2); // Explicit float literals
    vec3 ta = vec3(swayX, 1.8 + swayY, 2.0); // Explicit float literals
    mat3 cam = setCamera(ro, ta, 0.0); // Explicit float literal
    vec3 rd = cam * sphereDir;
    
    // REMOVED: Raymarching for paper airplane - not needed.
    // REMOVED: hitPlane and planeDist variables.

    // Removed airplane color calculation - not needed.
    vec3 col = vec3(0.0); // Placeholder, will not be used in this version.

    // Рэймаршинг для тумана (Clouds/Fog only)
    float d = 0.0; // Explicitly initialized
    float maxDist = 15.0; // Explicitly initialized
    vec3 p = vec3(0.0); // Explicitly initialized
    
    vec3 fogColorAccum = vec3(0.0); // Explicitly initialized
    float fogWeightSum = 0.0; // Explicitly initialized
    vec4 cloudCol = vec4(0.0); // Explicitly initialized

    // The original `if (!hitPlane || planeDist > 0.0)` condition is now effectively `true` always,
    // as the airplane part is removed.
    for (int i = 0; i < 80; i++) { // Explicitly initialized loop variable
        p = ro + rd * d;
        p.z += t_frag * 4.0; // Using t_frag, Applied GLOBAL_ANIMATION_SPEED
        p += cos(p.z + t_frag + p.yzx * 0.5) * 0.5; // Using t_frag // Explicit float literals
        float s_temp = 5.0 - length(p.xy); // Explicit float literal // Renamed `s` to `s_temp`
        for (float n_inner = 0.06; n_inner < 1.0; n_inner += n_inner) { // Explicitly initialized loop variable, renamed `n` to `n_inner`
            // Fixed non-standard `mat2` construction
            p.xy *= rotate(t_frag * 0.1); // Using `t_frag`
            // Applied GLOBAL_ANIMATION_SPEED implicitly through t_frag
            s_temp -= abs(dot(sin(p.z + t_frag + p * n_inner * 20.0), vec3(0.05))) / max(n_inner, EPSILON); // Using `t_frag`, Explicit float literals, robustness
        }
        d += s_temp = 0.02 + abs(s_temp) * 0.1; // Explicit float literals
        vec3 fogColor = vec3(
            0.2 + 0.1 * sin(t_frag * 0.3 + p.z * 0.05 + 0.0), // Using `t_frag`, Explicit float literals
            0.4 + 0.2 * sin(t_frag * 0.3 + p.z * 0.05 + 0.5), // Using `t_frag`, Explicit float literals
            0.6 + 0.3 * sin(t_frag * 0.3 + p.z * 0.05 + 1.0)  // Using `t_frag`, Explicit float literals
        );
        float weight = 0.5 / max(s_temp, EPSILON); // Смягчено // Explicit float literal, robustness
        cloudCol += vec4(fogColor * weight, weight);
        fogColorAccum += fogColor * weight;
        fogWeightSum += weight;
        if (d > maxDist) break;
    }
    
    if (fogWeightSum > 0.0) { // Explicit float literal
        fogColorAccum /= max(fogWeightSum, EPSILON); // Robustness
    }
    
    vec2 uv_main_image = (fragCoord.xy - 0.5 * iResolution.xy) / max(iResolution.y, EPSILON) * 2.0; // Corrected usage of uv variable.
    vec2 uv_point = uv_main_image + vec2(-swayX * 0.1, 0.66 - swayY * 0.1); // Explicit float literals
    // Replaced tanh with tanh_approx, added robustness to divisions.
    cloudCol = tanh_approx(cloudCol / max(d, EPSILON) / max(1200.0, EPSILON) / max(length(uv_point), EPSILON)); // Уменьшена интенсивность // Explicit float literal
    
    // Композитинг (Now only clouds/fog)
    // fragColor = hitPlane ? vec4(col, 1.0) : cloudCol; // Original line, now simplified.
    fragColor = cloudCol; // Only render the cloud color.

    // --- Post-processing: Apply BCS (Brightness, Contrast, Saturation) Adjustments ---
    vec3 final_rgb = fragColor.rgb; // Get the color before BCS

    // 1. Brightness Adjustment
    final_rgb += BRIGHTNESS;

    // 2. Contrast Adjustment
    final_rgb = (final_rgb - 0.5) * CONTRAST + 0.5;

    // 3. Saturation Adjustment
    float luminance = dot(final_rgb, vec3(0.299, 0.587, 0.114));
    final_rgb = mix(vec3(luminance), final_rgb, SATURATION);

    // Apply final color to output, clamped to 0-1 range to prevent over-exposure artifacts
    fragColor.rgb = clamp(final_rgb, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv_outer = (fragCoord.xy - 0.5 * iResolution.xy) / max(iResolution.y, EPSILON) * 2.0; // Explicit float literals, robustness
    if (length(uv_outer) > 1.0) { // Explicit float literal
        fragColor = vec4(0.0, 0.0, 0.0, 1.0); // Explicit float literals
    } else {
        frag(fragColor, fragCoord, _uv_to_sphere(uv_outer, 180.0)); // Explicit float literal
    }
}
