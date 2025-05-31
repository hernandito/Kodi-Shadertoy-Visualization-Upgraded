#define T iTime
#define showNor 1

// --- Post-Processing BCS Parameters (Adjust these for final image look) ---
#define BRIGHTNESS -0.150         // Adjusts the overall brightness. 0.0 is no change, positive values brighten, negative values darken.
#define CONTRAST 1.10           // Adjusts the overall contrast. 1.0 is no change, values > 1.0 increase contrast, < 1.0 decrease.
#define SATURATION 0.4         // Adjusts the overall saturation. 1.0 is no change, values > 1.0 increase saturation, < 1.0 decrease.

// https://iquilezles.org/articles/smin/
float smin( float a, float b, float k )
{
    k *= 1.0;
    float r = exp2(-a/k) + exp2(-b/k);
    return -k*log2(r);
}

mat2 rotate(float a){
  float c = cos(a);
  float s = sin(a);
  return mat2(c,-s,s,c);
}


float map(vec3 p){
  float h = 10.;
  float d1 = abs(p.y-h);
  float d2 = abs(p.y+h);
  d1 = min(d1,d2);

  vec3 q = p;

  // this trick from https://www.shadertoy.com/view/3ftGDX
  d2 = length(cos(q.xz*0.4)*2.-q.y*0.1)-.5;
  // d2 = max(d2, -( p.y+h+1.));
  // d2 = max(d2, -(-p.y+h+1.));

  d1 = smin(d1,d2,.6);

  return d1;
}

// --- Robust Tanh Conversion Method ---
float tanh_approx(float x) {
    return x / (1.0 + abs(x));
}

float scaled_tanh_approx(float x, float scale_factor) {
    return tanh_approx(x * scale_factor);
}
// --- End Robust Tanh Conversion Method ---

/**
 * @brief Applies Brightness, Contrast, and Saturation adjustments to a color.
 *
 * @param color The input RGB color.
 * @param brightness The brightness adjustment.
 * @param contrast The contrast adjustment.
 * @param saturation The saturation adjustment.
 * @return The adjusted RGB color.
 */
vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color += brightness;

    // Apply contrast
    // Midpoint for contrast adjustment is 0.5 (gray).
    color = ((color - 0.5) * contrast) + 0.5;

    // Apply saturation
    // Convert to grayscale (luminance)
    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    // Interpolate between grayscale and original color based on saturation
    color = mix(vec3(luminance), color, saturation);

    return color;
}

void mainImage(out vec4 O, in vec2 I){
  vec2 R = iResolution.xy;
  vec2 uv = (I*2.-R) / R.y;
  O.rgb *= 0.;
  O.a = 1.;

  vec2 m = (iMouse.xy*2.-R)/R.y;

  float d = 0.;
  float d_acc = 0.;
  float z = 0.;
  vec3 ro = vec3(0,0,-1);
  vec3 rd = normalize(vec3(uv,1));
  vec3 p;
  for(float i=0.;i<50.;i++){
    p = ro + rd * z;

    if(iMouse.z>0.){
      p.xz *= rotate(m.x);
      p.yz *= rotate(m.y);
    }
    p.z += T;
    // p.x += sin(T)*5.;

    d = map(p);

    // step make transparent: https://www.shadertoy.com/view/WfKGRD
    d = 0.03 + abs(d) * .6;
    d_acc += 1./d;


    z += d;
  }

  // Warmer amber/cognac base color (less green)
  vec3 c = (vec3(4.5, 1.5, 0.3) + p.y * 0.1);
  vec3 tanh_input_transparent = c * d_acc / z / 1e2;
  vec3 tanh_result_transparent = vec3(
      scaled_tanh_approx(tanh_input_transparent.r, 3.0),
      scaled_tanh_approx(tanh_input_transparent.g, 3.0),
      scaled_tanh_approx(tanh_input_transparent.b, 3.0)
  );

  // Apply BCS post-processing
  vec3 finalColor = applyBCS(tanh_result_transparent, BRIGHTNESS, CONTRAST, SATURATION);

  // transparent
  O.rgb = finalColor;
  O.a = 1.0;
}