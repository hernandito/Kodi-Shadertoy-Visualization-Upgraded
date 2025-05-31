//-----------------------------------------------------
// SnowIsFalling.glsl
//  v1.0  2017-08-24  initial version
//  v1.1  2018-04-17  test with mysteryMountain
// combining background of https://www.shadertoy.com/view/4dl3R4
// and falling snow of     https://www.shadertoy.com/view/ldsGDn
//-----------------------------------------------------

// Global constants
const float ANIMATION_SPEED = 0.40; // Controls complete animation speed (1.0 = normal, <1.0 slows, >1.0 speeds up)
const bool ASH_MODE = false; // Toggle between snowflakes (false) and ash (true)
const float sunBrightness = 0.30; // Adjust to reduce sun brightness (0.0 to 1.0)
const float brightness = 0.90; // Adjust overall brightness (0.0 to 2.0, 1.0 = normal)
const float contrast = 1.8; // Adjust contrast (0.0 to 2.0, 1.0 = normal)
const float saturation = 1.0; // Adjust saturation (0.0 to 2.0, 1.0 = normal)

//=== background ===

#define mod289(x) mod(x, 289.)

vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

//-----------------------------------------------------
float snoise(vec2 v)
{
  const vec4 C = vec4(0.211324865405187,0.366025403784439,-0.577350269189626,0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
                	+ i.x + vec3(0.0, i1.x, 1.0 ));
  
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
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
//-----------------------------------------------------
float fbm(vec2 p) 
{
  float f = 0.0;
  float w = 0.5;
  for (int i = 0; i < 5; i ++) 
  {
    f += w * snoise(p);
    p *= 2.;
    w *= 0.5;
  }
  return f;
}
//-----------------------------------------------------
// background of https://www.shadertoy.com/view/4dl3R4
//-----------------------------------------------------
vec3 background(vec2 uv)
{
  uv.x += iMouse.x / iResolution.x - 1.0;
  float speed = 2.0;
  
  // Static sun position, raised above screen
  vec2 sunCenter = vec2(0.3, 0.90); // Raised to 0.90, more glow visible
  float suns = clamp(1.2 - distance(uv, sunCenter), 0.0, 1.0);
  float sunsh = smoothstep(0.85, 0.95, suns);
  
  float slope = 1.0 - smoothstep(0.55, 0.0, 0.8 + uv.x - 2.3 * uv.y);								
  
  float noise = abs(fbm(uv * 1.5));
  slope = (noise * 0.2) + (slope - ((1.0 - noise) * slope * 0.1)) * 0.6;
  slope = clamp(slope, 0.0, 1.0);
  						
  vec2 GA = speed * vec2(iTime * ANIMATION_SPEED, iTime * ANIMATION_SPEED * 0.5); // Unified speed control
  
  // Compute base background brightness
  float baseBrightness = 0.35 + (slope * 0.5);
  
  // Apply warm tint to base background
  vec3 bgColor = vec3(baseBrightness * 1.1, baseBrightness * 1.0, baseBrightness * 0.9);
  
  // Add sun contribution with a warm yellowish-orange base color, scaled by sunBrightness
  vec3 sunColor = vec3(1.0, 0.9, 0.6); // Warm yellowish-orange
  vec3 sunContribution = sunColor * (suns + (sunsh * 0.6)) * sunBrightness;
  
  // Combine background and sun colors
  return bgColor + sunContribution;
}

//-----------------------------------------------------
// falling snow of https://www.shadertoy.com/view/ldsGDn
//-----------------------------------------------------

#define LAYERS 66

#define DEPTH1 .3
#define WIDTH1 .4
#define SPEED1 1.16

#define DEPTH2 .1
#define WIDTH2 .3
#define SPEED2 .1

vec3 snowing(in vec2 uv, in vec2 fragCoord)
{
  const mat3 p = mat3(13.323122,23.5112,21.71123,21.1212,28.7312,11.9312,21.8112,14.7212,61.3934);
  vec2 mp = iMouse.xy / iResolution.xy;
  uv.x += mp.x * 4.0;    
  mp.y *= 0.25;
  float depth = smoothstep(DEPTH1, DEPTH2, mp.y);
  float width = smoothstep(WIDTH1, WIDTH2, mp.y);
  float speed = smoothstep(SPEED1, SPEED2, mp.y);
  float acc = 0.0;
  float dof = 5.0 * sin(iTime * ANIMATION_SPEED); // Unified speed control
  for (int i = 0; i < LAYERS; i++)
  {
    float fi = float(i);
    vec2 q = uv * (1.0 + fi * depth);
    float w = width * mod(fi * 7.238917, 1.0) - width * 0.1 * sin(iTime * ANIMATION_SPEED + fi);
    
    // Add chaotic motion for ash
    if (ASH_MODE)
    {
        vec2 ashJitter = vec2(snoise(q + fi), snoise(q + fi + 10.0)) * 0.02;
        q += ashJitter;
    }
    
    q += vec2(q.y * w, speed * iTime * ANIMATION_SPEED / (1.0 + fi * depth * 0.03));
    vec3 n = vec3(floor(q), 31.189 + fi);
    vec3 m = floor(n) * 0.00001 + fract(n);
    vec3 mp = (31415.9 + m) / fract(p * m);
    vec3 r = fract(mp);
    vec2 s = abs(mod(q, 1.0) - 0.5 + 0.9 * r.xy - 0.45);
    s += 0.01 * abs(2.0 * fract(10.0 * q.yx) - 1.); 
    
    // Add irregularity to shape for ash
    float d;
    if (ASH_MODE)
    {
        float distortion = snoise(q * 5.0) * 0.05; // Noise-based distortion
        d = 0.6 * max(s.x - s.y + distortion, s.x + s.y + distortion) + max(s.x, s.y) - 0.01;
    }
    else
    {
        d = 0.6 * max(s.x - s.y, s.x + s.y) + max(s.x, s.y) - 0.01;
    }
    
    float edge = 0.05 + 0.05 * min(0.5 * abs(fi - 5.0 - dof), 1.0);
    acc += smoothstep(edge, -edge, d) * (r.x / (1.0 + 0.02 * fi * depth));
  }
  
  // Define ash color explicitly
  if (ASH_MODE)
  {
      return vec3(0.05, 0.05, 0.05) * acc; // Very dark gray to black ash
  }
  else
  {
      return vec3(acc); // White snow
  }
}
//-----------------------------------------------------  
// '[2TC 15] Mystery Mountains' by David Hoskins.
// Add layers of the texture of differing frequencies and magnitudes...
//-----------------------------------------------------
#define F +texture(iChannel1, .3+p.xz*s/3e3)/(s+=s) 
bool MysteryMountains(inout vec4 c, vec2 w)
{
    vec4 p = vec4(w / iResolution.xy, 1, 1) - 0.5, d = p, t;
    p.z += iTime * ANIMATION_SPEED; // Unified speed control
    for (float i = 1.5; i > 0.3; i -= 0.002)
    {
        float s = 0.8;
        t = F F F F F;
        c = vec4(1, 1., 0.9, 9) + d.x - t * i;
        if (t.x > p.y * 0.017 + 1.3) return true;
        p += d;
    }
    return false;
}
//-----------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.y;
    
    vec3 bg = background(uv);
    fragColor = vec4(bg, 1.0); // Background now returns vec3
    vec3 snowOut = snowing(uv, fragCoord);
    if (ASH_MODE)
    {
        // Multiplicative blending to darken the background where ash appears
        float ashIntensity = dot(snowOut, vec3(1.0)) / 0.05; // Normalize based on max ash color
        fragColor.rgb *= (1.0 - ashIntensity * 0.4); // Darken background proportionally
        fragColor.rgb = max(fragColor.rgb, 0.0); // Clamp to prevent over-darkening
    }
    else
    {
        fragColor.rgb += snowOut; // Additive blend for snow
    }

    // Apply BCS adjustment
    vec3 color = fragColor.rgb;
    // Convert to luminance
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    // Apply contrast
    color = mix(vec3(luminance), color, contrast);
    // Apply brightness
    color = color * brightness;
    // Apply saturation
    color = mix(vec3(luminance), color, saturation);
    fragColor.rgb = clamp(color, 0.0, 1.0);
}