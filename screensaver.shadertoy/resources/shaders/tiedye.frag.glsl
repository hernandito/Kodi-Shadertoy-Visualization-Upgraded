// License CC0: Random sunday fractal
// Result after a bit of random coding on sunday

#define PI             3.141592654
#define TAU            (2.0*PI)
#define TIME           iTime*.4
#define RESOLUTION     iResolution
#define ROT(a)         mat2(cos(a), sin(a), -sin(a), cos(a))
#define PCOS(x)        (0.5+0.5*cos(x))
#define DOT2(x)        dot(x, x)

const vec3 std_gamma        = vec3(2.2);

float g_cd = 0.0;

float tanh_approx(float x) {
//  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// From: https://stackoverflow.com/a/17897228/418488
vec3 hsv2rgb(vec3 c) {
  const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 postProcess(vec3 col, vec2 q) {
  col = clamp(col, 0.0, 1.0);
  col = pow(col, 1.0/std_gamma);
  col = col*0.6+0.4*col*col*(3.0-2.0*col);
  col = mix(col, vec3(dot(col, vec3(0.33))), -0.4);
  col *=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

float box(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float torus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}


float boxf(vec3 p, vec3 b, float e) {
  p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
         length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
         length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
         length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float pmin(float a, float b, float k) {
  float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
  return mix( b, a, h ) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

vec3 pmin(vec3 a, vec3 b, float k) {
  vec3 h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
  return mix( b, a, h ) - k*h*(1.0-h);
}

vec3 pabs(vec3 a, float k) {
  return -pmin(a, -a, k);
}

float df(vec3 p) {
  float d = 1E6;
  vec3 op = p;

  const float zf = 2.0-0.1;
  const vec3 nz = normalize(vec3(1.0, .0, -1.0));
  const vec3 ny = normalize(vec3(1.0, -1., 0.0));
  float z = 1.0;
  const float rsm = 0.125*0.25;
  float a = 124.7+TIME*TAU/173.0;
  mat2 rxy = ROT(a);
  mat2 ryz = ROT(a*sqrt(0.5));

  float off = 0.8;
  vec3 cp = vec3(0.55, 0.5, 0.45);
  float cd = 1E6;

  const int mid   = 0;
  const int upper = 7;
  for (int i = 0; i < mid; ++i) {
    cd = min(cd, length(p-cp));
    z *= zf;
    p *= zf;
    p.xy *= rxy;
    p.yz *= ryz;
    p   = pabs(p, rsm);
    p -= nz*pmin(0.0, dot(p, nz), rsm)*2.0;
    p -= ny*pmin(0.0, dot(p, ny), rsm)*2.0;

    p -= vec3(off/zf, 0.0, 0.0);
  }


  for (int i = mid; i < upper; ++i) {
    cd = min(cd, length(p-cp));
    vec3 pp = p;
    float dd4 = torus(pp.zxy, 0.5*vec2(1.0, 0.2));
    float dd5 = boxf(pp, vec3(0.2), 0.00)-0.025;
    float dd  = dd5;
    dd = min(dd5, dd4);
    dd  /= z;

    z *= zf;
    p *= zf;
    p.xy *= rxy;
    p.yz *= ryz;
    p   = pabs(p, rsm);
    p -= nz*pmin(0.0, dot(p, nz), rsm)*2.0;
    p -= ny*pmin(0.0, dot(p, ny), rsm)*2.0;

    p -= vec3(off/zf, 0.0, 0.0);
    d = pmax(d, -(dd-0.1/z), 0.05/z);

    d = min(d, dd);
  }

  g_cd = cd;
  return d;
}

float df(vec2 p) {
  vec3 p3 = vec3(p, mix(0.0, 1.0, PCOS(TAU*TIME/331.0)));
  p3.xz *= ROT(TAU*TIME/127.0);
  p3.yz *= ROT(TAU*TIME/231.0);
  const float z = 0.25;
  p3 *= z;
  return df(p3)/z;
}

float hf(vec2 p) {
  float d = df(p);
  float aa = 0.0125;
  return -0.025*smoothstep(-aa, aa, -d);
}

vec3 normal(vec2 p) {
  vec2 v;
  vec2 w;
  vec2 e = vec2(4.0/RESOLUTION.y, 0);

  vec3 n;
  n.x = hf(p + e.xy) - hf(p - e.xy);
  n.y = 2.0*e.x;
  n.z = hf(p + e.yx) - hf(p - e.yx);

  return normalize(n);
}

vec3 color_right(vec2 p) { // New function for the right-side color
  float cd    = g_cd;
  float hue   = fract(0.85-0.5*PI*cd);
  float sat   = clamp(0.85*PCOS(10.0*cd), 0.0, 1.0);
  float vue   = 1.0-1.0*PCOS(8.0*cd);
  vec3 hsv     = vec3(hue, sat, vue);
  return (1.0*hsv2rgb(hsv));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  // Calculate the distance field (which affects g_cd)
  vec3 p3 = vec3(p, mix(0.0, 1.0, PCOS(TAU*TIME/331.0)));
  p3.xz *= ROT(TAU*TIME/127.0);
  p3.yz *= ROT(TAU*TIME/231.0);
  const float z_df = 0.25;
  df(p3 * z_df) / z_df; // Call df to update g_cd

  vec3 col = color_right(p); // Use only the right-side color logic

  col = postProcess(col, q);

  fragColor = vec4(col, 1.0);
}