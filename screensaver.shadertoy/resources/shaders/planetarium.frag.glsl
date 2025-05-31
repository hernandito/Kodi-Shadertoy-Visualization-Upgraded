uniform float uBrightness; // Brightness (set externally or defaults below)
uniform float uContrast;   // Contrast (set externally or defaults below)
uniform float uSaturation; // Saturation (set externally or defaults below)

const float DEFAULT_BRIGHTNESS = 0.80;
const float DEFAULT_CONTRAST = 1.121;
const float DEFAULT_SATURATION = 0.90;
const float ANIM_SPEED = 0.5; // Animation speed scale (1.0 = normal, 0.5 = half speed)

float g(vec4 p, float s) {
    return abs(dot(sin(p * s), cos(p.zxwy)) - 1.0) / s;
}

float tanh_approx(float x) {
    float x2 = x * x;
    return clamp(x * (27.0 + x2) / (27.0 + 9.0 * x2), -1.0, 1.0);
}

vec3 tanh_approx(vec3 x) {
    return vec3(tanh_approx(x.x), tanh_approx(x.y), tanh_approx(x.z));
}

vec4 tanh_approx(vec4 x) {
    return vec4(tanh_approx(x.x), tanh_approx(x.y), tanh_approx(x.z), tanh_approx(x.w));
}

float sRGB(float t) { return mix(1.055 * pow(t, 1.0/2.4) - 0.055, 12.92 * t, step(t, 0.0031308)); }

vec3 sRGB(in vec3 c) { return vec3(sRGB(c.x), sRGB(c.y), sRGB(c.z)); }

vec3 aces_approx(vec3 v) {
    v = max(v, 0.0);
    v *= 0.6;
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((v * (a * v + b)) / (v * (c * v + d) + e), 0.0, 1.0);
}

vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
    return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}

vec2 mod2(inout vec2 p, vec2 size) {
    vec2 c = floor((p + size * 0.5) / size);
    p = mod(p + size * 0.5, size) - size * 0.5;
    return c;
}

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453123);
}

vec2 shash2(vec2 p) {
    return -1.0 + 2.0 * hash2(p);
}

vec3 toSpherical(vec3 p) {
    float r = length(p);
    float t = acos(p.z / r);
    float ph = atan(p.y, p.x);
    return vec3(r, t, ph);
}

vec3 blackbody(float Temp) {
    vec3 col = vec3(255.0);
    col.x = 56100000.0 * pow(Temp, (-3.0 / 2.0)) + 148.0;
    col.y = 100.04 * log(Temp) - 623.6;
    if (Temp > 6500.0) col.y = 35200000.0 * pow(Temp, (-3.0 / 2.0)) + 184.0;
    col.z = 194.18 * log(Temp) - 1448.6;
    col = clamp(col, 0.0, 255.0) / 255.0;
    if (Temp < 1000.0) col *= Temp / 1000.0;
    return col;
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float n = mix(mix(dot(shash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
                     dot(shash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
                  mix(dot(shash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
                     dot(shash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
    return 2.0 * n;
}

float fbm(vec2 p, float o, float s, int iters) {
    p *= s;
    p += o;
    const float aa = 0.5;
    const mat2 pp = 2.04 * mat2(cos(1.0), sin(1.0), -sin(1.0), cos(1.0));
    float h = 0.0;
    float a = 1.0;
    float d = 0.0;
    for (int i = 0; i < iters; ++i) {
        d += a;
        h += a * noise(p);
        p += vec2(10.7, 8.3);
        p *= pp;
        a *= aa;
    }
    h /= d;
    return h;
}

float height(vec2 p) {
    float h = fbm(p, 0.0, 5.0, 5);
    h *= 0.3;
    h += 0.0;
    return h;
}

vec3 stars(vec3 ro, vec3 rd, vec2 sp, float hh) {
    vec3 col = vec3(0.0);
    const float m = 5.0;
    hh = tanh_approx(20.0 * hh);
    for (float i = 0.0; i < m; ++i) {
        vec2 pp = sp + 0.5 * i;
        float s = i / (m - 1.0);
        vec2 dim = vec2(mix(0.05, 0.003, s) * 3.141592654);
        vec2 np = mod2(pp, dim);
        vec2 h = hash2(np + 127.0 + i);
        vec2 o = -1.0 + 2.0 * h;
        float y = sin(sp.x);
        pp += o * dim * 0.5;
        pp.y *= y;
        float l = length(pp);
        float h1 = fract(h.x * 1667.0);
        float h2 = fract(h.x * 1887.0);
        float h3 = fract(h.x * 2997.0);
        vec3 scol = mix(8.0 * h2, 0.25 * h2 * h2, s) * blackbody(mix(3000.0, 22000.0, h1 * h1));
        vec3 ccol = col + exp(-(mix(6000.0, 2000.0, hh) / mix(2.0, 0.25, s)) * max(l - 0.001, 0.0)) * scol;
        col = h3 < y ? ccol : col;
    }
    return col;
}

vec2 raySphere(vec3 ro, vec3 rd, vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - sph.w * sph.w;
    float h = b * b - c;
    if (h < 0.0) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b - h, -b + h);
}

vec4 moon(vec3 ro, vec3 rd, vec2 sp, vec3 lp, vec4 md) {
    vec2 mi = raySphere(ro, rd, md);
    vec3 p = ro + mi.x * rd;
    vec3 n = normalize(p - md.xyz);
    vec3 r = reflect(rd, n);
    vec3 ld = normalize(lp - p);
    float fre = dot(n, rd) + 1.0;
    fre = pow(fre, 15.0);
    float dif = max(dot(ld, n), 0.0);
    float spe = pow(max(dot(ld, r), 0.0), 8.0);
    float i = 0.5 * tanh_approx(20.0 * fre * spe + 0.05 * dif);
    vec3 col = blackbody(1500.0) * i + hsv2rgb(vec3(0.6, mix(0.6, 0.0, i), i));
    float t = tanh_approx(0.25 * (mi.y - mi.x));
    return vec4(col, t);
}

vec3 sky(vec3 ro, vec3 rd, vec2 sp, vec3 lp, out float cf) {
    float ld = max(dot(normalize(lp - ro), rd), 0.0);
    float y = -0.5 + sp.x / 3.141592654;
    y = max(abs(y) - 0.02, 0.0) + 0.1 * smoothstep(0.5, 3.141592654, abs(sp.y));
    vec3 blue = hsv2rgb(vec3(0.6, 0.75, 0.35 * exp(-15.0 * y)));
    float ci = pow(ld, 10.0) * 2.0 * exp(-25.0 * y);
    vec3 yellow = blackbody(1500.0) * ci;
    cf = ci;
    return blue + yellow;
}

vec3 galaxy(vec3 ro, vec3 rd, vec2 sp, out float sf) {
    vec2 gp = sp;
    gp *= mat2(cos(0.67), sin(0.67), -sin(0.67), cos(0.67));
    gp += vec2(-1.0, 0.5);
    float h1 = height(2.0 * sp);
    float gcc = dot(gp, gp);
    float gcx = exp(-abs(3.0 * (gp.x)));
    float gcy = exp(-abs(10.0 * (gp.y)));
    float gh = gcy * gcx;
    float cf = smoothstep(0.05, -0.2, -h1);
    vec3 col = vec3(0.0);
    col += blackbody(mix(300.0, 1500.0, gcx * gcy)) * gcy * gcx;
    col += hsv2rgb(vec3(0.6, 0.5, 0.00125 / gcc));
    col *= mix(mix(0.15, 1.0, gcy * gcx), 1.0, cf);
    sf = gh * cf;
    return col;
}

vec3 grid(vec3 ro, vec3 rd, vec2 sp) {
    const float m = 1.0;
    const vec2 dim = vec2(1.0 / 8.0 * 3.141592654);
    vec2 pp = sp;
    vec2 np = mod2(pp, dim);
    vec3 col = vec3(0.0);
    float y = sin(sp.x);
    float d = min(abs(pp.x), abs(pp.y * y));
    float aa = 2.0 / iResolution.y;
    col += 2.0 * vec3(0.5, 0.5, 1.0) * exp(-2000.0 * max(d - 0.00025, 0.0));
    return 0.25 * tanh_approx(col);
}

vec3 color(vec3 ro, vec3 rd, vec3 lp, vec4 md) {
    vec2 sp = toSpherical(rd.xzy).yz;
    float sf = 0.0;
    float cf = 0.0;
    vec3 col = vec3(0.0);
    vec4 mcol = moon(ro, rd, sp, lp, md);
    col += stars(ro, rd, sp, sf) * (1.0 - tanh_approx(2.0 * cf));
    col += galaxy(ro, rd, sp, sf);
    col = mix(col, mcol.xyz, mcol.w);
    col += sky(ro, rd, sp, lp, cf);
    col += grid(ro, rd, sp);
    if (rd.y < 0.0) col = vec3(0.0);
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 q = fragCoord / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x / iResolution.y;
    // Apply cinematic letterbox (16:9 ratio with black bars)
    float targetAspect = 16.0 / 9.0; // Match TV aspect ratio
    float displayAspect = iResolution.x / iResolution.y; // Likely 16:9
    float scaleY = 0.9; // Scale to create black bars, 0.9 fine-tunes for 16:9
    p.y *= scaleY; // Shrink vertical to create letterbox
    // Center vertically by adjusting bounds
    float offsetY = 0.25; // Initial offset
    if (abs(p.y + offsetY) > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black bars
        return;
    }
    // Slow down animation uniformly
    float slowedTime = iTime * ANIM_SPEED;
    // Adjust cycle timing: 2s fade-in, 2s fade-out, total 34s cycle
    float cycleDuration = 34.0; // Extended to stretch middle
    float fadeInEnd = 2.0; // Faster fade-in
    float fadeOutStart = 32.0; // Faster fade-out (last 2 seconds)
    vec3 ro = vec3(0.0, 0.0, 0.0);
    vec3 lp = 500.0 * vec3(1.0, -0.25, 0.0);
    vec4 md = 50.0 * vec4(vec3(1.0, 1.0, -0.6), 0.5);
    vec3 la = vec3(1.0, 0.5, 0.0);
    vec3 up = vec3(0.0, 1.0, 0.0);
    la.xz *= mat2(cos(6.28318530718 * mod(slowedTime, cycleDuration) / 60.0 - 1.57079632679), sin(6.28318530718 * mod(slowedTime, cycleDuration) / 60.0 - 1.57079632679), -sin(6.28318530718 * mod(slowedTime, cycleDuration) / 60.0 - 1.57079632679), cos(6.28318530718 * mod(slowedTime, cycleDuration) / 60.0 - 1.57079632679));
    vec3 ww = normalize(la - ro);
    vec3 uu = normalize(cross(up, ww));
    vec3 vv = normalize(cross(ww, uu));
    vec3 rd = normalize(p.x * uu + p.y * vv + 1.5 * ww); // Wider view
    vec3 col = color(ro, rd, lp, md);
    col *= smoothstep(0.0, fadeInEnd, mod(slowedTime, cycleDuration)) * smoothstep(cycleDuration, fadeOutStart, mod(slowedTime, cycleDuration));
    // Apply B/C/S adjustments with fallbacks
    float brightness = (uBrightness == 0.0) ? DEFAULT_BRIGHTNESS : uBrightness;
    float contrast = (uContrast == 0.0) ? DEFAULT_CONTRAST : uContrast;
    float saturation = (uSaturation == 0.0) ? DEFAULT_SATURATION : uSaturation;
    col = (col - 0.5) * contrast + 0.5;
    col *= brightness;
    float luminance = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luminance), col, saturation);
    col = aces_approx(col);
    col = sRGB(col);
    fragColor = vec4(col, 1.0);
}