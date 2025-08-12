// Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
#define POST_BRIGHTNESS 1.0
#define POST_CONTRAST   1.04
#define POST_SATURATION 1.0

vec4 applyBCS(vec4 color) {
    color.rgb *= POST_BRIGHTNESS;
    color.rgb = ((color.rgb - 0.5) * POST_CONTRAST) + 0.5;
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(luma);
    color.rgb = mix(gray, color.rgb, POST_SATURATION);
    return clamp(color, 0.0, 1.0);
}
// --- END BCS Parameters and Function ---

// --- NEW: Global Animation Speed Control Parameter ---
// Adjust this value to control the overall speed of the animation.
// 1.0 for normal speed. <1.0 for slower, >1.0 for faster.
#define ANIMATION_SPEED 0.25
// --- END NEW ---


// CC0: Beat Boxing
//  I believe computers are made to spin cubes so wanted to do a spinning and beating "cube".
//  I think there are lot of ways to improve the char count but currently too tired to think about it
//  BPM: 114

// Note: Browsers don't allow audio to play without user interaction so if the shader don't move
//  fiddle with the start and stop button under the graphics area.


void mainImage(out vec4 O, vec2 C) {
  // Time-based animation variables - All variables are explicitly initialized for robustness.
  float
    // MODIFIED: Apply ANIMATION_SPEED to the base time variable (iChannelTime[0])
    t=iChannelTime[0] * ANIMATION_SPEED // t = raw audio time (drives the beat)
  , i = 0.0             // i = raymarching iteration counter
  , j = 0.0             // j = fractal iteration counter
  , d = 0.0             // d = distance field value (distance to nearest surface)
  , z = 0.0             // z = depth along ray (how far we've marched)
  , X = 0.0             // X = distance from origin (used for color/lighting effects)
  , Y = 0.0             // Y = original Y position (determines above/below horizon)
  , S = 0.0             // S = current fractal scale (starts at 1, halves each iteration)
  , D = 0.0             // D = distance to current sphere in fractal loop
  , B=t*1.9             // B = scaled time (creates 114 BPM beat timing)
  , F=sqrt(fract(B))    // F = beat transition, at each beat speeds up and then slows down
  , T=floor(B)+F        // T = beating time
  ;
  vec4
    o = vec4(0.0)       // o = accumulated color/light (final output before tone mapping) - Crucially initialized
  , p = vec4(0.0)       // p = current position
  , U=vec4(1,2,3,0)     // U = utility vector (provides different constants for calculations) - Already initialized
  , W = vec4(0.0)       // W = weighted color (p.w * p, alpha-scaled color)
  , E = vec4(0.0)       // E = flash effect (bright light that fades)
  ;

  // Rotation matrix that changes over time - creates spinning motion
  mat2 R = mat2(cos(.3*T + 11.*U.wxzw));

  // Main raymarching loop - shoots rays from camera through each pixel
  for (
      vec2 r = iResolution.xy
    ; ++i<77.
    ; z+=.7*d+1E-3
    ) {

    // Convert screen coordinate to 3D ray direction, extend to 4D
    p = vec4(z*normalize(vec3(C-.5*r, r.y)),.1);
    p.z -= 6.;

    // Store Y position for lighting decision, then apply vertical offset
    Y = p.y += 1.8;

    // Create ground plane reflection effect
    p.y = abs(p.y)-2.3;

    // Apply 3D rotation to create spinning effect
    p.xy *= R;
    p.zx *= R;
    p.yz *= R;

    X = length(p);

    // Fractal iteration loop - creates cube-like shape built from spheres
    for (
          d=S=j=1.
        ; ++j<8.
        ; S *= .5
        )
        D=length(p) - S
      , d = max(d, .1*S-D)
      , d = min(d, D)
      , p = abs(p)
      , p.xyz -= .7*S
      , p.w -= .1*cos(4.*X+3.+F)
      ;
    d = abs(d);

    // Calculate colors based on position and distance from origin
    p = 1.+sin(6.+3.*X + U.wxyw);

    // Lighting effects
    E=exp(-6.*F)*U*1E3/max(pow(X,6.),1E-3);
    W=p.w*p;

    // Different lighting above vs below the horizon
    if (Y > 0.)
        o += W/max(d, 1E-3)+E;
    else
        o += .2*U*W/max(d*d*d, 5E-3)+.5*E+9.*U,
        d *= .5;
  }

  // Tone mapping - convert accumulated light to final color
  O = tanh_approx(o/3E4);

  // Apply Brightness, Contrast, Saturation adjustments
  O = applyBCS(O);
}