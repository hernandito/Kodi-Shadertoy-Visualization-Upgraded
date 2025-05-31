#define POINT_COUNT 9
vec2 points[POINT_COUNT];
float speed = 3.0;
float scale = 0.012;
float len = 0.3;
// Glow Parameters: These control the neon glow effect
float intensity = 1.3; // Controls the falloff rate of the glow (higher = sharper falloff, less haze; default: 1.3)
float radius = 0.015;  // Controls the size/extent of the glow (higher = glow extends further; default: 0.015)

float sdBezier(vec2 pos, vec2 A, vec2 B, vec2 C){    
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;
    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      
    float res = 0.0;
    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;
    if (h >= 0.0){ 
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = uv.x + uv.y - kx;
        t = clamp( t, 0.0, 1.0 );
        vec2 qos = d + (c + b*t)*t;
        res = length(qos);
    } else{
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = vec3(m + m, -n - m, n - m) * z - kx;
        t = clamp( t, 0.0, 1.0 );
        vec2 qos = d + (c + b*t.x)*t.x;
        float dis = dot(qos,qos);
        res = dis;
        qos = d + (c + b*t.y)*t.y;
        dis = dot(qos,qos);
        res = min(res,dis);
        qos = d + (c + b*t.z)*t.z;
        dis = dot(qos,qos);
        res = min(res,dis);
        res = sqrt( res );
    }
    return res;
}

vec2 getShape1(float t){
    float r = 12.0;
    return vec2(r * cos(t), r * sin(t * 3.0));
}

vec2 getShape2(float t){
    float r = 12.0;
    return vec2(r * cos(t), r * sin(t * 4.0));
}

vec2 getShape3(float t){
    float r = 22.0;
    float a = 1.0 * cos(t);
    float denom = 1.0 + sin(t) * sin(t);
    return vec2(r * a / denom, r * sin(t) * cos(t) / denom);
}

vec2 getShape4(float t){
    float r = 6.0;
    return vec2(r * sin(t) * (exp(cos(t)) - 2.0*cos(4.0*t) - pow(sin(t/12.0), 5.0)),
                r * cos(t) * (exp(cos(t)) - 2.0*cos(4.0*t) - pow(sin(t/12.0), 5.0)));
}

vec2 getShape5(float t){
    float r = 11.0;
    float k = 5.0; 
    return vec2(r * cos(t) * (1.0 + 0.5 * cos(k * t)),
                r * sin(t) * (1.0 + 0.5 * cos(k * t)));
}

vec2 getShape6(float t){
    float r = 16.0;
    return vec2(r * sin(2.0 * t), r * sin(3.0 * t));
}

vec2 getShape7(float t) {
    float r = 15.0;
    return vec2(r * cos(t) * sin(4.0 * t), r * cos(t) * cos(2.0 * t));
}

vec2 getShape8(float t){
    float r = 1.2;
    return r * vec2(16.0 * sin(t) * sin(t) * sin(t),
                    (10.0 * cos(t) - 5.0 * cos(2.0*t)
                    - 2.0 * cos(3.0*t) - cos(4.0*t)));
}


// Glow Calculation Function
float getGlow(float dist, float radius, float intensity){
    // This function computes the glow effect based on distance to the Bezier curve
    // - 'dist' is the distance to the curve (from sdBezier)
    // - 'radius' (default: 0.015) determines how far the glow extends (higher = larger glow)
    // - 'intensity' (default: 1.3) determines the falloff rate (higher = sharper falloff, less haze)
    // Formula: pow(radius/dist, intensity) creates a glow that is bright near the curve and fades with distance
    // To fine-tune:
    // - Increase 'intensity' (e.g., 2.0) for a sharper glow with less haze
    // - Increase 'radius' (e.g., 0.02) to make the glow extend further
    return pow(radius/dist, intensity);
}

float getSegment(float t, vec2 pos, float offset, int shapeIndex){
    for(int i = 0; i < POINT_COUNT; i++){
        float param = offset + float(i)*len + (speed * t);
        param = mod(param, 6.28318530718);
        
        if(shapeIndex == 0)
            points[i] = getShape1(param);
        else if(shapeIndex == 1)
            points[i] = getShape2(param);
        else if(shapeIndex == 2)
            points[i] = getShape3(param);
        else if(shapeIndex == 3)
            points[i] = getShape4(param);
        else if(shapeIndex == 4)
            points[i] = getShape5(param);
        else if(shapeIndex == 5)
            points[i] = getShape6(param);
        else if(shapeIndex == 6)
            points[i] = getShape7(param);
        else
            points[i] = getShape8(param);
    }
    
    vec2 c = (points[0] + points[1]) / 2.0;
    vec2 c_prev;
    float dist = 10000.0;
    
    for(int i = 0; i < POINT_COUNT-1; i++){
        c_prev = c;
        c = (points[i] + points[i+1]) / 2.0;
        dist = min(dist, sdBezier(pos, scale * c_prev, scale * points[i], scale * c));
    }
    return max(0.0, dist);
}

// Post-processing function for brightness and contrast
vec3 adjustBrightnessContrast(vec3 color, float brightness, float contrast) {
    color += brightness;
    color = (color - 0.5) * contrast + 0.5;
    return clamp(color, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = fragCoord/iResolution.xy;
    
    vec2 gridSize = vec2(4.0, 2.0);
    vec2 cellSize = 1.0 / gridSize;
    
    vec2 cellIndex = floor(uv * gridSize);
    int cellNumber = int(cellIndex.y * gridSize.x + cellIndex.x);
    
    vec2 localUV = fract(uv * gridSize);
    
    localUV = (localUV - 0.5) * 2.0;
    
    float cellAspect = (iResolution.x/gridSize.x) / (iResolution.y/gridSize.y);
    localUV.y *= cellAspect;
    
    localUV *= 0.4;
    
    float t = iTime*0.15;
    
    // First Layer: Core line + Glow
    float dist = getSegment(t, localUV, 0.0, cellNumber);
    float glow = getGlow(dist, radius, intensity);
    
    vec3 col = vec3(0.0);
    
    // Core of the neon line: Bright, sharp center (not part of the glow)
    // The smoothstep creates a sharp, bright line where dist is small
    // Line Thickness Control:
    // - smoothstep(0.006, 0.003, dist) defines the thickness of the core line
    // - 0.006 is the outer edge of the line (where it starts to fade)
    // - 0.003 is the inner edge (where it’s fully bright)
    // - The difference (0.006 - 0.003 = 0.003) is the transition width
    // - To increase thickness, increase both values (e.g., 0.008, 0.005)
    // - To decrease thickness, decrease both values (e.g., 0.004, 0.002)
    col += 10.0*vec3(smoothstep(0.004, 0.002, dist));

    vec3 color1, color2;
    if(cellNumber == 0) {
        color1 = vec3(1.0, 0.05, 0.1);
        color2 = vec3(0.1, 0.4, 1.0);
    } else if(cellNumber == 1) {
        color1 = vec3(1.0, 0.5, 0.0);
        color2 = vec3(0.0, 0.8, 0.3);
    } else if(cellNumber == 2) {
        color1 = vec3(0.8, 0.1, 0.1);
        color2 = vec3(0.1, 0.8, 0.8);
    } else if(cellNumber == 3) {
        color1 = vec3(1.0, 0.8, 0.0);
        color2 = vec3(0.0, 0.5, 1.0);
    } else if(cellNumber == 4) {
        color1 = vec3(0.6, 0.5, 0.6);
        color2 = vec3(0.6, 0.1, 0.1);
    } else if(cellNumber == 5) {
        color1 = vec3(0.8, 0.2, 0.0);
        color2 = vec3(0.0, 0.4, 0.8);
    } else if(cellNumber == 6) {
        color1 = vec3(0.8, 0.2, 0.0);
        color2 = vec3(0.0, 0.8, 0.6);
    } else {
        color1 = vec3(0.6, 0.5, 0.6);
        color2 = vec3(0.6, 0.1, 0.1);
    }
    
    // Add the glow for the first layer
    // The glow is scaled by the color (color1) and added to the core line
    // The intensity and extent of the glow are controlled by the 'intensity' and 'radius' parameters in getGlow
    col += glow * color1;
    
    // Second Layer: Core line + Glow (offset by 3.4 for a different animation phase)
    dist = getSegment(t, localUV, 3.4, cellNumber);
    glow = getGlow(dist, radius, intensity);
    
    // Core of the second layer
    // Same thickness control as the first layer
    col += 10.0 * vec3(smoothstep(0.006, 0.003, dist));
    
    // Add the glow for the second layer
    col += glow * color2;

    // Exposure adjustment: Enhances the brightness of the glow and core line
    // This step makes the glow more visible, including the outer haze
    col = 1.0 - exp(-col);
    
    // Gamma correction: Adjusts the overall brightness and contrast
    col = pow(col, vec3(0.4545));

    // Apply brightness and contrast post-processing
    float brightness = -0.093; // Approx -14/150 from Photoshop
    float contrast = 1.7; // Approx +100 maps to doubling contrast
    col = adjustBrightnessContrast(col, brightness, contrast);

    fragColor = vec4(col, 1.0);
}