// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 0.90
#define CONTRAST   1.30
#define SATURATION 1.0

vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    // Brightness
    color += brightness - 1.0;
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    // Saturation
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

#define T iTime*.2
#define PI 3.141596
const float EPSILON = 1e-6;

mat2 rotate(float a){
  float s = sin(a);
  float c = cos(a);
  return mat2(c,-s,s,c);
}

float smin( float a, float b, float k )
{
  k *= 1.0 / (1.0 - sqrt(0.5));
  float h = max( k - abs(a-b), 0.0 ) / k;
  return min(a,b) - k * 0.5 * (1.0 + h - sqrt(1.0 - h * (h - 2.0)));
}
float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}


float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

void mainImage(out vec4 O, in vec2 I){
  vec2 R = iResolution.xy;
  vec2 uv = (I * 2.0 - R) / R.y;
  vec2 m = (iMouse.xy * 2.0 - R) / R * PI * 2.0;

  // Explicitly initialize output color and alpha
  O.rgb = vec3(0.0);
  O.a = 1.0;

  vec3 ro = vec3(0.0, 0.0, -8.0);
  vec3 rd = normalize(vec3(uv, 1.0));

  float zMax = 10.0;
  float z = 0.1;

  vec3 col = vec3(0.0);
  float d = 0.0;
  
  for(float i=0.0;i<100.0;i++){
    vec3 p = ro + rd * z;

    p.xz *= rotate(T * 0.2);

    if(iMouse.z > 0.0){
      p.xz *= rotate(m.x);
      p.yz *= rotate(m.y);
    }

    vec3 q = cos(p);
    for(float l=1.0;l<6.0;l++){
      q += sin(q.zxy * l + T) * 0.2;
    }

    d = length(q) - 0.6;
    {
      float d1 = sdBox(p, vec3(4.0));
      d = smax(d1, -d, 1.0);
    }
    d = abs(d) * 0.3 + 0.005;

    vec3 c = sin(vec3(3.0, 2.0, 1.0) + dot(p,p) * 0.1 + T) + 1.0;
    col += c * pow(0.014 / max(d, EPSILON), 2.0);
    
    if(d < EPSILON || z > zMax) break;
    z += d;
  }
  
  // Apply tanh approximation
  vec4 temp_col = vec4(col, 0.0) / 100.0;
  col = tanh_approx(temp_col).rgb;

  // Apply BCS post-processing
  col = bcs(col, BRIGHTNESS, CONTRAST, SATURATION);

  O.rgb = col;
}