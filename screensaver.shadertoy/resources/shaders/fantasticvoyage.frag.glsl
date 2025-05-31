/*
    Simplified, Traced Minkowski Tube.
    ----------------------------------
    
    This was inspired by Shadertoy user Akaitora's "Worley Tunnel" which you can find here:
    https://www.shadertoy.com/view/XtjSzR
    
    Modified by Grok to adjust travel speed, Voronoi cell size, brightness/contrast, Voronoi pattern variation,
    remove camera look-around motion, adjust light reach, change to a cylindrical tunnel with bump mapping,
    smooth lighting transition, and adjust camera target to a smaller tilt.
*/

// Parameters
const float travelSpeed = 0.06; // Travel speed through the tunnel
const float voronoiScale = 5.0; // Voronoi cell scale (smaller cells/more cells)
const float voronoiVariation = 0.0; // Variation in Voronoi cell shapes/sizes (0.0 = uniform)
const float brightness = -0.025; // Brightness adjustment (-1.0 to 1.0, 0.0 = no change)
const float contrast = 1.09; // Contrast adjustment (0.0 to 2.0, 1.0 = no change)
const float lightReach = 0.5; // Light falloff control (0.0 to 2.0, smaller = light reaches deeper)
const vec2 tunnelScale = vec2(1.0, 1.0); // Scale of the cylinder (adjust aspect ratio if needed)
const float targetOffsetX = 0.9; // Offset of the camera target to the right (between 0.75 and 1.0)
const float lightOffsetZ = 0.5; // Light position offset ahead of camera (closer to green square area)

// 2D rotation (kept for potential future use, but not used now).
mat2 rot(float th) { 
    float cs = cos(th), si = sin(th); 
    return mat2(cs, -si, si, cs); 
}

// Hash function for introducing variation in Voronoi pattern
vec3 hash33(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yzx + 33.33);
    return fract((p.xxy + p.yzz) * p.zyx);
}

// 3D Voronoi-like function with variation parameter
float Voronesque(in vec3 p) {
    vec3 i = floor(p + dot(p, vec3(0.333333))); 
    p -= i - dot(i, vec3(0.166666));
    vec3 i1 = step(p.yzx, p), i2 = max(i1, 1.0 - i1.zxy); 
    i1 = min(i1, 1.0 - i1.zxy);    
    vec3 p1 = p - i1 + 0.166666;
    vec3 p2 = p - i2 + 0.333333;
    vec3 p3 = p - 0.5;
    vec3 offset1 = hash33(i + i1) * voronoiVariation;
    vec3 offset2 = hash33(i + i2) * voronoiVariation;
    vec3 offset3 = hash33(i + 1.0) * voronoiVariation;
    p1 += offset1;
    p2 += offset2;
    p3 += offset3;
    vec3 rnd = vec3(7.0, 157.0, 113.0);
    vec4 v = max(0.5 - vec4(dot(p, p), dot(p1, p1), dot(p2, p2), dot(p3, p3)), 0.0);
    vec4 d = vec4(dot(i, rnd), dot(i + i1, rnd), dot(i + i2, rnd), dot(i + 1.0, rnd));
    d = fract(sin(d) * 262144.0) * v * 2.0; 
    v.x = max(d.x, d.y);
    v.y = max(d.z, d.w);
    v.z = max(min(d.x, d.y), min(d.z, d.w));
    v.w = min(v.x, v.y); 
    return max(v.x, v.y) - max(v.z, v.w);  
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Screen coordinates, centered without look-around motion
    vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
    
    // Camera position (travels along the center of the tunnel)
    vec3 ro = vec3(0.0, 0.0, iTime * travelSpeed);
    
    // Camera target (1 unit ahead, offset to the right)
    vec3 target = ro + vec3(targetOffsetX, 0.0, 1.0);
    
    // Camera coordinate system
    vec3 forward = normalize(target - ro); // Forward direction (tilted to the right)
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward)); // Right vector
    vec3 up = cross(forward, right); // Up vector
    
    // Ray direction (adjusted to tilt toward the right)
    vec3 rd = normalize(forward + uv.x * right + uv.y * up);
 
    // Screen color, initialized to black
    vec3 col = vec3(0.0);
    
    // Ray intersection of a cylindrical tube
    float sDist = max(length(rd.xy * tunnelScale), 1e-16); 
    sDist = 1.0 / sDist; // Distance to the cylinder surface (radius 1.0)
    
    // Surface position
    vec3 sp = ro + rd * sDist;
 
    // Surface normal for a cylinder
    vec3 sn = normalize(vec3(-sp.xy * tunnelScale * tunnelScale, 0.0));
    
    // Bump mapping
    vec2 eps = vec2(0.025, 0.0);
    float c = Voronesque(sp * voronoiScale); // Base value for coloring
    vec3 gr = (vec3(Voronesque((sp - eps.xyy) * voronoiScale), 
                    Voronesque((sp - eps.yxy) * voronoiScale), 
                    Voronesque((sp - eps.yyx) * voronoiScale)) - c) / eps.x;
    gr -= sn * dot(sn, gr);
    sn = normalize(sn + gr * 0.1);

    // Lighting
    vec3 lp = vec3(0.0, 0.0, iTime * travelSpeed + lightOffsetZ); // Light closer to camera
    vec3 ld = lp - sp;
    float dist = max(length(ld), 0.001);
    ld /= dist;

    // Custom attenuation for smoother falloff
    float atten = 1.0 / (1.0 + pow(dist * lightReach, 1.5)); // Smoother falloff (exponential-like)
    atten = clamp(atten, 0.0, 1.0);
    float diff = max(dot(sn, ld), 0.0);
    float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.0), 16.0);
    float ref = Voronesque((sp + reflect(rd, sn) * 0.5) * voronoiScale);
    
    // Coloring the surface
    vec3 objCol = pow(min(vec3(1.5, 1.0, 1.0) * (c * 0.97 + 0.03), 1.0), vec3(1.0, 3.0, 16.0));
    col = (objCol * (diff + ref * 0.35 + 0.25 + vec3(1.0, 0.9, 0.7) * spec) + (c + 0.35) * vec3(0.25, 0.5, 1.0) * ref) * atten;
    
    // Apply brightness and contrast adjustments
    col = col * contrast + (brightness + 0.5 * (1.0 - contrast));
    
    // Rough gamma correction
    fragColor = vec4(sqrt(clamp(col, 0.0, 1.0)), 1.0);
}