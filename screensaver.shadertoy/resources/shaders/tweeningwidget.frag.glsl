#define FAR 30.
#define REFLECTIVITY 1.0  // Controls reflectivity of metallic elements (default: 1.0)

// BCS Post-Processing Parameters
#define BRIGHTNESS 1.020    // Adjust brightness
#define CONTRAST 1.010      // Adjust contrast
#define SATURATION 1.0    // Adjust saturation iTime

vec4 vObjID;
int objID = -1; // Default initialization

// Standard 2D rotation formula.
mat2 rot2(in float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Tri-Planar blending function.
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n) {    
    n = max(n * n - 0.2, 0.001);
    n /= dot(n, vec3(1.0));
    vec3 tx = texture2D(tex, p.yz).xyz;
    vec3 ty = texture2D(tex, p.zx).xyz;
    vec3 tz = texture2D(tex, p.xy).xyz;
    return mat3(tx * tx, ty * ty, tz * tz) * n;
}

// IQ's unsigned box formula.
float sBox(in vec3 p, in vec3 b, in float sf) {
    return length(max(abs(p) - b + sf, 0.0)) - sf;
}

// IQ's unsigned rectangle formula.
float sBox(in vec2 p, in vec2 b, in float sf) {
    return length(max(abs(p) - b + sf, 0.0)) - sf;
}

const float PI = 3.14159265358979;

// Easing functions.
float easeInOutCubic(float t) { return t < 0.5 ? 4.0 * t * t * t : (t - 1.0) * (2.0 * t - 2.0) * (2.0 * t - 2.0) + 1.0; }
float easeInOutQuint(float t) { return t < 0.5 ? 16.0 * t * t * t * t * t : 1.0 + 16.0 * (--t) * t * t * t * t; }
float easeOutQuad(float t) { return -1.0 * t * (t - 2.0); }
float easeInQuad(float t) { return t * t; }
float bounceOut(float t) { const float a = 4.0 / 11.0, b = 8.0 / 11.0, c = 9.0 / 10.0, ca = 4356.0 / 361.0, cb = 35442.0 / 1805.0, cc = 16061.0 / 1805.0; float t2 = t * t; return t < a ? 7.5625 * t2 : t < b ? 9.075 * t2 - 9.9 * t + 3.4 : t < c ? ca * t2 - cb * t + cc : 10.8 * t * t - 20.52 * t + 10.72; }
float bounceInOut(float t) { return t < 0.5 ? 0.5 * (1.0 - bounceOut(1.0 - t * 2.0)) : 0.5 * bounceOut(t * 2.0 - 1.0) + 0.5; }
float bounceIn(float t) { return 1.0 - bounceOut(1.0 - t); }
float elasticOut(float t) { return sin(-13.0 * (t + 1.0) * PI / 2.0) * pow(2.0, -10.0 * t) + 1.0; }
float circularInOut(float t) { return t < 0.5 ? 0.5 * (1.0 - sqrt(1.0 - 4.0 * t * t)) : 0.5 * (sqrt((3.0 - 2.0 * t) * (2.0 * t - 1.0)) + 1.0); }
float exponentialOut(float t) { return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t); }
float exponentialIn(float t) { return t == 0.0 ? t : pow(2.0, 10.0 * (t - 1.0)); }
float exponentialInOut(float t) { return t == 0.0 || t == 1.0 ? t : t < 0.5 ? 0.5 * pow(2.0, (20.0 * t) - 10.0) : -0.5 * pow(2.0, 10.0 - (t * 20.0)) + 1.0; }

// Time variables.
float tm, t, t2;

// Animation segment ID.
int segID = 0;

// The motion tween block with manual modulo.
void doTweenTime() {
    float time = iTime*.75 + 10.0;
    tm = time - floor(time / 10.25) * 10.25; // Manual modulo for GLSL ES 1.00
    if (float(tm) < 1.0) {
        t = tm;
        t = bounceOut(t);
        t = mix(0.0, PI / 2.0, t);
        segID = 0;
    } else if (float(tm) < 2.0) {
        t = tm - 1.0;
        t2 = exponentialInOut(t);
        t = easeInOutCubic(t);
        segID = 1;
    } else if (float(tm) < 3.0) {
        t = tm - 2.0;
        t2 = t;
        t = exponentialOut(t);
        segID = 2;
    } else if (float(tm) < 4.0) {
        t = tm - 3.0;
        t2 = t;
        t = bounceOut(t);
        t = mix(0.0, PI / 2.0, t);
        segID = 3;
    } else if (float(tm) < 5.0) {
        t = tm - 4.0;
        t2 = easeInQuad(t);
        t = easeInOutCubic(t);
        t = mix(PI / 2.0, 0.0, t);
        segID = 4;
    } else if (float(tm) < 6.0) {
        t = tm - 5.0;
        t2 = t;
        t = easeInOutCubic(t);
        t = mix(0.0, PI, t);
        segID = 5;
    } else if (float(tm) < 7.0) {
        t = tm - 6.0;
        t = bounceOut(t);
        t = mix(0.0, -PI / 2.0, t);
        segID = 6;
    } else if (float(tm) < 8.0) {
        t = tm - 7.0;
        t = easeInOutCubic(t);
        t2 = t;
        segID = 7;
    } else if (float(tm) < 9.0) {
        t = tm - 8.0;
        t2 = t;
        t = easeInOutCubic(t);
        t = mix(PI / 2.0, 0.0, t);
        segID = 8;
    } else if (float(tm) < 10.0) {
        t = tm - 9.0;
        t2 = easeOutQuad(t);
        segID = 9;
    } else if (float(tm) < 10.25) {
        segID = 10;
    }
}

void move(in vec3 p, inout vec3 q, inout vec3 q2, inout vec3 svDim, in vec3 bDim2) {
    vec3 bDim = svDim;
    if(segID == 0) {
        q.y -= bDim.y;
        q.xy = rot2(-t) * (q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
        q2 = q;
        q2.y -= -bDim2.y;
        q2.xy = rot2(-t) * (q2.xy - vec2(-bDim2.x, bDim2.y)) - vec2(-bDim2.x, -bDim2.y);
    }
    else if(segID == 1) {
        q.x -= mix(0.0, -bDim.x * 3.0, t);
        q.y -= bDim.y;
        svDim.y = mix(bDim.y, bDim.y / 2.0, t);
        q.xy = rot2(-PI / 2.0) * (q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
        q2 = q;
        q2.x -= -bDim.x * 2.0;
        q2.y -= mix(bDim.x, 0.0, t);
        q2.yz = rot2(t2 * PI * 2.0) * q2.yz;
    }      
    else if(segID == 2) {
        svDim.y = mix(bDim.y / 2.0, bDim.y, t);
        q.y -= svDim.y;
        q.xy = rot2(0.0) * (q.xy - vec2(bDim.x, -svDim.y)) - vec2(-bDim.x, svDim.y);
        q2 = p;
        q2.y -= svDim.y * 2.0 + bDim2.y;
        if(t2 < 0.35) q2.y -= t2 / 0.35 * bDim.y * 0.7;
        else q2.y -= (bDim.y - bounceOut((t2 - 0.35) / 0.65) * bDim.y) * 0.7;
        q2.yz = rot2(-t2 * PI) * q2.yz;
    }    
    else if(segID == 3) {
        q.y -= svDim.y;
        q.xy = rot2(-t) * (q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
        q2 = q;
        q2.y -= bDim.y + bDim2.y;
        q2.xy = rot2(t * 2.0) * (q2.xy - vec2(-bDim2.x, -bDim2.y)) - vec2(bDim2.x, bDim2.y);
    }
    else if(segID == 4) {
        q.y -= bDim.y;
        q.xy = rot2(-t) * (q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
        q2 = q;
        q2.x -= -bDim2.x * 2.0;
        q2.y -= mix(bDim2.y, -bDim2.y, t2);
    }
    else if(segID == 5) {
        q.y -= bDim.y;
        q.xz = rot2(t) * (q.xz - vec2(bDim.x, bDim.z)) - vec2(-bDim.x, -bDim.z);
        q2 = q;
        q2.y -= -bDim2.y;
        q2.x -= -bDim2.x * 2.0;
        q2.xz = rot2(-t) * (q2.xz - vec2(bDim.x, bDim.z)) - vec2(-bDim.x, -bDim.z);
    }
    else if(segID == 6) {
        q.y -= bDim.y;
        q.x -= bDim.x * 2.0;
        q.z -= bDim.z * 2.0;
        q.xy = rot2(-t) * (q.xy - vec2(-bDim.x, -bDim.y)) - vec2(bDim.x, bDim.y);
        q2 = p;
        q2.y -= bDim2.y;
        q2.x -= bDim2.x * 2.0;
    }
    else if(segID == 7) {
        q.y -= bDim.y;
        q.x -= mix(bDim.x * 2.0, bDim.x * 4.0, t);
        q.z -= bDim.z * 2.0;
        q.xy = rot2(PI / 2.0) * (q.xy - vec2(-bDim.x, -bDim.y)) - vec2(bDim.x, bDim.y);
        q2 = q;
        q2.y -= -bDim2.y * 3.0;
        q2.z -= -bDim2.z * 2.0;
        q2.yz = rot2(-t2 * PI / 2.0) * (q2.yz - vec2(bDim.x, bDim.z)) - vec2(-bDim.x, -bDim.z);
    }
    else if(segID == 8) {
        q.y -= bDim.y;
        q.x -= -bDim.x * 2.0;
        q.z -= bDim.z * 2.0;
        q.xz = rot2(t2 * PI) * (q.xz - vec2(bDim.x, -bDim.z)) - vec2(-bDim.x, bDim.z);
        q.xy = rot2(-t) * (q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
        q2 = q;
        q2.xy = rot2(t2 * PI) * (q2.xy - vec2(-bDim.x, bDim.y)) - vec2(bDim.x, -bDim.y);
        q2.y -= bDim2.y * 3.0;
    }  
    else if(segID == 9) {
        q.y -= bDim.y;
        q.xz = rot2(t * PI / 2.0) * q.xz;
        q2 = q;
        q2.x -= bDim.x * 2.0;
        q2.y -= mix(bDim2.y, -bDim2.y, t2);
        q2.xz = rot2(t * PI) * (q2.xz - vec2(-bDim.x, bDim.z)) - vec2(bDim.x, -bDim.z);
    }
    else {
        q.y -= bDim.y;
        q2 = q;
        q2.y -= -bDim2.y;
        q2.x -= -bDim.x * 2.0;
    }
}

float map(vec3 p) {
    float fl = p.y;
    vec3 bDim = vec3(0.25, 0.5, 0.25);
    const vec3 bDim2 = vec3(0.25, 0.25, 0.25);
    vec3 q = p, q2 = p;
    move(p, q, q2, bDim, bDim2);
    float obj = sBox(q, bDim, 0.04);
    float obj2 = sBox(q2, bDim2, 0.04);
    obj = max(obj, -sBox(q.xy, bDim.xy * vec2(0.25, 0.667), 0.04));
    obj = max(obj, -sBox(q.xz, bDim.xz * vec2(0.25, 0.25), 0.04));
    obj = max(obj, -sBox(q.yz, bDim.yz * vec2(0.667, 0.25), 0.04));
    obj = min(obj, sBox(q2, bDim2 * vec3(0.25, 0.25, 1.2), 0.04));
    obj = min(obj, sBox(q2, bDim2 * vec3(0.25, 1.2, 0.25), 0.04));
    obj = min(obj, sBox(q2, bDim2 * vec3(1.2, 0.25, 0.25), 0.04));
    obj = min(obj, sBox(q, bDim * vec3(0.833), 0.04));
    vObjID = vec4(fl, obj, obj2, 0.0);
    return min(min(fl, obj), obj2);
}

float trace(vec3 ro, vec3 rd) {
    float t = 0.0, d;
    for (int i = 0; i < 80; i++) {
        d = map(ro + rd * t);
        if(abs(d) < 0.001 || t > FAR) break;
        t += d;
    }
    return t;
}

float traceRef(vec3 ro, vec3 rd) {
    float t = 0.0, d;
    for (int i = 0; i < 48; i++) {
        d = map(ro + rd * t);
        if(abs(d) < 0.002 || t > FAR) break;
        t += d;
    }
    return t;
}

float softShadow(vec3 ro, vec3 lp, float k) {
    const int maxIterationsShad = 24;
    vec3 rd = lp - ro;
    float shade = 1.0;
    float dist = 0.002;
    float end = max(length(rd), 0.001);
    rd /= end;
    for (int i = 0; i < maxIterationsShad; i++) {
        float h = map(ro + rd * dist);
        shade = min(shade, smoothstep(0.0, 1.0, k * h / dist));
        dist += clamp(h, 0.01, 0.25);
        if (h < 0.0 || dist > end) break;
    }
    return max(shade, 0.0);
}

float calcAO(in vec3 p, in vec3 n) {
    float sca = 1.5, occ = 0.0;
    for (int i = 0; i < 5; i++) {
        float hr = float(i + 1) * 0.25 / 5.0;
        float d = map(p + n * hr);
        occ += (hr - d) * sca;
        sca *= 0.7;
        if(occ > 1e5) break;
    }
    return clamp(1.0 - occ, 0.0, 1.0);
}

vec3 getNormal(in vec3 p) {
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = e.zzz;
    for(float i = 0.0; i < 6.0; i += 1.0) {
        mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if(mod(i, 2.0) == 1.0) { mp = mp.yzx; e = e.zxy; }
    }
    return normalize(mp);
}

vec3 getObjectColor(vec3 p, vec3 r, vec3 n) {
    vec3 col;
    if(objID == 0) {
        vec3 tx = texture2D(iChannel0, p.xz / 4.0).xyz; tx *= tx;
        col = tx * vec3(1.0, 0.7, 0.5) * 0.5;
    }
    else if(objID == 1) {
        col = vec3(0.65, 0.85, 1.0);
    }
    else {
        col = vec3(2.0, 0.9, 0.45);
    }
    vec3 cTx = tex3D(iChannel0, reflect(r, n) / 1.5, n);
    cTx *= vec3(1.0, 0.8, 0.6);
    if(objID > 0) col *= cTx * 2.0 * REFLECTIVITY; // Reduced reflectivity for metallic objects
    else col += cTx * 0.1;
    return col;
}

vec3 doColor(in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, float t) {
    vec3 sceneCol = vec3(0.0);
    if(t < FAR) {
        vec3 ld = lp - sp;
        float lDist = max(length(ld), 0.0001);
        ld /= lDist;
        float ao = calcAO(sp, sn);
        float atten = 1.0 / (1.0 + lDist * 0.2 + lDist * lDist * 0.05);
        float diff = max(dot(sn, ld), 0.0);
        float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.0), 8.0);
        diff = pow(diff, 4.0) * 2.0;
        vec3 objCol = getObjectColor(sp, rd, sn);
        sceneCol = objCol * ((diff + ao * 0.2) + vec3(1.0, 0.97, 0.92) * spec * 4.0);
        sceneCol *= atten * ao;
    }
    float fogF = smoothstep(0.0, 0.9, t / FAR);
    sceneCol = mix(sceneCol, vec3(0.0), fogF);
    return sceneCol;
}

vec3 getRd(vec2 u, vec3 ro) {
    vec3 lk = vec3(0.0, 0.5, 0.0);
    float FOV = PI / 3.0;
    vec3 fw = normalize(lk - ro);
    vec3 rt = normalize(vec3(fw.z, 0.0, -fw.x));
    vec3 up = cross(fw, rt);
    vec3 rd = normalize(fw + (u.x * rt + u.y * up) * FOV);
    return rd;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
    float r = dot(uv, uv);
    uv *= 1.0 + 0.2 * (r * r + r);
    float cTm = iTime / 36.0;
    vec3 ro = vec3(sin(cTm) * 2.65, cos(tm) * sin(cTm) * 0.25 + 2.25, cos(cTm) * 2.65);
    vec3 rd = getRd(uv, ro);
    vec3 lp = vec3(1.0, 3.0, -1.0);
    doTweenTime();
    float t = trace(ro, rd);
    objID = vObjID.x < vObjID.y && vObjID.x < vObjID.z ? 0 : vObjID.y < vObjID.z ? 1 : 2;
    ro += rd * t;
    vec3 sn = getNormal(ro);
    vec3 sceneColor = doColor(ro, rd, sn, lp, t);
    float sh = softShadow(ro + sn * 0.0015, lp, 12.0);
    sh = min(sh + 0.3, 1.0);
    rd = reflect(rd, sn);
    t = traceRef(ro + sn * 0.003, rd);
    objID = vObjID.x < vObjID.y && vObjID.x < vObjID.z ? 0 : vObjID.y < vObjID.z ? 1 : 2;
    ro += rd * t;
    sn = getNormal(ro);
    vec3 rCol = doColor(ro, rd, sn, lp, t);
    sceneColor = sceneColor + rCol * 0.75;
    sceneColor *= sh;
    vec3 finalColor = sceneColor;
    finalColor = finalColor * BRIGHTNESS;
    finalColor = (finalColor - 0.5) * CONTRAST + 0.5;
    vec3 luminance = vec3(0.299, 0.587, 0.114);
    float luma = dot(finalColor, luminance);
    finalColor = mix(vec3(luma), finalColor, SATURATION);
    fragColor = vec4(sqrt(clamp(finalColor, 0.0, 1.0)), 1.0);
}