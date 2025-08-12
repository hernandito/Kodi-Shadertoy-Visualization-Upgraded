precision mediump float; // Required for ES 2.0

#define CYCLE_DURATION 48.0    // Cycle duration in seconds: 24.0 as set, adjust to change transition length

// Animation speed parameter
#define ANIMATION_SPEED .050    // Animation speed: 1.0 for default, >1.0 to speed up, <1.0 to slow down

#define FDIST 0.5
#define SCALE 4.
#define STARTSCALE 0.5
#define OCTAVES 2
#define EPS 5e-3
#define STEPS 50
#define MAXDIST 50.
#define RADIUS 0.4

#define SHADOWEPS 3e-2

float map(in vec3 ro) {
    ro.xy = fract(ro.xy);
    return length(vec3(ro.xy - 0.5, ro.z)) - RADIUS;
}

float height(in vec2 uv) {
    uv = fract(uv) - 0.5;
    return sqrt(max(0., RADIUS * RADIUS - dot(uv, uv)));
}

float mapTerrain(in vec3 ro) {
    float h = ro.z;
    float s = STARTSCALE;
    ro *= STARTSCALE;
    
    vec2 offset = vec2(iTime * 0.7 * ANIMATION_SPEED, 53.9029103);
    mat2 rotmat = mat2(0.5, 0.88, -0.88, 0.5); // Changed to mat2
    // Manual inverse for 2x2 matrix: 1/(ad - bc) * [[d, -b], [-c, a]]
    float det = 0.5 * 0.5 - 0.88 * (-0.88); // ad - bc
    mat2 invmat = mat2(0.5 / det, -0.88 / det, 0.88 / det, 0.5 / det); // Approximate inverse
    
    for (int i = 0; i < OCTAVES; ++i) {
        vec2 cellCenter = floor(ro.xy) + 0.5;
        cellCenter /= SCALE;
        cellCenter = invmat * cellCenter;
        cellCenter -= offset;
        float prevHeight = i == 0 ? 0. : height(cellCenter);
        
        float currH = map((ro - vec3(0., 0., prevHeight) * s * 2.)) / s;

        // Use CYCLE_DURATION for transition length, unaffected by ANIMATION_SPEED
        if (mod(float(i), 2.0) < 1.0 || fract(iTime / CYCLE_DURATION) < 0.5) {
            h = min(h, currH);
        } else {
            h = max(h, -currH);
        }
        ro.xy += offset;
        ro.xy = rotmat * ro.xy;
        s *= SCALE;
        ro *= SCALE;
    }
    return h;
}

vec3 normals(in vec3 ro) {
    vec2 ofs = vec2(0., EPS);
    float d100 = mapTerrain(ro + ofs.yxx);
    float d010 = mapTerrain(ro + ofs.xyx);
    float d001 = mapTerrain(ro + ofs.xxy);
    return normalize(vec3(d100, d010, d001) - mapTerrain(ro));
}

float trace(in vec3 eye, in vec3 rd, out int i) {
    float t = 0.;
    
    for (i = 0; i < STEPS; ++i) {
        float d = mapTerrain(eye + t * rd);
        if (abs(d) < EPS) {
            break;
        }
        if (t > MAXDIST) {
            t = -1.;
            break;
        }
        t += d;
    }
    
    return t;
}

float shadow(in vec3 eye, in vec3 rd, in float k) {
    float fac = 1.0;
    float t = SHADOWEPS;
    
    for (int i = 0; i < 10; ++i) {
        float d = mapTerrain(eye + rd * t);
        fac = min(fac, k * d / t);
        t += clamp(d, 0.1, 0.5);
    }
    return max(fac, 0.);
}

float tracePlane(in vec3 eye, in vec3 rd) {
    return -eye.z / rd.z;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.x;
    
    vec3 up = vec3(0., 0., 1.);
    vec3 lookAt = vec3(0., 0., 2.5);
    vec3 eye = 4. * vec3(cos(iTime * 0.5 * ANIMATION_SPEED), sin(iTime * 0.5 * ANIMATION_SPEED), 1.);
    vec3 viewDir = normalize(lookAt - eye);
    vec3 u = normalize(cross(viewDir, up));
    vec3 v = cross(u, viewDir);
    vec3 rd = normalize(viewDir * FDIST + uv.x * u + uv.y * v);
    
    int i;
    float t = trace(eye, rd, i);
    vec3 col;
    if (t > 0.) {
        vec3 lightDir = normalize(vec3(1.));
        vec3 ro = eye + t * rd;
        vec3 n = normals(ro);
        float shadowfac = shadow(ro, lightDir, 8.);
        // Increased ambient light to brighten shadows
        col = vec3(0.1, 0.3, 0.5) * max(n.z, 0.2) + 1.3 * vec3(0.8, 0.8, 0.7) * vec3(max(0., dot(n, lightDir))) * shadowfac;
    } else {
        col = mix(vec3(0.3, 0.5, 1.), vec3(0., 0., 1.), rd.z * rd.z);
    }
    
    fragColor = vec4(pow(col, vec3(0.7)), 1.0);
}