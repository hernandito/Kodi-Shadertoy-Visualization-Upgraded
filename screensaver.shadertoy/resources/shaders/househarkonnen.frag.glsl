// CC0: Necropolis for Windows Terminal
//  Tweaked the earlier alien city shader and ported it to Windows Terminal

// https://github.com/mrange/windows-terminal-shader-gallery/

#define TIME          iTime
#define RESOLUTION    iResolution

#define PI            3.141592654
#define TAU           (2.0*PI)
#define TOLERANCE     0.0001
#define MAX_RAY_LENGTH      16.0
#define MAX_RAY_MARCHES     60
#define MAX_SHADOW_MARCHES  24
#define NORM_OFF      0.001
#define REPS          6

// New #define parameter to change the overall hue.
// Value is from 0.0 to 1.0 (a full color wheel rotation). Default is 0.0.
#define HUE_SHIFT     0.550

// New #define parameters for Brightness, Contrast, and Saturation.
// 1.0 is the default value for all.
#define BRIGHTNESS    1.01
#define CONTRAST      1.01
#define SATURATION    1.50

// New #define parameter to shift the scene along the X-axis.
// A positive value shifts the scene to the left. Default is 0.5.
#define X_SHIFT       0.6

// New #define parameter to adjust the camera's horizontal gaze (yaw).
// A positive value shifts the view to the left, a negative value shifts it right. Default is 1.0.
#define YAW_SHIFT     4.0

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

// Color definitions are now shifted by HUE_SHIFT
const vec3 bcol = HSV2RGB(vec3(fract(0.45 + HUE_SHIFT), 0.85, 0.051));
const vec3 dcol = HSV2RGB(vec3(fract(0.58 + HUE_SHIFT), 0.666, 0.666));
const vec3 scol = HSV2RGB(vec3(fract(0.58 + HUE_SHIFT), 0.5  , 2.0));
const vec3 gcol = HSV2RGB(vec3(fract(0.35 + HUE_SHIFT), 0.36 , 5.0));
const vec3 skyCol = (0.125*gcol+dcol)*0.5; 
const vec2 csize  = vec2(4.5);

// License: Unknown, author: nmz (twitter: @stormoid), found: https://www.shadertoy.com/view/NdfyRM
vec3 sRGB(vec3 t) {
  return mix(1.055*pow(t, vec3(1./2.4)) - 0.055, 12.92*t, step(t, vec3(0.0031308)));
}

// License: Unknown, author: Claude Brezinski, found: https://mathr.co.uk/blog/2017-09-06_approximating_hyperbolic_tangent.html
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float ubox(vec3 p, vec3 b) {
  vec3 q = p;
  q.xz = abs(p.xz);
  q -= b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
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
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}


float df(vec3 p) {
  float d1 = p.y;
  p.y -= 0.50;
  float d = 1E6;
  vec2 n = mod2(p.xz, csize);
  float d2 = length(p-vec3(0.0, 0.5, 0.0))-0.5;
  float sc = 1.;
  const float zz = 2.0;
  const float hh = 1.0;
  for (int i = 0; i < REPS; ++i) {
    float d0 = ubox(p, vec3(1.0, hh, 1.))-0.033;
    vec3 tp = p;
    tp.y -= -0.5*hh;
    vec3 sp = p;
    sp.y -= hh;
    float d4 = length(sp)-1.1;
    float dd = d0;
    dd = min(dd, d0);
    dd = pmax(dd, -d4, 0.2);
    dd *= sc;       
    d = pmin(d, dd, 0.25*sc);
    p.xz = abs(p.xz);
    const float off = 1.125;
    p -= vec3(off, -hh*0.25, off);
    p *= zz;
    sc /= zz;
  }
  
  d = min(d, d1);
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

float rayMarch(vec3 ro, vec3 rd, float initt, out int iter) {
  float t = initt;
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

float softShadow(vec3 ps, vec3 ld, float mint, float k) {
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
  const vec3 lightDir = normalize(vec3(5.0, 10.0, 10.0));
  int iter;
  float initt = -(ro.y-1.65)/rd.y;
  float bott  = -(ro.y-0.0125)/rd.y;
  float t = rayMarch(ro, rd, initt, iter);
  vec3 col = skyCol;
  vec3 bp = ro+rd*bott;
  vec3 p = ro+rd*t;
  vec3 n = normal(p);
  vec3 r = reflect(rd, n);
  float sd = softShadow(p, lightDir, 0.025, 4.0);
  float dif = max(dot(lightDir, n), 0.0);
  dif *= dif;
  dif *= dif;
  float spe = pow(max(dot(lightDir, r), 0.0), 10.0);
  float ii = float(iter)/float(MAX_RAY_MARCHES);
  if (t < MAX_RAY_LENGTH) {
    col = dcol;
    col += gcol*tanh_approx(1.0*ii*ii);
    col *= mix(0.05, 1.0, dif*sd);
    col += spe*sd*scol;
  }
  float wp = 0.25*bp.x;
  float wn = mod(floor(wp), 2.0);
  wp = fract(wp);
  wp = mix(wp, 1.0-wp, wn);
  float wave = texture(iChannel0, vec2(wp, 0.75)).x-0.5;
  float gd = abs(abs(bp.z+0.25*wave) - 2.25);
  gd -= mix(0.0025, 0.01, 0.5+0.5*(sin(13.0*bp.x+2.0*TIME)*sin(6.0*bp.x+3.0*TIME)));
  
  col += bcol/max(gd+.5*max(bott-t, 0.001), 0.0002*bott*bott);

  float c = tanh_approx(p.y*p.y*5.0);
  col = mix(skyCol, col, exp(-mix(0.25, 0.125, c)*max(t-initt, 0.)-0.25*max(t-5.0, 0.)));
  return col;
}

vec3 adjustBCS(vec3 color, float brightness, float contrast, float saturation) {
  // Brightness
  color += brightness - 1.0;

  // Contrast
  color = (color - 0.5) * contrast + 0.5;

  // Saturation
  vec3 luma = vec3(0.2126, 0.7152, 0.0722);
  vec3 greyscale = vec3(dot(color, luma));
  color = mix(greyscale, color, saturation);

  return color;
}

vec3 effect(vec2 p, vec2 pp) {
  // Camera origin (ro) with animation
  vec3 ro = vec3(3.0 - 0.1*TIME, 3.35, 0.0);
  
  // A fixed base viewing direction that defines the pitch (downward angle)
  vec3 base_view_dir = normalize(vec3(-3.0, -2.0, 0.0));
  
  // Calculate the yaw rotation angle based on YAW_SHIFT
  float yaw_angle = YAW_SHIFT * 0.1; // Adjust this multiplier for sensitivity

  // Create a 2D rotation matrix for the XZ plane
  mat2 rot_matrix = mat2(cos(yaw_angle), -sin(yaw_angle),
                         sin(yaw_angle),  cos(yaw_angle));

  // Apply the rotation to the XZ components of the base viewing direction
  vec2 rotated_xz = rot_matrix * base_view_dir.xz;

  // Reconstruct the full viewing vector with the original Y component
  vec3 ww = normalize(vec3(rotated_xz.x, base_view_dir.y, rotated_xz.y));
  
  const vec3 up = normalize(vec3(0.0, 1.0, 0.0));
  vec3 uu = normalize(cross(up, ww));
  vec3 vv = (cross(ww,uu));
  const float fov = tan(TAU/6.);
  vec3 rd = normalize(-p.x*uu + p.y*vv + fov*ww);

  float ll = length(pp);
  vec3 col = render(ro, rd);
  col -= 0.1*vec3(0.0, 1.0, 2.0).zyx*(ll+0.3);
  col *= smoothstep(1.75, 1.0-0.5, ll);
  
  col = adjustBCS(col, BRIGHTNESS, CONTRAST, SATURATION);

  col = aces_approx(col); 
  col = sRGB(col);
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  
  // This is the post-processing shift. 
  // We add X_SHIFT to the x-coordinate to move the entire scene.
  p.x *= RESOLUTION.x/RESOLUTION.y;
  p.x += X_SHIFT;

  vec3 col = effect(p,pp);
  fragColor = vec4(col, 1.0);
}
