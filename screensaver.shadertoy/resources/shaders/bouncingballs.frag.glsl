// CC0: Gravity sucks
//  Tinkering away....

#define LAYERS      1.0
#define SCALE       1.0

#define TIME        iTime*.2
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)

#define REFLECTION_STRENGTH 0.05    // 0.0 (none) to 1.0 (fully bright mirror-like)
#define REFLECTION_BLUR_AMOUNT 0.15 // Higher = blurrier reflection falloff

// --- Post-processing functions for better output control (BCS) ---
vec4 saturate(vec4 color, float sat) {
    // Adjusts color saturation
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    // Applies brightness, contrast, and saturation adjustments
    // Contrast: (color - 0.5) * contrast + 0.5
    // Brightness: result * brightness
    color.rgb = (color.rgb - 0.5) * contrast + 0.5; // Use 0.5 for clarity
    color.rgb *= brightness;
    return saturate(color, saturation);
}
// -----------------------------------------------------------------

// --- Post-processing Parameters (BCS) ---
// Adjust these values to fine-tune the final image appearance.
// These are 'const float' values, which means you edit them directly in the code.
// No need for external sliders or JSON configuration for these.
const float brightness = 1.40; // Controls overall lightness/darkness. Recommended start: 1.0
const float contrast   = 1.0; // Controls difference between light/dark areas. Recommended start: 1.0
const float saturation = 1.50; // Controls color intensity/purity. Recommended start: 1.0
// ----------------------------------------


float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

float mod1(inout float p, float size) {
  float halfsize = size*.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

float bounce(float t, float dy, float dropOff) {
  const float g = 5.0; // Explicit float
  float p0 = 2.0*dy/g; // Explicit float

  t += p0/2.0; // Explicit float
    
  float ldo = log(dropOff);
    
  float yy = 1.0 - (1.0 - dropOff) * t / p0; // Explicit float

  if (yy > 0.0001)  { // Explicit float
    float n  = floor(log(yy) / ldo);
    float dn = pow(dropOff, n);

    float yyy = dy * dn;
    t -= p0 * (1.0 - dn) / (1.0 - dropOff); // Explicit float

    return -0.5*g*t*t + yyy*t; // Explicit float

  } else {
      return 0.0; // Explicit float
  }
}

vec3 ball(vec3 col, vec2 pp, vec2 p, float r, float pal) {
  const vec3 ro = vec3(0.0, 0.0, 10.0); // Explicit float
  const vec3 difDir = normalize(vec3(1.0, 1.5, 2.0)); // Explicit float
  const vec3 speDir = normalize(vec3(1.0, 2.0, 1.0)); // Explicit float
  vec3 p3 = vec3(pp, 0.0); // Explicit float
  vec3 rd = normalize(p3-ro);
  
  vec3 bcol = 0.5+0.5*sin(0.5*vec3(0.0, 1.0, 2.0)+TAU*pal); // Explicit float
  float aa = sqrt(8.0)/RESOLUTION.y; // Explicit float
  float z2 = (r*r-dot(p, p));
  if (z2 > 0.0) { // Explicit float
    float z = sqrt(z2);
    vec3 cp = vec3(p, z);
    vec3 cn = normalize(cp);
    vec3 cr = reflect(rd, cn);
    float cd= max(dot(difDir, cn), 0.0); // Explicit float
    float cs= 1.008-dot(cr, speDir); // Explicit float
    
    vec3 ccol = mix(0.1, 1.0, cd*cd)*bcol+sqrt(bcol)*(0.01/cs); // Explicit float for 0.1, 1.0, 0.01
    float d = length(p)-r;
    col = mix(col, ccol, smoothstep(0.0, -aa, d)); // Explicit float for 0.0
  }
  
  return col;
}


vec3 effect(vec2 p) {
  p.y += 0.5; // Explicit float
  float sy = sign(p.y);
  p.y = abs(p.y);
  if (sy < 0.0) { // Explicit float
    p.y *= 1.5; // Explicit float
  }

  vec3 col = vec3(0.0); // Explicit float
  float aa = sqrt(4.0)/RESOLUTION.y; // Explicit float
  for (float i = 0.0; i < LAYERS; ++i) { // Explicit float
    float h0 = hash(i+123.4); // Explicit float
    float h1 = fract(8667.0*h0); // Explicit float
    float h2 = fract(8707.0*h0); // Explicit float
    float h3 = fract(8887.0*h0); // Explicit float
    float tf = mix(0.5, 1.5, h3); // Explicit float
    float it = tf*TIME;
    float cw = mix(0.25, 0.75, h0*h0)*SCALE; // Explicit float
    float per = mix(0.75, 1.5, h1*h1)*cw; // Explicit float
    vec2 p0 = p;
    float nt = floor(it/per);
    p0.x -= cw*(it-nt*per)/per;
    float n0 = mod1(p0.x, cw)-nt;
    if (n0 > -7.0-i*3.0) continue; // Explicit float
    float ct = it+n0*per;

    float ch0 = hash(h0+n0);
    float ch1 = fract(8667.0*ch0); // Explicit float
    float ch2 = fract(8707.0*ch0); // Explicit float
    float ch3 = fract(8887.0*ch0); // Explicit float
    float ch4 = fract(9011.0*ch0); // Explicit float

    float radii = cw*mix(0.25, 0.5, ch0*ch0); // Explicit float
    float dy = mix(3.0, 2.0, ch3); // Explicit float
    float bf = mix(0.6, 0.9, ch2); // Explicit float
    float b = bounce(ct/tf+ch4, dy, bf);
    p0.y -= b+radii;
    col = ball(col, p, p0, radii, ch1);
  }
  
  if (sy < 0.0) { // Explicit float
    float blur = exp(-p.y * REFLECTION_BLUR_AMOUNT);
    vec3 reflectionTint = vec3(0.05, 0.1, 0.2); // Explicit float
    col *= reflectionTint;
    col *= REFLECTION_STRENGTH * blur;
    col += 0.1 * vec3(0.0, 0.0, 1.0) * max(p.y * p.y, 0.0); // Explicit float
  }
  
  col = sqrt(col);
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1.0 + 2.0 * q; // Explicit float
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p);
  fragColor = vec4(col, 1.0); // Explicit float

  // --- Apply Post-processing (BCS) ---
  // Adjust the 'brightness', 'contrast', and 'saturation' values
  // directly above in the 'const float' declarations.
  fragColor = applyPostProcessing(fragColor, brightness, contrast, saturation);
  // -----------------------------------
}
