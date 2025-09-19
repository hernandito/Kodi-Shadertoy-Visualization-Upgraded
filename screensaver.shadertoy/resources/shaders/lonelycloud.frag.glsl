// "Volumetric Clouds"
// A simplified raymarched cloud sphere.

// Shadertoy uniforms: iTime, iResolution
precision highp float;


// ---------------- USER PARAMETERS ----------------
#define BRIGHTNESS 0.80
#define CONTRAST   1.50
#define SATURATION 1.0
// -------------------------------------------------

// ---------- utils
vec3 bcs_final(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    vec3 grayscale = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
    color = mix(grayscale, color, saturation);
    return color;
}

#define MAX_STEPS 100

float sdSphere(vec3 p, vec2 t) {
   vec2 q = vec2(length(p.xz)-t.x,p.y);
 return length(q)-t.y;
}

// Better hash function for smoother noise
float hash(float n) {
   return fract(sin(n) * 43758.5453);
}

float hash3d(vec3 p) {
   return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

// Improved 3D noise function with proper interpolation 
float noise(vec3 x) {
   // Scale the input for appropriate cloud features
   x *= 0.55;
  
   vec3 p = floor(x);
   vec3 f = fract(x);
  
   // Smooth interpolation (quintic instead of cubic for even smoother results)
   f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
  
   // Sample noise at 8 corners of the cube
   float n000 = hash3d(p + vec3(0.0, 0.0, 0.0));
   float n001 = hash3d(p + vec3(0.0, 0.0, 1.0));
   float n010 = hash3d(p + vec3(0.0, 1.0, 0.0));
   float n011 = hash3d(p + vec3(0.0, 1.0, 1.0));
   float n100 = hash3d(p + vec3(1.0, 0.0, 0.0));
   float n101 = hash3d(p + vec3(1.0, 0.0, 1.0));
   float n110 = hash3d(p + vec3(1.0, 1.0, 0.0));
   float n111 = hash3d(p + vec3(1.0, 1.0, 1.0));
  
   // Trilinear interpolation
   float nx00 = mix(n000, n100, f.x);
   float nx01 = mix(n001, n101, f.x);
   float nx10 = mix(n010, n110, f.x);
   float nx11 = mix(n011, n111, f.x);
  
   float nxy0 = mix(nx00, nx10, f.y);
   float nxy1 = mix(nx01, nx11, f.y);
  
   return mix(nxy0, nxy1, f.z) * 2.0 - 1.0;
}

float fbm(vec3 p) {
   vec3 q = p + iTime*.3 * 0.5 * vec3(1.0, -0.2, -1.0);
   float g = noise(q);
  
   float f = 0.0;
   float scale = 0.5;
   float factor = 2.02;
  
   for (int i = 0; i < 6; i++) {
       f += scale * noise(q);
       q *= factor;
       factor += 0.21;
       scale *= 0.5;
   }
  
   return f;
}

float scene(vec3 p) {
   float distance = sdSphere(p, vec2(1.5, 0.7));
   float f = fbm(p);
   return -distance + f;
}

const vec3 SUN_POSITION = vec3(1.0, 0.0, 0.0);
const float MARCH_SIZE = 0.08;

vec4 raymarch(vec3 rayOrigin, vec3 rayDirection) {
   float depth = 0.0;
   vec3 p = rayOrigin + depth * rayDirection;
   vec3 sunDirection = normalize(SUN_POSITION);
   vec4 res = vec4(0.0);
  
   for (int i = 0; i < MAX_STEPS; i++) {
       float density = scene(p);
      
       if (density > 0.0) {
           float diffuse = clamp((scene(p) - scene(p + 0.3 * sunDirection)) / 0.3, 0.0, 1.0);
           vec3 lin = vec3(0.60, 0.60, 0.75) * 1.1 + 0.8 * vec3(1.0, 0.6, 0.3) * diffuse;
           vec4 color = vec4(mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), density), density);
           color.rgb *= lin;
           color.rgb *= color.a;
           res += color * (1.0 - res.a);
       }
      
       depth += MARCH_SIZE;
       p = rayOrigin + depth * rayDirection;
   }
  
   return res;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
   vec2 uv = fragCoord / iResolution.xy;
   uv -= 0.5;
   uv.x *= iResolution.x / iResolution.y;
  
   vec3 ro = vec3(0.0, 0.0, 5.0);
   vec3 rd = normalize(vec3(uv, -1.0));
  
   vec3 color = vec3(0.0);
  
   vec3 sunDirection = normalize(SUN_POSITION);
   float sun = clamp(dot(sunDirection, rd), 0.0, 1.0);
  
   color = vec3(0.7, 0.7, 0.90);
   color -= 0.8 * vec3(0.90, 0.75, 0.90) * rd.y;
   color += 0.5 * vec3(1.0, 0.5, 0.3) * pow(sun, 10.0);
  
   vec4 res = raymarch(ro, rd);
   color = color * (1.0 - res.a) + res.rgb;
  
    // Apply BCS post-processing adjustments
    color = bcs_final(color, BRIGHTNESS, CONTRAST, SATURATION);

   fragColor = vec4(color, 1.0);
}