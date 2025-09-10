// Day 20!
// Spirals!

# define res iResolution.xy
# define PI 3.141

# define lightDir normalize(vec3(0.0, -1.0, 0.0))

// IQ's distance to a plane.
float sdPlane( vec3 p, vec3 n, float h )
{
    return dot(p,n) + h;
}

float map(vec3 p) {
    // Flip the coordinate so that it travels along the X axis.
    p.xyz = p.zxy;
    
    // Change the angle based off of iTime.
    // This, for some reason, creates the illusion of movement.
    float angle = 2.0 * p.y + iTime * 0.4;
    
    // Rotate based on the angle.
    float c = cos(angle);
    float s = sin(angle);
    
    p.xz *= mat2(c, -s, s, c);
    
    // Return the distance to a plane.
    return sdPlane(p, normalize(vec3(0.0, 1.0, 1.0)), 0.5);
}

vec3 getNormal(vec3 p) {
    float e = 0.0005;
    vec2 h = vec2(e, 0.0);
    return normalize(vec3(
        map(p + h.xyy) - map(p - h.xyy),
        map(p + h.yxy) - map(p - h.yxy),
        map(p + h.yyx) - map(p - h.yyx)
    ));
}

// IQ's palette
// ( shadertoy.com/view/ll2GD3 )
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

void mainImage(out vec4 O, vec2 I) {
    // Explicit variable initialization
    vec2 p = vec2(0.0);
    vec3 camPos = vec3(0.0);
    vec3 camDir = vec3(0.0);
    vec3 worldUp = vec3(0.0);
    vec3 camRight = vec3(0.0);
    vec3 camUp = vec3(0.0);
    vec3 rayPos = vec3(0.0);
    vec3 rayDir = vec3(0.0);
    float t = 0.0;
    bool hit = false;
    float glow = 0.0;
    vec3 hitPoint = vec3(0.0);
    vec3 col = vec3(0.0);
    
    p = (I - 0.5 * res) / max(res.y, 1e-6) * 7.0;
    
    // Camera.
    camPos = vec3(0.0, 0.0, 0.0);
    camDir = normalize(vec3(1.0, 0.0, 0.0));
    
    float fov = radians(45.0);
    worldUp = vec3(0.0, 1.0, 0.0);
    
    // Make divisions robust
    camRight = normalize(cross(camDir, worldUp));
    camUp = cross(camRight, camDir);
    
    // Ray.
    rayPos = camPos;
    t = tan(fov * 0.5);
    rayDir = normalize(camDir + p.x * camRight * t + p.y * camUp * t);
    
    // Instead of raymarching, which leads to some horrid artifacts, 
    // the ray is being marched in a fixed step size.
    
    // This means that I had to significantly increase the maximum number of steps
    // lowering the performance.
    const int maxSteps = 1000;
    const float stepSize = 0.01;
    
    for(int i = 0; i < maxSteps; i++) {
        // Take the distance.
        float d = map(rayPos);
        
        // Accumulate glow.
        // The nice thing about the fixed step size is that it makes it quite 
        // easy to accummulate things, as it acts almost as an approximation for
        // an integral.
        glow += exp(-d * 10.0) * stepSize;
    
        // If the ray is close enough, call it a hit and break.
        if(d < 0.001) {hit = true; break;}
        
        // Move the ray along it's direction with the step size
        rayPos += stepSize * rayDir;
    }
    
    hitPoint = rayPos;
    
    // Coloring!
    if(hit) {
        // Get the normal vector of the map.
        vec3 normal = getNormal(hitPoint);
        
        // Bottom and top lighting.
        float light1 = dot(normal, lightDir);
        float light2 = dot(normal, -lightDir);
        
        // The camera is facing along the x axis, so take the x part of
        // the hit point for coloring.
        t = hitPoint.x * 0.2;
        
        // Use the pallete to get a color.
        vec3 a = vec3(0.5, 0.5, 0.5);
        vec3 b = vec3(1.0, 1.0, 1.0);
        vec3 c = vec3(1.0, 1.0, 1.0);
        vec3 d = vec3(0.0, 0.1, 0.2);
        
        vec3 color = pal(t, a, b, c, d);
        
        // Calculate the lighting.
        float light = max(light1, 0.0) + max(light2, 0.0);
        col = color * light;
        
        // Fog.
        float fd = length(hitPoint - camPos);
        fd /= max(stepSize * float(maxSteps), 1e-6);
        col = mix(col, vec3(0.0, 0.0, 0.0), fd);           
        
        // Apply the glow.
        col += color * glow;
    }

    O = vec4(col, 1.0);
}