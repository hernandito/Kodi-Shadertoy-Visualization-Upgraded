// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Explicit Variable Initialization
    vec2 uv = vec2(0.0);
    float r = 0.0;
    float t = 0.0;
    vec2 p = vec2(0.0);
    vec2 v = vec2(0.0);
    vec4 color = vec4(0.0);

    // --- PARAMETERS ---
    #define BRIGHTNESS 1.10    // Brightness adjustment (1.0 = neutral)
    #define CONTRAST 1.30      // Contrast adjustment (1.0 = neutral)
    #define SATURATION 1.00    // Saturation adjustment (1.0 = neutral)
    #define SCREEN_SCALE 0.90  // Scale factor for zooming the effect (e.g., 0.5 for zoom in, 2.0 for zoom out)

    // 標準化ピクセル座標 (-1 to 1)
    uv = (fragCoord.xy / iResolution.xy) * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y; // アスペクト比補正

    // Apply screen scale for zooming
    uv /= SCREEN_SCALE;

    // 基本スケールと時間
    r = 1.0;
    t = iTime * 0.5;

    // モザイク位置計算
    p = 3.0 * uv / r;
    v = p + p + (t + r) * cos(r + ceil(p + sin(p * 5.0)));

    // 色の生成 - Applying tanh_approx and robust division
    vec4 numerator = 0.1 * (cos(0.6 * p.x + 0.3 * sin(v.y) + vec4(0, 1, 2, 3)) + 1.0);
    float denominator = length(0.9 + sin(v));

    // Ensure robust division
    color = tanh_approx(numerator / max(denominator, 1e-6));

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = color.rgb;
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    finalColor = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

    fragColor = vec4(finalColor, 1.0);
}
//see Xor https://x.com/XorDev
