// Day 57!
// A bit of insperation taken from shadertoy.com/view/33syzM . iTime

// =========================================================================
// USER-TUNABLE PARAMETERS
// =========================================================================
// Controls the density of the rods. Smaller value = Denser rods. (Default: 0.2)
#define ROD_CELL_SIZE 0.1

// =========================================================================
// POST-PROCESSING PARAMETERS (Brightness, Contrast, Saturation)
// =========================================================================
#define BRIGHTNESS 0.01  // Adjusts overall lightness (-1.0 to 1.0)
#define CONTRAST   1.03  // Adjusts the intensity difference (0.0 to 2.0)
#define SATURATION 1.0  // Adjusts color vividness (0.0 for grayscale, 1.0 for normal)

// =========================================================================
// OUTPUT CLAMP PARAMETER
// =========================================================================
#define OUTPUT_CLAMP_MAX (0.65) // Clamps the final bright colors to a maximum value.

#define res iResolution.xy

float gv;

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
    return a + b * cos(6.28318 * (c * t + d));
}

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 34.0);
    return fract(sin(p.x + p.y) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float a = 1.0;
    float f = 0.5;
    float r = 0.0;
    
    for (int i = 0; i < 5; i++) {
        r += f * noise(p * a);
        
        a *= 2.0;
        f *= 0.5;
    }
    
    return r;
}

float sdSphere(vec3 p, float s)
{
    return length(p) - s;
}

float sdCappedCylinder(vec3 p, float h, float r)
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float map(vec3 p) { 
    vec3 q = p;
    
    // Repetition technique for the rod grid
    float s = ROD_CELL_SIZE; // Controlled by the new parameter
    vec2 cell = floor(q.xz / s);
    float d1 = 1e20;

    for (int j = -2; j <= 2; ++j) {
        for (int i = -2; i <= 2; ++i) {
            vec2 rid = cell + vec2(float(i), float(j));
            vec2 center = (rid + 0.5) * s;
            vec3 rp = q;
            rp.xz -= center;
            float seed = hash(rid);

            // Rod height is animated and seeded
            float h = 0.4 + 0.9 * (0.5 + 0.5 * sin(iTime * .25 * 1.3 + seed * 6.282));

            // Rod geometry: Capped Cylinder with height h and radius h * 0.05
            float d = sdCappedCylinder(rp, h, h * 0.05);
            
            // Find the closest rod (minimum distance) and save its seed value
            if (d < d1) { d1 = d; gv = seed; }
        }
    }
    
    return d1;
}

vec3 getNormal(in vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773;
    const float eps = 0.001;
    return normalize(e.xyy * map(pos + e.xyy * eps) + 
                     e.yyx * map(pos + e.yyx * eps) + 
                     e.yxy * map(pos + e.yxy * eps) + 
                     e.xxx * map(pos + e.xxx * eps));
}

void mainImage(out vec4 O, in vec2 I)
{
    vec2 p = 3.0 * (I - 0.5 * res) / res.y;
    
    vec3 camPos = vec3(3.0, 3.0, -iTime * .1);
    vec3 camDir = normalize(vec3(0.0, -0.9, -1.0));
    
    float fov = radians(45.0);
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 camRight = normalize(cross(camDir, worldUp));
    vec3 camUp = cross(camRight, camDir);

    vec3 rayPos = camPos;
    float t = tan(fov * 0.5);
    vec3 rayDir = normalize(camDir + p.x * camRight * t + p.y * camUp * t);
    
    const float factor = 1.0;
    const int maxSteps = 200;
    bool hit = false; 
    
    int n = 0;
    for (int i = 0; i < maxSteps; i++) { 
        float d = map(rayPos) * factor;

        if (d < 0.01) { hit = true; break; }

        rayPos += rayDir * d; n++;
    }
    
    vec3 col = vec3(0.0);
    
    if (hit) {
        vec3 hitPoint = rayPos;
        
        vec3 normal = getNormal(hitPoint);
        
        vec3 lightDir = normalize(vec3(0.3, 0.7, 0.2));
        float light = dot(lightDir, normal);
        
        // Palletized color based on rod seed value
        vec3 color = 0.3 + 0.5 * pal(gv, 
                                     vec3(0.5, 0.5, 0.5),
                                     vec3(0.5, 0.5, 0.5),
                                     vec3(.50, .5, .5),
                                     vec3(0.0, 0.1, 0.2));
        
        float fog = min(pow(1.0 / length(rayPos - camPos) * 4.0, 3.0), 1.0);
        
        // Approximate Ambient Occlusion (steps taken)
        float AO = pow(1.0 - float(n) / float(maxSteps), 20.0);
        
        col = color * light * fog * AO;
        
        // ----------------------------------------------------
        // Apply Brightness, Contrast, Saturation (BCS)
        // ----------------------------------------------------
        
        // 1. Brightness
        col += BRIGHTNESS; 
        
        // 2. Contrast (pivots around 0.5 gray)
        col = (col - 0.5) * CONTRAST + 0.5;
        
        // 3. Saturation (standard luma weights: 0.2126, 0.7152, 0.0722)
        float gray = dot(col, vec3(0.2126, 0.7152, 0.0722));
        col = mix(vec3(gray), col, SATURATION); 
    }

    // Apply final exposure boost (the original * 3.0 multiplier)
    col *= 3.0;

    // Apply the user-requested clamp: max value is OUTPUT_CLAMP_MAX
    col = clamp(col, 0.0, OUTPUT_CLAMP_MAX);
    
    // Final output: use the clamped color and a fixed alpha of 1.0
    O = vec4(col, 1.0);
}
