// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Volumetric clouds demo, GLES-compatible (e.g. Kodi Shadertoy addon).

#define SAMPLE_COUNT 40
#define PERIOD        2.0

bool STRUCTURED;
vec3 sundir;

// 3D value noise via a lookup texture in iChannel0
float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0 - 2.0*f);
    vec2 uv = (p.xy + vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = textureLod(iChannel0, (uv + 0.5)/256.0, 0.0).yx;
    return mix(rg.x, rg.y, f.z);
}

// density→color mapping
vec4 map(in vec3 p) {
    float d = 0.1 + 0.8*sin(0.6*p.z)*sin(0.5*p.x) - p.y;
    vec3 q = p;
    float f;
    f  = 0.5000*noise(q); q *= 2.02;
    f += 0.2500*noise(q); q *= 2.03;
    f += 0.1250*noise(q); q *= 2.01;
    f += 0.0625*noise(q);
    d += 2.75 * f;
    d = clamp(d, 0.0, 1.0);

    vec4 res = vec4(d);
    vec3 col = 1.15*vec3(1.0,0.95,0.8)
             + vec3(1.0,0.0,0.0)*exp2(d*10.0 - 10.0);
    res.xyz = mix(col, vec3(0.7), d);
    return res;
}

// compute line-sampling offsets & weights
void SetupSampling(out vec2 t, out vec2 dt, out vec2 wt,
                   in vec3 ro, in vec3 rd)
{
    if (!STRUCTURED) {
        dt = vec2(PERIOD, PERIOD);
        t  = dt;
        wt = vec2(0.5);
    } else {
        vec3 n0 = (abs(rd.x) > abs(rd.z))
                 ? vec3(1.0,0.0,0.0)
                 : vec3(0.0,0.0,1.0);
        vec3 n1 = vec3(sign(rd.x*rd.z), 0.0, 1.0);
        vec2 ln = vec2(length(n0), length(n1));
        n0 /= ln.x; n1 /= ln.y;
        vec2 ndotro = vec2(dot(ro,n0), dot(ro,n1));
        vec2 ndotrd = vec2(dot(rd,n0), dot(rd,n1));
        vec2 period = ln * PERIOD;
        dt = period / abs(ndotrd);
        t  = -sign(ndotrd) * mod(ndotro, period) / abs(ndotrd);
        if (ndotrd.x > 0.0) t.x += dt.x;
        if (ndotrd.y > 0.0) t.y += dt.y;
        float minp = PERIOD, maxp = sqrt(2.0)*PERIOD;
        wt = smoothstep(maxp, minp, dt/ln);
        wt /= (wt.x + wt.y);
    }
}

// raymarch through the volume
vec4 raymarch(in vec3 ro, in vec3 rd) {
    vec4 sum = vec4(0.0);
    vec2 t, dt, wt;
    SetupSampling(t, dt, wt, ro, rd);

    float f         = 0.6;
    float endFade   = f * float(SAMPLE_COUNT) * PERIOD;
    float startFade = 0.8 * endFade;

    // --- CAMERA FADE SETTINGS ---
    float cameraFadeRadius = 2.0;  // radius around camera to start fading
    float fadeInner = 1.0;         // inner radius (fully faded)
    float fadeOuter = cameraFadeRadius; // outer radius (no fade)

    for (int i = 0; i < SAMPLE_COUNT; i++) {
        if (sum.a > 0.99) continue;

        vec4 data = (t.x < t.y)
            ? vec4(t.x, wt.x, dt.x, 0.0)
            : vec4(t.y, wt.y, 0.0, dt.y);
        vec3 pos = ro + data.x * rd;
        float w = data.y;
        t += data.zw;
        w *= smoothstep(endFade, startFade, data.x);

        float camDist = length(pos - ro);
        float fadeNear = smoothstep(fadeInner, fadeOuter, camDist);  // 0..1
        w *= fadeNear;

        vec4 col = map(pos);
        float dif = clamp((col.w - map(pos + 0.6*sundir).w)/0.6, 0.0,1.0);
        vec3 lin = vec3(0.51,0.53,0.63)*1.35 
                 + vec3(0.85,0.57,0.30)*0.55*dif;
        col.xyz *= lin * col.xyz;
        col.a   *= 0.75;
        col.rgb *= col.a;

        sum += col * (1.0 - sum.a) * w;
    }

    sum.xyz /= (0.001 + sum.w);
    return clamp(sum, 0.0, 1.0);
}

// simple sky fallback
vec3 sky(in vec3 rd) {
    vec3 col = vec3(0.0);
    float hort = 1.0 - clamp(abs(rd.y), 0.0, 1.0);
    col += 0.5*vec3(0.99,0.5,0.0)*exp2(hort*8.0 - 8.0);
    col += 0.1*vec3(0.5,0.9,1.0)*exp2(hort*3.0 - 3.0);
    col += 0.55*vec3(0.6,0.6,0.9);
    float sun = clamp(dot(sundir, rd), 0.0, 1.0);
    col += 0.2*vec3(1.0,0.3,0.2)*sun*sun;
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // ─── USER CONTROLS ────────────────────────────────
    float animationSpeed   = 0.1;    // 0.1 = 10× slower, 1.0 = original, >1 → faster
    float cameraHeightOffset = .20;  // raises both camera and target by this much

    STRUCTURED = (iMouse.z <= 10.0);
    sundir = normalize(vec3(-1.0, 0.0, -1.0));

    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= iResolution.x / iResolution.y;

    float t = iTime * animationSpeed;

    vec3 lookDir = vec3(cos(0.53*t), 0.0, sin(t));
    vec3 camVel   = vec3(-20.0, 0.0, 0.0);
    vec3 basePos  = vec3(0.0, 1.5, 0.0) + vec3(0.0, cameraHeightOffset, 0.0);
    vec3 ro       = basePos + t * camVel;
    vec3 ta       = ro + lookDir + vec3(0.0, cameraHeightOffset, 0.0);

    vec3 ww  = normalize(ta - ro);
    vec3 uu  = normalize(cross(vec3(0,1,0), ww));
    vec3 vv  = normalize(cross(ww, uu));
    float fov = 1.0;
    vec3 rd  = normalize(fov*p.x*uu + fov*1.2*p.y*vv + 1.5*ww);

    vec4 clouds = raymarch(ro, rd);
    vec3 col    = clouds.xyz;
    if (clouds.w < 0.99)
        col = mix(sky(rd), col, clouds.w);

    col = clamp(col, 0.0, 1.0);
    col = smoothstep(0.0,1.0,col);
    col *= pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.12); // vignette

    fragColor = vec4(col, 1.0);
}

/*

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Volumetric clouds demo, GLES-compatible (e.g. Kodi Shadertoy addon).

#define SAMPLE_COUNT 40
#define PERIOD        2.0

bool STRUCTURED;
vec3 sundir;

// 3D value noise via a lookup texture in iChannel0
float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0 - 2.0*f);
    vec2 uv = (p.xy + vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = textureLod(iChannel0, (uv + 0.5)/256.0, 0.0).yx;
    return mix(rg.x, rg.y, f.z);
}

// density→color mapping
vec4 map(in vec3 p) {
    float d = 0.1 + 0.8*sin(0.6*p.z)*sin(0.5*p.x) - p.y;
    vec3 q = p;
    float f;
    f  = 0.5000*noise(q); q *= 2.02;
    f += 0.2500*noise(q); q *= 2.03;
    f += 0.1250*noise(q); q *= 2.01;
    f += 0.0625*noise(q);
    d += 2.75 * f;
    d = clamp(d, 0.0, 1.0);

    vec4 res = vec4(d);
    vec3 col = 1.15*vec3(1.0,0.95,0.8)
             + vec3(1.0,0.0,0.0)*exp2(d*10.0 - 10.0);
    res.xyz = mix(col, vec3(0.7), d);
    return res;
}

// compute line-sampling offsets & weights
void SetupSampling(out vec2 t, out vec2 dt, out vec2 wt,
                   in vec3 ro, in vec3 rd)
{
    if (!STRUCTURED) {
        dt = vec2(PERIOD, PERIOD);
        t  = dt;
        wt = vec2(0.5);
    } else {
        vec3 n0 = (abs(rd.x) > abs(rd.z))
                 ? vec3(1.0,0.0,0.0)
                 : vec3(0.0,0.0,1.0);
        vec3 n1 = vec3(sign(rd.x*rd.z), 0.0, 1.0);
        vec2 ln = vec2(length(n0), length(n1));
        n0 /= ln.x; n1 /= ln.y;
        vec2 ndotro = vec2(dot(ro,n0), dot(ro,n1));
        vec2 ndotrd = vec2(dot(rd,n0), dot(rd,n1));
        vec2 period = ln * PERIOD;
        dt = period / abs(ndotrd);
        t  = -sign(ndotrd) * mod(ndotro, period) / abs(ndotrd);
        if (ndotrd.x > 0.0) t.x += dt.x;
        if (ndotrd.y > 0.0) t.y += dt.y;
        float minp = PERIOD, maxp = sqrt(2.0)*PERIOD;
        wt = smoothstep(maxp, minp, dt/ln);
        wt /= (wt.x + wt.y);
    }
}

// raymarch through the volume
vec4 raymarch(in vec3 ro, in vec3 rd) {
    vec4 sum = vec4(0.0);
    vec2 t, dt, wt;
    SetupSampling(t, dt, wt, ro, rd);

    float f         = 0.6;
    float endFade   = f * float(SAMPLE_COUNT) * PERIOD;
    float startFade = 0.8 * endFade;

    // --- CAMERA FADE SETTINGS ---
    float cameraFadeRadius = 2.0;  // radius around camera to start fading
    float fadeInner = 1.0;         // inner radius (fully faded)
    float fadeOuter = cameraFadeRadius; // outer radius (no fade)

    for (int i = 0; i < SAMPLE_COUNT; i++) {
        if (sum.a > 0.99) continue;

        vec4 data = (t.x < t.y)
            ? vec4(t.x, wt.x, dt.x, 0.0)
            : vec4(t.y, wt.y, 0.0, dt.y);
        vec3 pos = ro + data.x * rd;
        float w = data.y;
        t += data.zw;
        w *= smoothstep(endFade, startFade, data.x);

        float camDist = length(pos - ro);
        float fadeNear = smoothstep(fadeInner, fadeOuter, camDist);  // 0..1
        w *= fadeNear;

        vec4 col = map(pos);
        float dif = clamp((col.w - map(pos + 0.6*sundir).w)/0.6, 0.0,1.0);
        vec3 lin = vec3(0.51,0.53,0.63)*1.35 
                 + vec3(0.85,0.57,0.30)*0.55*dif;
        col.xyz *= lin * col.xyz;
        col.a   *= 0.75;
        col.rgb *= col.a;

        sum += col * (1.0 - sum.a) * w;
    }

    sum.xyz /= (0.001 + sum.w);
    return clamp(sum, 0.0, 1.0);
}

// simple sky fallback
vec3 sky(in vec3 rd) {
    vec3 col = vec3(0.0);
    float hort = 1.0 - clamp(abs(rd.y), 0.0, 1.0);
    col += 0.5*vec3(0.99,0.5,0.0)*exp2(hort*8.0 - 8.0);
    col += 0.1*vec3(0.5,0.9,1.0)*exp2(hort*3.0 - 3.0);
    col += 0.55*vec3(0.6,0.6,0.9);
    float sun = clamp(dot(sundir, rd), 0.0, 1.0);
    col += 0.2*vec3(1.0,0.3,0.2)*sun*sun;
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // ─── USER CONTROLS ────────────────────────────────
    float animationSpeed   = 0.1;    // 0.1 = 10× slower, 1.0 = original, >1 → faster
    float cameraHeightOffset = .20;  // raises both camera and target by this much

    STRUCTURED = (iMouse.z <= 10.0);
    sundir = normalize(vec3(-1.0, 0.0, -1.0));

    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= iResolution.x / iResolution.y;

    float t = iTime * animationSpeed;

    vec3 lookDir = vec3(cos(0.53*t), 0.0, sin(t));
    vec3 camVel   = vec3(-20.0, 0.0, 0.0);
    vec3 basePos  = vec3(0.0, 1.5, 0.0) + vec3(0.0, cameraHeightOffset, 0.0);
    vec3 ro       = basePos + t * camVel;
    vec3 ta       = ro + lookDir + vec3(0.0, cameraHeightOffset, 0.0);

    vec3 ww  = normalize(ta - ro);
    vec3 uu  = normalize(cross(vec3(0,1,0), ww));
    vec3 vv  = normalize(cross(ww, uu));
    float fov = 1.0;
    vec3 rd  = normalize(fov*p.x*uu + fov*1.2*p.y*vv + 1.5*ww);

    vec4 clouds = raymarch(ro, rd);
    vec3 col    = clouds.xyz;
    if (clouds.w < 0.99)
        col = mix(sky(rd), col, clouds.w);

    col = clamp(col, 0.0, 1.0);
    col = smoothstep(0.0,1.0,col);
    col *= pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.12); // vignette

    fragColor = vec4(col, 1.0);
}


*/