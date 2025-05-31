// CC0: Illuminated sphere
//  I like the Windows 11 sphere wallpapers.
//  Created this as an impression of them

// Comment if you don't like the color cycling
#define POSTPROC

#define TIME        iTime*1.25
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
vec3 rgb2hsv(vec3 c) {
  const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

const vec3 skyCol     = HSV2RGB(vec3(0.58, 0.86, 1.0));
const vec3 speCol1    = HSV2RGB(vec3(0.60, 0.25, 1.0));
const vec3 speCol2    = HSV2RGB(vec3(0.55, 0.25, 1.0));
const vec3 diffCol1   = HSV2RGB(vec3(0.60, 0.90, 1.0));
const vec3 diffCol2   = HSV2RGB(vec3(0.55, 0.90, 1.0));

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

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/intersectors/intersectors.htm
float rayPlane(vec3 ro, vec3 rd, vec4 p) {
  return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/spherefunctions/spherefunctions.htm
vec2 raySphere(vec3 ro, vec3 rd, vec4 dim) {
  vec3 ce = dim.xyz;
  float ra = dim.w;
  vec3 oc = ro - ce;
  float b = dot( oc, rd );
  float c = dot( oc, oc ) - ra*ra;
  float h = b*b - c;
  if( h<0.0 ) return vec2(-1.0); // no intersection
  h = sqrt( h );
  return vec2( -b-h, -b+h );
}

vec3 skyColor(vec3 ro, vec3 rd) {
  const vec3 sunDir1 = normalize(vec3(0., 0.1, 1.0));
  const vec3 sunDir2 = normalize(vec3(0., 0.82, 1.0));
  vec3 col = vec3(0.0);
  col += 0.025*skyCol;
//  col += clamp(vec3(0.0025/abs(rd.y))*skyCol, 0.0, 1.0);
//  col += skyCol*0.0005/pow((1.0001+((dot(sunDir1, rd)))), 2.0);
  col += skyCol*0.0033/pow((1.0001+((dot(sunDir2, rd)))), 2.0);

  float tp0  = rayPlane(ro, rd, vec4(vec3(0.0, 1.0, 0.0), 4.0));
  float tp1  = rayPlane(ro, rd, vec4(vec3(0.0, -1.0, 0.0), 6.0));
  float tp = tp1;
  tp = max(tp0,tp1);


  if (tp1 > 0.0) {
    vec3 pos  = ro + tp1*rd;
    vec2 pp = pos.xz;
    float db = box(pp, vec2(5.0, 9.0))-3.0;
    
    col += vec3(4.0)*skyCol*rd.y*rd.y*smoothstep(0.25, 0.0, db);
    col += vec3(0.8)*skyCol*exp(-0.5*max(db, 0.0));
  }

  if (tp0 > 0.0) {
    vec3 pos  = ro + tp0*rd;
    vec2 pp = pos.xz;
    float ds = length(pp) - 0.5;
    
    col += vec3(0.25)*skyCol*exp(-.5*max(ds, 0.0));
  }

  return clamp(col, 0.0, 10.0);
}

vec3 render(vec3 ro, vec3 rd) {
  vec3 skyCol = skyColor(ro, rd);
  vec3 col = skyCol;
  
  const vec4 sdim = vec4(vec3(0.0), 2.0);
  vec2 si = raySphere(ro, rd, sdim);
  
  vec3 nsp = ro + rd*si.x;

  const vec3 lightPos1   = vec3(0.0, 10.0, 10.0);
  const vec3 lightPos2   = vec3(0.0, -80.0, 10.0);
  
  vec3 nld1   = normalize(lightPos1-nsp); 
  vec3 nld2   = normalize(lightPos2-nsp); 
  
  vec3 nnor   = normalize(nsp - sdim.xyz);

  vec3 nref   = reflect(rd, nnor);

  const float sf = 4.0;
  float ndif1 = max(dot(nld1, nnor), 0.0);
  ndif1       *= ndif1;
  vec3 nspe1  = pow(speCol1*max(dot(nld1, nref), 0.0), sf*vec3(1.0, 0.8, 0.5));

  float ndif2 = max(dot(nld2, nnor), 0.0);
  ndif2       *= ndif2;
  vec3 nspe2  = pow(speCol2*max(dot(nld2, nref), 0.0), sf*vec3(0.9, 0.5, 0.5));

  vec3 nsky   = skyColor(nsp, nref);
  float nfre  = 1.0+dot(rd, nnor);
  nfre        *= nfre;

  vec3 scol = vec3(0.0); 
  scol += nsky*mix(vec3(0.25), vec3(0.5, 0.5, 1.0), nfre);
  scol += diffCol1*ndif1;
  scol += diffCol2*ndif2;
  scol += nspe1;
  scol += nspe2;

  if (si.x > 1.0) {
    col = mix(col, scol, tanh_approx(0.9*(si.y-si.x)));
  }

  return col;
}

vec3 effect(vec2 p) {
  const float fov = tan(TAU/6.0);
  const vec3 ro = 1.0*vec3(0.0, 2.0, 5.0);
  const vec3 la = vec3(0.0, 0.0, 0.0);
  const vec3 up = vec3(0.0, 1.0, 0.0);

  vec3 ww = normalize(la - ro);
  vec3 uu = normalize(cross(up, ww));
  vec3 vv = cross(ww,uu);
  vec3 rd = normalize(-p.x*uu + p.y*vv + fov*ww);

  vec3 col = render(ro, rd);
  
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p);
  col = aces_approx(col); 
#if defined(POSTPROC)  
  vec3 hsv = rgb2hsv(col);
  hsv.x = fract(hsv.x-(-abs(p.x)*p.y+p.y*p.y)*0.08+0.01*TIME);
  col = hsv2rgb(hsv);
#endif  
  col = sRGB(col);

  fragColor = vec4(col, 1.0);
}
