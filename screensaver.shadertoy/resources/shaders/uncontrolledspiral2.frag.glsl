// CC0: Spiralling out of control'

// Define BCS parameters
#define BRIGHTNESS 1.0    // Adjust brightness (1.0 is neutral)
#define CONTRAST 1.4      // Adjust contrast (1.0 is neutral)
#define SATURATION 1.10   // Adjust saturation (1.0 is neutral)

// Define center offset parameters
#define CENTER_OFFSET_X 100.0  // Positive shifts right, negative shifts left
#define CENTER_OFFSET_Y -50.0  // Positive shifts up, negative shifts down

// Define turbulence detail parameters
#define TURB_LAYER1 23.0   // Higher = finer detail, lower = coarser
#define TURB_LAYER2 17.0
#define TURB_LAYER3 11.0
#define TURB_LAYER4 5.0    // New added layer for additional intricacy
#define TURB_EXTRA_SCALE 1.95 // >1.0 = more detail, <1.0 = less detail

// Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Gyriod distance field function
float g(vec4 p, float s) {
    return abs(dot(sin(p *= s), cos(p.zxwy)) - 1.) / s;
}

// The main entry point
void mainImage(out vec4 o, vec2 C) {
    // Apply center offset
    C -= vec2(CENTER_OFFSET_X, CENTER_OFFSET_Y);

    float i = 0.0,
          z = 0.0,
          Y = 0.0,
          D = 0.0;
    vec4 O = vec4(0.0),
         p = vec4(0.0),
         X = vec4(0.0),
         U = vec4(3, 2, 1, 0);

    // Ray marching loop
    for (; ++i < 77.; O += p.w / max(D, 1e-6) * p)
        p.yxz = iResolution,
        p = z * normalize(vec3(C - 0.5 * p.yx, p)).xyzy,
        p.z += iTime * 0.2,
        D = g(p, TURB_LAYER1 * TURB_EXTRA_SCALE) +
            g(p, TURB_LAYER2 * TURB_EXTRA_SCALE) +
            g(p, TURB_LAYER3 * TURB_EXTRA_SCALE) +
            g(p, TURB_LAYER4 * TURB_EXTRA_SCALE),
        p.xy *= mat2(cos(0.3 * iTime * 0.2 + 0.4 * p.z + 11. * U.wzxw)),
        Y = 0.9 + 0.5 * sin(0.5 * p.z),
        X = abs(p) / max(Y, 1e-6),
        z += D = 0.7 * abs(Y * abs(float(X.x) - floor(max(float(X.x), 1.0) + 0.5)) + D / 9. - 0.1) + 1e-3,
        D *= 1. + dot(p.xy, p.xy) / 4.,
        p = 1. + sin(4. * p.x + p.y + (p.x < 0. ? 0.25 + U.yzwy : U.zyxz - 0.25));

    // Tone mapping & glow
    vec4 color = tanh_approx((O + z * z * z * 2. * U) / 9e3);

    // Apply BCS adjustments
    color.rgb *= BRIGHTNESS;
    color.rgb = (color.rgb - 0.5) * CONTRAST + 0.5;
    vec3 luminance = vec3(0.299, 0.587, 0.114);
    vec3 gray = vec3(dot(color.rgb, luminance));
    color.rgb = mix(gray, color.rgb, SATURATION);

    o = color;
}
