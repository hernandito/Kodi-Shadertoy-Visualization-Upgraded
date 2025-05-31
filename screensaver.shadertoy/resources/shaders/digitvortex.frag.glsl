precision highp float; // Added precision directive for GLSL ES 1.0

// CC0 : Matrix maelstrom
//  Code is a bit of a mess, lots of hacking without thought and some lingering alias effects
//  Still... want to get something out before bed.

//#define CURSOR // Kept as a define, but might need manual removal if still causing issues

#define TIME        iTime
#define RESOLUTION  iResolution

#define PI          3.141592654
#define PI_2        (0.5*3.141592654)
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// --- Toggle for disabling the center rotating "knot" element ---
#define DISABLE_LOGO_EFFECT // Uncomment this line to disable the logo effect
// ----------------------------------------------------------------

// --- Toggle for disabling the center radial green glow ---
#define DISABLE_GLOW_EFFECT // Uncomment this line to disable the glow effect
// ---------------------------------------------------------

// --- Toggle for disabling the black radial fade at the center ---
#define DISABLE_RADIAL_FADE // Uncomment this line to disable the radial fade
// ----------------------------------------------------------------

// --- Color Palette Toggle ---
// Set to 0 for Green Palette (default)
// Set to 1 for Amber Palette
// Set to 2 for Blue Palette
// Set to 3 for Red Palette
#define COLOR_PALETTE_MODE 1 // Change this value to switch between palettes
// ----------------------------

// Base color of the effect, chosen by the COLOR_PALETTE_MODE
const vec3  bcol =
#if COLOR_PALETTE_MODE == 0
    vec3(0.0, 1.0, 0.25)*0.8; // Original Green Palette
#elif COLOR_PALETTE_MODE == 1
    vec3(1, 0.639, 0)*0.8;  // Amber Palette
#elif COLOR_PALETTE_MODE == 2
    vec3(0.0, 0.5, 1.0)*0.8;  // Blue Palette (similar to old calculators)
#else // COLOR_PALETTE_MODE == 3
    vec3(1.0, 0.0, 0.0)*1.0;  // Red Palette (similar to old calculators)
#endif

const float logo_radius = 0.25;
const float logo_off    = 0.25;
const float logo_width  = 0.10;

// License: MIT, author: Pascal Gilcher, found: https://www.shadertoy.com/view/flSXRV
float atan_approx(float y, float x) {
  float cosatan2 = x / (abs(x) + abs(y));
  float t = PI_2 - cosatan2 * PI_2;
  return y < 0.0 ? -t : t; // Explicit float for 0.0
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5; // Explicit float for 0.5
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

float spiralLength(float b, float a) {
  // https://en.wikipedia.org/wiki/Archimedean_spiral
  return 0.5*b*(a*sqrt(1.0+a*a)+log(a+sqrt(1.0+a*a))); // Explicit float for 0.5, 1.0
}

void spiralMod(inout vec2 p, float a) {
  vec2 op    = p;
  float b    = a/TAU;
  float  rr  = length(op);
  float  aa  = atan_approx(op.y, op.x); // Using atan_approx
  rr         -= aa*b;
  float nn   = mod1(rr, a);
  float sa   = aa + TAU*nn;
  float sl   = spiralLength(b, sa);
  p          = vec2(sl, rr);
}

float dsegmentx(vec2 p, vec2 dim) {
  p.x = abs(p.x);
  float o = 0.5*max(dim.x-dim.y, 0.0); // Explicit float for 0.5, 0.0
  if (p.x < o) {
    return abs(p.y) - dim.y;
  }
  return length(p-vec2(o, 0.0))-dim.y; // Explicit float for 0.0
}

// --- GLSL ES 1.0 Compatible round() replacement ---
float round_es10(float x) {
    return floor(x + 0.5); // Explicit float for 0.5
}
// --------------------------------------------------

// --- GLSL ES 1.0 Compatible 7-segment digit logic (no bitwise ops) ---
// This function determines if a specific segment should be lit for a given digit.
// digit_value: 0-15 (for hex digits 0-F)
// segment_index: 0-6 (standard 7-segment display indexing)
//
//   --0--
//  |     |
//  5     1
//  |     |
//   --6--
//  |     |
//  4     2
//  |     |
//   --3--
//
bool get_segment_state(int digit_value, int segment_index) {
    if (digit_value == 0) { // 0x7D (0b01111101)
        return (segment_index == 0 || segment_index == 1 || segment_index == 2 ||
                segment_index == 3 || segment_index == 4 || segment_index == 5);
    } else if (digit_value == 1) { // 0x50 (0b01010000)
        return (segment_index == 1 || segment_index == 2);
    } else if (digit_value == 2) { // 0x4F (0b01001111)
        return (segment_index == 0 || segment_index == 1 || segment_index == 3 ||
                segment_index == 4 || segment_index == 6);
    } else if (digit_value == 3) { // 0x57 (0b01010111)
        return (segment_index == 0 || segment_index == 1 || segment_index == 2 ||
                segment_index == 3 || segment_index == 6);
    } else if (digit_value == 4) { // 0x72 (0b01110010)
        return (segment_index == 1 || segment_index == 2 || segment_index == 5 ||
                segment_index == 6);
    } else if (digit_value == 5) { // 0x37 (0b00110111)
        return (segment_index == 0 || segment_index == 2 || segment_index == 3 ||
                segment_index == 5 || segment_index == 6);
    } else if (digit_value == 6) { // 0x3F (0b00111111)
        return (segment_index == 0 || segment_index == 2 || segment_index == 3 ||
                segment_index == 4 || segment_index == 5 || segment_index == 6);
    } else if (digit_value == 7) { // 0x51 (0b01010001)
        return (segment_index == 0 || segment_index == 1 || segment_index == 2);
    } else if (digit_value == 8) { // 0x7F (0b01111111)
        return (segment_index == 0 || segment_index == 1 || segment_index == 2 ||
                segment_index == 3 || segment_index == 4 || segment_index == 5 ||
                segment_index == 6);
    } else if (digit_value == 9) { // 0x77 (0b01110111)
        return (segment_index == 0 || segment_index == 1 || segment_index == 2 ||
                segment_index == 3 || segment_index == 5 || segment_index == 6);
    } else if (digit_value == 10) { // A (0x7B) (0b01111011)
        return (segment_index == 0 || segment_index == 1 || segment_index == 2 ||
                segment_index == 4 || segment_index == 5 || segment_index == 6);
    } else if (digit_value == 11) { // B (0x3E) (0b00111110) - lower-case b
        return (segment_index == 2 || segment_index == 3 || segment_index == 4 ||
                segment_index == 5 || segment_index == 6);
    } else if (digit_value == 12) { // C (0x2D) (0b00101101) - upper-case C
        return (segment_index == 0 || segment_index == 3 || segment_index == 4 ||
                segment_index == 5);
    } else if (digit_value == 13) { // D (0x5E) (0b01011110) - lower-case d
        return (segment_index == 1 || segment_index == 2 || segment_index == 3 ||
                segment_index == 4 || segment_index == 6);
    } else if (digit_value == 14) { // E (0x2F) (0b00101111)
        return (segment_index == 0 || segment_index == 3 || segment_index == 4 ||
                segment_index == 5 || segment_index == 6);
    } else if (digit_value == 15) { // F (0x2B) (0b00101011)
        return (segment_index == 0 || segment_index == 4 || segment_index == 5 ||
                segment_index == 6);
    }
    return false; // Should not happen for valid digit_value
}
// ------------------------------------------------------------------

vec3 digit(vec3 col, vec2 p, vec3 acol, vec3 icol, float aa, float n, float t) {
  const vec2 dim = vec2(0.75, 0.075); // Explicit float for 0.75, 0.075
  const float eps = 0.1; // Explicit float for 0.1
  vec2 ap = abs(p);
  if (ap.x > (0.5+dim.y+eps)) return col; // Explicit float for 0.5
  if (ap.y > (1.0+dim.y+eps)) return col; // Explicit float for 1.0
  float m = mod(floor(n), 16.0); // Explicit float for 16.0
  int digit_val = int(m); // Renamed to avoid conflict with function name

  vec2 cp = (p-0.5); // Explicit float for 0.5
  vec2 cn = vec2(round_es10(cp.x), round_es10(cp.y)); // FIXED: Apply round_es10 to each component
  
  vec2 p0 = p;
  p0.y -= 0.5; // Explicit float for 0.5
  p0.y = p0.y-0.5; // Explicit float for 0.5
  float n0 = round_es10(p0.y); // Using round_es10 and initializing n0
  p0.y -= n0;
  float d0 = dsegmentx(p0, dim);

  vec2 p1 = p;
  vec2 n1 = sign(p1); 
  p1 = abs(p1);
  p1 -= 0.5; // Explicit float for 0.5
  p1 = p1.yx;
  float d1 = dsegmentx(p1, dim);
  
  vec2 p2 = p;
  p2.y = abs(p.y);
  p2.y -= 0.5; // Explicit float for 0.5
  p2 = abs(p2);
  float d2 = dot(normalize(vec2(1.0, -1.0)), p2); // Explicit float for 1.0, -1.0

  float d = d0;
  d = min(d, d1);

  float sx = 0.5*(n1.x+1.0) + (n1.y+1.0); // Explicit float for 0.5, 1.0
  float sy = -n0;
  float s_idx = d2 > 0.0 ? (3.0+sx) : sy; // Explicit float for 0.0, 3.0
  
  // Replaced bitwise operation with function call
  vec3 scol = get_segment_state(digit_val, int(s_idx)) ? acol : icol; 

  col = mix(col, scol, smoothstep(aa, -aa, d)*t);
  return col;
}

vec3 digit(vec3 col, vec2 p, vec3 acol, vec3 icol, float n, float t) {
  vec2 aa2 = fwidth(p);
  float aa = max(aa2.x, aa2.y);
  return digit(col, p, acol, icol, aa, n, t);
}

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453); // Explicit float for 12.9898, 13758.5453
}

// License: Unknown, author: Unknown, found: don't remember
float hash2(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453); // Explicit float for 12.9898, 58.233, 13758.5453
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size); // Explicit float for 0.5
  p = mod(p + size*0.5,size) - size*0.5; // Explicit float for 0.5
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0); // Explicit float for 0.0
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

float stripes(float d) {
  const float cc = 0.42; // Explicit float for 0.42
  d = abs(d)-logo_width*cc;
  d = abs(d)-logo_width*cc*0.5; // Explicit float for 0.5
  return d;
}

vec4 merge(vec4 s0, vec4 s1) {
  bool dt = s0.z < s1.z; 
  vec4 b = dt ? s0 : s1;
  vec4 t = dt ? s1 : s0;

  b.x *= 1.0 - exp(-max(80.0*(t.w), 0.0)); // Explicit float for 1.0, 80.0, 0.0

  vec4 r = vec4(
      mix(b.xy, t.xy, t.y)
    , b.w < t.w ? b.z : t.z 
    , min(b.w, t.w)
    );
  
  return r;
}

vec4 figure_8(vec2 p, float aa) {
  vec2  p1 = p-vec2(logo_off, -logo_off);
  float d1 = abs(circle(p1, logo_radius));
  float a1 = atan_approx(-p1.x, -p1.y); // Using atan_approx
  float s1 = stripes(d1);
  float o1 = d1 - logo_width;

  vec2  p2 = p-vec2(logo_off, logo_off);
  float d2 = abs(circle(p2, logo_radius));
  float a2 = atan_approx(p2.x, p2.y);   // Using atan_approx
  float s2 = stripes(d2);
  float o2 = d2 - logo_width;

  vec4 c0 = vec4(smoothstep(aa, -aa, s1), smoothstep(aa, -aa, o1), a1, o1);
  vec4 c1 = vec4(smoothstep(aa, -aa, s2), smoothstep(aa, -aa, o2), a2, o2);

  return merge(c0, c1);
}

vec4 clogo(vec2 p, float aa, out float d) {
  const mat2 rot0 = ROT(PI/4.0); // Explicit float for 4.0
  const mat2 rot1 = ROT(5.0*PI/4.0); // Explicit float for 5.0, 4.0

//#define SINGLE8 // Kept as a define

  float sgn = sign(p.y);
#if !defined(SINGLE8)
  p *= sgn;
#endif
  vec4 s0 = figure_8(p, aa);
  vec4 s1 = figure_8(p*rot0, aa);
  vec4 s2 = figure_8(p-vec2(-0.5, 0.0), aa); // Explicit float for -0.5, 0.0
  vec4 s3 = figure_8(p*rot1, aa);
  
  // This is very hackish to get it to look reasonable
  
  const float off = -PI;
  s1.z -= off;
  s3.z -= off;
  
  vec4 s = s0;
#if !defined(SINGLE8)
  s = merge(s, s1);
  s = merge(s, s2);
  s = merge(s, s3);
#endif

  d = s.w;
  return vec4(mix(0.025*bcol, bcol, s.x), s.y); // Explicit float for 0.025
}

vec3 logoEffect(vec3 col, vec2 p, vec2 pp, float aa) {
  float d;
  vec4 ccol = clogo(p, aa, d);

  const float period = TAU*10.0; // Explicit float for 10.0
  float ss = sin(period*d-TIME*TAU/10.0); // Explicit float for 10.0
  const float off = 0.2; // Explicit float for 0.2
  float doff = period*aa*cos(off); 
//  col = mix(col, col*0.125, smoothstep(doff, -doff, abs(ss)-off)); // Explicit float for 0.125
  col = mix(col, ccol.xyz, ccol.w);
  return col;
}

vec3 spiralEffect(vec3 col, vec2 p, vec2 pp, float aa) {
  vec2 sp = p;
  spiralMod(sp, 0.5); // Explicit float for 0.5

  vec2 dp = sp;
  float dz = 0.0125; // Explicit float for 0.0125
  dp /= dz;
  aa /= dz;
  float dny = mod1(dp.y, 3.06); // Explicit float for 3.06
  float dhy = hash(dny+1234.5); // Explicit float for 1234.5
  dp.x = -dp.x;
  float ltm = (TIME+1234.5)*mix(2.0, 10.0, (dhy))*0.125; // Explicit float for 1234.5, 2.0, 10.0, 0.125
  dp.x -= ltm;
  float opx = dp.x;
  float dnx = mod1(dp.x, 1.5); // Explicit float for 1.5
  const float stepfx = 0.125*0.25; // Explicit float for 0.125, 0.25
  float fx  = -2.0*stepfx*ltm+stepfx*dnx; // Explicit float for -2.0
  float fnx = floor(fx);
  float ffx = fract(fx);
  float dht = hash(fnx);
  float dhx = hash(dnx);
  float dh  = fract(dht+dhx+dhy);
  
  float l = length(p);
  float t = smoothstep(0.4, 0.5, l); // Explicit float for 0.4, 0.5

  const vec3 hcol = clamp(1.5*sqrt(bcol)+vec3(0.2), 0.0, 1.0); // Explicit float for 1.5, 0.2, 0.0, 1.0
  const vec3 acol = bcol;
  const vec3 icol = acol*0.1; // Explicit float for 0.1
  
  float fo = (smoothstep(0.0, 1.0, ffx)); // Explicit float for 0.0, 1.0
  float ff = smoothstep(1.0-2.0*sqrt(stepfx), 1.0, ffx*ffx); // Explicit float for 1.0, 2.0, 1.0
  col = digit(col, dp, mix(acol, hcol, ff), icol, aa, 100.0*dh, fo*t); // Explicit float for 100.0

#if defined(CURSOR)
  float fc = smoothstep(1.0-stepfx, 1.0, ffx); // Explicit float for 1.0, 1.0
  const float rb = 0.2; // Explicit float for 0.2

  float db = box(dp, vec2(0.5, 1.0))-rb; // Explicit float for 0.5, 1.0
  
  col = mix(col, mix(col, hcol, 0.33*fc*fc), smoothstep(aa, -aa, db)*t); // Explicit float for 0.33
#endif

  return col;
}

vec3 glowEffect(vec3 col, vec2 p, vec2 pp, float aa) {
  float d = length(p);
  col += 0.25*bcol*exp(-9.0*max(d-2.0/3.0, 0.0)); // Explicit float for 0.25, 9.0, 2.0, 3.0, 0.0
  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  float aa = 2.0/RESOLUTION.y; // Explicit float for 2.0
  vec3 col  = vec3(0.0); // Explicit float for 0.0
  col = spiralEffect(col, p, pp, aa);
#ifdef DISABLE_GLOW_EFFECT
  // Glow effect is disabled by this define
#else
  col = glowEffect(col,p, pp, aa);
#endif
#ifdef DISABLE_LOGO_EFFECT
  // Logo effect is disabled by this define
#else
  col = logoEffect(col, p*ROT(-0.05*TIME), pp, aa);
#endif
#ifdef DISABLE_RADIAL_FADE
  // Radial fade is disabled by this define
#else
  col *= smoothstep(1.25, 0.5, length(pp)); // Explicit float for 1.25, 0.5
#endif
  col = sqrt(col);
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1.0 + 2.0 * q; // Explicit float for -1.0, 2.0
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = effect(p, pp);   
  fragColor = vec4(col, 1.0); // Explicit float for 1.0
}
