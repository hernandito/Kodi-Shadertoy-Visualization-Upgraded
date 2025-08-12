// --- Post-processing Parameters ---
// Adjust brightness (1.0 is default, >1.0 brighter, <1.0 darker)
#define BRIGHTNESS 1.0
// Adjust contrast (1.0 is default, >1.0 more contrast, <1.0 less contrast)
#define CONTRAST 1.4
// Adjust saturation (1.0 is default, >1.0 more saturated, <1.0 desaturated)
#define SATURATION 1.0

// Learned from https://www.bilibili.com/video/BV1nX4y1W7Lj
// ref: https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm && https://www.shadertoy.com/view/DtGyzw iTime
float random(vec2 p){
    vec2 p2 = 145.3432 * fract(p * 49.1513);
    return fract((p2.x + p2.y) * p2.x * p2.y);
}

vec3 noise(vec2 pos){
    vec2 i = floor(pos);
    vec2 f = fract(pos);
    vec2 u = f * f * (3.0 - 2.0 * f);
    vec2 du = 6. * u * (1. - u);
    float LD = random(i);
    float RD = random(i + vec2(1.0, 0.));
    float LU = random(i + vec2(0.0, 1.0));
    float RU = random(i + vec2(1.0, 1.0));
    return vec3(LD + (RD - LD) * u.x * (1. - u.y) +
        (LU - LD) * (1. - u.x) * u.y +
        (RU - LD) * u.x * u.y, du * (vec2(RD - LD, LU - LD) +
        (LD - RD - LU + RU) * u.yx));
}

mat2 mat = mat2(0.6, -0.8, 0.8, 0.6);

float fbm(vec2 x, int iter){
    vec2 p = 0.003 * x;
    float h = 0.;
    float Amplitude = 1.;
    vec2 d = vec2(0);
    for (int i = 0; i < iter; ++i){
        vec3 n = noise(p);
        d += n.yz;
        h += Amplitude * n.x / (1. + dot(d, d));
        p = mat * p * 2.;
        Amplitude *= 0.52;
    }
    return 120. * h;
}

float rayMarch(vec3 ro, vec3 rd, float tmin, float tmax){
    float t = tmin;
    for (int i = 0; i < 128; ++i){
        vec3 p = ro + t * rd;
        float h = p.y - fbm(p.xz, 8);
        if (abs(h) < 0.001 * t || t > tmax)
            break;
        t += 0.4 * h;
    }
    return t;
}

float softShadow(in vec3 ro, in vec3 rd, float dis){
    float minStep = clamp(0.01 * dis, 0.5, 50.0);
    float res = 1.0;
    float t = 0.001;
    for (int i = 0; i < 80; ++i){
        vec3 p = ro + t * rd;
        float h = p.y - fbm(p.xz, 8);
        res = min(res, 8.0 * h / t);
        t += max(minStep, h);
        if(res < 0.001 || p.y > 200.0)
            break;
    }
    return clamp(res, 0.0, 1.0);
}

vec3 calcNormal(vec3 p, float t){
    vec2 epsilon = vec2(0.001 * t, 0);
    return normalize(vec3(fbm(p.xz - epsilon.xy, 16) - fbm(p.xz + epsilon.xy, 16),
    2.0 * epsilon.x, fbm(p.xz - epsilon.yx, 16) - fbm(p.xz + epsilon.yx, 16)));
}

mat3 setCamera(vec3 ro, vec3 target, float cr){
    vec3 z = normalize(target - ro);
    vec3 up = normalize(vec3(sin(cr), cos(cr), 0));
    vec3 x = cross(z, up);
    vec3 y = cross(x, z);
    return mat3(x, y, z);
}

vec3 sunsetSky(vec3 rd){
    vec3 skyTop = vec3(0.05, 0.05, 0.2);
    vec3 skyMiddle = vec3(0.3, 0.15, 0.4);
    vec3 skyHorizon = vec3(0.9, 0.3, 0.1);
    float h = rd.y;
    vec3 skyColor = mix(skyHorizon, skyMiddle, smoothstep(-0.2, 0.8, h));
    skyColor = mix(skyColor, skyTop, smoothstep(0.8, 1.0, h));
    float sunGlow = pow(max(dot(rd, vec3(0.2, 0.15, -0.97)), 0.0), 4.0);
    skyColor += 0.3 * vec3(1.0, 0.7, 0.4) * sunGlow;
    return skyColor;
}

vec3 render(vec2 uv){
    vec3 col = vec3(0.);
    float angle = iTime*.3 * 0.05;
    float r = 300.;
    vec2 pos2d = vec2(r * sin(angle), r * cos(angle));
    // float h = fbm(pos2d, 8) + 25.;
    float h = fbm(pos2d, 5) + 25.;
    vec3 ro = vec3(pos2d.x, h, pos2d.y);
    vec3 target = vec3(r * sin(angle + 0.01), h, r * cos(angle + 0.01));
    mat3 cam = setCamera(ro, target, 0.);
    float fl = 1.;
    vec3 rd = normalize(cam * vec3(uv, fl));
    float tmin = 0.01, tmax = 1000.;
    float maxh = 300.;
    float t = rayMarch(ro, rd, tmin, tmax);
    vec3 sunlight = normalize(vec3(0.8, 0.5, -0.2));
    float sundot = clamp(dot(rd, sunlight), 0., 1.);
    if (t > tmax) col = sunsetSky(rd);
    else {
        vec3 p = ro + t * rd;
        vec3 n = calcNormal(p, t);
        vec3 difColor = vec3(0.67, 0.57, 0.44);
        col = 0.1 * difColor;
        vec3 linear = vec3(0.);
        float dif = clamp(dot(sunlight, n), 0., 1.);
        float sh = softShadow(p + 0.01 * sunlight, sunlight, t);
        float amb = clamp(0.5 + 0.5 * n.y, 0., 1.);
        linear += dif * vec3(8.0, 5.0, 3.0) * 1.3 * vec3(sh, sh * sh * 0.5 + 0.5 * sh, sh * sh * 0.8 + 0.2 * sh);
        linear += amb * vec3(0.4, 0.6, 1.) * 5.2;
        col *= linear;
        col = mix(col, 0.55 * vec3(0.9, 0.3, 0.1), 1. - exp(-pow(0.002 * t, 1.5)));
    }
    // sun scatter
    col += 0.3 * vec3(1.0, 0.7, 0.3) * pow(sundot, 8.0);

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (2. * fragCoord.xy - iResolution.xy) / iResolution.x;
    vec3 col = render(uv);

    // --- Post-processing: Brightness, Contrast, Saturation ---
    // Apply Brightness
    col += (BRIGHTNESS - 1.0);

    // Apply Contrast
    col = ((col - 0.5) * CONTRAST) + 0.5;

    // Apply Saturation
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(luma), col, SATURATION);

    fragColor = vec4(1. - exp(-col * 1.2), 1.);
}
