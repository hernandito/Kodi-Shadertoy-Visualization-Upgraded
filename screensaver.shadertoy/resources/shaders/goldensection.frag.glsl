// CC0: Infinite boxy spiral
// Finally I used golden ratio in code after learning about 30 years ago

#define TIME        iTime
#define RESOLUTION  iResolution
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

const float
  pi = acos(-1.)
, tau= pi*2.
, phi= (1.+sqrt(5.))*0.5
;

float circle(vec2 p, float r) {
  return length(p)-r;
}

float superCircle8(vec2 p, float r) {
  p *= p;
  p *= p;
  return pow(dot(p,p), 1./8.)-r;
}

vec3 palette(float a) {
  return 0.5*(1.+sin(vec3(0.,1.,2.)+a));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = vec3(0.0);

  float d = 1E3;

  float anim = TIME*0.5;
  float ft = fract(anim);
  float nt = floor(anim);
  const float stp = 0.0125;
  float bsz = stp;
  vec2 off = vec2(phi+1., phi-1.)*stp;
  float iz = exp2(log2(phi)*ft);
  vec2 ip = p;
  ip /= iz; 
  ip *= ROT(-nt*tau/4.);
  // Offset derived by trial and error
  ip -= -vec2(0.45,1.35)*stp;
  float hit = 0.;
  float dhit = 1E3;
  float dc = 0.;
  const float nhit = 13.;
  for (float i = 0.; i < nhit; ++i) {
    float id = superCircle8(ip, bsz-2E-3/iz);
    float ic = circle(ip,bsz);
    ip -= off;
    bsz *= phi;
    off = phi*vec2(-off.y,off.x);
    if (id < dhit) {
      dhit = id;
      hit = i;
      dc = ic;
    }
    id *= iz;
    d = min(d, id);
  }
  float fade = 1.;
  if (hit == 0.) {
    fade = ft;
  }
  hit -= nt;
  float aa = sqrt(2.)/RESOLUTION.y;
  vec3 bcol = fade*(palette(hit*0.5)-0.3*dc*iz);
  col = mix(col, bcol, smoothstep(aa, -aa, d));
  /*
  vec2 ap = abs(p);
  float ad = min(ap.x, ap.y)-3E-3;
  col = mix(col, vec3(1.), smoothstep(aa, -aa, ad));
  */
  col = sqrt(col);
  
  fragColor = vec4(col, 1.0);
}


