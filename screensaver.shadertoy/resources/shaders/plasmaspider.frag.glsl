// Created by Fabio Ottaviani
// www.supah.it
// instagram.com/supahfunk

// === USER PARAMETERS ===
#define ANIMATION_SPEED 0.1    // Overall animation speed
#define BRIGHTNESS      1.00   // 1.0 = neutral
#define CONTRAST        1.200   // 1.0 = neutral
#define SATURATION      1.40   // 1.0 = neutral
// ========================

// Simplex 2D noise
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float s(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, -s, s, c);
	return m * v;
}

float L(float t, float s, float e, float b){
    float s1 = smoothstep(s - b, s + b, t);
    float s2 = smoothstep(e + b, e - b, t);
    return s1 * s2;
}

// BCS adjustment
vec3 applyBCS(vec3 color) {
    // Brightness
    color *= BRIGHTNESS;

    // Saturation
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(luma), color, SATURATION);

    // Contrast
    color = (color - 0.5) * CONTRAST + 0.5;

    return clamp(color, 0.0, 1.0);
}

void mainImage(out vec4 O, in vec2 I)
{
    vec2 R = iResolution.xy;
    vec2 u = (I - 0.5 * R) / R.y;
         
    vec3 C = vec3(0.0);
    float num = 20.0;
    float t = iTime * ANIMATION_SPEED;

    for (float i = 0.0; i < num; i++) {
        float n = i / num;
        vec2 uv = u;
        float no = s(uv + sin(t + i));
        uv += smoothstep(0.1, 0.4, length(uv)) * no * 0.1;
        uv = rotate(u + vec2(sin(t) * 0.2, sin(t * 0.3) * 0.2), t * 0.5 + no * 0.15 + n * 3.14);
        vec3 col = vec3(n * 1.5, 0.4 + n * 0.4, 0.6);
        C += L(uv.y, 0.0, 0.0, 0.01 + sin(0.01 + t * 3.0) * 0.0013 - length(uv) * 0.01) * 1.5 * col;
    }

    C *= C + C + (1.0 - length(u));
    C = applyBCS(C);  // Apply brightness/contrast/saturation
    O = vec4(C, 1.0);
}
