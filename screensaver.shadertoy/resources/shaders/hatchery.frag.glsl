// === Adjustable Brightness, Contrast, Saturation ===
#define BRIGHTNESS   -0.350    // default: 0.0, range: [-1.0 to 1.0]
#define CONTRAST     1.150    // default: 1.0, range: [0.0 to 3.0]
#define SATURATION   0.850    // default: 1.0, range: [0.0 to 3.0]

#define RESOLUTION  iResolution
#define TIME        iTime*.5

#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

const int   max_iter = 70;

// Signed distance function helpers...
float box(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

vec2 modMirror2(inout vec2 p, vec2 size) {
  vec2 halfsize = size*0.5;
  vec2 c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  p *= mod(c,vec2(2))*2.0 - vec2(1.0);
  return c;
}

float apollonian(vec3 p, out float ss) {
  float s = mix(1.4, 1.45, smoothstep(0.9, 1.0, sin(-length(p.xz)+TAU*TIME/10.0)));
  float scale = 1.5;

  const int rep = 5;
  mat2 rr = ROT(PI/5.5);

  for(int i=0; i<rep; ++i) {
    mod1(p.y, 2.0);
    modMirror2(p.xz, vec2(2.0));
    p.xz *= rr;
    float r2 = dot(p,p);
    float k = s/r2;
    p *= k;
    scale *= k;
  }

  float d = -(box(p - 0.1, vec3(1.0, 2.0, 1.)) - 0.6);
  ss = scale;
  return 0.25*d/scale;
}

vec3 glow(vec3 ro, vec3 rd) {
  float res;
  float t = .75;
  int iter = max_iter;

  vec3 col = vec3(0.0);    
  for(int i = 0; i < max_iter; ++i) {
    vec3 p = ro + rd * t;
    float ss;
    res = apollonian(p, ss);
    col += 0.06*(0.5+0.5*cos(3.0+vec3(1.0, 2.0, 3.0)+0.8*log(ss)))*exp(-0.05*t-.5*res*float(i*i));
    if(res < 0.0003 * t || res > 20.) {
      iter = i;
      break;
    }
    t += res;
  }
  return col;
}

vec3 render(vec2 p) {
  vec3 ro = 1.2*vec3(-1.0, .8, -0.0);
  ro.xz *= ROT(TIME/10.0);
  const vec3 la = vec3(0.0, 1.6, 0.0);
  vec3 ww = normalize(la-ro);
  vec3 uu = normalize(cross(vec3(0.0,1.0,0.0), ww ));
  vec3 vv = normalize(cross(ww,uu));
  const float fov = 3.0;
  vec3 rd = normalize(-p.x*uu + p.y*vv + fov*ww );
  return glow(ro, rd);
}

// === Post-processing: Brightness, Contrast, Saturation ===
vec3 adjustBCS(vec3 color) {
  // Brightness
  color += BRIGHTNESS;

  // Contrast
  color = (color - 0.5) * CONTRAST + 0.5;

  // Saturation
  float gray = dot(color, vec3(0.299, 0.587, 0.114)); // Luma
  color = mix(vec3(gray), color, SATURATION);

  return clamp(color, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q  = fragCoord / RESOLUTION.xy;
  vec2 p  = -1.0 + 2.0*q;
  p.x    *= RESOLUTION.x / RESOLUTION.y;

  vec3 col = render(p);

  col -= 0.1*vec3(1.0, 2.0, 0.5);
  col = clamp(col, 0.0, 0.8);
  col = sqrt(col);  // gamma correction

  // Apply BCS post-processing
  col = adjustBCS(col);

  fragColor = vec4(col, 1.0);
}
