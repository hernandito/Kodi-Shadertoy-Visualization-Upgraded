// GLSL ES 1.0 / Shadertoy Cross-Compatible
// Converted to be compatible with Kodi/GLSL ES 1.0, including new configuration parameters.

precision highp float;
precision highp int;



// ------------------------------------------------------------------
// --- USER CONFIGURATION ---
// ------------------------------------------------------------------
#define AA 1

// 1. Post-Processing BCS (Brightness, Contrast, Saturation)
#define BRIGHTNESS_ADJ 0.10   // -1.0 to 1.0 (0.0 is neutral)
#define CONTRAST_ADJ   1.85   // 0.0 to 2.0 (1.0 is neutral)
#define SATURATION_ADJ .50    // 0.0 to 2.0 (1.0 is neutral)

// 2. Camera/View
#define CAMERA_FOV 1.9        // Determines zoom (Lower value = wide angle/zoomed out, Higher value = telephoto/zoomed in)

// 3. Object Motion
#define RING_ROTATION_SPEED 0.001 // Speed of the entire rod grouping rotation (0.0 disables wave animation speed is separate)

// 4. Geometry Color (RGB: 0.0 to 1.0) - Currently set to light metallic blue
#define GEOMETRY_R 0.2
#define GEOMETRY_G 0.45
#define GEOMETRY_B 0.0

// 5. Screen Offset (NEW PARAMETER)
#define SCREEN_Y_OFFSET 0.07   // Vertical screen offset (-1.0 moves scene up, 1.0 moves scene down)
// ------------------------------------------------------------------

// Helper function to safely define the geometry color
vec3 getGeometryColor() {
    return vec3(GEOMETRY_R, GEOMETRY_G, GEOMETRY_B);
}

// ------------------------------------------------------------------
// --- GLSL ES 1.0 Compatibility Functions ---
// ------------------------------------------------------------------

// The Robust Tanh Conversion Method
vec3 tanh_approx_3(vec3 x) { 
    const float EPSILON = 1e-6; 
    // tanh(x) ~ x / (1 + |x|)
    return x / (1.0 + max(abs(x), vec3(EPSILON))); 
}

// Standard Distance Field Primitive
float sdCylinder(vec3 p, float r, float h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// ------------------------------------------------------------------
// --- BCS Post-Processing ---
// ------------------------------------------------------------------

vec3 applyBCS(vec3 color, float B, float C, float S) {
    // 1. Brightness
    color += B;

    // 2. Contrast (pivots around 0.5)
    // C must be >= 0.0 to prevent color inversion
    float contrast = max(0.0, C);
    color = (color - 0.5) * contrast + 0.5;

    // 3. Saturation (Gray point is calculated using luminance)
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(luma);
    color = mix(gray, color, S);

    return color;
}

// ------------------------------------------------------------------
// --- World Definition & Logic ---
// ------------------------------------------------------------------

float map(vec3 p) {
    float minDist = 1e6;
    
    // Configuration constants
    float spacingA = 0.3;        
    float spacingB = 0.26;       
    float rodRadius = 0.065;     
    float rodHeight = 1.5;       
    int numRings = 14;           
    
    // Apply object rotation to p.xz coordinates
    float rotation = iTime * RING_ROTATION_SPEED;
    float c = cos(rotation);
    float s = sin(rotation);
    
    // Rotate the XZ plane of the current ray marching point
    float x_rot = p.x * c - p.z * s;
    float z_rot = p.x * s + p.z * c;
    p.x = x_rot;
    p.z = z_rot; 
    
    // Wave configuration
    float waveTime = iTime*.2 * 0.9;
    float maxRadius = (float(numRings) + 0.5) * spacingA;
    float waveRadius = maxRadius * 0.65; 
    float waveAmplitude = 2.00; 
    float waveWidth = 3.; 
    
    // Two wave center positions (opposite each other)
    vec2 waveCenter1 = vec2(cos(waveTime), sin(waveTime)) * waveRadius;
    vec2 waveCenter2 = -waveCenter1; 
    
    // Concentric rings starting from ring 0
    for (int ring = 0; ring <= numRings; ring++) {
        float numRods = 0.0;
        float ringRadius = 0.0;
        
        if (ring == 0) {
            numRods = 4.0;
            ringRadius = spacingA/1.7;
        } else {
            ringRadius = (float(ring)+0.5) * spacingA;
            float circumference = 2.0 * 3.14159 * ringRadius;
            numRods = floor((circumference / spacingB + 0.5) + (circumference*2.0) - 9.4);
        }
        
        // Calculate angle between rods (Robust division)
        float angleStep = 2.0 * 3.14159 / max(numRods, 1e-6);
        
        // Get current angle
        float angle = atan(p.z, p.x);
        
        // Find nearest rod in this ring using domain repetition
        float rodIndex = floor(angle / angleStep + 0.5);
        float rodAngle = rodIndex * angleStep;
        
        // Position of the rod center
        vec3 rodCenter = vec3(cos(rodAngle) * ringRadius, 0.30, sin(rodAngle) * ringRadius);
        
        // Calculate wave influence on this rod
        vec2 rodPos2D = rodCenter.xz;
        float dist1 = length(rodPos2D - waveCenter1);
        float dist2 = length(rodPos2D - waveCenter2);
        float minWaveDist = min( 2.2, min(dist1, dist2));
        
        // Create smooth wave using cosine
        float wave = cos(minWaveDist / waveWidth * 3.14159) * 0.5 + 0.5;
        wave = smoothstep(0.0, 1.0, wave);
        float heightOffset = wave * waveAmplitude;
        
        // Adjust rod center with height offset
        vec3 adjustedRodCenter = rodCenter + vec3(0.0, heightOffset, 0.0);
        
        // Distance to this rod
        float dist = sdCylinder(p - adjustedRodCenter, rodRadius, rodHeight);
        minDist = min(minDist, dist);
    }
    
    return minDist;
}


vec3 calcNormal(vec3 p) {
    const vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}


vec3 lighting(vec3 p, vec3 normal, vec3 rayDir, vec3 lightPos) {
    vec3 lightDir = normalize(lightPos - p);
    
    float diff = max(dot(normal, lightDir), 0.0);
    
    // Use the defined geometry color
    vec3 geoColor = getGeometryColor();
    
    // Modulate ambient and diffuse components by the defined geometry color
    vec3 ambient = geoColor * 0.4;
    vec3 diffuse = geoColor * 0.5 * diff;
    
    return ambient + diffuse;
}


float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 60; i++) {
        vec3 p = ro + t * rd;
        float d = map(p);
        if (d < 0.001 || t > 50.0) break;
        t += d/2.0; 
    }
    return t;
}

void mainImage0(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Apply the vertical screen offset
    uv.y += SCREEN_Y_OFFSET; 
    
    float time = iTime*.2 * 0.3;
    float camDist = 14.0;
    float camHeight = 13.0;
    vec3 ro = vec3(cos(time) * camDist, camHeight, sin(time) * camDist);
    vec3 ta = vec3(0.0, 0.0, 0.0);
    
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = normalize(cross(uu, ww));
    
    // Apply CAMERA_FOV define here
    vec3 rd = normalize(uv.x * uu + uv.y * vv + CAMERA_FOV * ww);

    float t = raymarch(ro, rd);
    vec3 bg = vec3(0.1, 0.1, 0.1);
    vec3 color = bg;
    
    if (t < 40.0) {
        vec3 p = ro + t * rd;
        vec3 normal = calcNormal(p);
        vec3 lightPos = vec3(0.0, 8.0, 0.0);
        
        color = lighting(p, normal, rd, lightPos)*(1.0+p.y/2.0);
    }
    
    color = max(bg, color);
    
    // 1. Apply BCS adjustments (Brightness, Contrast, Saturation)
    color = applyBCS(color, BRIGHTNESS_ADJ, CONTRAST_ADJ, SATURATION_ADJ);
    
    // 2. Tanh Conversion Method: Replaced native tanh with robust approximation for tone mapping
    color = tanh_approx_3(color * 1.2);
    
    fragColor = vec4(color, 1.0);
}

// multisampling
void mainImage(out vec4 o, vec2 u) 
{ 
    float s = float(AA); 
    float k = 0.0; 
    vec4 c = vec4(0.0);
    
    vec2 j = vec2(.5); 
    o = vec4(0); 
    
    // Sample 1 (for initial value)
    mainImage0(c, u); 
    
    // Multisampling loop
    for (k = s; k-- > 0.5; ) { 
        mainImage0(c, u + j - 0.5); 
        o += c; 
        j = fract(j + vec2(.755, .57).yx); 
    }
    
    // Robust division
    o /= max(s, 1e-6); 
    
    // Ensure alpha is 1.0
    o.a = 1.0; 
}
