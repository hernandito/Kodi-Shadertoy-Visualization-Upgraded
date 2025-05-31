// Constants
#define MAX_STEPS 200
#define MAX_DIST 250.0
#define SURF_DIST 0.01

// SDFs
float sdSphere(vec3 p, float r) { return length(p) - r; }
float sdPlane(vec3 p) { return p.y; }

// Scene SDF with object IDs (0=sphere, 1=plane)
vec2 sceneDistWithID(vec3 p) {
    vec3 spherePos = vec3(0., 1.0, 7.);
    float sphere = sdSphere(p - spherePos, 1.0);
    float plane = sdPlane(p);
    
    if (sphere < plane) return vec2(sphere, 0.0); // Sphere
    else return vec2(plane, 1.0); // Plane
}

// Ray marching with object ID
vec2 rayMarch(vec3 ro, vec3 rd) {
    float dist = 0.0;
    float objID = -1.0;
    
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dist;
        vec2 d = sceneDistWithID(p);
        dist += d.x;
        
        if (d.x < SURF_DIST) return vec2(dist, d.y); // Hit
        if (dist > MAX_DIST) break;
    }
    return vec2(MAX_DIST, -1.0); // Miss
}

// Normal calculation
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.01, 0);
    return normalize(vec3(
        sceneDistWithID(p).x - sceneDistWithID(p - e.xyy).x,
        sceneDistWithID(p).x - sceneDistWithID(p - e.yxy).x,
        sceneDistWithID(p).x - sceneDistWithID(p - e.yyx).x
    ));
}

// Shadow ray marching
vec2 rayMarchShadow(vec3 ro, vec3 rd, float maxDist) {
    float dist = 0.0;
    float minDist = 1e10;
    
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dist;
        float h = sceneDistWithID(p).x;
        minDist = min(minDist, h);
        dist += h;
        
        if (h < SURF_DIST || dist > maxDist) break;
    }
    return vec2(dist, minDist);
}

// Shadow calculation with softness, disabled for plane
float getShadow(vec3 p, vec3 normal, vec3 toLight, float lightDist, float objID) {
    // Disable shadow casting on the plane (objID >= 0.5)
    if (objID >= 0.5) {
        return 1.0; // No shadow from light on the plane
    }
    
    vec2 shadowResult = rayMarchShadow(p + normal * 0.02, toLight, lightDist);
    float shadowDist = shadowResult.x;
    float minDist = shadowResult.y;
    if (shadowDist >= lightDist - 0.1) {
        return 1.0;
    } else {
        float k = 8.0; // Softness factor
        return mix(0.2, 1.0, smoothstep(0.0, 1.0, k * minDist / lightDist));
    }
}

// Simple noise function for dithering based on fragment coordinates
float ditherNoise(vec2 fragCoord) {
    return fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453);
}

// Background color
vec3 bgcol(vec3 rd) {
    return vec3(0.10); // Matches plane base color for cyclorama effect
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 ro = vec3(0, 5, -12);
    vec3 rd = normalize(vec3(uv, 1));
    
    vec2 marchResult = rayMarch(ro, rd);
    float dist = marchResult.x;
    float objID = marchResult.y;
    
    vec3 col = bgcol(rd); // Background
    if (dist < MAX_DIST) {
        vec3 p = ro + rd * dist;
        vec3 normal = getNormal(p);
        vec3 lightPos = vec3(-2, 5, 8);
        lightPos.xz += 5.0 * vec2(cos(iTime), sin(iTime));
        vec3 toLight = normalize(lightPos - p);
        float lightDist = length(lightPos - p);
        float shadow = getShadow(p, normal, toLight, lightDist, objID); // Pass objID to disable shadow on plane
        
        // Diffuse term
        float diffuse = max(dot(normal, toLight), 0.0);
        
        // Specular term (Phong model)
        vec3 viewDir = -rd;
        vec3 reflectDir = reflect(-toLight, normal);
        float specular = pow(max(dot(viewDir, reflectDir), 0.5), 64.0); // Shininess 64 for well-defined highlight
        
        // Colors
        // Warm light color and intensity setting
        vec3 lightColor = vec3(1.2, 0.96, 0.6) * 1.3; // Warm light (previously adjusted)
        vec3 sphereColor = vec3(1.0, 0.0, 0.0); // Bright red
        vec3 planeColor = vec3(0.5); // Gray floor
        vec3 specularColor = vec3(1, 0.882, 0.424); // White specular
        
        // Ambient lighting parameter for the sphere
        float ambientStrength = 0.15; // Subtle brightening for sphere
        vec3 ambient = ambientStrength * sphereColor; // Ambient term for sphere
        
        if (objID < 0.5) { // Sphere
            col = sphereColor * diffuse * lightColor * shadow + specularColor * specular * shadow + ambient;
        } else { // Plane
            // Base plane lighting
            col = planeColor * diffuse * lightColor * shadow;
            
            // Contact shadow: Darken area where ball touches floor
            vec2 contactPoint = vec2(0.0, 3.0); // Ball's contact point (x, z)
            float contactDist = length(p.xz - contactPoint); // Distance to contact point
            float contactShadow = smoothstep(0.0, 1.5, contactDist); // Blurred edge, radius 1.5
            float shadowIntensity = 0.1; // Darkest shadow intensity (0.0 = black, 1.0 = no shadow)
            col *= mix(shadowIntensity, 1.0, contactShadow); // Darken near contact point
            
            // Cyclorama effect: Blend based on ray angle and distance
            float horizonBlend = 1.0 - smoothstep(0.0, 0.5, abs(dot(normalize(p - ro), vec3(0, 1, 0))));
            col = mix(col, bgcol(rd), horizonBlend);
            
            // Dither effect to reduce banding on the floor
            float ditherAmount = 1.0 / 255.0; // Small amplitude to match 8-bit color depth
            // Guidance:
            // - ditherAmount = 1.0/255.0: Subtle dithering, suitable for 8-bit displays (default).
            // - ditherAmount = 2.0/255.0: More pronounced dithering, if banding persists.
            // - ditherAmount = 0.0: Disables dithering, may show banding.
            float noise = ditherNoise(fragCoord) * ditherAmount;
            col += noise; // Add dither noise to break up banding
        }
    }
    
    // Gamma correction for more "punch"
    float gamma = 2.2; // Default gamma value (standard for most displays)
    // Guidance:
    // - gamma = 2.2: Standard display gamma, balanced look (default).
    // - gamma < 2.2 (e.g., 1.8): Brightens midtones, increases vibrancy, adds "punch".
    // - gamma > 2.2 (e.g., 2.6): Darkens midtones, increases contrast, may lose shadow detail.
    col = pow(col, vec3(1.0));
    
    fragColor = vec4(col, 1.0);
}