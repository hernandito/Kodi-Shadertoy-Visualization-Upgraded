// CC0: Not what I intended...
//  Looked at some twitter art, attempted to recreate it.
//  End up with something completely different.

#define TIME          iTime*.3
#define RESOLUTION    iResolution

#define PI            3.141592654
#define TAU           (2.0*PI)

#define TOLERANCE     0.0001
#define MAX_RAY_LENGTH  12.0
#define MAX_RAY_MARCHES 90
#define MAX_SHADOW_MARCHES 30
#define NORM_OFF      0.00125
#define ROT(a)        mat2(cos(a), sin(a), -sin(a), cos(a))
#define H13(n) fract((n)*vec3(12.9898,78.233,45.6114)*43758.5453123)

// New #define parameter to control the floor color.
// Adjust the R, G, and B values (0.0 to 1.0) to change the color.
#define FLOOR_COLOR     vec3(0.9, 0.5, 0.2)

// New #define parameter to control the Field of View.
// This is the FOV angle in radians. The default value of 1.0472 is approximately 60 degrees.
#define FOV_ANGLE       1.0

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

const float hoff      = 0.0;
const vec3 skyCol     = HSV2RGB(vec3(hoff+0.57, 0.70, 0.25));
const vec3 glowCol    = HSV2RGB(vec3(hoff+0.025, 0.85, 0.5));
const vec3 sunCol1    = HSV2RGB(vec3(hoff+0.60, 0.50, 0.5));
const vec3 sunCol2    = HSV2RGB(vec3(hoff+0.05, 0.75, 25.0));
const vec3 diffCol    = HSV2RGB(vec3(hoff+0.60, 0.75, 0.25));
const vec3 sunDir1    = normalize(vec3(3., 3.0, -7.0));

// License: Unknown, author: nmz (twitter: @stormoid), found: https://www.shadertoy.com/view/NdfyRM
vec3 sRGB(vec3 t) {
  return mix(1.055*pow(t, vec3(1./2.4)) - 0.055, 12.92*t, step(t, vec3(0.0031308)));
}

// License: Unknown, author: Matt Taylor (https://github.com/64), found: https://64.github.io/tonemapping/
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

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/articles/distfunctions2d/
float torus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float torus_(vec3 p, vec2 t) {
  p = p.yzx;
  return torus(p, t);
  
}

mat3 g_rot;

mat3 rot_z(float a) {
  float c = cos(a);
  float s = sin(a);
  return mat3(
      c,s,0
    ,-s,c,0
    , 0,0,1
    );
}

mat3 rot_y(float a) {
  float c = cos(a);
  float s = sin(a);
  return mat3(
      c,0,s
    , 0,1,0
    ,-s,0,c
    );
}

mat3 rot_x(float a) {
  float c = cos(a);
  float s = sin(a);
  return mat3(
      1, 0,0
    , 0, c,s
    , 0,-s,c
    );
}

float modRadial(inout vec2 p, float o, float m) {
  float l = length(p);
  float k = l;
  l -= o;
  float n = mod1(l, m);
  
  p = (l/k)*p;
  return n;
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/articles/distfunctions/
float rayPlane(vec3 ro, vec3 rd, vec4 p) {
  return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

float sphere4(vec3 p, float r) {
  p *= p;
  return pow(dot(p, p), 0.25) - r; 
}

float df(vec3 p) {
  vec3 p1 = p;
  p1 *= g_rot;
  
  float d0 = sphere4(p1, 2.0);
  
  float d1 = 1E4;
  const float ff = 1.5-1.25;
  float l = length(p);
  for (float i = 0.0; i < 4.0; ++i) {
    p1 *= g_rot;
    vec3 pp = p1;
    float nn = 0.0;
    nn = modRadial(pp.xz, ff*0.5*i, ff*2.0);
    float dd = torus_(pp, 1.0*ff*vec2(1.0, 0.1));
    dd = max(dd, l-ff*(11.0+i*0.5));
    d1 = pmin(d1, dd, 0.025);
}

  d0 = pmax(d0, -(d1-0.05), 0.25);

  return d0;
}

vec3 normal(vec3 pos) {
  vec2  eps = vec2(NORM_OFF,0.0);
  vec3 nor;
  nor.x = df(pos+eps.xyy) - df(pos-eps.xyy);
  nor.y = df(pos+eps.yxy) - df(pos-eps.yxy);
  nor.z = df(pos+eps.yyx) - df(pos-eps.yyx);
  return normalize(nor);
}

float rayMarch(vec3 ro, vec3 rd) {
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
  return t;
}

// Found somewhere, unsure where
float softShadow(vec3 ps, vec3 ld, float initt, float mint, float k) {
  // Walks towards the light source and accumulates how much in shadow we are.
  
  float res = 1.0;
  float t = initt;
  for (int i=0; i<MAX_SHADOW_MARCHES; ++i) {
    vec3 p = ps + ld*t;
    float d = df(p);
    res = min(res, k*d/t);
    if (res < TOLERANCE) break;
    
    t += max(d, mint);
  }
  return clamp(res, 0.0, 1.0);
}

vec3 render0(vec3 ro, vec3 rd) {
  vec3 col = vec3(0.0);
  float sd = max(dot(sunDir1, rd), 0.0);
  float sf = 1.0001-sd;
  col += clamp(vec3(0.0025/abs(rd.y))*glowCol, 0.0, 1.0);
  col += 0.75*skyCol*pow((1.0-abs(rd.y)), 8.0);
  col += 2.0*sunCol1*pow(sd, 100.0);
  col += sunCol2*pow(sd, 800.0);

  float tp1  = rayPlane(ro, rd, vec4(vec3(0.0, -1.0, 0.0), -6.0));

  if (tp1 > 0.0) {
    vec3 pos  = ro + tp1*rd;
    vec2 pp = pos.xz;
    float db = box(pp, vec2(5.0, 9.0))-3.0;
    
    // The floor color is now controlled by the FLOOR_COLOR #define
    col += vec3(4.0)*FLOOR_COLOR*rd.y*rd.y*smoothstep(0.25, 0.0, db);
    col += vec3(0.8)*FLOOR_COLOR*exp(-0.5*max(db, 0.0));
    col += 0.25*sqrt(FLOOR_COLOR)*max(-db, 0.0);
  }

  return clamp(col, 0.0, 10.0);;
}


vec3 render1(vec3 ro, vec3 rd) {
  float t = rayMarch(ro, rd);
  vec3 col = render0(ro, rd);

  vec3 p = ro+rd*t;
  vec3 n = normal(p);
  vec3 r = reflect(rd, n);
  float fre = 1.0+dot(rd, n);
  fre *= fre;
  float dif = dot(sunDir1, n); 
  if (t < MAX_RAY_LENGTH) {
    float sd  = softShadow(p, r, 0.1, 0.025, 4.0);
    sd = sqrt(sd);
    col = vec3(0.0);
    col += sunCol1*dif*dif*diffCol*0.25;
    col += mix(0.333, 1.0, fre)*render0(p, r)*sd;
  }


  return col;
}

vec3 effect(vec2 p) {
  float tm = TIME*0.5+10.0;
  g_rot = rot_x(0.1*tm)*rot_y(0.23*tm)*rot_z(0.35*tm);
  
  vec3 ro = vec3(5.0, 1.0, 0.);
  ro.xz *= ROT(-0.1*tm);
  const vec3 la = vec3(0.0, 0.0, 0.0);
  const vec3 up = normalize(vec3(0.0, 1.0, 0.0));

  vec3 ww = normalize(la - ro);
  vec3 uu = normalize(cross(up, ww ));
  vec3 vv = (cross(ww,uu));
  const float fov = tan(FOV_ANGLE);
  vec3 rd = normalize(-p.x*uu + p.y*vv + fov*ww);

  vec3 col = render1(ro, rd);
  
  return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = vec3(0.0);
  col = effect(p);
  col *= smoothstep(1.5, 0.5, length(pp));
  col = aces_approx(col); 
  col = sRGB(col);
  fragColor = vec4(col, 1.0);
}
