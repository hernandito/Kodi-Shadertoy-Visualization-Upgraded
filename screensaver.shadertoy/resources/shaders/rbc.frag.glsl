#define pi 3.14159265359

vec3 center;
vec3 ray;
vec3 color;
vec3 normal;
bool hit;
vec4 resColor;

float sMin(float a, float b, float k) {
    float t = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - t * t * t * k * 0.16666666667;
}

float sMax(float a, float b, float k) {
    float t = max(k - abs(a - b), 0.0) / k;
    return max(a, b) + t * t * t * k * 0.16666666667;
}

float Union(float d1, float d2) { return min(d1, d2); }
float sUnion(float d1, float d2, float k) { return sMin(d1, d2, k); }
float Intersection(float d1, float d2) { return max(d1, d2); }
float sIntersection(float d1, float d2, float k) { return sMax(d1, d2, k); }
float Difference(float d1, float d2) { return max(d1, -d2); }
float sDifference(float d1, float d2, float k) { return sMax(d1, -d2, k); }

float sphereSDF(vec3 p, vec3 pos, float r) { return distance(p, pos) - r; }

float diskSDF(vec3 p, vec3 n, vec3 pos, float r, float t) {
    vec3 d = dot(p - pos, n) * n;
    vec3 o = p - pos - d;
    o -= normalize( o ) * min( length( o ), r );
    return length( d + o ) - t;
}

float scene(vec3 p) {   
    vec3 norm = normalize(vec3(
        sin(iTime * 0.2 + 0.0), 
        sin(iTime * 0.4 + 0.455), 
        sin(iTime * 0.6 + 0.892)
    ));
    
    vec3 pos = vec3(0.0, 6.0, 0.0);
    
    float di = diskSDF(p, norm, pos, 5.0, 3.0);
    float s1 = sphereSDF(p, pos + 6.5 * norm, 5.0);
    float s2 = sphereSDF(p, pos - 6.5 * norm, 5.0);

    return sDifference(sDifference(di, s1, 3.0), s2, 3.0);
    //return Difference(Difference(di, s1), s2);
}

float march(int maxSteps, float maxDist, float minDist) {
    hit = false;
    
    float travel = 0.0;
    for (int i = 0; i < maxSteps; i++) {
        float d = scene(center + travel*ray);
        if (d < minDist) { hit = true; return travel; }
        if (travel > maxDist) { return 0.0; }
        travel += d;
    }
}

vec3 calcNormal( vec3 pos )
{
    const float ep = 0.0001;
    vec2 e = vec2(1.0,-1.0)*0.5773;
    return normalize( e.xyy*scene( pos + e.xyy*ep ) + 
					  e.yyx*scene( pos + e.yyx*ep ) + 
					  e.yxy*scene( pos + e.yxy*ep ) + 
					  e.xxx*scene( pos + e.xxx*ep ) );
}

float surfaceArea(vec3 i, vec3 n) {
    return max(cos(pi*(1.0-dot(i, n))/2.0), 0.0);
}

vec3 circleLight(vec3 pos, float r, vec3 power, vec3 intersection, vec3 n, vec3 lightnormal) {
    vec3 light = pos;
    vec3 li = light-intersection;
    vec3 lightVec = normalize(li);
    float invSq = dot(li, li);
    float area = surfaceArea(-lightVec, lightnormal)*pi*r*r;
    center = intersection-n/100.; //no shadow acne
    ray = lightVec;
    march(256, 64.0, 0.01);
    if (!hit) return vec3(0);
    return surfaceArea(lightVec, n)/invSq*power*area;
}

vec3 raymarch(vec2 uv) {
    center = vec3(0, 6, -30);
    ray = normalize(vec3(uv, 1.5));
    
    float d = march(400, 64.0, 0.005);
    if (hit) {
        vec3 inters = center + d*ray;
        normal = calcNormal(inters);
        float skim = dot(normal, ray) * 0.5 + 0.5;
        skim = skim * skim * skim;
        //return vec3((normal + 1.0) / 2.0);
        vec3 c1 = circleLight(vec3(8.0, 15.0, -10.0), 3.0, 1.5*vec3(2.0, 2.5, 2.0), inters, normal, vec3(0, -1, 0));
        vec3 c2 = circleLight(vec3(-4.0, -10.0, -15.0), 3.0, 2.0*vec3(0.5, 0.2, 0.1), inters, normal, vec3(0, 1, 0));
        
        return (c1 + c2) * vec3(0.8,0,0) + vec3(skim);
    } else {
        return vec3(0);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 px = (fragCoord - iResolution.xy / 2.0) / iResolution.y;
    fragColor = vec4(pow(raymarch(px), vec3(.4545)), 1.0);
}