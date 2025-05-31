// Created by Danil (2021+) https://cohost.org/arugl
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// self https://www.shadertoy.com/view/NslGRN

// Hardcoded based on active defines: NO_ALPHA, ROTATION_SPEED
#define NO_ALPHA
#define ROTATION_SPEED 0.8999

#define tshift 53.
#define FDIST 0.7
#define PI 3.1415926
#define GROUNDSPACING 0.5
#define GROUNDGRID 0.05
#define BOXDIMS vec3(0.75, 0.75, 1.25)
#define IOR 1.33

mat3 rotx(float a) { float s = sin(a); float c = cos(a); return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c)); }
mat3 roty(float a) { float s = sin(a); float c = cos(a); return mat3(vec3(c, 0.0, s), vec3(0.0, 1.0, 0.0), vec3(-s, 0.0, c)); }
mat3 rotz(float a) { float s = sin(a); float c = cos(a); return mat3(vec3(c, s, 0.0), vec3(-s, c, 0.0), vec3(0.0, 0.0, 1.0)); }

vec3 fcos(vec3 x) {
    vec3 w = fwidth(x);
    float lw = length(w);
    if (lw == 0.0 || lw > 1e6) {
        vec3 tc = vec3(0.);
        tc += cos(x);
        tc += cos(x + x * (-3.0) * (0.01 * 400. / iResolution.y));
        tc += cos(x + x * (-2.0) * (0.01 * 400. / iResolution.y));
        tc += cos(x + x * (-1.0) * (0.01 * 400. / iResolution.y));
        tc += cos(x + x * (0.0) * (0.01 * 400. / iResolution.y));
        tc += cos(x + x * (1.0) * (0.01 * 400. / iResolution.y));
        tc += cos(x + x * (2.0) * (0.01 * 400. / iResolution.y));
        tc += cos(x + x * (3.0) * (0.01 * 400. / iResolution.y));
        return tc / 8.0;
    }
    return cos(x) * smoothstep(3.14 * 2.0, 0.0, w);
}

vec3 getColor(vec3 p) {
    p = abs(p);
    p *= 1.25;
    p = 0.5 * p / dot(p, p);
    float t = 0.13 * length(p);
    vec3 col = vec3(0.3, 0.4, 0.5);
    col += 0.12 * fcos(6.28318 * t * 1.0 + vec3(0.0, 0.8, 1.1));
    col += 0.11 * fcos(6.28318 * t * 3.1 + vec3(0.3, 0.4, 0.1));
    col += 0.10 * fcos(6.28318 * t * 5.1 + vec3(0.1, 0.7, 1.1));
    col += 0.10 * fcos(6.28318 * t * 17.1 + vec3(0.2, 0.6, 0.7));
    col += 0.10 * fcos(6.28318 * t * 31.1 + vec3(0.1, 0.6, 0.7));
    col += 0.10 * fcos(6.28318 * t * 65.1 + vec3(0.0, 0.5, 0.8));
    col += 0.10 * fcos(6.28318 * t * 115.1 + vec3(0.1, 0.4, 0.7));
    col += 0.10 * fcos(6.28318 * t * 265.1 + vec3(1.1, 1.4, 2.7));
    col = clamp(col, 0.0, 1.0);
    return col;
}

void calcColor(vec3 ro, vec3 rd, vec3 nor, float d, float len, int idx, bool si, float td, out vec4 colx, out vec4 colsi) {
    vec3 pos = ro + rd * d;
    float a = 1.0 - smoothstep(len - 0.15 * 0.5, len + 0.00001, length(pos));
    vec3 col = getColor(pos);
    colx = vec4(col, a);
    if (si) {
        pos = ro + rd * td;
        float ta = 1.0 - smoothstep(len - 0.15 * 0.5, len + 0.00001, length(pos));
        col = getColor(pos);
        colsi = vec4(col, ta);
    } else {
        colsi = vec4(0.0);
    }
}

bool iBilinearPatch(vec3 ro, vec3 rd, vec4 ps, vec4 ph, float sz, out float t, out vec3 norm, out bool si, out float tsi, out vec3 normsi, out float fade, out float fadesi) {
    vec3 va = vec3(0.0, 0.0, ph.x + ph.w - ph.y - ph.z);
    vec3 vb = vec3(0.0, ps.w - ps.y, ph.z - ph.x);
    vec3 vc = vec3(ps.z - ps.x, 0.0, ph.y - ph.x);
    vec3 vd = vec3(ps.xy, ph.x);
    t = -1.0;
    tsi = -1.0;
    si = false;
    fade = 1.0;
    fadesi = 1.0;
    norm = vec3(0.0, 1.0, 0.0);
    normsi = vec3(0.0, 1.0, 0.0);

    float tmp = 1.0 / (vb.y * vc.x);
    float a = 0.0;
    float b = 0.0;
    float c = 0.0;
    float d = va.z * tmp;
    float e = 0.0;
    float f = 0.0;
    float g = (vc.z * vb.y - vd.y * va.z) * tmp;
    float h = (vb.z * vc.x - va.z * vd.x) * tmp;
    float i = -1.0;
    float j = (vd.x * vd.y * va.z + vd.z * vb.y * vc.x) * tmp - (vd.y * vb.z * vc.x + vd.x * vc.z * vb.y) * tmp;

    float p = dot(vec3(a, b, c), rd.xzy * rd.xzy) + dot(vec3(d, e, f), rd.xzy * rd.zyx);
    float q = dot(vec3(2.0, 2.0, 2.0) * ro.xzy * rd.xyz, vec3(a, b, c)) + dot(ro.xzz * rd.zxy, vec3(d, d, e)) +
              dot(ro.yyx * rd.zxy, vec3(e, f, f)) + dot(vec3(g, h, i), rd.xzy);
    float r = dot(vec3(a, b, c), ro.xzy * ro.xzy) + dot(vec3(d, e, f), ro.xzy * ro.zyx) + dot(vec3(g, h, i), ro.xzy) + j;

    if (abs(p) < 0.000001) {
        float tt = -r / q;
        if (tt <= 0.0)
            return false;
        t = tt;
        vec3 pos = ro + t * rd;
        if (length(pos) > sz) return false;
        vec3 grad = vec3(2.0) * pos.xzy * vec3(a, b, c) + pos.zxz * vec3(d, d, e) + pos.yyx * vec3(f, e, f) + vec3(g, h, i);
        norm = -normalize(grad);
        return true;
    } else {
        float sq = q * q - 4.0 * p * r;
        if (sq < 0.0) {
            return false;
        } else {
            float s = sqrt(sq);
            float t0 = (-q + s) / (2.0 * p);
            float t1 = (-q - s) / (2.0 * p);
            float tt1 = min(t0 < 0.0 ? t1 : t0, t1 < 0.0 ? t0 : t1);
            float tt2 = max(t0 > 0.0 ? t1 : t0, t1 > 0.0 ? t0 : t1);
            float tt0 = tt1;
            if (tt0 <= 0.0)
                return false;
            vec3 pos = ro + tt0 * rd;
            bool ru = step(sz, length(pos)) > 0.5;
            if (ru) {
                tt0 = tt2;
                pos = ro + tt0 * rd;
            }
            if (tt0 <= 0.0)
                return false;
            bool ru2 = step(sz, length(pos)) > 0.5;
            if (ru2)
                return false;

            if ((tt2 > 0.0) && (!ru) && !(step(sz, length(ro + tt2 * rd)) > 0.5)) {
                si = true;
                fadesi = s;
                tsi = tt2;
                vec3 tpos = ro + tsi * rd;
                vec3 tgrad = vec3(2.0) * tpos.xzy * vec3(a, b, c) + tpos.zxz * vec3(d, d, e) +
                             tpos.yyx * vec3(f, e, f) + vec3(g, h, i);
                normsi = -normalize(tgrad);
            }
            
            fade = s;
            t = tt0;
            vec3 grad = vec3(2.0) * pos.xzy * vec3(a, b, c) + pos.zxz * vec3(d, d, e) + pos.yyx * vec3(f, e, f) + vec3(g, h, i);
            norm = -normalize(grad);
            return true;
        }
    }
}

float box(vec3 ro, vec3 rd, vec3 r, out vec3 nn, bool entering) {
    rd += 0.0001 * (1.0 - abs(sign(rd)));
    vec3 dr = 1.0 / rd;
    vec3 n = ro * dr;
    vec3 k = r * abs(dr);
    vec3 pin = -k - n;
    vec3 pout = k - n;
    float tin = max(pin.x, max(pin.y, pin.z));
    float tout = min(pout.x, min(pout.y, pout.z));
    if (tin > tout)
        return -1.0;
    if (entering) {
        nn = -sign(rd) * step(pin.zxy, pin.xyz) * step(pin.yzx, pin.xyz);
    } else {
        nn = sign(rd) * step(pout.xyz, pout.zxy) * step(pout.xyz, pout.yzx);
    }
    return entering ? tin : tout;
}

vec3 bgcol(vec3 rd) {
    return mix(vec3(0.01), vec3(0.336, 0.458, 0.668), 1.0 - pow(abs(rd.z + 0.25), 1.3));
}

vec3 background(vec3 ro, vec3 rd, vec3 l_dir, out float alpha) {
    float t = (-BOXDIMS.z - ro.z) / rd.z;
    alpha = 0.0;
    vec3 bgc = bgcol(rd);
    if (t < 0.0)
        return bgc;
    vec2 uv = ro.xy + t * rd.xy;
    
    // Shadow parameters
    const float shadowRadius = 0.7;    // How far the shadow extends beyond the cube
    const float shadowIntensity = 0.4; // How dark the shadow is (0.0 = black, 1.0 = no shadow)
    
    // Calculate distance to cube's footprint
    vec2 distVec = abs(uv) - vec2(BOXDIMS.x, BOXDIMS.y);
    float dist = length(max(distVec, 0.0));
    float shadowFactor = smoothstep(0.0, shadowRadius, dist);
    
    float aofac = smoothstep(-0.95, 0.75, length(abs(uv) - min(abs(uv), vec2(0.45))));
    float lght = max(dot(normalize(ro + t * rd + vec3(0.0, -0.0, -5.0)), normalize(l_dir - vec3(0.0, 0.0, 1.0)) * rotz(PI * 0.65)), 0.0);
    vec3 col = mix(vec3(0.4), vec3(0.71, 0.772, 0.895), lght * lght * aofac + 0.05) * aofac;
    
    // Apply shadow
    col *= mix(shadowIntensity, 1.0, shadowFactor);
    
    alpha = 1.0 - smoothstep(7.0, 10.0, length(uv));
    return mix(col * length(col) * 0.8, bgc, smoothstep(7.0, 10.0, length(uv)));
}

vec4 insides(vec3 ro, vec3 rd, vec3 nor_c, vec3 l_dir, out float tout) {
    tout = -1.0;
    vec3 trd = rd;
    vec3 col = vec3(0.0);
    float pi = 3.1415926;

    if (abs(nor_c.x) > 0.5) {
        rd = rd.xzy * nor_c.x;
        ro = ro.xzy * nor_c.x;
    } else if (abs(nor_c.z) > 0.5) {
        l_dir *= roty(pi);
        rd = rd.yxz * nor_c.z;
        ro = ro.yxz * nor_c.z;
    } else if (abs(nor_c.y) > 0.5) {
        l_dir *= rotz(-pi * 0.5);
        rd = rd * nor_c.y;
        ro = ro * nor_c.y;
    }

    float curvature = 0.5;
    float bil_size = 1.0;
    vec4 ps = vec4(-bil_size, -bil_size, bil_size, bil_size) * curvature;
    vec4 ph = vec4(-bil_size, bil_size, bil_size, -bil_size) * curvature;
    
    vec4 colx0 = vec4(0.0);
    vec4 colx1 = vec4(0.0);
    vec4 colsi0 = vec4(0.0);
    vec4 colsi1 = vec4(0.0);
    float t0 = -1.0;
    float t1 = -1.0;
    vec3 norm0 = vec3(0.0);
    vec3 norm1 = vec3(0.0);
    bool si0 = false;
    bool si1 = false;
    float tsi0 = -1.0;
    float tsi1 = -1.0;
    vec3 normsi0 = vec3(0.0);
    vec3 normsi1 = vec3(0.0);
    float fade0 = 1.0;
    float fade1 = 1.0;
    float fadesi0 = 1.0;
    float fadesi1 = 1.0;

    if (iBilinearPatch(ro, rd, ps, ph, bil_size, t0, norm0, si0, tsi0, normsi0, fade0, fadesi0)) {
        if (t0 > 0.0) {
            vec4 tcol = vec4(0.0);
            vec4 tcolsi = vec4(0.0);
            calcColor(ro, rd, norm0, t0, bil_size, 0, si0, tsi0, tcol, tcolsi);
            if (tcol.a > 0.0) {
                float dif = clamp(dot(norm0, l_dir), 0.0, 1.0);
                float amb = clamp(0.5 + 0.5 * dot(norm0, l_dir), 0.0, 1.0);
                vec3 shad = vec3(0.32, 0.43, 0.54) * amb + vec3(1.0, 0.9, 0.7) * dif;
                const vec3 tcr = vec3(1.0, 0.21, 0.11);
                float ta = clamp(length(tcol.rgb), 0.0, 1.0);
                tcol = clamp(tcol * tcol * 2.0, 0.0, 1.0);
                colx0 = vec4((tcol.rgb * shad * 1.4 + 3.0 * (tcr * tcol.rgb) * clamp(1.0 - (amb + dif), 0.0, 1.0)), min(tcol.a, ta));
                colx0.rgb = clamp(2.0 * colx0.rgb * colx0.rgb, 0.0, 1.0);
                colx0 *= min(fade0 * 5.0, 1.0);
                if (si0) {
                    dif = clamp(dot(normsi0, l_dir), 0.0, 1.0);
                    amb = clamp(0.5 + 0.5 * dot(normsi0, l_dir), 0.0, 1.0);
                    shad = vec3(0.32, 0.43, 0.54) * amb + vec3(1.0, 0.9, 0.7) * dif;
                    ta = clamp(length(tcolsi.rgb), 0.0, 1.0);
                    tcolsi = clamp(tcolsi * tcolsi * 2.0, 0.0, 1.0);
                    colsi0 = vec4(tcolsi.rgb * shad + 3.0 * (tcr * tcolsi.rgb) * clamp(1.0 - (amb + dif), 0.0, 1.0), min(tcolsi.a, ta));
                    colsi0.rgb = clamp(2.0 * colsi0.rgb * colsi0.rgb, 0.0, 1.0);
                    colsi0.rgb *= min(fadesi0 * 5.0, 1.0);
                }
            }
        }
    }

    ro *= rotz(-pi / 3.0);
    rd *= rotz(-pi / 3.0);
    if (iBilinearPatch(ro, rd, ps, ph, bil_size, t1, norm1, si1, tsi1, normsi1, fade1, fadesi1)) {
        if (t1 > 0.0) {
            vec4 tcol = vec4(0.0);
            vec4 tcolsi = vec4(0.0);
            calcColor(ro, rd, norm1, t1, bil_size, 1, si1, tsi1, tcol, tcolsi);
            if (tcol.a > 0.0) {
                float dif = clamp(dot(norm1, l_dir), 0.0, 1.0);
                float amb = clamp(0.5 + 0.5 * dot(norm1, l_dir), 0.0, 1.0);
                vec3 shad = vec3(0.32, 0.43, 0.54) * amb + vec3(1.0, 0.9, 0.7) * dif;
                const vec3 tcr = vec3(1.0, 0.21, 0.11);
                float ta = clamp(length(tcol.rgb), 0.0, 1.0);
                tcol = clamp(tcol * tcol * 2.0, 0.0, 1.0);
                colx1 = vec4((tcol.rgb * shad * 1.4 + 3.0 * (tcr * tcol.rgb) * clamp(1.0 - (amb + dif), 0.0, 1.0)), min(tcol.a, ta));
                colx1.rgb = clamp(2.0 * colx1.rgb * colx1.rgb, 0.0, 1.0);
                colx1 *= min(fade1 * 5.0, 1.0);
                if (si1) {
                    dif = clamp(dot(normsi1, l_dir), 0.0, 1.0);
                    amb = clamp(0.5 + 0.5 * dot(normsi1, l_dir), 0.0, 1.0);
                    shad = vec3(0.32, 0.43, 0.54) * amb + vec3(1.0, 0.9, 0.7) * dif;
                    ta = clamp(length(tcolsi.rgb), 0.0, 1.0);
                    tcolsi = clamp(tcolsi * tcolsi * 2.0, 0.0, 1.0);
                    colsi1 = vec4(tcolsi.rgb * shad + 3.0 * (tcr * tcolsi.rgb) * clamp(1.0 - (amb + dif), 0.0, 1.0), min(tcolsi.a, ta));
                    colsi1.rgb = clamp(2.0 * colsi1.rgb * colsi1.rgb, 0.0, 1.0);
                    colsi1.rgb *= min(fadesi1 * 5.0, 1.0);
                }
            }
        }
    }

    vec4 colx = colx0;
    vec4 colsi = colsi0;
    float t = t0;
    if (t1 > t0 && t1 > 0.0) {
        colx = colx1;
        colsi = colsi1;
        t = t1;
    }

    tout = t;
    float a = max(colx.a, colsi.a);
    if (si0 && tsi0 > t) {
        col = mix(colsi.rgb, colx.rgb, colx.a);
    } else {
        col = colx.rgb;
    }
    return vec4(col, a);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float osc = 0.5;
    vec3 l_dir = normalize(vec3(0.0, 1.0, 0.0));
    l_dir *= rotz(0.5);
    float mouseY = PI * 0.49 - smoothstep(0.0, 8.5, mod((iTime + tshift) * 0.33, 25.0)) * (1.0 - smoothstep(14.0, 24.0, mod((iTime + tshift) * 0.33, 25.0))) * 0.55 * PI;
    float mouseX = -2.0 * PI - 0.25 * (iTime * ROTATION_SPEED + tshift);
    vec3 eye = 4.0 * vec3(cos(mouseX) * cos(mouseY), sin(mouseX) * cos(mouseY), sin(mouseY));
    vec3 w = normalize(-eye);
    vec3 up = vec3(0.0, 0.0, 1.0);
    vec3 u = normalize(cross(w, up));
    vec3 v = cross(u, w);

    vec4 tot = vec4(0.0);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.x;
    vec3 rd = normalize(w * FDIST + uv.x * u + uv.y * v);

    vec3 ni;
    float t = box(eye, rd, BOXDIMS, ni, true);
    vec3 ro = eye + t * rd;
    vec2 coords = ro.xy * ni.z / BOXDIMS.xy + ro.yz * ni.x / BOXDIMS.yz + ro.zx * ni.y / BOXDIMS.zx;
    float fadeborders = (1.0 - smoothstep(0.915, 1.05, abs(coords.x))) * (1.0 - smoothstep(0.915, 1.05, abs(coords.y)));

    if (t > 0.0) {
        float ang = -iTime * 0.33;
        vec3 col = vec3(0.0);
        float R0 = (IOR - 1.0) / (IOR + 1.0);
        R0 *= R0;
        vec2 theta = vec2(0.0);
        vec3 n = vec3(cos(theta.x) * sin(theta.y), sin(theta.x) * sin(theta.y), cos(theta.y));
        vec3 nr = n.zxy * ni.x + n.yzx * ni.y + n.xyz * ni.z;
        vec3 rdr = reflect(rd, nr);
        float talpha;
        vec3 reflcol = background(ro, rdr, l_dir, talpha);
        vec3 rd2 = refract(rd, nr, 1.0 / IOR);
        float accum = 1.0;
        vec3 no2 = ni;
        vec3 ro_refr = ro;
        vec4 colo0 = vec4(0.0);
        vec4 colo1 = vec4(0.0);

        for (int j = 0; j < 2; j++) {
            float tb;
            vec2 coords2 = ro_refr.xy * no2.z + ro_refr.yz * no2.x + ro_refr.zx * no2.y;
            vec3 eye2 = vec3(coords2, -1.0);
            vec3 rd2trans = rd2.yzx * no2.x + rd2.zxy * no2.y + rd2.xyz * no2.z;
            rd2trans.z = -rd2trans.z;
            vec4 internalcol = insides(eye2, rd2trans, no2, l_dir, tb);
            if (tb > 0.0) {
                internalcol.rgb *= accum;
                if (j == 0) colo0 = internalcol;
                if (j == 1) colo1 = internalcol;
            }
            if ((tb <= 0.0) || (internalcol.a < 1.0)) {
                float tout = box(ro_refr, rd2, BOXDIMS, no2, false);
                no2 = n.zyx * no2.x + n.xzy * no2.y + n.yxz * no2.z;
                vec3 rout = ro_refr + tout * rd2;
                vec3 rdout = refract(rd2, -no2, IOR);
                float fresnel2 = R0 + (1.0 - R0) * pow(1.0 - dot(rdout, no2), 1.3);
                rd2 = reflect(rd2, -no2);
                ro_refr = rout;
                ro_refr.z = max(ro_refr.z, -0.999);
                accum *= fresnel2;
            }
        }
        float fresnel = R0 + (1.0 - R0) * pow(1.0 - dot(-rd, nr), 5.0);
        col = mix(mix(colo1.rgb * colo1.a, colo0.rgb, colo0.a) * fadeborders, reflcol, pow(fresnel, 1.5));
        col = clamp(col, 0.0, 1.0);
        float cineshader_alpha = clamp(0.15 * dot(eye, ro), 0.0, 1.0);
        vec4 tcolx = vec4(col, cineshader_alpha);
        tot = tcolx;
    } else {
        vec4 tcolx = vec4(0.0);
        float alpha;
        tcolx = vec4(background(eye, rd, l_dir, alpha), 0.15);
        tcolx.w = alpha;
        tot = tcolx;
    }

    fragColor = tot;
    fragColor.w = 1.0;
    fragColor.rgb = clamp(fragColor.rgb, 0.0, 1.0);
}