#define T iTime*.15
#define PI 3.141596
#define S smoothstep

// Parameters for Brightness, Contrast, Saturation (BCS) adjustment
#define BRIGHTNESS 0.00 // Adjusts overall brightness (-1.0 to 1.0)
#define CONTRAST 1.40   // Adjusts contrast (0.0 for no contrast, >1.0 for more)
#define SATURATION 1.0 // Adjusts color saturation (0.0 for grayscale, >1.0 for more vivid)

vec4 map(vec3 p) {
  float freq = .5;
  float amp = 2.;
  // xor https://mini.gmshaders.com/p/turbulence
  for(float i=1.;i<5.;i++){
    p += amp * sin(p.zxy * freq+T);
    freq *= 2.;
    amp *= .5;
  }
  float d = -(length(p.xy)-10.);
  vec3 col = sin(vec3(3,2,1)+p.z*.3)*.5+.5;
  return vec4(col, d);
}


// https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0);
    const float eps = 0.0005;
    return normalize(
            e.xyy*map( pos + e.xyy*eps ).w +
            e.yyx*map( pos + e.yyx*eps ).w +
            e.yxy*map( pos + e.yxy*eps ).w +
            e.xxx*map( pos + e.xxx*eps ).w );
}

// https://www.shadertoy.com/view/MtsGWH
vec4 boxmap( in sampler2D s, in vec3 p, in vec3 n, in float k )
{
    // project+fetch
    vec4 x = texture( s, p.yz );
    vec4 y = texture( s, p.zx );
    vec4 z = texture( s, p.xy );

    // and blend
  vec3 m = pow( abs(n), vec3(k) );
    return (x*m.x + y*m.y + z*m.z) / (m.x + m.y + m.z);
}

float rayMarch(vec3 ro, vec3 rd, float zMin, float zMax){
  float z = zMin;
  for(float i=0.;i<100.;i++){
    vec3 p = ro + rd * z;
    float d = map(p).w;
    d *= .2;
    if(d<1e-3 || z>zMax) break;
    z += d;
  }
  return z;
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

void mainImage(out vec4 O, in vec2 I){
  vec2 R = iResolution.xy;
  vec2 uv = (I*2.-R)/R.y;

  O.rgb *= 0.;
  O.a = 1.;

  vec3 ro = vec3(0,0,T*5.);
  vec3 rd = normalize(vec3(uv, 1.));

  float zMax = 30.;

  float z = rayMarch(ro, rd, 0., zMax);

  vec3 col = vec3(0);
  if(z<zMax) {
    vec3 p = ro + rd * z;
    vec3 nor = calcNormal(p);

    vec4 M = map(p);

    //col = M.rgb;  // try custom color
    col = boxmap(iChannel0, p*.5, nor, 7.).rgb;

    vec3 l_dir = normalize(vec3(0,0,ro.z+10.)-p);
    float diff = max(dot(l_dir,nor), 0.);
    col += diff*.4;

    float spe = pow(max(dot(normalize(l_dir-rd),nor),0.), 100.);
    col += spe;
  }

  col *= exp(-3e-4*z*z*z);
  // Apply BCS adjustments in post-processing
  col = adjustBCS(col, BRIGHTNESS, CONTRAST, SATURATION);
  O.rgb = col;
}
