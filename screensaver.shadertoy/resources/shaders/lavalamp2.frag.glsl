// CC0: Sort of a lavalamp
//  A quick hack

#ifdef GL_ES
precision mediump float;
#endif

// ===================== PARAMETERS =====================
// Center offset parameters
#define CENTER_OFFSET_X 300.0  // Positive shifts right, negative shifts left
#define CENTER_OFFSET_Y -0.0   // Positive shifts up, negative shifts down

// Brightness / Contrast / Saturation parameters
#define BRIGHTNESS 1.0   // 1.0 = neutral
#define CONTRAST   1.0    // 1.0 = neutral
#define SATURATION 1.0    // 1.0 = grayscale, higher = more vivid

// Turbulence detail parameter
#define TURBULENCE_DETAIL 3.0  // >1.0 = more fine detail, <1.0 = smoother

// Alternate color palette toggle
#define USE_ALT_PALETTE 1      // 0 = normal palette, 1 = alternate
#define ALT_HUE_SHIFT -18.0    // Photoshop-style hue shift (-180 to 180)

// ===================== FUNCTIONS ======================
// Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// RGB <-> HSV conversion helpers
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0., -1./3., 2./3., -1.0);
    vec4 p = mix(vec4(c.bg, K.wz),
                 vec4(c.gb, K.xy),
                 step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r),
                 vec4(c.r, p.yzx),
                 step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
                d / (q.x + e),
                q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0., 4., 2.), 6.0) - 3.0) - 1.0,
                     0.0,
                     1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 shiftHue(vec3 color, float hueShift) {
    vec3 hsv = rgb2hsv(color);
    hsv.x = mod(hsv.x + hueShift, 1.0);
    return hsv2rgb(hsv);
}

// ===================== MAIN ===========================
void mainImage(out vec4 o, vec2 C) {
    // Apply center offset
    C.x += CENTER_OFFSET_X;
    C.y += CENTER_OFFSET_Y;

    // Explicit variable initialization
    float i = 0.0;
    float d = 0.0;
    float z = 0.0;
    float T = iTime * 0.1; // Slow down time

    vec3 O = vec3(0.0); // Accumulated color
    vec3 p = vec3(0.0); // Current position
    vec3 S = vec3(0.0); // Saved position

    vec2 r = iResolution.xy; // Screen resolution
    vec2 Q = vec2(0.0); // Temp vector

    // Raymarching loop
    for (; ++i < 60.0; O += o.w / max(d, 1e-6) * o.xyz) {
        // Ray setup
        p = z * normalize(vec3(C - 0.5 * r, r.y));
        p.z -= 4.0; // Camera back
        S = p;

        // Distance field animation with turbulence detail applied
        d = p.y - T;
        p.x += 0.4 * (1.0 + p.y) *
               sin(d * TURBULENCE_DETAIL) *
               sin(0.34 * d * TURBULENCE_DETAIL);

        // Rotation in xz plane
        Q = p.xz *= mat2(cos((p.y + vec4(0, 11, 33, 0) - T) * TURBULENCE_DETAIL));

        // Distance field calc
        z += d = abs(sqrt(length(Q * Q)) - 0.25 * (5.0 + S.y)) / max(3.0, 1e-6) + 8e-4;

        // Color calc
        o = 1.0 + sin(S.y + p.z * 0.5 + S.z - length(S - p) + vec4(2, 1, 0, 8));
    }

    // Tone mapping with robust tanh
    vec4 color = tanh_approx(vec4(O, 0.0) / 1e4);
    color.a = 1.0;

    // ===================== POST BCS =====================
    // Brightness
    color.rgb *= BRIGHTNESS;
    // Contrast
    color.rgb = (color.rgb - 0.5) * CONTRAST + 0.5;
    // Saturation
    vec3 luminance = vec3(0.299, 0.587, 0.114);
    vec3 gray = vec3(dot(color.rgb, luminance));
    color.rgb = mix(gray, color.rgb, SATURATION);

    // ===================== ALT PALETTE ==================
    #if USE_ALT_PALETTE
        float shift = ALT_HUE_SHIFT / 360.0; // Normalize to [0,1)
        color.rgb = shiftHue(color.rgb, shift);
    #endif

    o = color;
}
