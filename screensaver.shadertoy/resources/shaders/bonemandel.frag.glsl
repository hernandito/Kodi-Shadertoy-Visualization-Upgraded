// Based upon: https://www.shadertoy.com/view/XdlSD4

// I always liked mandelbox_ryu made by EvilRyu
// Was tinkering a bit with the code and came up with this which at least I liked.

// Uses very simple occlusion based lighting which made it look more like a structure
// of bones than my other futile lighting attemps.

// --- PARAMETERS FOR ADJUSTMENT ---
// Adjust the Brightness, Contrast, and Saturation of the final image.
// Default values maintain the original look.
#define BRIGHTNESS 0.85
#define CONTRAST_FACTOR 0.2
#define SATURATION_FACTOR -0.5

// Adjust the color of the main bone-like structure.
// Default is a bone-like color: vec3(0.89, 0.855, 0.788).
#define BONE_COLOR vec3(0.878, 0.82, 0.706)

const float fixed_radius2 = 1.9;
const float min_radius2   = 0.5;
const vec3  folding_limit = vec3(1.0);
const float scale         = -2.8;
const int   max_iter      = 120;
// Replaced the 'bone' const with a define parameter
// const vec3  bone          = vec3(0.89, 0.855, 0.788);

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

vec3 pmin(vec3 a, vec3 b, vec3 k) {
  vec3 h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0);
  
  return mix(b, a, h) - k*h*(1.0-h);
}

void box_fold(float k, inout vec3 z, inout float dz) {
  // Soft clamp after suggestion from ollij
  vec3 zz = sign(z)*pmin(abs(z), folding_limit, vec3(k));
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
    const float k = 0.05;
    for(int n = 0; n < 5; ++n) {
        box_fold(k/dr, z, dr);
        sphere_fold(z, dr);
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
    float d1 = mb(p);
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
    // BCS Adjustments
    col=pow(clamp(col,0.0,1.0),vec3(BRIGHTNESS)); 
    col=col*CONTRAST_FACTOR+(1.0-CONTRAST_FACTOR)*col*col*(3.0-2.0*col); // contrast
    col=mix(col, vec3(dot(col, vec3(0.33))), SATURATION_FACTOR); // satuation
    col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )  { 
    vec2 q=fragCoord.xy/iResolution.xy; 
    vec2 uv = -1.0 + 2.0*q; 
    uv.x*=iResolution.x/iResolution.y; 
    
    float stime=sin(iTime*0.03); 
    float ctime=cos(iTime*0.03); 

    vec3 ta=vec3(0.0,0.0,0.0); 
    vec3 ro= 0.63*vec3(3.0*stime,2.0*ctime,5.0+1.0*stime);
    vec3 cf = normalize(ta-ro); 
    vec3 cs = normalize(cross(cf,vec3(0.0,1.0,0.0))); 
    vec3 cu = normalize(cross(cs,cf)); 
    vec3 rd = normalize(uv.x*cs + uv.y*cu + 2.8*cf);  // transform from view to world

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
