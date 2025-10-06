const float PI = acos(-1.0);

const int NUM_ITERATIONS = 256;
const float EPSILON = 1e-3;
const float MAX_DIST = 100.0;

const float FL = 1.0;

vec3 repeat(vec3 p, float size, vec3 offset) {
    return mod(p + offset, size) - offset;
}

float sphere_dist(vec3 c, float r, vec3 p) {
    return distance(c, p) - r;
}

float get_dist(vec3 p) {
    float theta = floor(p.z / 6.0) * PI * 0.25;
    return sphere_dist(vec3(cos(theta), sin(theta), 5.0), 1.0,
        repeat(p, 6.0, vec3(3.0, 3.0, 0.0)));
}

void mainImage(out vec4 frag_color, vec2 frag_coord) {
    vec2 uv = (frag_coord - iResolution.xy * 0.5) / iResolution.xx;

    vec3 cam_pos = vec3(-cos(iTime*.2), -sin(iTime*.2), mod(iTime*.1 * 12.0 / PI, 24.0)) * 4.0;
    vec3 o = cam_pos;
    vec3 d = normalize(vec3(uv, FL));
    bool hit = false;
    int i;
    for(i = 0; i < NUM_ITERATIONS; ++i) {
        float dist = get_dist(o);
        if(dist < EPSILON) {
            hit = true;
            break;
        } else if(dist > MAX_DIST)
            break;
        o += d * dist;
    }
    vec3 color = hit ? vec3(1.0 - distance(cam_pos, o) / 200.0)
        * vec3(1.0 - float(i) / float(NUM_ITERATIONS), 1.0, 1.0) : vec3(0.0);

    frag_color = vec4(color, 1.0);
}