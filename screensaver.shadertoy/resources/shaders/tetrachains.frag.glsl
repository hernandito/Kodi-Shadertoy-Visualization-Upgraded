#define PI 3.14159;

mat2 rotate2D(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float calcPattern(vec2 uv) {
    float o = 0.0;
    for (float i = 1.0; i <= 20.0; i++) {
        float d;
        vec2 p = uv * i * 3.0;
        p.y += iTime*.1;
        p *= rotate2D(i * 2.4);
        p.x += iTime*.1 * sin(ceil(p.y / 8.0) * 2.4) * 5.0;
        p.y = mod(p.y, 8.0) - 4.0;
        p.x = fract(p.x) - 0.5;
        p = p.y < 0.0 ? -p : p;
        p.x -= 0.5;
        d = abs(length(p) - 0.7);
        p.x += 1.0;
        if (d > 0.2) {
            d = abs(length(p) - 0.7);
        }
        if (d < 0.2) {
            o += step(d, 0.15) * exp(-i * i * 0.01);
            break;
        }
    }
    return o;
}


float sdTetrahedron( vec3 p, float g )
{
    //float angle = 2.86; iTime
    float angle = 2.86 + iTime*.05 * 0.75;
    float c = cos(angle);
    float s = sin(angle);
    mat2 rot = mat2(c, -s, s, c);
    p.xz = rot * p.xz;

    const vec3 n1 = normalize(vec3( 1.0, 1.0, 1.0));
    const vec3 n2 = normalize(vec3( 1.0,-1.0,-1.0));
    const vec3 n3 = normalize(vec3(-1.0, 1.0,-1.0));
    const vec3 n4 = normalize(vec3(-1.0,-1.0, 1.0));
    return max(max(dot(p,n1), dot(p,n2)), max(dot(p,n3), dot(p,n4))) - g;
}

float map(vec3 p) {
    float res = sdTetrahedron(p, 1.60);
    return res;
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(
        vec3(
            map(p + e.xyy) - map(p - e.xyy),
            map(p + e.yxy) - map(p - e.yxy),
            map(p + e.yyx) - map(p - e.yyx)
        )
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv_screen = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    
    vec3 ro = vec3(0.0, 0.0, 3.0);
    vec3 rd = normalize(vec3(uv_screen, -1.5));
    
    float t = 0.0;
    vec3 col = vec3(0.0);
    
    for (int i = 0; i < 100; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        
        if (d < 0.001) {
            vec3 normal = calcNormal(p);
            

            vec2 uv_sphere = vec2(atan(p.z, p.x), acos(p.y / length(p)));
            uv_sphere /= PI;

            float pattern_value = calcPattern(uv_sphere * 4.0);

            vec3 materialColor = vec3(pattern_value + pattern_value * cos(iTime*.1), 
                                      pattern_value, 
                                      pattern_value + pattern_value * sin(iTime*.1));
            
            vec3 lightPos = vec3(2.0, 3.0, 4.0);
            vec3 lightDir = normalize(lightPos - p);
            float diff = max(0.0, dot(normal, lightDir));
            float ambient = 0.2;

            col = materialColor * (diff + ambient);
            break;
        }
        
        if (t > 100.0) {
            break;
        }
        
        t += d;
    }
    
    fragColor = vec4(col, 1.0);
}