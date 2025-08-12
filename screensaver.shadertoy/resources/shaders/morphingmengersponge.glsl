// License CC0: Slicing a 4d mengersponge
// TBH; I don't know if the generalization I made of mengersponge to 4D is valid 
//  but it looks weird and that's the only quality I need.
// Based of https://www.shadertoy.com/view/4sX3Rn

#define TOLERANCE       0.0001
#define MAX_RAY_LENGTH  8.0
#define MAX_RAY_MARCHES 100

#define PI              3.141592654
#define TAU             (2.0*PI)

// New Parameter: Adjust this value to change the morphing speed.
// A higher value will make the effect faster.
#define EFFECT_SPEED    0.002

// New #define parameters for Brightness, Contrast, and Saturation
// Adjust these values to fine-tune the final image.
#define iBrightness    - 0.010  // A value between -1.0 and 1.0 (0.0 is neutral).
#define iContrast       1.02  // A value between 0.0 and 2.0 (1.0 is neutral).
#define iSaturation     1.0  // A value between 0.0 and 2.0 (1.0 is neutral).

float tanh_approx(float x) {
//  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

void rot(inout vec2 v, float a) {
  float c = cos(a);
  float s = sin(a);
  v.xy = vec2(v.x*c + v.y*s, -v.x*s + v.y*c);
}

float sphere(vec3 p, float r) {
  return length(p) - r;
}

float box(vec4 p, vec4 b) {
  vec4 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(max(q.x, q.w),max(q.y,q.z)),0.0);
}


float mengerSponge(vec4 p) {
  float db = box(p, vec4(1.0));
  if(db > .125) return db;
    
  float d_ = db;
  float res = d_;

  float s = 1.0;
  for(int m = 0; m < 5; ++m) {
    float ss = 0.75;
    vec4 a = mod(p*s, 2.0)-1.0;
    s *= 3.0;
    vec4 r = abs(1.0 - 3.0*abs(a));

    float da = max(max(r.x,r.y),r.w);
    float db = max(max(r.y,r.z),r.w);
    float dc = max(max(r.z,r.x),r.w);
    float dd = max(max(r.z,r.x),r.y);
    float df = length(r)-2.16;

    float du = da;
    du = min(du, db);
    du = min(du, dc);
    du = pmin(du, dd, ss); // Soften the edges a bit
    du = max(du, -df);
    du -= 1.0;
    du /= s;

    res = max(res, du);
  }

  return res;
}


float df(in vec3 p) {
  const float s = 1.0/3.0;
  p -= vec3(0.0, 1.0, 0.0);
  p /= s;
  // This line now uses the new parameter
  float a = EFFECT_SPEED*pmax(iTime-5.0, 0.0, 5.0);
  vec4 pp = vec4(p, 0.5*cos(a*sqrt(2.0)));
  rot(pp.xw, a);
  rot(pp.yw, a*sqrt(0.5));
  rot(pp.zw, a*sqrt(0.3));
  float dm = mengerSponge(pp);
  
  float d = dm;
  return d*s;
}

float rayMarch(in vec3 ro, in vec3 rd, out int iter) {
  float t = 0.0;
  int i = 0;
  for (i = 0; i < MAX_RAY_MARCHES; i++) {
    float distance = df(ro + rd*t);
    if (distance < TOLERANCE || t > MAX_RAY_LENGTH) break;
    t += distance;
  }
  iter = i;
  return t;
}

vec3 normal(in vec3 pos) {
  vec3  eps = vec3(.0005,0.0,0.0);
  vec3 nor;
  nor.x = df(pos+eps.xyy) - df(pos-eps.xyy);
  nor.y = df(pos+eps.yxy) - df(pos-eps.yxy);
  nor.z = df(pos+eps.yyx) - df(pos-eps.yyx);
  return normalize(nor);
}

float softShadow(in vec3 pos, in vec3 ld, in float ll, float mint, float k) {
  const float minShadow = 0.25;
  float res = 1.0;
  float t = mint;
  for (int i=0; i<24; i++) {
    float distance = df(pos + ld*t);
    res = min(res, k*distance/t);
    if (ll <= t) break;
    if(res <= minShadow) break;
    t += max(mint*0.2, distance);
  }
  return clamp(res,minShadow,1.0);
}

// Updated postProcess function with new #define parameters
vec3 postProcess(in vec3 col, in vec2 q)  {
  // Apply Brightness, Contrast, and Saturation
  vec3 luma = vec3(0.2126, 0.7152, 0.0722);
  col = mix(vec3(dot(col, luma)), col, iSaturation); // Saturation
  col = col * iContrast + (0.5 - 0.5 * iContrast); // Contrast
  col += iBrightness; // Brightness
    
  col=pow(clamp(col,0.0,1.0),vec3(1.0/2.2)); 
  col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
  return col;
}


vec3 hsv2rgb(vec3 c) {
  const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 render(in vec3 ro, in vec3 rd) {
  vec3 lightPos = 2.0*vec3(1.5, 3.0, 1.0);

  // background color
  vec3 skyCol = vec3(0.0);

  int iter = 0;
  float t = rayMarch(ro, rd, iter);

  float ifade = 1.0-tanh_approx(3.0*float(iter)/float(MAX_RAY_MARCHES));

  vec3 pos = ro + t*rd;    
  vec3 nor = vec3(0.0, 1.0, 0.0);
  
  vec3 color = vec3(0.0);
  
  // This is the original logic to check if a ray hit the main object, the sky, or the ground.
  // The logic for the ground plane has been removed.
  if (t < MAX_RAY_LENGTH) {
    // Ray intersected object
    nor      = normal(pos);
    // This formula correctly reverses the original hue gradient, starting with the greenish-tan
    // color (0.3) in the foreground and transitioning to the magenta color (-0.2) in the background.
    // The hue range is adjusted and the gradient is subtracted to reverse the direction.
    vec3 hsv = vec3(0.3 - 0.25*t, 1.0 - ifade, 1.0);
    color = hsv2rgb(hsv);
  } else {
    // If the ray did not intersect the object, it returns the sky color.
    // This effectively removes the ground plane.
    return skyCol*ifade;
  }


  vec3 lv    = lightPos - pos;
  float ll2 = dot(lv, lv);
  float ll  = sqrt(ll2);
  vec3 ld    = lv / ll;
  float sha = softShadow(pos, ld, ll, 0.01, 64.0);

  float dm  = min(1.0, 40.0/ll2);
  float dif = max(dot(nor,ld),0.0)*dm;
  float spe = pow(max(dot(reflect(-ld, nor), -rd), 0.), 10.);
  float l   = dif*sha;

  float lin = mix(0.2, 1.0, l);

  vec3 col = lin*color + spe*sha;

  float f = exp(-20.0*(max(t-3.0, 0.0) / MAX_RAY_LENGTH));
    
  return mix(skyCol, col , f)*ifade;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q=fragCoord.xy/iResolution.xy; 
  vec2 p = -1.0 + 2.0*q;
  p.x *= iResolution.x/iResolution.y;

  // camera
  vec3 ro = .4*vec3(2.0, 0, 0.2)+vec3(0.0, 1.25, 0.0);
  rot(ro.xz, sin(iTime*0.03));
  rot(ro.yz, sin(iTime*0.03*sqrt(0.5))*0.25);
  vec3 ww = normalize(vec3(0.0, 1.0, 0.0) - ro);
  vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
  vec3 vv = normalize(cross(ww,uu));
  vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );

  vec3 col = render(ro, rd);

  fragColor = vec4(postProcess(col, q),1.0);
}
