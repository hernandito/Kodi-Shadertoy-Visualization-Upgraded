// Sphere SDF
float sdSphere(vec3 p, float r){
    return length(p) - r;
}

// Mirroring 3d space on a plane specified by normal vector n
vec3 fold(vec3 p, vec3 n){
    n = normalize(n);
    return p - 2.0 * min(0.0, dot(p, n)) * n;
}
    
// Map function that takes in 3d point and returns distance to nearest object and a color iTime
vec4 map(vec3 p) {
    // Setup
    float dist = 10.0;
    float d = dist;
    vec3 col = vec3(0);
    
    // Scaling, offset and rotation at each step
    float Scale = 2.;
    vec3 Offset = vec3(.5, .5, .5);
    float th = 0.1;
    
    float maxIters = 15.;
    for (float i=0.; i<maxIters; i++){
        // First, make 3 folds and collect color based on fold
        if (-p.x + p.y + p.z < 0.){ p = fold(p, vec3(-1, 1, 1)); col.x += 1.5/maxIters;}
        if (p.x - p.y + p.z < 0.){ p = fold(p, vec3(1, -1, 1)); col.y += 1./maxIters; }
        if (p.x + p.y - p.z < 0.){ p = fold(p, vec3(1, 1, -1)); col.z += 0.5/maxIters; }
        
        // Then apply scaling, offset, and rotation
        p = p*Scale - Offset*(Scale-1.0);
        if (i > 5.){ // Add time variations at smaller scales
            th = 0.1 + .25 * sin(iTime*.3);
        }
        p = vec3(p.x * cos(th) - p.y * sin(th), p.x * sin(th) + p.y * cos(th), p.z);
    }
    
    // Add a sphere to the iteratively transformed space
    d = sdSphere(p, 1.) / pow(2., maxIters); // Correct for the scaling
    if (d < dist){
        dist = d;
    }
    
    return vec4(dist, col);
}

// Use map to calculate normal
vec3 getNormal(vec3 p) {
    float d = map(p).x;
    vec2 e = vec2(0.00001, 0.0);

    vec3 n = d - vec3(
        map(p - e.xyy).x,
        map(p - e.yxy).x,
        map(p - e.yyx).x
    );

    return normalize(n);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord*2.0 - iResolution.xy)/iResolution.y;

    // Mouse controls
    vec2 m = iMouse.xy;
    if (iMouse.z <= 0.0) {
        m = iResolution.xy * 0.5;
    }
    vec2 normMouse = (m / iResolution.xy - 0.5) * 2.0;
    uv = uv + normMouse;
    
    // Specify ray origin, ray direction, light position
    vec3 ro = vec3(0.275 + 0.00017 * iTime*.3, 0.341 + 0.0007 * iTime*.3, -.575 + 0.001 * iTime*.3);
    vec3 ta = ro + vec3(uv, 1.); 
    vec3 rd = normalize(ta - ro);
    vec3 lightPos = ro + vec3(0, 1, 0);
    
    // Raymarching information: iterations, distance for convergence, maximum ray distance
    float maxIters = 100.;
    float distMin = 0.00005;
    float distMax = 0.15;
    
    // Raymarching start setup
    float t=0.;
    vec3 col = vec3(0);
    float iters = 0.;
    
    for (float i=1.; i<=maxIters; i++) {
        // Get distance to and color of nearest object of the current position of the ray
        vec3 pos = ro + t*rd;
        vec4 dcol = map(pos);
        float dist = dcol.x;
        
        // If ray converges, get color and add lighting
        if (dist < distMin){
            col = dcol.yzw;
            vec3 l = normalize(lightPos - pos);
            vec3 n = getNormal(pos);
            float lighting = max(dot(n, l), 0.);
            col *= lighting;
            // Slowly fade into the background color if ray is far enough away
            if (t > 0.8*distMax){
                float mixFactor = (t - 0.8*distMax) / (0.2*distMax);
                mixFactor = pow(mixFactor, 0.5);
                col = mix(col, vec3(0), mixFactor);
                }
            break;
        }
        
        // If ray travels maximum distance, set background color
        if (t > distMax){
            col = vec3(0);
            break;
        }
    
    // Update distance travelled and number of iterations
    t += dist;
    iters++;
    }
    
    // Add a cyan glow effect
    col = col + iters / maxIters * vec3(0, 1, 1);
    
    // Output to screen
    fragColor = vec4(col,1.0);
}