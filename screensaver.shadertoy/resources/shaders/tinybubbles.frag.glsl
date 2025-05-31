// CCO: Colorful underwater bubbles II
//  Recoloring of earlier shader + spherical shading

#define TIME        iTime*.8
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
const float MaxIter = 12.0;

// Fine-tuning parameters
#define GAMMA       0.70    // Adjust gamma (e.g., 1.8 to 2.2 for darker, 1.5 for brighter)
#define BRIGHTNESS  0.8    // Adjust brightness (e.g., 0.7 to 1.0, lower for darker)
#define SATURATION  1.1    // Adjust saturation (e.g., 1.0 to 1.5, higher for more vibrant)

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

// License: Unknown, author: Unknown, found: don't remember
float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

vec4 plane(vec2 p, float i, float zf, float z, vec3 bgcol) {
  float sz = 0.5*zf;
  vec2 cp = p;
  vec2 cn = mod2(cp, vec2(2.0*sz, sz));
  float h0 = hash(cn+i+123.4);
  float h1 = fract(4483.0*h0);
  float h2 = fract(8677.0*h0);
  float h3 = fract(9677.0*h0);
  float h4 = fract(7877.0*h0);
  float h5 = fract(9967.0*h0);
  if (h4 < 0.5) {
    return vec4(0.0);
  }
  float fi = exp(-0.25*max(z-2.0, 0.0));
  float aa = mix(0.0125, 2.0/RESOLUTION.y, fi); 
  float r  = sz*mix(0.1, 0.475, h0*h0);
  float amp = mix(0.5, 0.5, h3)*r;
  cp.x -= amp*sin(mix(3.0, 0.25, h0)*TIME+TAU*h2);
  cp.x += 0.95*(sz-r-amp)*sign(h3-0.5)*h3;
  cp.y += 0.475*(sz-2.0*r)*sign(h5-0.5)*h5;
  float d = length(cp)-r;
  if (d > aa) {
    return vec4(0.0);
  }
  // Introduce purple tones alongside yellow-amber
  vec3 phase = h1 < 0.3 ? vec3(1.0, 0.0, 2.0) : vec3(2.0, 1.5, 0.0); // 30% chance of purple, 70% yellow-amber
  vec3 ocol = (0.5 + 0.5 * sin(phase + h1 * TAU));
  vec3 icol = sqrt(ocol);
  ocol *= 1.3; // Balance brightness
  icol *= 1.8; // Balance highlight brightness
  const vec3 lightDir = normalize(vec3(1.0, 1.5, 2.0));
  float z2 = (r*r-dot(cp, cp));
  vec3 col = ocol;
  float t = smoothstep(aa, -aa, d); // Base edge transparency
  if (z2 > 0.0) {
    float z = sqrt(z2);
    t *= mix(1.0, 0.8, z/r); // Initial depth adjustment (optional)
    // Corrected realistic transparency: more transparent at center, less at edges
    #define TRANSPARENCY_FACTOR 0.03  // Adjust to control transparency strength (e.g., 1.0 to 2.0)
    #define THICKNESS_POWER 7.0      // Adjust to control falloff curve (e.g., 1.0 to 3.0)
    float thickness = pow(1.0 - z/r, THICKNESS_POWER); // Higher at edges, lower at center
    t = t * (1.0 - (1.0 - thickness) * TRANSPARENCY_FACTOR); // Decrease transparency at edges
    t = clamp(t, 0.0, 1.0); // Ensure t stays within valid range
    vec3 pp = vec3(cp, z);
    vec3 nn = normalize(pp);
    float dd = max(dot(lightDir, nn), 0.0);
    float spec = pow(dd, 10.0); // Retain glossy highlight
    col = mix(ocol, icol, spec);
  }
  col *= mix(0.8, 1.0, h0);
  col = mix(bgcol, col, fi);
  return vec4(col, t);
}

// License: Unknown, author: Claude Brezinski, found: https://mathr.co.uk/blog/2017-09-06_approximating_hyperbolic_tangent.html
float tanh_approx(float x) {
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// Saturation adjustment function
vec3 adjustSaturation(vec3 color, float saturation) {
    vec3 luminance = vec3(0.299, 0.587, 0.114); // Standard luminance weights
    float lum = dot(color, luminance);
    return mix(vec3(lum), color, saturation);
}

vec3 effect(vec2 p, vec2 pp) {
  const vec3 bgcol0 = vec3(0.1, 0.0, 1.0) * 0.08; // Restore dark blue background (center)
  const vec3 bgcol1 = vec3(0.0, 0.4, 1.0) * 0.5;  // Restore lighter blue background (edges)
  vec3 bgcol = mix(bgcol1, bgcol0, tanh_approx(1.5*length(p)));
  vec3 col = bgcol;

  for (float i = 0.0; i < MaxIter; ++i) {
    const float Near = 4.0;
    float z = MaxIter - i;
    float zf = Near/(Near + MaxIter - i);
    vec2 sp = p;
    float h = hash(i+1234.5); 
    sp.y += -mix(0.2, 0.3, h*h)*TIME*zf;
    sp += h;
    vec4 pcol = plane(sp, i, zf, z, bgcol);
    col = mix(col, pcol.xyz, pcol.w);
  }
  col *= smoothstep(1.5, 0.5, length(pp));
  col = clamp(col, 0.0, 1.0);
  col = adjustSaturation(col, SATURATION); // Apply saturation adjustment
  col = pow(col, vec3(1.0 / GAMMA)) * BRIGHTNESS; // Apply gamma and brightness
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p, pp);
  fragColor = vec4(col, 1.0);
}


/*

    #define TRANSPARENCY_FACTOR 0.03  // Adjust to control transparency strength (e.g., 1.0 to 2.0)
    #define THICKNESS_POWER 7.0      // Adjust to control falloff curve (e.g., 1.0 to 3.0)

*/