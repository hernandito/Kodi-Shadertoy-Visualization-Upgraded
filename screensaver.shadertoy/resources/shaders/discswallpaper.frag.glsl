// License CC0: BubbleSort in 2022?
// I saw a tweet from hexler with some neat circle based shader
// Made a try to recreate it. Although not the same I think the result
// turned out neat
// WRT bubblesort. I do a bubble sort to sort the the circle heights.
// I am open for better ideas!


#define TIME        iTime*.25
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))


vec2 mod2_1(inout vec2 p) {
  p += 0.5;
  vec2 n = floor(p);
  p = fract(p)-0.5;
  return n;
}

// License: Unknown, author: Unknown, found: don't remember
vec2 hash(vec2 p) {
  p = vec2(dot (p, vec2 (127.1, 311.7)), dot (p, vec2 (269.5, 183.3)));
  return -1. + 2.*fract (sin (p)*43758.5453123);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
vec3 alphaBlend(vec3 back, vec4 front) {
  // Based on: https://en.wikipedia.org/wiki/Alpha_compositing
  return mix(back, front.xyz, front.w);
}

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

float cellhf(vec2 n) {
  float h = texture(iChannel0, 0.005*n+0.5).x;
  h = sqrt(h);
  h = smoothstep(0.1, 0.85, h);
  return h;
}

float celldf(vec2 p, vec2 n) {
  vec2 h = hash(n);
  const float off = 0.25;
  p += off*h;
  float dd = length(p) - (sqrt(0.5)+off);
  return dd;
}

// --- Post-processing functions for better output control (BCS) ---
vec4 saturate(vec4 color, float sat) {
    // Adjusts color saturation
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    // Applies brightness, contrast, and saturation adjustments
    color.rgb = (color.rgb - 0.5) * contrast + 0.5; // Use 0.5 for clarity
    color.rgb *= brightness;
    return saturate(color, saturation);
}
// -----------------------------------------------------------------

// --- Post-processing Parameters (BCS) ---
// Adjust these values to fine-tune the final image appearance
float post_brightness = 0.40; // Decreased for darker output
float post_contrast = 1.0;   // Neutral contrast
float post_saturation = 0.0; // Set to 0.0 for grayscale
// ----------------------------------------


vec3 effect(vec2 p) {
  const float sz = 0.25;
  const float amp = 10.0;
  const float th = -TAU*sz*20.0;
  p += amp*cos(vec2(1.0, sqrt(0.5))*TAU*(TIME)/(amp*30.0));
  vec2 op = p;
  p /= sz;
  float aa = 2.0/(sz*RESOLUTION.y);
  vec2 n = mod2_1(p);

  const int c = 1;
  const int l = (2*c+1)*(2*c+1);
  vec2 results[l];
  int j = 0;
  for (int x = -c; x <= c; ++x) {
    for (int y = -c; y <= c; ++y) {
      vec2 off = vec2(float(x), float(y));
      vec2 pp = p - off;
      vec2 nn = n + off;

      float d = celldf(pp, nn);
      float h = cellhf(nn);

      results[j] = vec2(d, h);
      ++j;
    }
  }

  // Bubble sort in 2022?
  for (int o = 1; o < l; ++o) {
    for (int i = o; i > 0; --i) {
      vec2 l_val = results[i-1]; // Renamed to avoid conflict with loop variable 'l'
      vec2 r_val = results[i];   // Renamed to avoid conflict with loop variable 'r'
      if (l_val.y > r_val.y) {
        results[i - 1] = r_val;
        results[i] = l_val;
      }
    }
  }

  vec3 col = vec3(0.0);
  for (int i = 0; i < l; ++i) {
      vec2 r_val = results[i]; // Renamed to avoid conflict with loop variable 'r'
      float d = r_val.x;
      float h = r_val.y;

      // --- Color Palette Adjustment for Grayscale Look ---
      // Eliminating color cycling and setting to grayscale tones
      vec4 bcol0 = vec4(hsv2rgb(vec3(0.0,          // Hue: Constant (doesn't matter for grayscale)
                                     0.0,          // Saturation: 0.0 for grayscale
                                     mix(0.1, 0.6, h))), 1.0); // Value: maps 'h' (from texture) to dark/light gray range
      // ---------------------------------------------------

      vec4 bcol1 = vec4(vec3(bcol0*bcol0*0.25), 0.5);
      vec4 bcol = mix(bcol0, bcol1, smoothstep(-th*aa, th*aa, sin(th*d)));
      float t_local = smoothstep(aa, -aa, d); // Renamed to avoid conflict with global 't'
      vec4 ccol = bcol;
      ccol.w *= t_local;


      col *= mix(1.0, 0.25, exp(-10.0*max(d, 0.0)));
      col = alphaBlend(col, ccol);
  }
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p);
  col = clamp(col, 0.0, 1.0);
  col *= smoothstep(0.0, 4.0, TIME);
  col = sqrt(col);

  // --- Apply Post-processing (BCS) ---
  fragColor = applyPostProcessing(vec4(col, 1.0), post_brightness, post_contrast, post_saturation);
  // -----------------------------------

  // Final clamp to ensure valid output range
  fragColor = clamp(fragColor, 0.0, 1.0); // Ensure final output is clamped
}
