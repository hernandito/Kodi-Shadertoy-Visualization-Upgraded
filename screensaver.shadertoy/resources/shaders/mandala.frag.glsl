// CC0: Amber windows terminal shader
//  I did a hercules green shader for Windows Terminal
//  I wanted an amber one as well to "relive" the good old days
//  Distance field based on an older shader but now with a glowing amber

#define TIME        (iTime * speed)
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// Adjustable parameter for the glow
const float glowIntensity = 0.24; // Adjust the intensity of the glow: 1.0 is default, <1.0 reduces glow (e.g., 0.15 for subtle glow), >1.0 increases glow

// Adjustable parameter for line thickness
const float lineThickness = 0.000001; // Adjust line thickness: 0.001 is default, <0.001 makes lines thinner (e.g., 0.00001 for extremely thin), >0.001 makes lines thicker

// Adjustable parameter for zoom
const float zoomFactor = 1.8; // Adjust zoom level: 1.0 is default, <1.0 zooms in (e.g., 0.667 to zoom in 1.5x), >1.0 zooms out

// Adjustable parameter for animation speed
const float speed = 0.05; // Adjust animation speed: 1.0 is default, <1.0 slows down (e.g., 0.5 for half speed), >1.0 speeds up

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

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

// -------------------------------------------------
// Mandelbox - https://www.shadertoy.com/view/XdlSD4
const float fixed_radius2 = 1.9;
const float min_radius2   = 0.5;
const float folding_limit = 1.0;
const float scale         = -2.1;
// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float pabs(float a, float k) {
  return pmax(a, -a, k);
}
vec3 pmin(vec3 a, vec3 b, vec3 k) {
  vec3 h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0);
  
  return mix(b, a, h) - k*h*(1.0-h);
}
void sphere_fold(inout vec3 z, inout float dz) {
    float r2 = dot(z, z);
    if(r2 < min_radius2) {
        float temp = (fixed_radius2 / min_radius2);
        z *= temp;
        dz *= temp;
    } else if(r2 < fixed_radius2) {
        float temp = (fixed_radius2 / r2);
        z *= temp;
        dz *= temp;
    }
}

void box_fold(inout vec3 z, inout float dz) {
  const float k = 0.05;
  // Soft clamp after suggestion from ollij
  vec3 zz = sign(z)*pmin(abs(z), vec3(folding_limit), vec3(k));
  // Hard clamp
  // z = clamp(z, -folding_limit, folding_limit);
  z = zz * 2.0 - z;
}

float sphere(vec3 p, float t) {
  return length(p)-t;
}

float torus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float mb(vec3 z) {
    vec3 offset = z;
    float dr = 1.0;
    float fd = 0.0;
    for(int n = 0; n < 5; ++n) {
        box_fold(z, dr);
        sphere_fold(z, dr);
        z = scale * z + offset;
        dr = dr * abs(scale) + 1.0;        
        float r1 = sphere(z, 5.0);
        float r2 = torus(z, vec2(8.0, 1));
        r2 = abs(r2) - 0.25;
        float r = n < 4 ? r2 : r1;        
        float dd = r / abs(dr);
        if (n < 3 || dd < fd) {
          fd = dd;
        }
    }
    return (fd);
}

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan(p.y, p.x));
}

vec2 toRect(vec2 p) {
  return vec2(p.x*cos(p.y), p.x*sin(p.y));
}

float modMirror1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize,size) - halfsize;
  p *= mod(c, 2.0)*2.0 - 1.0;
  return c;
}
// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float smoothKaleidoscope(inout vec2 p, float sm, float rep) {
  vec2 hp = p;

  vec2 hpp = toPolar(hp);
  float rn = modMirror1(hpp.y, TAU/rep);

  float sa = PI/rep - pabs(PI/rep - abs(hpp.y), sm);
  hpp.y = sign(hpp.y)*(sa);

  hp = toRect(hpp);

  p = hp;

  return rn;
}

float df(vec2 p) {
  const float s = 0.45 * zoomFactor; // Adjusted with zoom factor
  p /= s;
  float rep = 20.0;
  float ss = 0.05*6.0/rep;
  vec3 p3 = vec3(p.x, p.y, smoothstep(-0.9, 0.9, sin(TIME*0.21)));
  p3.yz *= ROT(TIME*0.05);
  p3.xy *= ROT(TIME*0.11);
  float n = smoothKaleidoscope(p3.xy, ss, rep);
  float d = mb(p3)*s;
  return abs(d);
}

// -------------------------------------------------

vec3 effect(vec2 p, vec2 pp) {
  float aa = 2.0/RESOLUTION.y;
  
  float d = df(p);
  const float hoff = 0.685;
  const float inte = 0.85;
  const vec3 bcol0 = HSV2RGB(vec3(0.50+hoff, 0.85, inte*0.85)); // Line color
  const vec3 bcol1 = HSV2RGB(vec3(0.33+hoff, 0.85, inte*0.025)); // Glow color
  const vec3 bcol2 = HSV2RGB(vec3(0.45+hoff, 0.85, inte*0.85)); // Background tint color (unused for background now)
  vec3 col = vec3(0.0); // True black background
  col += glowIntensity * bcol1/sqrt(abs(d)) * sqrt(1.0/zoomFactor); // Adjusted glow to maintain intensity
  col += bcol0*smoothstep(aa, -aa, (d-lineThickness/zoomFactor)); // Adjusted line thickness to maintain scale
  
  col *= smoothstep(1.5, 0.5, length(pp));
  
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p, pp);
  col = aces_approx(col);
  col = sqrt(col);
  fragColor = vec4(col, 1.0);
}