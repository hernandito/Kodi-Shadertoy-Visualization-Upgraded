// CC0: Second attempt to fake Wave Function Collapse
// I watched Coding Challenge 171: Wave Function Collapse: https://www.youtube.com/watch?v=rI_y2GAlQFM
// The algorithm AFAIK doesn't fit shader world that well.
// But I thought I could fake it.
// So randomizing rotations of out a 6 shapes in all grid tiles that don't touch each other
// Then in the connecting grid tiles I select a shape to match the surrounding randomized cells

// I thought it was a bit interesting and a bit different from how I usually do when doing truchet patterns so I shared

// See only the randomized tiles
//#define RANDOMIZED_TILES_ONLY

// See the debugging dots
//#define DEBUG_DOTS

#define TIME        iTime*.3
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// License: Unknown, author: Unknown, found: don't remember
float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

const float linew = 0.02;
const float circle = 0.1;

float halfPlane(vec2 p) {
  float d0 = length(p);
  float d1 = abs(p.x);
  return p.y < 0.0 ? d0 : d1;
}

float cell0(vec2 p) {
  float d0 = abs(p.x);
  float d1 = abs(p.y);
  float d2 = length(p)-circle;
  float d = min(d0, d1);
  d = min(d, d2);
  d = max(d, -d2);
  d -= linew;
  return d;
}

float cell2_corner(vec2 p) {
  float d0 = length(p-0.5)-0.5;
  float d = d0;
  d = abs(d);
  d -= linew;
  return d;
}

float cell2_line(vec2 p) {
  float d0 = abs(p.y);
  float d = d0;
  d -= linew;
  return d;
}

float cell1(vec2 p) {
  float d0 = abs(p.x);
  float d1 = abs(p.y);
  float d2 = length(p)-circle;
  float d = 
    p.x > 0.0
    ? min(d0, d1)
    : d0
    ;
  d = min(d, d2);
  d = max(d, -d2);
    
  d -= linew;
  return d;
}

float cell3(vec2 p) {
  float d0 = halfPlane(p);
  float d2 = length(p)-circle;
  float d = d0;
  d = min(d, d2);
  d = max(d, -d2);
  d -= linew;
  return d;
}

float cell4(vec2 p) {
  float d = length(p)-circle;
  d = abs(d);
  d -= linew;
  return d;
}

// Function to simulate distribution array
int getDistribution(int index) {
  if (index == 0) return 0;
  else if (index == 1 || index == 2) return 1;
  else if (index >= 3 && index <= 7) return 2;
  else if (index >= 8 && index <= 12) return 3;
  else if (index == 13 || index == 14) return 4;
  else if (index == 15) return 5;
  return 0; // Default case
}

void selector(vec2 cn, out int rot, out int shape) {
  float h0 = hash(cn);
  float h1 = fract(h0*8677.0);
  rot   = int(floor(4.0*h1));
  shape = getDistribution(int(floor(16.0*h0)));
}

// Function to simulate open array
bool isOpenAt(int shape, int rotOffset) {
  if (shape == 0) return false;  // cell0: all false
  else if (shape == 1) return rotOffset == 0;  // cell1: only left true
  else if (shape == 2) return rotOffset == 0 || rotOffset == 3;  // cell2_corner: left and bottom true
  else if (shape == 3) return rotOffset == 1 || rotOffset == 3;  // cell2_line: top and bottom true
  else if (shape == 4) return rotOffset == 0 || rotOffset == 2 || rotOffset == 3;  // cell3: left, right, bottom true
  else if (shape == 5) return true;  // cell4: all true
  return false;
}

bool isOpen(int off, vec2 cn) {
  int rot;
  int shape;
  selector(cn, rot, shape);
  int r = int(mod(float(off + rot), 4.0));
  return isOpenAt(shape, r);
}

float df(vec2 p) {
  vec2 cp = p-0.5;
  vec2 cn = floor(cp + 0.5);
  cp -= cn;
  
  if (mod(cn.x+cn.y, 2.0) == 0.0) {
    int rot;
    int shape;
    selector(cn, rot, shape);
    float angle = float(rot) * TAU / 4.0;
    mat2 rotMat = ROT(angle);
    cp *= rotMat;
    if (shape == 0) {
      return cell0(cp);
    } else if (shape == 1) {
      return cell1(cp);
    } else if (shape == 2) {
      return cell2_corner(cp);
    } else if (shape == 3) {
      return cell2_line(cp);
    } else if (shape == 4) {
      return cell3(cp);
    } else if (shape == 5) {
      return cell4(cp);
    } else {
      return length(p);
    }
  } else {
    float d = 1E6;

    int ol = isOpen(2, cn+vec2(-1.0, 0.0)) ? 0 : 1;
    int ot = isOpen(3, cn+vec2( 0.0, 1.0)) ? 0 : 2;
    int or = isOpen(0, cn+vec2( 1.0, 0.0)) ? 0 : 4;
    int ob = isOpen(1, cn+vec2( 0.0,-1.0)) ? 0 : 8;

#ifdef DEBUG_DOTS
    const float dbgw = 0.025;
    if (ol == 0) {
      d = min(d, length(cp-4.0*dbgw*vec2(-1.0, 0.0))-dbgw);
    }
    if (ot == 0) {
      d = min(d, length(cp-4.0*dbgw*vec2( 0.0, 1.0))-dbgw);
    }
    if (or == 0) {
      d = min(d, length(cp-4.0*dbgw*vec2( 1.0, 0.0))-dbgw);
    }
    if (ob == 0) {
      d = min(d, length(cp-4.0*dbgw*vec2( 0.0, -1.0))-dbgw);
    }
#endif

    int sel = ol + ot + or + ob;
    float ds = length(cp)-linew;

#ifdef RANDOMIZED_TILES_ONLY
#else
    if (sel == 0) {
      ds = cell4(cp);
    } else if (sel == 1) {
      ds = cell3(-cp.yx);
    } else if (sel == 2) {
      ds = cell3(cp);
    } else if (sel == 4) {
      ds = cell3(cp.yx);
    } else if (sel == 8) {
      ds = cell3(-cp);
    } else if (sel == 3) {
      ds = cell2_corner(vec2(cp.y, -cp.x));
    } else if (sel == 6) {
      ds = cell2_corner(cp);
    } else if (sel == 9) {
      ds = cell2_corner(-cp);
    } else if (sel == 12) {
      ds = cell2_corner(vec2(-cp.y, cp.x));
    } else if (sel == 5) {
      ds = cell2_line(cp);
    } else if (sel == 10) {
      ds = cell2_line(cp.yx);
    } else if (sel == 7) {
      ds = cell1(cp.yx);
    } else if (sel == 11) {
      ds = cell1(-cp);
    } else if (sel == 13) {
      ds = cell1(-cp.yx);
    } else if (sel == 14) {
      ds = cell1(cp);
    } else if (sel == 15) {
      ds = cell0(cp);
    }
    d = min(d, ds);
#endif    
    return d;
  }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  // Rotation parameters
  const float rotationSpeed = 0.1; // Radians per second
  const float rotationCenterX = -0.5; // X-coordinate of rotation center (-1 to 1)
  const float rotationCenterY = 0.5; // Y-coordinate of rotation center (-1 to 1)

  // Apply rotation around custom center
  float angle = rotationSpeed * TIME;
  mat2 rotMat = ROT(angle);
  vec2 rotationCenter = vec2(rotationCenterX, rotationCenterY);
  p -= rotationCenter; // Translate to origin
  p = rotMat * p; // Rotate
  p += rotationCenter; // Translate back

  float aa = 2.0/RESOLUTION.y;
  float z = mix(0.25, 0.05, smoothstep(0.25, -0.25, cos(TIME*TAU/20.0)));
  vec2 dp = p;
  const float spd = 2.0;
  const float r = 10.0;
  dp /= z;
  dp += r*sin(vec2(sqrt(0.5), 1.0)*TIME*spd/r);
  float d = df(dp)*z;

  // Drop shadow parameters
  const float shadowOffsetX = 0.05; // Horizontal offset of shadow
  const float shadowOffsetY = -0.05; // Vertical offset of shadow (negative for bottom)
  const float shadowScale = 1.80; // Scales the shadow size relative to the lines
  const float shadowStrength = 0.75; // Opacity/intensity of the shadow (0.0 to 1.0)
  const float shadowFalloff = 0.2; // Distance over which shadow fades

  // Compute shadow distance with scaling
  vec2 shadowOffset = vec2(shadowOffsetX, shadowOffsetY) * shadowScale * z;
  float shadowD = df(dp + shadowOffset)*z;
  float shadowAlpha = shadowStrength * clamp(1.0 - shadowD / (shadowFalloff * z), 0.0, 1.0);

  // Background color
  vec3 col = vec3(0.0, 0.07, 0.03); // Your updated muted green background

  // Apply shadow with multiply blend mode
  col = col * (1.0 - shadowAlpha); // Multiply blend: darkens the background

  // Draw grey lines on top
  col = mix(col, vec3(0.729, 0.592, 0.278), smoothstep(aa, -aa, d));

  // Apply vignette effect
  vec2 uv = fragCoord.xy / RESOLUTION.xy;
  uv *= 1.0 - uv.yx; // Transform UV for vignette
  float vignetteIntensity = 25.0; // Intensity of vignette
  float vignettePower = 0.60; // Falloff curve of vignette
  float vig = uv.x * uv.y * vignetteIntensity;
  vig = pow(vig, vignettePower);

  // Apply dithering to reduce banding
  const float ditherStrength = 0.05; // Strength of dithering (0.0 to 1.0)
  int x = int(mod(fragCoord.x, 2.0));
  int y = int(mod(fragCoord.y, 2.0));
  float dither = 0.0;
  if (x == 0 && y == 0) dither = 0.25 * ditherStrength;
  else if (x == 1 && y == 0) dither = 0.75 * ditherStrength;
  else if (x == 0 && y == 1) dither = 0.75 * ditherStrength;
  else if (x == 1 && y == 1) dither = 0.25 * ditherStrength;
  vig = clamp(vig + dither, 0.0, 1.0);

  col *= vig; // Apply vignette by multiplying the color

  col = sqrt(col);
  fragColor = vec4(col, 1.0);
}