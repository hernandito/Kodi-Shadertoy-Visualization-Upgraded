// Define basic colors
const vec3 red    = vec3(0.816, 0.325, 0.227);
const vec3 green  = vec3(0.584, 0.639, 0.38);
const vec3 blue   = vec3(0.498, 0.588, 0.49);
const vec3 yellow = vec3(0.843, 0.725, 0.353);
const vec3 white  = vec3(0.91,  0.804, 0.596);
const vec3 black  = vec3(0.125, 0.098, 0.078);

// fewer belts = more fps. Max is 32.
#define NUM_BELTS 32

// Custom rounding function for GLSL ES compatibility
// Handles both positive and negative numbers without relying on 'sign()'
float round_compat(float x) {
    if (x >= 0.0) {
        return floor(x + 0.5);
    } else {
        return ceil(x - 0.5);
    }
}

float rand(float x) {
  return fract(sin(x) * 43758.5453);
}

// Helper function that returns 1 if f is between
// lo and hi, and 0 otherwise. The transition between
// 0 and 1 is smoothed to about 2 pixels.
float high_between(float f, float lo, float hi) {
  float d = 2.0 / iResolution.x;
  float rad = (hi - lo) / 2.0;
  float mid = (lo + hi) / 2.0;
  return smoothstep(-d, d, rad - abs(f - mid));
}

// Helper functions to get foreground and background colors
// Replaces array constructors not supported in GLSL ES 1.00
vec3 get_fg_color(int index) {
    if (index == 0) return blue;
    else if (index == 1) return red;
    else if (index == 2) return green;
    else if (index == 3) return green;
    else if (index == 4) return yellow;
    else if (index == 5) return blue;
    else if (index == 6) return red;
    else if (index == 7) return green;
    return black; // Default or error color
}

vec3 get_bg_color(int index) {
    if (index == 0) return red;
    else if (index == 1) return yellow;
    else if (index == 2) return yellow;
    else if (index == 3) return blue;
    else if (index == 4) return white;
    else if (index == 5) return white;
    else if (index == 6) return white;
    else if (index == 7) return white;
    return black; // Default or error color
}

float pattern(int i, vec2 p) {
  // Use float mod and cast back to int for GLSL ES 1.00 compatibility
  i = int(mod(float(i), 4.0));
  float s = (p.x - p.y) / sqrt(2.0);
  if (0 == i) {
    return high_between(mod(s, 0.03), 0.2 * 0.03, 0.55 * 0.03);
  }
  if (1 == i) {
    float m = mod(s, 0.03);
    return high_between(m, 0.1 * 0.03, 0.3 * 0.03)
         + high_between(m, 0.5 * 0.03, 0.8 * 0.03);
  }
  if (2 == i) {
    return high_between(mod(s, 0.01), 0.2 * 0.01, 0.65 * 0.01);
  }
  if (3 == i) {
    // Manual transpose for GLSL ES 1.00 compatibility
    // mat2 rot = sqrt(2.0) / 2.0 * mat2( 1.0, -1.0, 1.0, 1.0);
    // transpose(rot) is equivalent to:
    // mat2(rot[0][0], rot[1][0], rot[0][1], rot[1][1])
    // So, for rot = sqrt(2.0) / 2.0 * mat2(1.0, -1.0, 1.0, 1.0)
    // rot[0] = vec2(sqrt(2.0)/2.0, sqrt(2.0)/2.0)
    // rot[1] = vec2(-sqrt(2.0)/2.0, sqrt(2.0)/2.0)
    // Transposed rot will be:
    mat2 rot_transposed = sqrt(2.0) / 2.0 * mat2(1.0, 1.0, -1.0, 1.0);

    // Use round_compat for GLSL ES 1.00 compatibility on each component
    vec2 p_rotated_scaled = rot_transposed * p * 100.0;
    vec2 dot_center = rot_transposed * vec2(round_compat(p_rotated_scaled.x), round_compat(p_rotated_scaled.y)) / 100.0;
    
    float dot_radius = mix(rand(dot_center.x + dot_center.y), 1.0, 0.8) * 0.003;
    return high_between(length(dot_center - p), dot_radius, 100.0);
  }
  return 0.0;
}

float cbrt(float f) {
  return sign(f) * pow(abs(f), 1.0 / 3.0);
}
float bezier(vec2 a, vec2 b, vec2 c, vec2 p) { // from https://www.shadertoy.com/view/lsdBDS
    vec2  ny     = normalize(a - 2.0 * b + c);
    vec2  nx     = vec2(ny.y, -ny.x);
    float xa     = dot(a - b, ny) / dot(a - b, nx) / 2.0;
    float xc     = dot(c - b, ny) / dot(c - b, nx) / 2.0;
    float scale  = (xa - xc) / dot(a - c, nx);
    vec2  vertex = a - (nx * xa + ny * xa * xa) / scale;
    vec2  p2 = (p - vertex) * mat2(nx, ny) * scale;
    float min_x = min(xa, xc);
    float max_x = max(xa, xc);
    float l = 0.5 - p2.y;
    float e = -(l * l * l / 27.0);
    float dis = p2.x * p2.x * 0.25 - 4.0 * e;
    if (0.0 <= dis) {
        float f = p2.x * 0.25 + sign(p2.x) * sqrt(dis) * 0.5;
        float qx = clamp(cbrt(f) + cbrt(e / f), min_x, max_x);
        return length(vec2(qx, qx * qx) - p2) / scale;
    }
    float r3p = sqrt(p2.y - 0.5) * (2.0 / sqrt(3.0));
    float ac = acos(-1.5 * p2.x / (l * r3p)) / 3.0;
    float qx0 = clamp(r3p * cos(ac             ), min_x, max_x);
    float qx1 = clamp(r3p * cos(ac - 4.188790205), min_x, max_x);
    vec2 d0 = vec2(qx0, qx0 * qx0) - p2;
    vec2 d1 = vec2(qx1, qx1 * qx1) - p2;
    return sqrt(min(dot(d0, d0), dot(d1, d1))) / scale;
}
float segment(vec2 a, vec2 b, vec2 p) {
    vec2 ba = b - a;
    vec2 pa = p - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - h * ba);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // (0,0) at the center, -1 left, 1 right, -1 bottom, 1 top.
  vec2  p = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.x;

  // add two levels of noise to the pixel position:
  // 1. some coarse noise to make the likes look more hand-drawn.
  p += vec2(sin(p.x * 64.0 + p.y * 128.0) * 0.000625,
            sin(p.y * 64.0 + p.x * 32.0) * 0.000625);
  // 2. some fine noise to make the edges look more like ink on paper. 
  p += vec2(rand(p.x * 31.0 + p.y * 87.0) * 0.001,
            rand(p.x * 11.0 + p.y * 67.0) * 0.001);

  float outline = 0.0;
  float id = -1.0;
  for (int i = 0; i < NUM_BELTS; ++i) {
    float t = iTime + float(i * 16) + 1024.0;
    vec2 p0 =      vec2(-1.5,                  sin(t * 0.02));
    vec2 p1 =      vec2( sin(t*0.1) * 0.1, sin(t * 0.07) * 0.7);
    vec2 p2 =      vec2( 1.5,                  sin(t * 0.03));
    vec2 c0 = p1 + vec2(-0.5,                  sin(t * 0.13) * 0.5);
    vec2 c1 = 2.0 * p1 - c0;
    float dist = min(
        bezier(
          p.x < p1.x ? p0 : p1,
          p.x < p1.x ? c0 : c1,
          p.x < p1.x ? p1 : p2,
          p),
        segment(
          p1,
          p.x < p1.x ? c1 : c0,
          p));

#if 1
    vec2 p3 = p0 - vec2(1.0 - sin(t * 0.025), 1.0 - sin(t * 0.027)) * 0.05;
    vec2 p4 = p1 + vec2(      sin(t * 0.014),      sin(t * 0.032)) * 0.05;
    vec2 p5 = p2 + vec2(1.0 - sin(t * 0.014), 1.0 - sin(t * 0.032)) * 0.05;
    vec2 c2 = p4 + vec2(-1.0,                  sin(t * 0.13))  * 0.5;
    vec2 c3 = 2.0 * p4 - c0;
    float dist2 = min(
        bezier(
          p.x < p4.x ? p3 : p4,
          p.x < p4.x ? c2 : c3,
          p.x < p4.x ? p4 : p5,
          p),
        segment(
          p4,
          p.x < p4.x ? c3 : c2,
          p));
    dist = min(dist, dist2 + 0.01);
#endif
    dist *= sin(p.x * 10.0 + sin(p.y)) * 0.2 + 1.0;

    float fill   = high_between(dist, -1.0,   0.025);
    float border = high_between(dist,  0.022, 0.028);
    id     = mix(id, float(i), fill);
    outline = mix(outline, border, fill);
  }
  // Use helper functions to get colors
  vec3 fg = 0.0 <= id ? get_fg_color(int(id)/4) : white;
  vec3 bg = 0.0 <= id ? get_bg_color(int(id)/4) : white;
  vec3 color = mix(mix(fg, bg, pattern(int(id), p)), black, outline);

  // Some noise to make it look more paper-y
  color *= 0.95 + rand(p.x + p.y) * 0.1;
  fragColor = vec4(color, 1.0);
}
