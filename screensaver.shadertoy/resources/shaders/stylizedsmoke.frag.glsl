// Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- NEW: BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
#define POST_BRIGHTNESS 1.0 
#define POST_CONTRAST   1.5 
#define POST_SATURATION 2.30 

vec4 applyBCS(vec4 color) {
    color.rgb *= POST_BRIGHTNESS;
    color.rgb = ((color.rgb - 0.5) * POST_CONTRAST) + 0.5;
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(luma);
    color.rgb = mix(gray, color.rgb, POST_SATURATION);
    return clamp(color, 0.0, 1.0);
}
// --- END NEW: BCS Parameters and Function ---


// CC0: Saturday smoke
// Continuing working on small shaders I wanted to try something different
// from what I've done so far. This creates translucent twisted planes
// with glowing edges that resemble smoke or vapor.

// Twigl: https://twigl.app?ol=true&ss=-OS9WbjQWLpMmr_oL7fB

void mainImage(out vec4 O, vec2 C) {
  float i = 0.0;
  float j = 0.0;
  float d = 0.0;
  float D = 1e5;
  float z = 0.0;
  float T = .3*iChannelTime[0];
  
  vec4 o = vec4(0.0);
  vec4 p,P,U=vec4(0,1,2,3);
  
  for (
      vec2 r=iResolution.xy
    ; ++i<77.
    ; z+=.6*d+1E-3
    )
    
    for (
        p=z*normalize(vec3(C-.5*r, r.y)).xyzz
      , p.z-=d=j=4.
      ; ++j<9.
      ; d = min(d, D)
      ) {
        D = 2./(j-3.)+p.y/3.;
      
        P = p;
        P.x -= .3*sin(p.y+T);
      
        P.xz *= mat2(cos(j-T+p.y+11.*U.xywx));
      
        P = abs(P);
      
        // Distance function:
        // MODIFIED: Increased the offset from 2E-2 (0.02) to 5E-2 (0.05) to make lines thicker.
        D = min(
           max(P.z,P.x-D)+5E-2 // <-- MODIFIED THIS VALUE FOR THICKER LINES
         , length(P.xz-D*U.yx)
         );
      
        P = 1.2+sin(j+U.xyzy+z);
      
        o += P.w*P/max(D, 1E-6);
      }
    ;
  
  O = tanh_approx(o/1E3);
  O = applyBCS(O);
}