// Paper Lantern created by SeongWan Kim (kaswan / twitter @idgmatrix)
// Thanks to iq and @kevinroast 
// shadow and glow effect codes from http://www.kevs3d.co.uk/dev/shaders/distancefield6.html

#define EPSILON 0.005
#define MAX_ITERATION 256
#define AO_SAMPLES 12
#define SSS_SAMPLES 5
#define SHADOW_RAY_DEPTH 16

// BCS Parameters
#define BRIGHTNESS 0.650   // Adjust for overall brightness (e.g., 1.2 for brighter, 0.8 for darker)
#define CONTRAST   1.50   // Adjust for contrast (e.g., 1.2 for more contrast, 0.8 for less)
#define SATURATION 1.0   // Adjust for saturation (e.g., 1.2 for more vivid, 0.8 for less)

float longitude;
float latitude;
float sphere(vec3 pos)
{
    float r = 1.0;
    
    vec3 rpos = pos;
    
    float time = iTime * 0.5;
    float s = sin(time);
    float c = cos(time);
    
    rpos.x = pos.x * c + pos.z * s; 
    rpos.z = pos.x * s - pos.z * c; 
    
    float d = length(rpos);
    
    longitude = atan(rpos.z, rpos.x);
    latitude = asin(rpos.y / d);
    
    d += abs(sin(longitude * 3.0) * 0.15) * abs(sin(latitude * 14.0) * 0.15);
    
    d -= r;
    
    return d;
}

float cylinder(vec3 pos, vec3 c)
{
  return length(pos.xz - c.xy) - c.z;
}

float paperLantern(vec3 pos)
{
    float d = sphere(pos);
    return max(d, -cylinder(pos, vec3(0.0, 0.0, 0.45)));
}

bool isPlane = false;
float plane(vec3 pos, vec4 n)
{
      float d = dot(pos, n.xyz) - n.w;
    
    if (d < EPSILON) isPlane = true;
    
    return d;
}

float scene(vec3 pos)
{
    float d;
    
    d = paperLantern(pos);
    d = min(d, plane(pos, vec4(0.0, 1.0, 0.0, -1.2)));
    d = min(d, plane(pos, vec4(0.0, 0.0, -1.0, -10.0)));
    // CORRECTED LINE BELOW:
    d = min(d, plane(pos, vec4(1.0, 0.0, 0.0, -6.0)));
    d = min(d, plane(pos, vec4(-1.0, 0.0, 0.0, -6.0)));
    
    return d;
}

float calcAO(vec3 p, vec3 n)
{
   float r = 0.0;
   float w = 1.0;
   for (int i = 1; i <= AO_SAMPLES; i++)
   {
      float d0 = float(i) * 0.2;
      r += w * (d0 - scene(p + n * d0));
      w *= 0.5;
   }
   return 1.0 - clamp(r, 0.0, 1.0);
}

float calcSSS(vec3 ro, vec3 rd)
{
   float total = 0.0;
   float weight = 0.5;
   for (int i = 1; i <= SSS_SAMPLES; i++)
   {
      float delta = pow(float(i), 2.5) * EPSILON * 32.0;
      total += -weight * min(0.0, sphere(ro+rd * delta));
      weight *= 0.9;
   }
   return clamp(total, 0.0, 1.0);
}

float shadow(vec3 ro, vec3 rd)
{
    vec3 p = ro + rd * 0.12;
    
    for (int i = 0; i < SHADOW_RAY_DEPTH; i++)
    {
            
        float d = scene(p);
        
        if (d < EPSILON) {
            return 0.0;
        }
        
        p += rd * d;
    }
    
    return 1.0;
}

float softShadow(vec3 ro, vec3 rd, float k)
{
   float res = 1.0;
   float t = 0.12;           
   for (int i = 0; i < SHADOW_RAY_DEPTH; i++)
   {
     float h = scene(ro + rd * t);
     res = min(res, k*h/t);
     t += h;
     if (t > 5.0) break; 
   }
   return clamp(res, 0.25, 1.0);
}

vec3 lightColor = vec3(1, 1, 1);
//vec3 sssColor = vec3(1.9 + 0.1 * abs(sin(iTime * 6.0)), 1.3, 0.5);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    float aspectRatio = iResolution.x / iResolution.y;
    uv.x *= aspectRatio;    
    
    vec3 sssColor = vec3(1.9 + 0.1 * abs(sin(iTime * 6.0)), 1.3, 0.5);
    vec3 d = vec3(uv, -2.0) - vec3(0.0, -0.0, -5.0);;
    vec3 rd = normalize(d);
    
    vec3 lpos = vec3(-2.0*sin(iTime * 0.5), 3.0, -2.0*cos(iTime * 0.5));
    //vec3 lpos = vec3(-2.0, 3.0, -2.0);
    
    vec3 pos = vec3(0.0, 0.0, -5.0);
    
    float distance;
    
    for (int i = 0; i < MAX_ITERATION; i++) {
        
        distance = scene(pos);
        
        if (distance < EPSILON) {
            
            vec3 eps = vec3(EPSILON, 0.0, 0.0);
            vec3 normal;
                
            normal.x = scene(pos + eps.xyz) - scene(pos - eps.xyz);
            normal.y = scene(pos + eps.yxz) - scene(pos - eps.yxz);
            normal.z = scene(pos + eps.zyx) - scene(pos - eps.zyx);
            
            vec3 n = normalize(normal);
            vec3 l = normalize(lpos - pos);
            
            vec3 light = max(dot(n,l),0.0) * lightColor * 0.5;

            vec4 tex;
            if (isPlane) {
                vec4 c;
                tex = texture(iChannel0, pos.yz * 0.2) * abs(n.x);
                tex += texture(iChannel0, pos.zx * 0.2) * abs(n.y);
                tex += texture(iChannel0, pos.xy * 0.2) * abs(n.z);
                
                light *= tex.xyz * vec3(1.0, 0.45, 0.1);
            }
            else{
                vec2 uv = vec2(longitude, latitude); 
                tex = texture(iChannel1, uv * 1.0);
                
                light += tex.xyz * 0.08;
            }
            
            light *= softShadow(pos, l, 8.0) * 1.5;
            light = mix(light, sssColor, calcSSS(pos, rd));
            light += calcAO(pos, n) * 0.3;
            
            // --- POST-PROCESSING FOR BRIGHTNESS, CONTRAST, SATURATION ---
            vec3 finalColor = light; // Start with the calculated light/color
            
            // Apply Brightness
            finalColor *= BRIGHTNESS;

            // Apply Contrast (around a mid-gray point, typically 0.5)
            finalColor = (finalColor - 0.5) * CONTRAST + 0.5;

            // Apply Saturation (Luminance preserving)
            // Calculate luminance
            float luma = dot(finalColor, vec3(1.0)); // sRGB luminance coefficients
            // Interpolate between grayscale and original color
            finalColor = mix(vec3(luma), finalColor, SATURATION);

            fragColor = vec4(finalColor, 1.0); // Assign the post-processed color
            
            return;
        }

        pos += distance * rd;
    
    }
    
    fragColor = vec4(1.0, 0.2, 0.0, 1.0);    
}