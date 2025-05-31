// ------------------------------
// Editable Parameters
// ------------------------------
#define ANIMATION_SPEED 0.125   // Default animation speed (0.5 = normal)
#define STRIPE_FREQUENCY 75.0 // Stripes per unit distance

// --- Background stripe colors ---
vec3 COLOR_STRIPE_DARK = vec3(1.0); // Default: very dark gray (almost black) -0.12
vec3 COLOR_STRIPE_LIGHT = vec3(0.867, 1, 0.996); // Default: dark gray - 0.18

// --- Highlight colors ---
vec3 COLOR_BEZIER_LINE = vec3(1,0,0);         // Default: white 1.0
vec3 COLOR_CONTROL_LINE = vec3(0.5);        // Default: dark gray .3
vec3 COLOR_CONTROL_POINTS = vec3(1.0);      // Default: white 1.0
vec3 COLOR_BBOX_SIMPLE = vec3(1.0, 0.6, 0.0); // Default: yellow-orange 1.0, 0.6, 0.0
vec3 COLOR_BBOX_PRECISE = vec3(0.2, 0.5, 1.0); // Default: cyan 0.2, 0.5, 1.0

// ------------------------------
// Bezier and Utility Functions (unchanged)
// ------------------------------
vec4 bboxBezier(in vec2 p0, in vec2 p1, in vec2 p2, in vec2 p3) {
    // [unchanged]
    vec2 mi = min(p0, p3);
    vec2 ma = max(p0, p3);

    vec2 k0 = -1.0 * p0 + 1.0 * p1;
    vec2 k1 = 1.0 * p0 - 2.0 * p1 + 1.0 * p2;
    vec2 k2 = -1.0 * p0 + 3.0 * p1 - 3.0 * p2 + 1.0 * p3;

    vec2 h = k1 * k1 - k0 * k2;

    if (h.x > 0.0) {
        h.x = sqrt(h.x);
        float t = k0.x / (-k1.x - h.x);
        if (t > 0.0 && t < 1.0) {
            float s = 1.0 - t;
            float q = s*s*s*p0.x + 3.0*s*s*t*p1.x + 3.0*s*t*t*p2.x + t*t*t*p3.x;
            mi.x = min(mi.x, q); ma.x = max(ma.x, q);
        }
        t = k0.x / (-k1.x + h.x);
        if (t > 0.0 && t < 1.0) {
            float s = 1.0 - t;
            float q = s*s*s*p0.x + 3.0*s*s*t*p1.x + 3.0*s*t*t*p2.x + t*t*t*p3.x;
            mi.x = min(mi.x, q); ma.x = max(ma.x, q);
        }
    }

    if (h.y > 0.0) {
        h.y = sqrt(h.y);
        float t = k0.y / (-k1.y - h.y);
        if (t > 0.0 && t < 1.0) {
            float s = 1.0 - t;
            float q = s*s*s*p0.y + 3.0*s*s*t*p1.y + 3.0*s*t*t*p2.y + t*t*t*p3.y;
            mi.y = min(mi.y, q); ma.y = max(ma.y, q);
        }
        t = k0.y / (-k1.y + h.y);
        if (t > 0.0 && t < 1.0) {
            float s = 1.0 - t;
            float q = s*s*s*p0.y + 3.0*s*s*t*p1.y + 3.0*s*t*t*p2.y + t*t*t*p3.y;
            mi.y = min(mi.y, q); ma.y = max(ma.y, q);
        }
    }

    return vec4(mi, ma);
}

vec4 bboxBezierSimple(in vec2 p0, in vec2 p1, in vec2 p2, in vec2 p3) {
    vec2 mi = min(min(p0, p1), min(p2, p3));
    vec2 ma = max(max(p0, p1), max(p2, p3));
    return vec4(mi, ma);
}

float sdBox(in vec2 p, in vec2 b) {
    vec2 q = abs(p) - b;
    vec2 m = vec2(min(q.x, q.y), max(q.x, q.y));
    return (m.x > 0.0) ? length(q) : m.y;
}

float length2(in vec2 v) { return dot(v, v); }

float sdSegmentSq(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length2(pa - ba * h);
}

float sdSegment(in vec2 p, in vec2 a, in vec2 b) {
    return sqrt(sdSegmentSq(p, a, b));
}

vec2 udBezier(vec2 p0, vec2 p1, vec2 p2, in vec2 p3, vec2 pos) {
    const int kNum = 50;
    vec2 res = vec2(1e10, 0.0);
    vec2 a = p0;
    for (int i = 1; i < kNum; i++) {
        float t = float(i) / float(kNum - 1);
        float s = 1.0 - t;
        vec2 b = p0*s*s*s + 3.0*p1*s*s*t + 3.0*p2*s*t*t + p3*t*t*t;
        float d = sdSegmentSq(pos, a, b);
        if (d < res.x) res = vec2(d, t);
        a = b;
    }
    return vec2(sqrt(res.x), res.y);
}

// ------------------------------
// Main Image Function
// ------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float time = iTime * ANIMATION_SPEED - 0.7;

    vec2 p0 = 0.8 * sin(time * 0.7 + vec2(3.0, 1.0));
    vec2 p1 = 0.8 * sin(time * 1.1 + vec2(0.0, 6.0));
    vec2 p2 = 0.8 * sin(time * 1.3 + vec2(4.0, 2.0));
    vec2 p3 = 0.8 * sin(time * 1.5 + vec2(1.0, 5.0));

    vec4 b1 = bboxBezierSimple(p0, p1, p2, p3);
    vec4 b2 = bboxBezier(p0, p1, p2, p3);

    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float px = 2.0 / iResolution.y;

    // --- SHARP BACKGROUND STRIPES ---
    float be = udBezier(p0, p1, p2, p3, p).x;
    float stripe = mod(floor(be * STRIPE_FREQUENCY), 2.0);
    vec3 col = mix(COLOR_STRIPE_DARK, COLOR_STRIPE_LIGHT, stripe); // ← STRIPE COLORS HERE
    col *= 1.0 - 0.3 * length(p);

    // --- BBOX 1 (Simple) ---
    float d = sdBox(p - (b1.xy + b1.zw) * 0.5, (b1.zw - b1.xy) * 0.5);
    col = mix(col, COLOR_BBOX_SIMPLE, 1.0 - smoothstep(0.003, 0.003 + px, abs(d)));

    // --- BBOX 2 (Precise) ---
    d = sdBox(p - (b2.xy + b2.zw) * 0.5, (b2.zw - b2.xy) * 0.5);
    col = mix(col, COLOR_BBOX_PRECISE, 1.0 - smoothstep(0.003, 0.003 + px, abs(d)));

    // --- Control Line Segments ---
    d = sdSegment(p, p0, p1);
    col = mix(col, COLOR_CONTROL_LINE, 1.0 - smoothstep(0.003, 0.003 + px, d));
    d = sdSegment(p, p1, p2);
    col = mix(col, COLOR_CONTROL_LINE, 1.0 - smoothstep(0.003, 0.003 + px, d));
    d = sdSegment(p, p2, p3);
    col = mix(col, COLOR_CONTROL_LINE, 1.0 - smoothstep(0.003, 0.003 + px, d));

    // --- Bezier Curve ---
    col = mix(col, COLOR_BEZIER_LINE, 1.0 - smoothstep(0.003, 0.003 + px * 1.5, be));

    // --- Control Points ---
    d = length(p0 - p); col = mix(col, COLOR_CONTROL_POINTS, 1.0 - smoothstep(0.04, 0.04 + px, d));
    d = length(p1 - p); col = mix(col, COLOR_CONTROL_POINTS, 1.0 - smoothstep(0.04, 0.04 + px, d));
    d = length(p2 - p); col = mix(col, COLOR_CONTROL_POINTS, 1.0 - smoothstep(0.04, 0.04 + px, d));
    d = length(p3 - p); col = mix(col, COLOR_CONTROL_POINTS, 1.0 - smoothstep(0.04, 0.04 + px, d));

    fragColor = vec4(col, 1.0);
}
