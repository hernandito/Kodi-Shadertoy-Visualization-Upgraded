precision mediump float; // Set default precision for floats

#define T iTime*.2 // Original definition
#define PI 3.141596
#define S smoothstep

// --- POST-PROCESSING DEFINES (BCS) ---
#define BRIGHTNESS 1.0    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.30      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)

// Robust Tanh Approximation Function (for vec3)
vec3 tanh_approx(vec3 x) {
    const float EPSILON = 1e-6; // Define a small epsilon to prevent division by zero
    // Apply the approximation component-wise
    return x / (1.0 + max(abs(x), vec3(EPSILON)));
}

mat2 rotate(float a){
  float s = sin(a);
  float c = cos(a);
  return mat2(c,-s,s,c);
}


void mainImage(out vec4 O, in vec2 I){
  vec2 R = iResolution.xy;
  // Initialize uv and apply robust division
  vec2 uv = (I * 2.0 - R) / max(R.y, 1e-6);


  // Explicitly initialize output color and alpha
  O.rgb = vec3(0.0);
  O.a = 1.0;

  // Explicitly initialize ray origin and direction
  vec3 ro = vec3(0.0, 0.0, -22.0);
  vec3 rd = normalize(vec3(uv, 1.0));

  // Explicitly initialize raymarch distance and total distance
  float z = 0.0;
  float d = 1e10;

  for(float i = 0.0; i < 100.0; i++){ // Explicitly 0.0f, 100.0f
    vec3 p = ro + rd * z; // Explicitly initialized p

    p.xy *= rotate(T * 0.2); // Explicitly 0.2f
    p.xz *= rotate(T * 0.2); // Explicitly 0.2f
    // p.yz *= rotate(T * 0.5); // Commented out in original

    vec3 q = p; // Explicitly initialized q
    // Replaced round() with floor(x + 0.5) for Kodi compatibility
    vec3 id = floor(q / 4.0 + 0.5) * 4.0; // Explicitly 4.0f, 0.5f, 4.0f
    q -= id;

    q -= cos(id + T * 5.0); // Explicitly 5.0f

    float r = 0.5; // Explicitly 0.5f
    float d1 = length(q.yz) - r; 
    float d2 = length(q.xy) - r; 
    float d3 = length(q.xz) - r;
    d = min(d1, min(d2, d3));


    {
      vec3 q_local = p; // Renamed q to q_local to avoid conflict
      q_local = abs(q_local) - vec3(10.0); // Explicitly 10.0f
      float box = max(max(q_local.x, q_local.y), q_local.z);
      d = max(d, box);
    }

    d = max(0.01, d * 0.6); // Explicitly 0.01f, 0.6f
    // Apply robust division for the accumulation step
    O.rgb += (1.1 + sin(vec3(3.0, 2.0, 1.0) + (p.x + p.y + p.z) * 0.1 + T)) / max(d, 1e-6); // Explicitly 1.1f, 3.0f, 2.0f, 1.0f, 0.1f

    z += d;

    if(z > 50.0 || d < 1e-3) break; // Explicitly 50.0f, 1e-3f
  }

  // Apply the robust tanh approximation
  O.rgb = tanh_approx(O.rgb / 1e4); // Explicitly 1e4f

  // Apply BCS adjustments
  vec3 finalColor = O.rgb;
  // Brightness
  finalColor += (BRIGHTNESS - 1.0);

  // Contrast
  finalColor = (finalColor - 0.5) * CONTRAST + 0.5;

  // Saturation
  float luminance = dot(finalColor, vec3(0.2126, 0.7152, 0.0722)); // Standard Rec. 709 luminance
  vec3 grayscale = vec3(luminance);
  finalColor = mix(grayscale, finalColor, SATURATION);

  O.rgb = clamp(finalColor, 0.0, 1.0); // Clamp final color to [0, 1] range
}
