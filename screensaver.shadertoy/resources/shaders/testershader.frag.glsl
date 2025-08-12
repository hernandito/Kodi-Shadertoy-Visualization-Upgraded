// General purpose small epsilon for numerical stability
const float TINY_EPSILON = 1e-6;

// Define parameter for day cycle duration in seconds
#define DAY_CYCLE_DURATION 55.0

// Structure definitions
struct SDF {
    float dist;
    vec3 color;
    bool water;
};

struct MarchResult {
    SDF nearest;
    vec3 pos;
    float z;
    vec3 color;
    float mindist;
    vec3 dir;
};

// HELPER FUNCTIONS
float fresnel(vec3 dir, vec3 n, float base) {
    return base + (1.0 - base) * pow(1.0 - dot(-dir, n), 5.0);
}

float fog(float z, float density) {
    return 1.0 - pow(2.0, -pow(z * density, 2.0));
}

float remap(float x, float minFrom, float maxFrom, float minTo, float maxTo) {
    return clamp((x - minFrom) / (maxFrom - minFrom) * (maxTo - minTo) + minTo, 0.0, 1.0);
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, vec3(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float rand(vec2 c) {
    return fract(sin(dot(c.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p, float freq) {
    float unit = freq;
    vec2 ij = floor(p / max(unit, TINY_EPSILON));
    vec2 xy = mod(p, unit) / max(unit, TINY_EPSILON);
    xy = 0.5 * (1.0 - cos(3.141592 * xy));
    float a = rand((ij + vec2(0.0, 0.0)));
    float b = rand((ij + vec2(1.0, 0.0)));
    float c = rand((ij + vec2(0.0, 1.0)));
    float d = rand((ij + vec2(1.0, 1.0)));
    float x1 = mix(a, b, xy.x);
    float x2 = mix(c, d, xy.x);
    return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, float res_float) {
    float persistance = 0.5;
    float n = 0.0;
    float normK = 0.0;
    float f = 4.0;
    float amp = 1.0;
    for (float i = 0.0; i < 50.0; i++) {
        n += amp * noise(p, f);
        f *= 2.0;
        normK += amp;
        amp *= persistance;
        if (i >= res_float) break;
    }
    float nf = n / max(normK, TINY_EPSILON);
    return nf * nf * nf * nf;
}

mat2 custom_rot_mat2(float a) {
    vec4 cs_val = cos(a + vec4(0.0, 33.0, 11.0, 0.0));
    return mat2(cs_val.x, cs_val.z, cs_val.y, cs_val.w);
}

vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), TINY_EPSILON));
}

vec3 tanh_approx(vec3 x) {
    return x / (1.0 + max(abs(x), TINY_EPSILON));
}

SDF sdfMin(SDF a, SDF b) {
    if (a.dist < b.dist) return a;
    else return b;
}

float tileBump(float x) {
    float k = 10.0;
    float spacing = 2.01;
    x = mod(x, spacing) - spacing / 2.0;
    return clamp(k - abs(x) * k, 0.0, 1.0);
}

float tileBump2D(vec2 p) {
    float height = 0.007;
    p *= 8.0;
    return tileBump(p.x) * tileBump(p.y) * height;
}

vec3 tileColor(vec3 p) {
    p *= 8.0;
    p = mod(p, vec3(2.01));
    p = smoothstep(0.02, 0.05, p);
    return vec3(max(p.x * p.y * p.z, 0.7));
}

float waterwaySDF(vec3 p) {
    float ceilingHoleInterval = 8.0;
    vec3 ceilingHoleP = p;
    ceilingHoleP.z += ceilingHoleInterval / 2.0;
    ceilingHoleP.z = mod(ceilingHoleP.z, ceilingHoleInterval);
    ceilingHoleP -= vec3(0.0, 3.0, ceilingHoleInterval / 2.0);
    return min(
        p.y + 2.0 - tileBump2D(p.xz),
        min(
            max(
                p.y + 0.2 - tileBump2D(p.xz),
                1.2 - abs(p.x) - tileBump2D(p.yz)
            ),
            max(
                p.y - 6.0,
                min(
                    max(
                        -sdBox(ceilingHoleP, vec3(2.3, 4.0, 2.3)),
                        5.0 - p.y - tileBump2D(p.xz)
                    ),
                    3.6 - abs(p.x) - tileBump2D(p.yz)
                )
            )
        )
    );
}

float crossWaterwaySDF(vec3 p) {
    p.z += 8.0;
    float interval = 24.0;
    p.z += interval / 2.0;
    p.z = mod(p.z, interval);
    p.z -= interval / 2.0;
    return waterwaySDF(p.zyx);
}

SDF waterway(vec3 p) {
    return SDF(max(waterwaySDF(p), crossWaterwaySDF(p)), tileColor(p), false);
}

float waves(vec2 p) {
    float o = 0.0;
    float mult = 1.0;
    for (float i = 0.0; i < 5.0; i++) {
        float si = mod(i, 2.0) * 2.0 - 1.0;
        o += sin(p.x * mult + iTime * si) * sin(p.y * mult + iTime * si) / max(mult, TINY_EPSILON);
        mult *= 1.3;
    }
    return o;
}

float waterSDF(vec3 p) {
    return p.y + 0.5 - waves(p.xz * 3.0) * 0.01;
}

SDF water(vec3 p, float i) {
    return SDF(waterSDF(p), vec3(0.0, 0.2, 0.3), true);
}

const float SECTOR_SIZE = 24.0 * 4.0;

SDF map(vec3 p, bool inclWater) {
    p.z = mod(p.z, SECTOR_SIZE);
    SDF s = waterway(p);
    if (inclWater) {
        return sdfMin(s, water(p, 0.0));
    }
    return s;
}

vec3 calcNormal(vec3 p, bool water) {
    const float h = 0.01;
    const vec2 k = vec2(1.0, -1.0);
    return normalize(k.xyy * map(p + k.xyy * h, water).dist +
                     k.yyx * map(p + k.yyx * h, water).dist +
                     k.yxy * map(p + k.yxy * h, water).dist +
                     k.xxx * map(p + k.xxx * h, water).dist);
}

float calcAO(in vec3 pos, in vec3 nor, bool water) {
    float occ = 0.0;
    float sca = 0.1;
    for (int i = 0; i < 5; i++) {
        float h = 0.01 + 0.2 * float(i) / 1.0;
        float d = map(pos + h * nor, water).dist;
        occ += (h - d) * sca;
        sca *= 0.95;
        if (occ > 0.35) break;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0) + (0.5 + 0.5 * nor.y);
}

MarchResult march(vec3 start, vec3 dir, float dist, bool water) {
    float z = 0.0;
    vec3 pos;
    SDF nearest;
    nearest.dist = 1000.0;
    nearest.color = vec3(0.0);
    nearest.water = false;
    float mindist = 1000.0;
    for (float i = 0.0; i < 700.0; i++) {
        z += dist;
        pos = start + dir * z;
        nearest = map(pos, water);
        dist = nearest.dist;
        mindist = min(dist, mindist);
        if (dist < 0.0001 || z > 500.0 || pos.y > 6.0) {
            break;
        }
    }
    return MarchResult(nearest, pos, z, nearest.color, mindist, dir);
}

float airMass(vec3 dir) {
    float planetRadius = 6380.0;
    float atmosphereThickness = 100.0;
    float atmosphereRatio = atmosphereThickness / (planetRadius + atmosphereThickness);
    float r = 1.0 - atmosphereRatio;
    float cosa = dir.y;
    float sina = sin(acos(dir.y));
    float a = sina * sina + cosa * cosa;
    float b = 2.0 * r * cosa;
    float c = r * r - 1.0;
    return (-b + sqrt(b * b - 4.0 * a * c)) / max(2.0 * a * atmosphereRatio, TINY_EPSILON);
}

float ambientStrength = 0.1;

vec3 sunDir(float day_progress_0_1) {
    float elevation_angle = 3.141592 / 2.0 * (1.0 - abs(2.0 * day_progress_0_1 - 1.0));
    float azimuth_angle = mix(-3.141592 / 2.0, 3.141592 / 2.0, day_progress_0_1);
    return vec3(cos(elevation_angle) * sin(azimuth_angle),
                sin(elevation_angle),
                cos(elevation_angle) * cos(azimuth_angle));
}

vec3 sunColor(float day_progress_0_1) {
    float elevation_angle = 3.141592 / 2.0 * (1.0 - abs(2.0 * day_progress_0_1 - 1.0));
    float rednessFac = smoothstep(0.0, 3.141592 / 4.0, elevation_angle) * smoothstep(3.141592 / 2.0, 3.141592 / 4.0, elevation_angle);
    rednessFac = 1.0 - rednessFac;
    return mix(vec3(1.0, 0.4, 0.13), vec3(0.95, 0.91, 0.77), 1.0 - rednessFac) * 2.0;
}

vec3 day(vec3 dir, float day_progress_0_1) {
    return mix(vec3(0.0, 0.1, 0.2), vec3(0.4, 1.0, 0.9) * 2.0, min(airMass(dir) / 11.0, 1.0));
}

vec3 sky(vec3 dir, float day_progress_0_1) {
    if (dir.y < 0.0) return vec3(0.0);
    vec3 base_day_color = day(dir, day_progress_0_1);
    float intensity_factor = smoothstep(0.0, 0.5, day_progress_0_1) * smoothstep(1.0, 0.5, day_progress_0_1);
    vec3 sky_color_morning_afternoon = mix(vec3(0.0, 0.1, 0.2), vec3(0.1, 0.3, 0.4), day_progress_0_1);
    vec3 sky_color_midday = vec3(0.4, 1.0, 0.9);
    vec3 interpolated_sky_color = mix(sky_color_morning_afternoon, sky_color_midday, intensity_factor);
    float s = pow(max(dot(dir, normalize(sunDir(day_progress_0_1))), 0.0), (1.0 - airMass(dir) / 11.0) * 10.0 + 1.0);
    vec3 sun_contribution = s * sunColor(day_progress_0_1) * max(1.0 - sunDir(day_progress_0_1).y, 0.0);
    return interpolated_sky_color * (0.5 + 0.5 * intensity_factor) + sun_contribution;
}

vec3 ambientColor(float day_progress_0_1) {
    float intensity_factor = smoothstep(0.0, 0.5, day_progress_0_1) * smoothstep(1.0, 0.5, day_progress_0_1);
    vec3 ambient_morning_afternoon = vec3(0.05, 0.08, 0.1);
    vec3 ambient_midday = vec3(0.5, 0.77, 0.8);
    return mix(ambient_morning_afternoon, ambient_midday, intensity_factor);
}

vec3 shade(MarchResult res, vec3 n, float day_progress_0_1) {
    if (res.nearest.water) {
        return res.color;
    }
    vec3 lightDir = normalize(sunDir(day_progress_0_1));
    if (res.pos.y > 6.0) {
        return sky(res.dir, day_progress_0_1);
    }
    vec3 light = ambientColor(day_progress_0_1) * ambientStrength;
    MarchResult lightRes = march(res.pos, lightDir, 1.0, false);
    float incLight = 0.0;
    if (lightRes.pos.y > 6.0) {
        incLight = clamp(lightRes.mindist / 0.7, 0.0, 1.0);
    }
    light += incLight * sunColor(day_progress_0_1) * max(dot(n, lightDir), 0.0);
    vec3 o = res.color * light;
    o *= calcAO(res.pos, n, false);
    return o;
}

vec3 shade_overload(MarchResult res, float day_progress_0_1) {
    return shade(res, calcNormal(res.pos, false), day_progress_0_1);
}

mat2 rot(float a) {
    a = radians(a);
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec4 renderScene(in vec2 fragCoord_in, float day_progress_0_1, float visibility_alpha) {
    vec2 uv = (fragCoord_in - iResolution.xy / 2.0) / max(iResolution.y, TINY_EPSILON);
    uv *= dot(uv, uv) * 0.3 + 1.0;
    vec3 origin = vec3(0.0, 1.4, 0.0);
    vec3 dir = normalize(vec3(uv, 1.0));
    dir.yz *= rot(10.0);
    MarchResult res = march(origin, dir, 0.0, true);
    vec3 n = calcNormal(res.pos, true);
    if (res.nearest.water) {
        MarchResult refl = march(res.pos, reflect(dir, n), 0.0, false);
        MarchResult refr = march(res.pos, refract(dir, n, 1.0 / 1.3333), 0.0, false);
        float reflFactor = fresnel(dir, n, 0.02);
        vec3 refrColor = exp(-vec3(1.0) * refr.z * 1.5);
        refrColor = mix(res.nearest.color, vec3(1.0), refrColor);
        res.color = mix(shade_overload(refr, day_progress_0_1) * refrColor, shade_overload(refl, day_progress_0_1), reflFactor);
    } else if (res.nearest.dist < 0.001) {
        MarchResult refl = march(res.pos, reflect(dir, n), 0.1, true);
        res.color += shade_overload(refl, day_progress_0_1) * fresnel(dir, n, 0.04);
    }
    vec3 color = shade(res, n, day_progress_0_1);
    color = mix(color, ambientColor(day_progress_0_1) * 0.2, fog(res.z, 0.003));
    return vec4(tanh_approx(pow(color, vec3(1.0 / 2.2))), 1.0) * visibility_alpha;
}

#define AA 1
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float total_cycle_duration = DAY_CYCLE_DURATION + 10.0; // 5s fade-in + 55s day + 5s fade-out
    float cycle_time = mod(iTime, total_cycle_duration);

    float fade_in_duration = 5.0; // 5s fade-in
    float day_duration = DAY_CYCLE_DURATION; // 55s from later morning to earlier afternoon
    float fade_out_duration = 5.0; // 5s fade-out

    float day_progress_0_1 = 0.0;
    float visibility_alpha = 1.0;

    if (cycle_time < fade_in_duration) {
        // Fade-in phase with sun starting at 7 AM (0.15 progress)
        float fade_in_progress = cycle_time / fade_in_duration;
        visibility_alpha = smoothstep(0.0, 1.0, fade_in_progress);
        day_progress_0_1 = 0.15 + fade_in_progress * 0.1; // 0.15 to 0.25
    } else if (cycle_time < fade_in_duration + day_duration) {
        // Day phase: sun moves from 7 AM to 5 PM
        float day_progress = (cycle_time - fade_in_duration) / day_duration;
        day_progress_0_1 = 0.25 + day_progress * 0.6; // 0.25 to 0.85
        visibility_alpha = 1.0;
    } else {
        // Fade-out phase
        float fade_out_progress = (cycle_time - (fade_in_duration + day_duration)) / fade_out_duration;
        visibility_alpha = 1.0 - smoothstep(0.0, 1.0, fade_out_progress);
        day_progress_0_1 = 0.85; // Stay at 5 PM during fade-out
    }

    #if AA == 1
    fragColor = renderScene(fragCoord, day_progress_0_1, visibility_alpha);
    #else
    vec4 o = vec4(0.0);
    for (float i = 0.0; i < float(AA); i++) {
        float noisex = fract(dot(fragCoord, cos(fragCoord + iTime + i)));
        float noisey = fract(dot(fragCoord, sin(fragCoord - i - iTime * 1.342)));
        vec2 noise = vec2(noisex, noisey);
        o += renderScene(fragCoord + noise * 0.5, day_progress_0_1, visibility_alpha);
    }
    fragColor = o / max(float(AA), TINY_EPSILON);
    #endif
}