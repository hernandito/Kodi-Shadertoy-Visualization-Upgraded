// CC0: Levels jerry, levels!
// Created on a bus trip last week (good seats and power outlets).
// Felt a bit meh at the time but looking at it today I felt it good enough to share 

#define TIME        iTime*.2
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

vec3 layerColor(float n) {
  return 0.75*(1.0+cos(1.2*vec3(0.0, 1.0, 2.0)+0.2*n-TIME));
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float dcross(vec2 p, vec2 b, float r )  {
  p = abs(p); p = (p.y>p.x) ? p.yx : p.xy;
  vec2  q = p - b;
  float k = max(q.y,q.x);
  vec2  w = (k>0.0) ? q : vec2(b.y-p.x,-k);
  return sign(k)*length(max(w,0.0)) + r;
}

float df(vec2 pp, float n) {
  float r = 0.0035*(n*n)+0.35;
  float nn = 4.0;
  return dcross(pp,r*vec2(2.0, 0.75), 0.3*r)-0.2*r;
}

vec3 effect(vec2 p, vec2 pp) {
  float lum = 0.125/max(length(p), 0.1);
  vec3 col = vec3(0.1, 0.2, 1.0)*lum;
  
  p *= ROT(0.1*TIME);
  
  float aa = 4.0/RESOLUTION.y;
  
  for (float n = 0.0; n < 12.0; ++n) {
    const float soff = 0.0125;
    float nn = 4.0;
    mat2 rot = ROT(0.5*PI*sin(0.25*TIME-0.1*n)*cos(-0.123*TIME+0.123*n));
    vec2 pp = p;
    pp *= rot;
    vec2 sp = p+vec2(0.0, soff);
    sp *= rot;
    float dd = df(pp, n);
    float sdd = df(sp, n);
    
    col *= mix(0.333, 1.0, smoothstep(0.0, 0.3, sqrt(max(-sdd+soff, 0.0))));
    vec3 dcol = layerColor(n);
    col = mix(col, dcol, smoothstep(0.0, -aa, -dd)); 
  }
  
  vec2 cpp = pp-vec2(0.0, 0.25);
  col -= 0.1*vec3(1.0, 2.0, 3.0).yzx*length(cpp);
  col *= smoothstep(2.0, 0.5, length(cpp));  
  col = sqrt(col);
  return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p, pp);
  fragColor = vec4(col, 1.0);
}
