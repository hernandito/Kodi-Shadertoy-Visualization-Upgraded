// Based orignally upon: https://www.shadertoy.com/view/XdlSD4

// I always liked mandelbox_ryu made by EvilRyu
// Was tinkering a bit with the code and came up with this which at least I liked.
// https://www.shadertoy.com/view/3ddSDs

// Uses very simple occlusion based lighting which made it look more like a structure
// of bones than my other futile lighting attemps.

// Continued tinkering and applied camera path and domain repetition

// --- PARAMETERS FOR ADJUSTMENT ---
// Adjust the Brightness, Contrast, and Saturation of the final image.
// Default values of 1.0 will maintain the original look.
#define BRIGHTNESS 1.0
#define CONTRAST 1.20
#define SATURATION 1.0

// Adjust the color of the main bone-like structure.
// Default is a bone-like color: vec3(0.89, 0.855, 0.788).
#define BONE_COLOR vec3(0.89, 0.8, 0.635)

const float fixed_radius2 = 4.5;
const float min_radius2   = 0.5;
const float folding_limit = 2.3;
const float scale         = -3.0;
const int   max_iter      = 120;
// Using the new define parameter BONE_COLOR instead of the original 'bone' constant
const vec3  rep           = vec3(10.0);

#define PATHA 0.4*vec2(0.11, 0.21)
#define PATHB 0.7*vec2(13.0, 3.0)

// Derived from https://www.shadertoy.com/view/XdcfR8
//  Another shade I really like

vec3 camPath(float z)  {
  return vec3(sin(z*PATHA)*PATHB, z);
}

vec3 camPathDeriv(float z)  {
  return vec3(PATHA*PATHB*cos(PATHA*z), 1.0);
}

vec3 camPathDeriv2(float z)  {
  return vec3(-PATHA*PATHA*PATHB*sin(PATHA*z), .0);
}

vec3 mod3(inout vec3 p, vec3 size) {
  vec3 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5, size) - size*0.5;
  return c;
}

void sphere_fold(float fr, inout vec3 z, inout float dz) {
  float r2 = dot(z, z);
  if(r2 < min_radius2) {
    float temp = (fr / min_radius2);
    z *= temp;
    dz *= temp;
  } else if(r2 < fr) {
    float temp = (fr / r2);
    z *= temp;
    dz *= temp;
  }
}

void box_fold(float fl, inout vec3 z, inout float dz) {
  z = clamp(z, -fl, fl) * 2.0 - z;
}

float sphere(vec3 p, float t) {
  return length(p)-t;
}

float torus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float mb(float fl, float fr, vec3 z) {
  vec3 offset = z;
  float dr = 1.0;
  float fd = 0.0;
  for(int n = 0; n < 5; ++n) {
    box_fold(fl, z, dr);
    sphere_fold(fr, z, dr);
    z = scale * z + offset;
    dr = dr * abs(scale) + 1.0;         
    float r1 = sphere(z, 5.0);
    float r2 = torus(z, vec2(8.0, 1));         
    float r = n < 4 ? r2 : r1;         
    float dd = r / abs(dr);
    if (n < 3 || dd < fd) {
      fd = dd;
    }
  }
  return fd;
}

float df(vec3 p) { 
  float tm = p.z;
  vec3 wrap = camPath(tm);
  vec3 wrapDeriv = normalize(camPathDeriv(tm));
  p.xy -= wrap.xy;
  p -= wrapDeriv*dot(vec3(p.xy, 0), wrapDeriv)*0.5*vec3(1,1,-1);

  p -= rep*vec3(0.5, 0.0, 0.0);
  p.y *= (1.0 + 0.1*abs(p.y));
  vec3 i = mod3(p, rep);
  
  float fl = folding_limit + 0.3*sin(0.025*iTime+1.0)- 0.3; 
  float fr = fixed_radius2 - 3.0*cos(0.025*sqrt(0.5)*iTime-1.0);

  float d1 = mb(fl, fr, p);
  
  return d1; 
} 


float hash(vec2 p)  {
  float h = dot(p,vec2(127.1,311.7));    
  return fract(sin(h)*43758.5453123);
}

float intersect(vec3 ro, vec3 rd, out int iter) {
  float res;
  float r = hash(ro.xy + ro.xz + ro.yz);
  float t = 10.0*mix(0.01, 0.02, r);
  iter = max_iter;
    
  for(int i = 0; i < max_iter; ++i) {
    vec3 p = ro + rd * t;
    res = df(p);
    if(res < 0.001 * t || res > 20.) {
      iter = i;
      break;
    }
    t += res;
  }
    
  if(res > 20.) t = -1.;
  return t;
}

float ambientOcclusion(vec3 p, vec3 n) {
  float stepSize = 0.012;
  float t = stepSize;

  float oc = 0.0;

  for(int i = 0; i < 12; i++) {
    float d = df(p + n * t);
    oc += t - d;
    t += stepSize;
  }

  return clamp(oc, 0.0, 1.0);
}

vec3 normal(in vec3 pos) {
  vec3  eps = vec3(.001,0.0,0.0);
  vec3 nor;
  nor.x = df(pos+eps.xyy) - df(pos-eps.xyy);
  nor.y = df(pos+eps.yxy) - df(pos-eps.yxy);
  nor.z = df(pos+eps.yyx) - df(pos-eps.yyx);
  return normalize(nor);
}

vec3 lighting(vec3 p, vec3 rd, int iter) {
  vec3 n = normal(p);
  float fake = float(iter)/float(max_iter);
  float fakeAmb = exp(-fake*fake*9.0);
  float amb = ambientOcclusion(p, n);

  vec3 col = vec3(mix(1.0, 0.125, pow(amb, 3.0)))*vec3(fakeAmb)*BONE_COLOR;
  return col;
}

vec3 post(vec3 col, vec2 q) {
  // BCS Adjustments using new define parameters
  col = pow(clamp(col, 0.0, 1.0), vec3(1.0 / BRIGHTNESS)); // Brightness
  col = 0.5 + (col - 0.5) * CONTRAST;                      // Contrast
  col = mix(vec3(dot(col, vec3(0.33))), col, SATURATION);  // Saturation
  col *= 0.5 + 0.5 * pow(19.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.7); // vigneting
  return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )  { 
  vec2 q=fragCoord.xy/iResolution.xy; 
  vec2 uv = -1.0 + 2.0*q; 
  uv.x*=iResolution.x/iResolution.y; 
  
  float tm = 2.0*iTime*.1;

  vec3 up = vec3(0.0, 1.0, 0.0) + 2.0*camPathDeriv2(tm);
    
  vec3 ro = camPath(tm);
  vec3 cf = normalize(camPathDeriv(tm));
  vec3 cs = normalize(cross(cf, up)); 
  vec3 cu = normalize(cross(cs,cf)); 
  vec3 rd = normalize(uv.x*cs + uv.y*cu + (3.0 - 1.0*length(uv))*cf);  // transform from view to world

  vec3 bg = mix(BONE_COLOR*0.5, BONE_COLOR, smoothstep(-1.0, 1.0, uv.y));
  vec3 col = bg;

  vec3 p=ro; 

  int iter = 0;
  
  float t = intersect(ro, rd, iter);
    
  if(t > -0.5) {
    p = ro + t * rd;
    col = lighting(p, rd, iter);
    col = mix(col, bg, 1.0-exp(-0.001*t*t)); 
  } 
    

  col=post(col, q);
  fragColor=vec4(col.x,col.y,col.z,1.0); 
}
