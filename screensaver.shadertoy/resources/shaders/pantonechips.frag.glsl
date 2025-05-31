precision highp float; // Added precision directive for GLSL ES 1.0

// CC0: Pretty sweet colors
//  I watched a YT (https://www.youtube.com/watch?v=pG0t19bEYJw), didn't remember anything except I thought
//  the colors and shapes were pretty sweet around 0:09 in the video. So improvised a shader around it.
//  Unfortunately in chromium (Chrome, Edge etc) the colors for me looks dull and boring. Hopefully it's ok for you.
//  In FF it looks right though.

//#define CURSOR // Kept as a define, but might need manual removal if still causing issues

#define TIME        iTime*.4
#define RESOLUTION  iResolution

#define PI          3.141592654
#define PI_2        (0.5*3.141592654)
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// --- BCS Parameters ---
#define BRIGHTNESS 0.0 // Adjust from -1.0 to 1.0
#define CONTRAST 1.02   // Adjust from 0.0 upwards
#define SATURATION 1.05 // Adjust from 0.0 upwards
// ----------------------

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
// This sRGB function is no longer used for the final output color, as per user request for exact colors.
float sRGB(float t) { return mix(1.055*pow(t, 1.0/2.4) - 0.055, 12.92*t, step(t, 0.0031308)); } // Explicit float for 1.0, 2.4, 0.055, 12.92, 0.0031308
vec3 sRGB(in vec3 c) { return vec3 (sRGB(c.x), sRGB(c.y), sRGB(c.z)); }

// Function to adjust brightness, contrast, and saturation
vec3 adjustBCS(vec3 color) {
    // Brightness
    color += BRIGHTNESS;

    // Contrast
    vec3 avg = vec3(0.2126, 0.7152, 0.0722);
    color = mix(avg, color, vec3(CONTRAST));

    // Saturation
    vec3 gray = vec3(dot(color, avg));
    color = mix(gray, color, vec3(SATURATION));

    return color;
}

float plane(vec2 p, vec3 pl) {
  return dot(p, pl.xy) + pl.z;
}

vec2 toSmith(vec2 p)  {
  // z = (p + 1)/(-p + 1)
  // (x,y) = ((1+x)*(1-x)-y*y,2y)/((1-x)*(1-x) + y*y)
  float d = (1.0 - p.x)*(1.0 - p.x) + p.y*p.y; // Explicit float for 1.0
  float x = (1.0 + p.x)*(1.0 - p.x) - p.y*p.y; // Explicit float for 1.0
  float y = 2.0*p.y; // Explicit float for 2.0
  return vec2(x,y)/d;
}

vec2 fromSmith(vec2 p)  {
  // z = (p - 1)/(p + 1)
  // (x,y) = ((x+1)*(x-1)+y*y,2y)/((x+1)*(x+1) + y*y)
  float d = (p.x + 1.0)*(p.x + 1.0) + p.y*p.y; // Explicit float for 1.0
  float x = (p.x + 1.0)*(p.x - 1.0) + p.y*p.y; // Explicit float for 1.0
  float y = 2.0*p.y; // Explicit float for 2.0
  return vec2(x,y)/d;
}

// --- GLSL ES 1.0 Compatible Array Declaration and Initialization ---
// Declare as a non-const global array with a fixed size.
// Initialize elements in mainImage.
#define NO_OF_BCOLS 8 // Define the size as a constant
vec3 bcols[NO_OF_BCOLS];
// ------------------------------------------------------------------

vec2 transform(vec2 p, float i) {
  float tm = TIME*0.2; // Explicit float for 0.2
  float ii = i/float(NO_OF_BCOLS); // Use NO_OF_BCOLS
  float f =sin(3.0*p.y+2.1*i+tm); // Explicit float for 3.0, 2.1
  vec2 sp = toSmith(p);
//  sp.y -= 0.1*i+0.9*sin(+0.1*i);
  sp *= ROT(0.1*i+tm); // Explicit float for 0.1
  sp *= ROT(mix(0.0, 0.2, ii)*f); // Explicit float for 0.0, 0.2
//  p.x += 0.08*f;
  p = fromSmith(sp);;
  return p;
}

float df(vec2 p, float i) {
  // Original plane distance calculation: 0.2*i-0.3
  // Smaller 'i' values result in planes closer to the camera (more negative SDF).
  return plane(p, vec3(normalize(-vec2(1.0, 1.0)), 0.2*i-0.3)); // Explicit float for 1.0, 0.2, 0.3
}

vec3 effect(vec2 p, vec2 np) {
  float aaa = 2.0/RESOLUTION.y;
  // Initialize 'col' with the first color of the palette (bcols[0]).
  // This color will serve as the background or the furthest layer.
  vec3 col = bcols[0];

  // Loop from the second color (index 1) to the last.
  // The loop variable 'i' directly corresponds to the palette index and the visual layer index.
  // This ensures bcols[1] is applied to the first visible plane, bcols[2] to the second, etc.
  for (int i = 1; i < NO_OF_BCOLS; ++i) {
    float current_plane_idx = float(i); // Use 'i' directly for transform and df

    vec2 pp    = transform(p, current_plane_idx);
    vec2 npp   = transform(np, current_plane_idx);
    float aa   = distance(pp, npp)*sqrt(0.5); // Re-introduced aa calculation for smoothstep and shadow
    float d    = df(pp, current_plane_idx); // Use the current_plane_idx for distance calculation

    // Reintroduce the darkening/shadowing mix operation.
    // This applies a darkening effect to the 'col' (which contains layers further away)
    // based on the distance 'd' to the current plane.
    // '0.33' can be adjusted for shadow intensity.
    col = mix(col, col * 0.33, exp(-max(10.0 * d * aaa / aa, 0.0)));

    // Mix in the current plane's color.
    // 'bcols[i]' is the color for the current plane in the order specified by the user.
    // 'smoothstep' creates the soft transition at the edge of the plane.
    col = mix(col, bcols[i], smoothstep(aa, -aa, d));
  }

  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // --- Color Palette Toggle ---
  // Set to 0 for Custom Palette 1
  // Set to 1 for Custom Palette 2
  // Set to 2 for Custom Palette 3
  #define COLOR_PALETTE_MODE 1 // Change this value to switch between palettes
  // ----------------------------

  // --- Initialize bcols array in mainImage based on COLOR_PALETTE_MODE ---
  #if COLOR_PALETTE_MODE == 0
      // Custom Palette 1
      bcols[0] = vec3(0.1647, 0.2549, 0.3020); // #2a414d
      bcols[1] = vec3(0.2235, 0.3176, 0.3569); // #39515b
      bcols[2] = vec3(0.2784, 0.3765, 0.4078); // #476068
      bcols[3] = vec3(0.4392, 0.4314, 0.3490); // #706e59
      bcols[4] = vec3(0.6118, 0.6471, 0.5922); // #9ca597
      bcols[5] = vec3(0.7843, 0.8588, 0.8314); // #c8dbd4
      bcols[6] = vec3(0.8314, 0.7843, 0.7020); // #d4c8b3
      bcols[7] = vec3(1.0000, 1.0000, 1.0000); // #ffffff
  #elif COLOR_PALETTE_MODE == 1
      // Custom Palette 2
      bcols[0] = vec3(0.7804, 0.3216, 0.1647); // #c7522a
      bcols[1] = vec3(0.8980, 0.7569, 0.5216); // #e5c185
      bcols[2] = vec3(0.9412, 0.8549, 0.6471); // #f0daa5
      bcols[3] = vec3(0.9843, 0.9490, 0.7686); // #fbf2c4
      bcols[4] = vec3(0.7216, 0.8039, 0.6706); // #b8cdab
      bcols[5] = vec3(0.4549, 0.6588, 0.5725); // #74a892
      bcols[6] = vec3(0.0000, 0.5216, 0.5216); // #008585
      bcols[7] = vec3(0.0000, 0.2627, 0.2627); // #004343
  #else // COLOR_PALETTE_MODE == 2
      // Custom Palette 3
      bcols[0] = vec3(0.0980, 0.1176, 0.0471); // #191e0c
      bcols[1] = vec3(0.2039, 0.2431, 0.0980); // #343e19
      bcols[2] = vec3(0.3098, 0.3647, 0.1490); // #4f5d26
      bcols[3] = vec3(0.4157, 0.4902, 0.2000); // #6a7d33
      bcols[4] = vec3(0.5176, 0.6157, 0.2510); // #849d40
      bcols[5] = vec3(0.6235, 0.7412, 0.3020); // #9fbd4d
      bcols[6] = vec3(0.7294, 0.8667, 0.3529); // #badd5a
      bcols[7] = vec3(0.8353, 0.9922, 0.4039); // #d5fd67
  #endif
  // ---------------------------------------------------

  vec2 q  = fragCoord/RESOLUTION.xy;
  vec2 p  = -1.0 + 2.0*q; // Explicit float for -1.0, 2.0
  p.x     *= RESOLUTION.x/RESOLUTION.y;
  vec2 np = p + 2.0/RESOLUTION.y; // Explicit float for 2.0

  vec3 col = effect(p, np);
  col = adjustBCS(col); // Apply Brightness, Contrast, Saturation
  // Removed sRGB(col) to ensure exact color output as per user request.
  fragColor = vec4(col, 1.0); // Explicit float for 1.0
}
