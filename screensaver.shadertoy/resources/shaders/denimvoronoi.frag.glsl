#define PI 3.14159265359

// Cosine palette coefficients
const vec3 EXPOSURE = vec3(0.628, 0.485, 0.224);
const vec3 CONTRAST = vec3(-0.318, -0.296, 0.498);
const vec3 FREQ = vec3(-0.412, -0.269, 0.176);
const vec3 PHASE = vec3(1.326, -0.592, -1.003);

vec3 palette(float t) {
    return EXPOSURE + CONTRAST * cos(2.0 * PI * (FREQ * t + PHASE));
}

float r(float n) {
    return fract(abs(sin(n*55.753)*367.34));   
}

float r(vec2 n) {
    return r(dot(n,vec2(2.46,-1.21)));
}

float cycle(float n) {
    return cos(fract(n)*2.0*PI)*0.5+0.5;
}

vec2 hash2(vec2 p) {
    p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
    return fract(sin(p)*43758.5453);
}

vec3 getVoronoiColor(vec2 uv) {
    vec2 id = floor(uv);
    vec2 gv = fract(uv);
    
    float minDist = 100.0;
    vec2 minId = vec2(0);
    
    // Check 3x3 grid of cells
    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i <= 1; i++) {
            vec2 neighbor = vec2(i, j);
            vec2 neighborId = id + neighbor;
            
            vec2 randomPoint = hash2(neighborId);
            vec2 point = neighbor + randomPoint;
            
            float dist = length(point - gv);
            
            if(dist < minDist) {
                minDist = dist;
                minId = neighborId;
            }
        }
    }
    
    // Color based on cell ID
    float base = r(floor(minId*4.0))*0.2 + r(floor(minId*2.0))*0.3 + r(minId)*0.5;
    float animated = cycle(base + iTime*.85*0.125);
    
    vec3 color = palette(animated);
    color *= 0.9 + 0.1 * (1.0 - minDist);
    
    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float zoom = 90.0;
    
    vec3 color = vec3(0.0);
    
    // 2x2 supersampling
    for(float x = -0.25; x <= 0.25; x += 0.5) {
        for(float y = -0.25; y <= 0.25; y += 0.5) {
            vec2 uv = (fragCoord.xy + vec2(x, y)) / zoom;
            uv.x += iTime*.2 * 2.0;
            
            color += getVoronoiColor(uv);
        }
    }
    
    color *= 0.25; // Average 4 samples
    
    fragColor = vec4(color, 1.0);
}