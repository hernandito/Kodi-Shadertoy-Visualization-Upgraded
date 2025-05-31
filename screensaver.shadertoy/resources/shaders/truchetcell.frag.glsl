// Adjustable Parameters
#define Iterations 48
#define Thickness 0.05
#define SuperQuadPower 8.0
#define Fisheye 0.5

float animation_speed = 0.25; // Animation speed multiplier (< 1.0 slows down, > 1.0 speeds up)
int palette = 1; // Palette selection (0: Original, 1: Copper, 2: Silver)
int reflectionMode = 1; // Reflection mode (0: None, 1: Envmap with falloff, 2: Raytraced with hybrid fallback)
float reflectStrength = 0.3; // Base reflection strength (0.0 to 1.0)
float reflectionFalloffDist = 9.0; // Distance at which reflection strength falls to 0

// Core Shader Code
float rand(vec3 r) { return fract(sin(dot(r.xy,vec2(1.38984*sin(r.z),1.13233*cos(r.z))))*653758.5453); }

float truchetarc(vec3 pos)
{
    float r = length(pos.xy);
    return pow(pow(abs(r-0.5),SuperQuadPower)+pow(abs(pos.z-0.5),SuperQuadPower),1.0/SuperQuadPower)-Thickness;
}

float truchetcell(vec3 pos)
{
    return min(min(
        truchetarc(pos),
        truchetarc(vec3(pos.z,1.0-pos.x,pos.y))),
        truchetarc(vec3(1.0-pos.y,1.0-pos.z,pos.x)));
}

float distfunc(vec3 pos)
{
    vec3 cellpos = fract(pos);
    vec3 gridpos = floor(pos);

    float rnd = rand(gridpos);

    if(rnd<1.0/8.0) return truchetcell(vec3(cellpos.x,cellpos.y,cellpos.z));
    else if(rnd<2.0/8.0) return truchetcell(vec3(cellpos.x,1.0-cellpos.y,cellpos.z));
    else if(rnd<3.0/8.0) return truchetcell(vec3(1.0-cellpos.x,cellpos.y,cellpos.z));
    else if(rnd<4.0/8.0) return truchetcell(vec3(1.0-cellpos.x,1.0-cellpos.y,cellpos.z));
    else if(rnd<5.0/8.0) return truchetcell(vec3(cellpos.y,cellpos.x,1.0-cellpos.z));
    else if(rnd<6.0/8.0) return truchetcell(vec3(cellpos.y,1.0-cellpos.x,1.0-cellpos.z));
    else if(rnd<7.0/8.0) return truchetcell(vec3(1.0-cellpos.y,cellpos.x,1.0-cellpos.z));
    else return truchetcell(vec3(1.0-cellpos.y,1.0-cellpos.x,1.0-cellpos.z));
}

vec3 gradient(vec3 pos)
{
    const float eps = 0.0001;
    float mid = distfunc(pos);
    return vec3(
        distfunc(pos+vec3(eps,0.0,0.0))-mid,
        distfunc(pos+vec3(0.0,eps,0.0))-mid,
        distfunc(pos+vec3(0.0,0.0,eps))-mid);
}

// Function to convert a 3D direction to spherical UV coordinates for envmap sampling
vec2 directionToSphericalUV(vec3 dir)
{
    const float pi = 3.141592;
    float u = atan(dir.z, dir.x) / (2.0 * pi) + 0.5; // Azimuth
    float v = acos(dir.y) / pi; // Zenith
    return vec2(u, v);
}

// Raytraced reflection function
vec3 raytraceReflection(vec3 startPos, vec3 reflectDir, float maxDist)
{
    vec3 ray_pos = startPos;
    vec3 ray_dir = reflectDir;
    float totalDist = 0.0;
    const int maxSteps = 24; // Reduced steps for performance (half of Iterations)

    for(int j = 0; j < maxSteps; j++)
    {
        float dist = distfunc(ray_pos);
        totalDist += dist;
        ray_pos += dist * ray_dir;

        if(abs(dist) < 0.001)
        {
            // Hit something, compute basic lighting for the reflected surface
            vec3 normal = normalize(gradient(ray_pos));
            float ao = 1.0 - float(j) / float(maxSteps);
            float what = pow(max(0.0, dot(normal, -ray_dir)), 3.0);
            float light = ao * (0.1 + what * 1.4); // Simplified lighting
            return vec3(0.95, 0.74, 0.44) * light; // Use copper color for reflected surface
        }
        if(totalDist > maxDist) break; // Stop if too far
    }
    return vec3(0.0); // No reflection (black background)
}

void mainVR(out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir)
{
    vec3 ray_dir = fragRayDir;
    vec3 ray_pos = fragRayOri;

    float i = float(Iterations);
    for(int j = 0; j < Iterations; j++)
    {
        float dist = distfunc(ray_pos);
        ray_pos += dist * ray_dir;

        if(abs(dist) < 0.001) { i = float(j); break; }
    }

    vec3 normal = normalize(gradient(ray_pos));

    // Ambient Occlusion
    float ao = 1.0 - i/float(Iterations);

    // Diffuse-like term with increased sharpness
    float what = pow(max(0.0, dot(normal, -ray_dir)), 3.0); // Increased exponent from 2.0 to 3.0

    // Specular highlight (Blinn-Phong approximation)
    vec3 view_dir = -ray_dir; // View direction is opposite to ray direction
    vec3 light_dir = -ray_dir; // Assume light direction aligns with view direction for simplicity
    vec3 halfway = normalize(light_dir + view_dir);
    float spec = pow(max(0.0, dot(normal, halfway)), 32.0); // Sharp specular highlight

    // Combine lighting terms
    float ambient = 0.1; // Small ambient term to enhance metallic feel
    float diffuse = what * 1.4; // Diffuse contribution
    float specular = spec * 0.3; // Subtle specular contribution
    float light = ao * (ambient + diffuse + specular);

    // Select color palette
    vec3 col;
    if (palette == 0) {
        // Original palette (greenish-magenta with hue variation)
        col = (cos(ray_pos/2.0) + 2.0) / 3.0;
    } else if (palette == 1) {
        // Copper palette (metallic red-gold)
        col = vec3(0.95, 0.74, 0.44); // Fixed copper color
        col = col * light; // Apply lighting
    } else {
        // Silver palette (palette == 2, simplified)
        col = vec3(0.9, 0.9, 0.95); // Fixed silver color
        col = col * light; // Same lighting effect
    }

    // Handle reflections based on reflectionMode
    if (reflectionMode > 0)
    {
        vec3 reflectDir = reflect(ray_dir, normal); // Compute reflection direction

        // Calculate distance from camera to surface point
        float distFromCamera = length(ray_pos - fragRayOri);
        float falloff = clamp(1.0 - distFromCamera / reflectionFalloffDist, 0.0, 1.0); // Linear falloff

        // Apply falloff to reflection strength
        float adjustedReflectStrength = reflectStrength * falloff;

        vec3 reflectionColor = vec3(0.0); // Default to black (no reflection)

        if (reflectionMode == 1)
        {
            // Option 1: Environment map reflection
            vec2 uv = directionToSphericalUV(reflectDir);
            reflectionColor = texture2D(iChannel0, uv).rgb; // Sample envmap.png
        }
        else if (reflectionMode == 2)
        {
            // Option 2: Raytraced reflection (hybrid with distance cutoff)
            float maxRaytraceDist = 3.0; // Distance beyond which raytracing is skipped
            if (distFromCamera < maxRaytraceDist)
            {
                reflectionColor = raytraceReflection(ray_pos + normal * 0.01, reflectDir, maxRaytraceDist);
            }
            else
            {
                // Hybrid fallback: Use envmap beyond maxRaytraceDist
                vec2 uv = directionToSphericalUV(reflectDir);
                reflectionColor = texture2D(iChannel0, uv).rgb;
            }
        }

        col = mix(col, reflectionColor, adjustedReflectStrength); // Blend reflection with base color
    }

    fragColor = vec4(col, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    const float pi = 3.141592;

    vec2 coords = (2.0 * fragCoord.xy - iResolution.xy) / length(iResolution.xy);

    // Apply animation speed to camera motion only
    float anim_time = iTime * animation_speed;
    float a = anim_time / 3.0;
    mat3 m = mat3(
        0.0, 1.0, 0.0,
        -sin(a), 0.0, cos(a),
        cos(a), 0.0, sin(a));
    m *= m;
    m *= m;

    vec3 ray_dir = m * normalize(vec3(2.0 * coords, -1.0 + dot(coords, coords)));

    float t = anim_time / 3.0;
    vec3 ray_pos = vec3(
        2.0 * (sin(t + sin(2.0 * t) / 2.0) / 2.0 + 0.5),
        2.0 * (sin(t - sin(2.0 * t) / 2.0 - pi/2.0) / 2.0 + 0.5),
        2.0 * ((-2.0 * (t - sin(4.0 * t) / 4.0) / pi) + 0.5 + 0.5));

    mainVR(fragColor, fragCoord, ray_pos, ray_dir);

    float vignette = pow(1.0 - length(coords), 0.3);
    fragColor.xyz *= vec3(vignette);
}