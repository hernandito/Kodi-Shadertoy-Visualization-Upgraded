// CC0: The Cube and the Torus
//  The modern version of the Beauty and the Beast
//  Wanted to create a small yet somewhat complex shader

// Twigl: https://twigl.app?ol=true&ss=-OWF0Z4mCTVsZm9bpODI

// If someone prefers the original shading I kept it on poshbrolly: https://www.poshbrolly.net/shader/Sd1aOOy3sHfWge4aCnHJ

const float EPSILON = 1e-6; // Epsilon for robust division and tanh_approx

// Robust tanh approximation function
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// Global variables for rotation axis and minimum distance to torus
vec3 X = vec3(0.0); // Rotation axis vector, explicitly initialized
float Y = 0.0; // Minimum distance to torus (used for glow effect), explicitly initialized

// --- Post-Processing Parameters ---
// BRIGHTNESS: Adjusts overall brightness (-1.0 to 1.0)
#define BRIGHTNESS -0.10
// CONTRAST: Adjusts contrast (0.0 for no contrast, >1.0 for more)
#define CONTRAST 1.1
// SATURATION: Adjusts color saturation (0.0 for grayscale, >1.0 for more vivid)
#define SATURATION 1.0
// ----------------------------------

// --- Animation Speed Control ---
// ANIMATION_SPEED: Multiplier for the overall animation speed.
// A value of 1.0 is normal speed. Higher values make it faster, lower values make it slower.
#define ANIMATION_SPEED .3
// -------------------------------

// --- Field of View (FOV) Control ---
// FOV_Z_SCALE: Adjusts the perceived field of view.
// Higher values will "zoom in" (narrower FOV), lower values will "zoom out" (wider FOV).
#define FOV_Z_SCALE .70
// -----------------------------------

// Distance function - returns shortest distance from point p to the scene geometry
float D(vec3 p) {
  // Inlined softmax and distance field functions by IQ: https://iquilezles.org/articles/distfunctions/
  //  Makes the code quite obscure
  vec3
      P = p,          // Copy of original point
      R = X;          // Copy of rotation axis (X is global and initialized)
  float
      d = 0.0,        // Final distance result, explicitly initialized
      z = 0.0,        // Distance to torus, explicitly initialized
      h = 0.0;        // Blend factor for mixing surfaces, explicitly initialized

  // Apply rotation around axis X to point p
  p = R * dot(R, p) + cross(R, p);

  // Cycle rotation axis (x->y, y->z, z->x) and apply to P to get a different rotation
  R = R.zxy;
  P = R * dot(R, P) + cross(R, P);
  P += 0.3; // Offset the rotated point

  // Calculate distance to torus (donut shape) and update global minimum
  Y = min(Y, z = length(vec2(length(P.xz) - 0.4, P.y)) - 0.01);

  // Create a bulbous surface using 8th power (makes it more rounded)
  d = pow(dot(P = p * p * p * p, P), 0.125); // 8th root of dot product of 4th powers

  // Blend factor based on distance differences to create smooth max
  // clamp is the correct version but min is smaller plus the artefact it creates looks ok
  // h=clamp(5.*(d+z)-2.25,0.,1.);
  h = min(5.0 * (d + z) - 2.25, 1.0);

  // Combine multiple surfaces: sphere, blended surface, and torus
  d = min(min(2.0 - sqrt(length(p * p)), h * (d + z - 0.45 - 0.1 * h) + 0.05 - z), z);
  
  // Create additional geometry by folding space (abs creates mirror symmetry)
  p = abs(p) - 1.0;
  vec2 Q = vec2(length(p.xz) - 0.2, p.y); // Distance to cylinder in xz plane

  // Return minimum distance between main surface and additional toruses
  return min(d, pow(dot(Q *= Q * Q * Q, Q), 0.125) - 0.05);
}

// Function to apply Brightness, Contrast, and Saturation adjustments
vec3 adjustBCS(vec3 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color += brightness;
    // Apply contrast (pivot around 0.5)
    color = (color - 0.5) * contrast + 0.5;
    // Apply saturation (mix with grayscale)
    float gray_val = dot(color, vec3(0.2126, 0.7152, 0.0722)); // Standard luminance coefficients
    vec3 gray = vec3(gray_val); // Correctly convert float to vec3
    color = mix(gray, color, saturation);
    return color;
}

void mainImage(out vec4 o, vec2 C) {
  float
      j = 0.0,          // Ray bounce counter, explicitly initialized
      d = 0.0,          // Distance from surface, explicitly initialized
      z = 0.0,          // Current ray distance, explicitly initialized
      E = 1e-3,         // Epsilon for surface detection and normal calculation
      A = 1.0;          // Light color accumulator, explicitly initialized
  vec3
      r = iResolution.xyz, // Screen resolution (reused as temp variable), explicitly initialized
      O_accum = vec3(0.0), // Accumulated color output, explicitly initialized (renamed to avoid conflict)
      p = vec3(0.0),      // Current ray position, explicitly initialized
      I = normalize(vec3(C - 0.5 * r.xy, r.y * FOV_Z_SCALE)), // Ray direction (camera to pixel), FOV applied
      N = vec3(0.0),      // Surface normal, explicitly initialized
      S = vec3(0.0);      // Ray starting position (camera position), explicitly initialized
  S.z = -1.8;
  // Create time-varying rotation axis using different frequencies
  X = normalize(vec3(cos(0.1 * iTime * ANIMATION_SPEED * vec3(2.0, 3.0, 5.0)))); // Explicit float literals, ANIMATION_SPEED applied

  // Main ray bouncing loop (up to 5 bounces)
  for(
    ; ++j < 6.0;        // Bounce counter, explicit float literal
    A *= z * 0.7        // Explicit float literal
    ) {

    // Reset distance and torus distance for this bounce
    d = Y = 9.0; // Explicit float literal

    // Ray marching loop - step along ray until we hit a surface
    for(
        z = E;            // Reset ray distance
        d > E;            // Continue until close to surface
        
    )
        // Step forward by distance to nearest surface
        z += d = D(p = z * I + S);

    // Calculate surface normal
    for (
        int i = 0;          // Loop counter, explicitly initialized
        i < 3;            // Calculate x, y, z components
        N[i++] = D(p + r) - d // Finite difference: f(x+h) - f(x)
    )
        r -= r,           // Reset offset vector to zero
        r[i] = E;         // Set current component to epsilon

    // Calculate lighting based on surface normal and ray direction
    z = 1.0 + dot(N = normalize(N), I); // Explicit float literal
    // Fake fresnel effect
    z = 0.6 + 0.4 * z * z; // Explicit float literals

    // Calculate distance to overhead light
    d = length((p + (5.0 - p.y) / max(abs(I.y), EPSILON) * I).xz) + 1.0; // Robust division, Explicit float literals

    // Glow effect from torus proximity
    O_accum += A / max(3e2, EPSILON) / max(Y, EPSILON) * vec3(9.0, 1.0, 1.0); // Robust division, Explicit float literals
    if(I.y > 0.0) // Explicit float literal
      // Overhead light
      O_accum += (A - A * z) * smoothstep(7.0, 4.0, d) * d * vec3(2.0, 2.0, 4.0); // Explicit float literals

    // Reflect ray off surface for next bounce
    I = reflect(I, N);
    // New direction and starting position (slightly offset)
    S = p + 5e-2 * N; // Explicit float literal
  }

  // Final color processing: apply tone mapping and gamma correction
  o = sqrt(tanh_approx(vec4(O_accum, 1.0))).xyzx; // Compress dynamic range and convert to sRGB, use tanh_approx

  // Apply BCS adjustments in post-processing
  o.rgb = adjustBCS(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}
