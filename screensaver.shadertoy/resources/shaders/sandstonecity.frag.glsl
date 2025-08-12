// CC0: Sandstone city
// I enjoyed Xor's city like tweets like this:
//  https://twitter.com/XorDev/status/1631107543387742210?s=20
//  Wanted to try to create something like it.

#define TIME            iTime*.2
#define RESOLUTION      iResolution

#define PI              3.141592654
#define TAU             (2.0*PI)
#define TOLERANCE       0.0001
#define MAX_RAY_LENGTH  24.0
#define MAX_RAY_MARCHES 70
#define MAX_SHADOW_MARCHES 30
#define NORM_OFF        0.001

// BCS Parameters
#define BRIGHTNESS      1.0
#define CONTRAST        .9
#define SATURATION      1.0

// Color Parameters (HSV values)
#define GEOMETRY_HUE    0.05
#define GEOMETRY_SAT    0.75
#define GEOMETRY_VAL    1.0
#define FOG_HUE         0.05
#define FOG_SAT         0.75
#define FOG_VAL         0.3

// AO Parameters
#define AO_STRENGTH      1.80
#define AO_OFFSET        0.1
#define SOFTSHADOW_K     1.0
#define AO_DISTANCE_FACTOR 8.0
#define AO_FADE_RATE     0.25

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

// License: Unknown, author: nmz (twitter: @stormoid), found: https://www.shadertoy.com/view/NdfyRM
vec3 sRGB(vec3 t) {
  return mix(1.055*pow(t, vec3(1./2.4)) - 0.055, 12.92*t, step(t, vec3(0.0031308)));
}

float ubox(vec3 p, vec3 b) {
  vec3 q = p;
  q.xz = abs(p.xz);
  q -= b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec3 aces_approx(vec3 v) {
  v = max(v, 0.0);
  v *= 0.6f;
  float a = 2.51f;
  float b = 0.03f;
  float c = 2.43f;
  float d = 0.59f;
  float e = 0.14f;
  return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0f, 1.0f);
}

vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

float rep(vec3 p) {
  p.xz += 0.5*TIME;
  float d = 1E6;
  vec2 n = mod2(p.xz, vec2(4.));
  p.y -= -1.75;
  float sc = 1.;
  const float zz = 2.0;
  const float hh = 1.0;
  for (int i = 0; i < 7; ++i) {
    float dd = ubox(p, vec3(1.0, hh, 1.0))-0.025;
    d = min(d, dd*sc);
    
    p.xz = abs(p.xz);
    p -= vec3(1.0, -hh*0.25, 1.0);
    p *= zz;
    sc /= zz;
  }
  
  return d;
}

float df(vec3 p) {
  float d1 = p.y+2.25;
  float d2 = rep(p);
  float d= d1;
  d = min(d, d2);

  return d;
}

vec3 normal(vec3 pos) {
  vec2  eps = vec2(NORM_OFF,0.0);
  vec3 nor;
  nor.x = df(pos+eps.xyy) - df(pos-eps.xyy);
  nor.y = df(pos+eps.yxy) - df(pos-eps.yxy);
  nor.z = df(pos+eps.yyx) - df(pos-eps.yyx);
  return normalize(nor);
}

float rayMarch(vec3 ro, vec3 rd, out int iter) {
  float t = 0.0;
  const float tol = TOLERANCE;
  vec2 dti = vec2(1e10,0.0);
  int i = 0;
  for (i = 0; i < MAX_RAY_MARCHES; ++i) {
    float d = df(ro + rd*t);
    if (d<dti.x) { dti=vec2(d,t); }
    if (d < TOLERANCE || t > MAX_RAY_LENGTH) {
      break;
    }
    t += d;
  }
  if(i==MAX_RAY_MARCHES) { t=dti.y; };
  iter = i;
  return t;
}

float softShadow(in vec3 ps, in vec3 ld, in float mint, in float k) {
  float res = 1.0;
  float t = mint*2.0;
  for (int i=0; i<MAX_SHADOW_MARCHES; ++i) {
    vec3 p = ps + ld*t;
    float d = df(p);
    res = min(res, k*d/t);
    if (res < TOLERANCE) break;
    
    t += max(d, mint);
  }
  return clamp(res, 0.0, 1.0);
}

vec3 render(vec3 ro, vec3 rd) {
  const vec3 lightDir = normalize(vec3(5.0, 6.0, 2.0)*2.0);
  int iter;
  float t = rayMarch(ro, rd, iter);
  vec3 col = vec3(0.0);
  vec3 p = ro+rd*t;
  vec3 n = normal(p);
  float sd = softShadow(p, lightDir, 0.025, SOFTSHADOW_K);
  float dif = max(dot(lightDir, n), 0.0);
  dif *= dif;
  const vec3 dcol = HSV2RGB(vec3(GEOMETRY_HUE, GEOMETRY_SAT, GEOMETRY_VAL)); // Geometry color
  float ii = float(iter)/float(MAX_RAY_MARCHES);
  if (t < MAX_RAY_LENGTH) {
    col = dcol;
    col *= mix(0.05, 1.0, dif*sd);
    col *= 1.0/(AO_OFFSET + ii * AO_STRENGTH); // Adjusted AO
  }
  col = mix(HSV2RGB(vec3(FOG_HUE, FOG_SAT, FOG_VAL)), col, exp(-AO_FADE_RATE*max(t-AO_DISTANCE_FACTOR, 0.))); // Adjusted fog/AO fade
  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  const vec3 ro = vec3(2.0, 2.5, -2.0);
  const vec3 la = vec3(0.0, 0.0, 0.0);
  const vec3 up = normalize(vec3(0.0, 1.0, 0.0));

  vec3 ww = normalize(la - ro);
  vec3 uu = normalize(cross(up, ww ));
  vec3 vv = (cross(ww,uu));
  const float fov = tan(TAU/6.);
  vec3 rd = normalize(-p.x*uu + p.y*vv + fov*ww);

  vec3 col = render(ro, rd);
  col *= smoothstep(1.75, 1.0-0.5, length(pp));
  col = aces_approx(col); 
  col = sRGB(col);
  return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  // Apply BCS adjustments
  vec3 col = effect(p, pp);
  float luminance = dot(col, vec3(0.299, 0.587, 0.114));
  vec3 saturated = mix(vec3(luminance), col, SATURATION);
  vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
  col = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

  fragColor = vec4(col, 1.0);
}