// Fork of https://www.shadertoy.com/view/3sKXDK by SebH (https://twitter.com/SebHillaire)
// by ootsta (https://twitter.com/ootsta)

// Amanatides 3D DDA marching implementation - Paper: http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.42.3443&rep=rep1&type=pdf
// Use mouse left to rotate camera (X axis)
// Morphed from https://www.shadertoy.com/view/MdlyDs

#define VOLUME_SIZE 200
#define USE_TEXTURE 1

// --- BCS Parameters ---
#define BRIGHTNESS -0.10   // -1.0 to 1.0, 0.0 is no change
#define CONTRAST   1.20   // 0.0 to inf, 1.0 is no change
#define SATURATION 1.0   // 0.0 to inf, 1.0 is no change
// --- End BCS Parameters ---

float sampleMap(vec3 uvs, out vec3 col)
{   
#if USE_TEXTURE
    vec4 t = texture(iChannel0, uvs.xz);
#else
    vec4 t = vec4(1.0*sin(uvs.x*uvs.z*15.0), 0.1+uvs.y, 0.1+uvs.y, 1.0); 
#endif
    col = t.rgb;    
    return uvs.y*8.0 > t.r ? 0.0: 1.0;
        
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    const float sz = float(VOLUME_SIZE);
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 color = vec3(0.0, 0.0, 0.0);
    
    vec2 mouseControl = iMouse.xy / iResolution.xy;
    vec3 viewDir = normalize(vec3((fragCoord.xy - iResolution.xy*0.35) / iResolution.y, 1.0));
    float viewAngle = iMouse.z<=0.0 ? iTime*0.02 : mouseControl.x * 10.0f;
    float camDist = 0.5 * sz;
    vec3 camTarget = vec3(sz/2.0,0.0,sz/2.0);
    vec3 camPos = camTarget + vec3(camDist*cos(viewAngle), camDist, camDist*sin(viewAngle));
    
    vec3 camUp = vec3(0,1.0,0);
    vec3 forward = normalize(camTarget - camPos);
    vec3 left = normalize(cross(forward, camUp));
    vec3 up = cross(left, forward);
    vec3 worldDir = normalize(viewDir.x*left + viewDir.y*up + viewDir.z*forward);
    
    vec3 D = worldDir; // Ray direction
    vec3 P = camPos;   // Ray position

    // Amanatides 3D-DDA data preparation
    vec3 stepSign = sign(D);
    vec3 tDelta = abs(1.0 / D);
    vec3 tMax = vec3(0.0, 0.0, 0.0);
    vec3 refPoint = floor(P);
    tMax.x = stepSign.x > 0.0 ? refPoint.x+1.0 - P.x : P.x - refPoint.x; // floor is more consistent than ceil iTime
    tMax.y = stepSign.y > 0.0 ? refPoint.y+1.0 - P.y : P.y - refPoint.y;
    tMax.z = stepSign.z > 0.0 ? refPoint.z+1.0 - P.z : P.z - refPoint.z;
    tMax.x *= tDelta.x;
    tMax.y *= tDelta.y;
    tMax.z *= tDelta.z;


    for (int i=0; i<384; i++) {
        // Amanatides 3D-DDA 
        if(tMax.x < tMax.y) {
            if(tMax.x < tMax.z) {
                P.x += stepSign.x;
                tMax.x += tDelta.x;
            } else {
                P.z += stepSign.z;
                tMax.z += tDelta.z;
            }
        } else {
            if(tMax.y < tMax.z) {
                P.y += stepSign.y;
                tMax.y += tDelta.y;
            } else {
                P.z += stepSign.z;
                tMax.z += tDelta.z;
            }
        }
        
        if (P.x < 0.0 || P.x > sz || P.z < 0.0 || P.z > sz) break;

        vec3 voxel = floor(P);
        vec3 voxelcol;
        if(sampleMap(vec3(voxel)/sz, voxelcol) > 0.0) {
            color = voxelcol;
            break;
        }
    }           
    
    color = pow(color, vec3(1.0/1.5)); // simple linear to gamma

    // --- Apply BCS Adjustments ---
    // Brightness
    color += BRIGHTNESS;

    // Contrast
    color = (color - 0.5) * CONTRAST + 0.5;

    // Saturation
    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(luminance), color, SATURATION);
    // --- End BCS Adjustments ---

    fragColor = vec4(color, 1.0);
}