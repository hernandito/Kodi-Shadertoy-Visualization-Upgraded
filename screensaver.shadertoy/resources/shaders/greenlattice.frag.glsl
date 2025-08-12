#define BRIGHTNESS 1.0  // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.30    // Contrast adjustment (1.0 = neutral)
#define SATURATION .80  // Saturation adjustment (1.0 = neutral)


precision mediump float; // Required for ES 2.0 (ES 1.0 compatible subset)

#define P(z) vec3(cos(vec2(.03,.05)*(z))*32.,z)
#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

#define BRIGHTNESS 1.0  // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.30    // Contrast adjustment (1.0 = neutral)
#define SATURATION .80  // Saturation adjustment (1.0 = neutral)
#define SCALE 2.0       // Screen scaling factor (1.0 = no zoom, <1.0 zooms in, >1.0 zooms out)

vec4 tanh_approx(vec4 x) { const float EPSILON = 1e-6; return x / (1.0 + max(abs(x), EPSILON)); }

void mainImage(out vec4 o, vec2 u) {
    // init
    float i = 0.0, a = 0.0, s = 0.0, t = 0.0, d = 0.0;
    vec3 q = vec3(0.0), p = vec3(0.0);
    o = vec4(0.0); // Initialize output

    // scale coords
    t = iTime * .50; // Assign time
    vec3 res = iResolution; // Assign resolution
    u = (u - res.xy / 2.0) / res.y * SCALE * rot(sin(t * 0.04) * 2.0);

    // ro and p are on our path at position 't' (time)
    vec3 ro = p = P(t);

    // this is our look-at matrix
    vec3 Z = normalize(P(t + 2.0) - p),
         X = normalize(vec3(Z.z, 0.0, -Z.x)),
         D = vec3(u, 1.0) * mat3(-X, cross(X, Z), Z);

    // clear o, 100 steps, accumulate color
    for (; i < 100.0; i += 1.0) {
        // march
        p = ro + D * d;
        // subtract path xy from p.xy, save as q
        q = p - P(p.z);
        // min of: repeat p with sin, repeat p with cos
        p = min(sin(p), cos(p));
        // @Xor style turbulence for the morph effect
        p += cos(0.1 * t + p.yzx * 0.8) * 0.04;
        // super sphere power
        p = p * p * p * p;
        // .005 + abs for translucent super spheres
        // 8.-length(q.xy) is our tunnel
        s = max(8.0 - length(q.xy), 0.005 + abs(dot(p, p * 0.3) - 0.5));
        // accumulate distance, understep a bit to correct some wobbles
        d += s * 0.6;
        o += 1.0 / max(s, 1e-6); // Accumulate color with robust division
    }

    // TONE MAPPING and BCS ADJUSTMENT
    vec4 color = tanh_approx(0.3 * vec4(0.6, 2.0, 1.20, 1.0) * o * d / max(8e4, 1e-6)); // Compress bright values with robust division
    // Luminance calculation
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    // Apply saturation
    vec3 saturated = mix(vec3(luminance), color.rgb, SATURATION);
    // Apply contrast
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    // Apply brightness
    o.rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0); // Final RGB with clamping
    o.a = 1.0; // Preserve alpha
}