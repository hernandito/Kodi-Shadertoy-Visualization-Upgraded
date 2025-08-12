// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Explicit Variable Initialization
    float i = 0.0;
    float e = 0.0;
    float R = 0.0;
    float s = 0.0;
    float t = iTime * 0.1;
    float o = 0.0;
    vec2 r = iResolution.xy;
    vec3 q = vec3(0.0);
    vec3 p = vec3(0.0);

    // --- PARAMETERS ---
    #define BRIGHTNESS 1.30    // Brightness adjustment (1.0 = neutral)
    #define CONTRAST 1.40      // Contrast adjustment (1.0 = neutral)
    #define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)
    #define SCREEN_SCALE 0.80  // Scale factor for zooming the effect (e.g., 0.5 for zoom in, 2.0 for zoom out)
    #define WHITE_TINT vec3(1.0, 0.7, 0.0) // RGB color for the white tint (e.g., vec3(1.0, 0.9, 0.8) for warm white)
    #define WHITE_TINT_STRENGTH .30 // How strongly to apply the tint (0.0 for no tint, 1.0 for full tint)

    // カメラ方向ベクトル（d）
    vec3 d = vec3((fragCoord * 2.0 - r) / r.y * 1.5 + vec2(0.0, 1.0), 1.0);

    // Apply screen scale for zooming
    d.xy /= SCREEN_SCALE; // Apply scaling to the UV part of the direction vector

    q = vec3(0.0, 0.0, 0.0);  // カメラ位置
    q.zy -= 1.0;              // ZとYにオフセット

    // レイマーチ
    for(i = 0.0; i < 77.0; i++) {
        o += 0.011 - exp(-e * 2000.0) * 0.016;
        s = 1.0;

        // 次の位置（p）を計算
        // Ensure robust division for R if it can be zero
        p = q += d * e * R * 0.2;
        R = length(p);

        // Robust division for log2 and atan arguments if necessary, though length(p) should prevent R from being 0
        p = vec3(
            log2(max(R, 1e-6)) - t * 0.4, // Robust division for log2 argument
            exp(-p.z / max(R, 1e-6)),     // Robust division
            atan(p.x, p.y) + t * 0.2
        );

        // 疑似フラクタル構造（ノイズ蓄積）
        e = --p.y;
        for(s = 1.0; s < 1000.0; s += s) {
            // Robust division for s
            e += abs(dot(sin(p.xxz * s), cos(p * s))) / max(s, 1e-6) * 0.17;
        }
    }

    o = tanh_approx(vec4(o)).x;  // トーンマッピング - Applying tanh_approx, taking .x component as 'o' is a float

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = vec3(o); // Start with the processed monochrome color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    finalColor = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

    // --- Apply White Tint ---
    // Mix the final color with the WHITE_TINT based on its luminance and the strength parameter.
    // This applies the tint more strongly to brighter areas.
    finalColor = mix(finalColor, WHITE_TINT, luminance * WHITE_TINT_STRENGTH);

    fragColor = vec4(finalColor, 1.0);  // モノクロ出力
}
