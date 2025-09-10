const vec3 SKY_BOTTOM = vec3(129.0, 204.0, 243.0) / 255.0;
const vec3 SKY_TOP = vec3(0.0, 101.0, 202.0) / 255.0;
const vec3 CLOUDS_BOTTOM = vec3(170.0, 211.0, 242.0) / 255.0;
const vec3 CLOUDS_TOP = vec3(244.0, 249.0, 252.0) / 255.0;
const vec3 DIR_TO_SUN = normalize(vec3(1.0, 1.0, 0.0));
const vec3 SUN_COLOR = vec3(1.0, 0.98, 0.55);
const float CLOUDS_HEIGHT = 14.0;
const float TAU = 6.2831853;

// BCS post-processing parameters
const float BRIGHTNESS = -0.20; // Adjusts the overall brightness
const float CONTRAST = 1.30;   // Adjusts the contrast, 1.0 is no change
const float SATURATION = 1.0; // Adjusts the color saturation, 1.0 is no change

// Hash functions: https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 getGradient2D(vec2 pos) {
    float angle = hash12(pos) * TAU;
    return vec2(sin(angle), cos(angle));
}

float getPerlinNoise2D(vec2 pos) {
    vec2 pos1 = floor(pos);
    vec2 pos2 = pos1 + vec2(1.0, 0.0);
    vec2 pos3 = pos1 + vec2(0.0, 1.0);
    vec2 pos4 = pos1 + vec2(1.0, 1.0);
    
    vec2 v1 = getGradient2D(pos1);
    vec2 v2 = getGradient2D(pos2);
    vec2 v3 = getGradient2D(pos3);
    vec2 v4 = getGradient2D(pos4);
    
    vec2 delta = pos - pos1;
    
    float r1 = dot(v1, delta);
    float r2 = dot(v2, pos - pos2);
    float r3 = dot(v3, pos - pos3);
    float r4 = dot(v4, pos - pos4);
    
    delta.x = smoothstep(0.0, 1.0, delta.x);
    delta.y = smoothstep(0.0, 1.0, delta.y);
    
    r1 = mix(r1, r2, delta.x);
    r2 = mix(r3, r4, delta.x);
    return mix(r1, r2, delta.y);
}

// SDF source: https://iquilezles.org/articles/distfunctions/

float getBoxSDF(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float getRoundBoxSDF(vec3 p, vec3 b, float r) {
    vec3 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

// Source: https://iquilezles.org/articles/smin/
float smin(float a, float b, float k) {
    k *= log(2.0);
    float x = b - a;
    return a + x / (1.0 - exp2(x / k));
}

float getCloudsSDF(vec3 pos) {
    float cloudScale = 4.0;
    float dUV = 1.0 / cloudScale;
    
    float dist = 1.0;
    vec2 uv = floor(pos.xz * 0.1 * cloudScale) * dUV;
    for (int j = 0; j < 9; j++) {
        // Replaced modulo with integer arithmetic for GLSL ES 1.0 compatibility
        vec2 sUV = uv + vec2(float(j - int(j / 3) * 3) - 1.0, float(j / 3) - 1.0) * dUV;
        if (getPerlinNoise2D(sUV) < 0.2) continue;
        vec2 horPos = sUV * 10.0;
        vec3 cloudPos = pos - vec3(horPos.x, CLOUDS_HEIGHT + 1.0, horPos.y);
        dist = min(dist, getRoundBoxSDF(cloudPos, vec3(1.75, 1.0, 1.75), 0.5));
    }
    return dist;
}

// https://iquilezles.org/articles/normalsSDF/
vec3 getCloudsNormal(vec3 pos) {
    const float h = 0.0001;
    const vec2 k = vec2(1.0, -1.0);
    return normalize(
        k.xyy * getCloudsSDF(pos + k.xyy * h) + 
        k.yyx * getCloudsSDF(pos + k.yyx * h) + 
        k.yxy * getCloudsSDF(pos + k.yxy * h) + 
        k.xxx * getCloudsSDF(pos + k.xxx * h)
    );
}

vec3 projectPointOnLine(vec3 point, vec3 pos1, vec3 pos2) {
    vec3 lineDir = pos2 - pos1;
    vec3 w = point - pos1;
    float dist = dot(w, lineDir) / dot(lineDir, lineDir);
    return pos1 + dist * lineDir;
}

vec3 getSkyColor(vec3 dir) {
    float vert = dot(dir, vec3(0.0, 1.0, 0.0));
    vert = max(vert, 0.0);
    vec3 color = mix(SKY_BOTTOM, SKY_TOP, vert);
    float bright = max(dot(dir, DIR_TO_SUN), 0.0);
    bright = pow(bright, 4.0);
    return mix(color, vec3(1.0), bright * 0.5);
}

vec4 getSunColor(vec3 dir) {
    vec3 radial = dir - DIR_TO_SUN;
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), DIR_TO_SUN));
    vec3 up = normalize(cross(DIR_TO_SUN, right));
    
    vec3 posR = projectPointOnLine(radial, DIR_TO_SUN, DIR_TO_SUN + right);
    vec3 posU = projectPointOnLine(radial, DIR_TO_SUN, DIR_TO_SUN + up);
    float du = abs(distance(posU, DIR_TO_SUN)) * 8.0;
    float dv = abs(distance(posR, DIR_TO_SUN)) * 8.0;
    
    if (du < 1.0 && dv < 1.0) return vec4(SUN_COLOR, 1.0);
    if (du > 4.0 || dv > 4.0) return vec4(0.0);
    
    float alpha = 1.0 + smin((1.0 - du) * 0.5, (1.0 - dv) * 0.5, 0.4);
    alpha = max(alpha, 0.0);
    
    return vec4(SUN_COLOR, alpha);
}

vec4 getCloudsColor(vec3 dir) {
    if (dir.y < 0.01) return vec4(0.0);
    float dist = CLOUDS_HEIGHT / dir.y;
    if (dist > 200.0) return vec4(0.0);
    float cloudMax = CLOUDS_HEIGHT + 2.0;
    
    float cloudScale = 4.0;
    float dUV = 1.0 / cloudScale;
    
    float time = iTime * 0.3;
    vec3 samplePos = dir * dist + vec3(time, 0.0, time);
    float totalDist = dist;
    
    for (int i = 0; i < 100; i++) {
        dist = max(getCloudsSDF(samplePos), 0.005);
        totalDist += dist;
        samplePos += dir * dist;
        if (dist < 0.01 || samplePos.y > cloudMax) break;
    }
    
    vec4 color = vec4(0.0);
    if (dist < 0.01) {
        vec3 normal = getCloudsNormal(samplePos);
        
        float light = dot(normal, normalize(vec3(0.0, 1.0, 0.0))) * 0.5 + 0.5;
        
        float depth = 0.0;
        samplePos += dir * 0.1;
        for (int i = 0; i < 20; i++) {
            dist = max(-getCloudsSDF(samplePos), 0.005);
            depth += dist;
            samplePos += dir * dist;
            if (dist < 0.01 || samplePos.y > cloudMax) break;
        }
        depth = min(exp(-depth + 0.5), 1.0);
        light = max(light, depth * 0.5);
        
        vec3 rgb = mix(SKY_BOTTOM, CLOUDS_TOP, light);
        rgb = mix(rgb, vec3(1.0), 0.3);
        
        dist = length(samplePos);
        float alpha = clamp((200.0 - totalDist) / 100.0, 0.0, 1.0);
        
        color = vec4(rgb, alpha);
    }
    
    return color;
}

void mainImage(out vec4 o, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 screenSpace = uv * 2.0 - 1.0;
    screenSpace.x *= iResolution.x / iResolution.y;
    
    float angle = iTime * 0.1;
    vec3 cameraPos = vec3(0.0, 0.0, 0.0);
    vec3 cameraDir = normalize(vec3(1.0, 0.75, 0.0));
    vec3 cameraRight = normalize(cross(vec3(0.0, 1.0, 0.0), cameraDir));
    vec3 cameraUp = normalize(cross(cameraDir, cameraRight));
    vec3 dir = normalize(cameraDir + cameraUp * screenSpace.y + cameraRight * screenSpace.x);
    
    vec3 sky = getSkyColor(dir);
    vec4 sun = getSunColor(dir);
    vec4 clouds = getCloudsColor(dir);
    vec3 color = mix(sky, sun.rgb, sun.a);
    color = mix(color, clouds.rgb, clouds.a);
    
    // Apply BCS (Brightness, Contrast, Saturation) post-processing
    // 1. Saturation
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    vec3 finalColor = mix(vec3(luma), color, SATURATION);

    // 2. Contrast
    finalColor = mix(vec3(0.5), finalColor, CONTRAST);
    
    // 3. Brightness
    finalColor += BRIGHTNESS;

    o = vec4(finalColor, 1.0);
}
