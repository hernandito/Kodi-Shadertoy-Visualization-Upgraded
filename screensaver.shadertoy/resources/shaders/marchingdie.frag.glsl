#define PASSES 2
#define FAR 40.
#define DELTA .001
#define GSCALE vec2(1./1.5)
#define PI 3.14159

// BCS Post-Processing Parameters iTime
#define BRIGHTNESS .96    // Adjust brightness (1.0 = no change, >1.0 increases, <1.0 decreases)
#define CONTRAST 1.04      // Adjust contrast (1.0 = no change, >1.0 increases, <1.0 decreases)
#define SATURATION 1.20    // Adjust saturation (1.0 = no change, >1.0 increases, <1.0 decreases)

// Initialize all global variables
int objID = 0, svObjID = 0;
vec3 gID = vec3(0.), svGID = vec3(0.);
mat2 gMat = mat2(1., 0., 0., 1.), svMat = mat2(1., 0., 0., 1.), lRot = mat2(1., 0., 0., 1.);
vec3 gTxP = vec3(0.), svTxP = vec3(0.), gPiv = vec3(0.), svPiv = vec3(0.), gOff = vec3(0.);
vec3 lPivot = vec3(0.), lTotDist = vec3(0.), dirI = vec3(0.);
float lStartXY = 0., lStartYZ = 0., gBounce = 0.;

// Utility functions
mat2 rot2(in float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
float hash21(vec2 p) { return fract(sin(dot(p, vec2(27.609, 57.583))) * 43758.5453); }
float smax(float a, float b, float k) {
    float f = max(0., 1. - abs(b - a) / k);
    return max(a, b) + k * .25 * f * f;
}

// Updated tex3D for Kodi (GLSL ES 1.00)
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n) {
    n = max(n * n - .2, .001);
    n /= dot(n, vec3(1));
    vec3 tx = texture2D(tex, p.yz).xyz;
    vec3 ty = texture2D(tex, p.zx).xyz;
    vec3 tz = texture2D(tex, p.xy).xyz;
    return mat3(tx * tx, ty * ty, tz * tz) * n;
}
float sBox(in vec3 p, in vec3 b, in float sf) {
    p = abs(p) - b + sf;
    return length(max(p, 0.)) + min(max(max(p.x, p.y), p.z), 0.) - sf;
}
float exponentialOut(float t) { return t == 1. ? t : 1. - pow(2., -8. * t); }

// Move cube function
void moveCube(float gTime) {
    const int ttm = 15;
    float tm = gTime * float(ttm) / GSCALE.x;
    float modtm = mod(tm, float(ttm));
    gOff = ((vec3(5., 4., -4.) - 0.5) + floor(tm / float(ttm)) * vec3(0., 1., 1.)) * GSCALE.x;
    lStartYZ = mod(floor(tm / float(ttm)), 2.);
    vec3 dir[15];
    dir[0] = vec3(0., 1., 1.); dir[1] = vec3(1., 1., 0.); dir[2] = vec3(0., 1., 1.);
    dir[3] = vec3(-1., -1., 0.); dir[4] = vec3(0., 1., 1.); dir[5] = vec3(-1., -1., 0.);
    dir[6] = vec3(0., 1., 1.); dir[7] = vec3(-1., -1., 0.); dir[8] = vec3(-1., -1., 0.);
    dir[9] = vec3(0., -1., -1.); dir[10] = vec3(1., 1., 0.); dir[11] = vec3(0., -1., -1.);
    dir[12] = vec3(1., 1., 0.); dir[13] = vec3(0., -1., -1.); dir[14] = vec3(1., 1., 0.);
    for(int i = 0; i < 15; i++) {
        int next_i = (i + 1 < 15) ? i + 1 : 0;
        if(hash21(vec2(floor(tm / float(ttm)), float(i)) / 15.) < 0.333) {
            vec3 temp = dir[i];
            dir[i] = dir[next_i];
            dir[next_i] = temp;
        }
    }
    lTotDist = vec3(0.);
    for(int i = 0; i < ttm; i++) {
        float fi = float(i);
        dirI = dir[i];
        if(modtm < fi + 1.) {
            float t = (modtm - fi) / 1.;
            t = exponentialOut(t);
            t = mix(0., PI, t);
            if(dirI.z < -0.5 || dirI.x > 0.5) t *= -1.;
            lRot = rot2(t);
            lPivot = dirI * GSCALE.x / 2.;
            gPiv = lPivot;
            gMat = lRot;
            break;
        }
        lTotDist += dirI;
    }
}

// Blocks function
vec4 blocks(vec3 q) {
    const vec2 dim = GSCALE;
    const vec2 s = dim * 2.;
    float d = 1e5;
    vec2 p, ip, id = vec2(0.), cntr;
    vec2 ps4[4];
    ps4[0] = vec2(-0.5, 0.5);
    ps4[1] = vec2(0.5, 0.5);
    ps4[2] = vec2(0.5, -0.5);
    ps4[3] = vec2(-0.5, -0.5);
    float height = 0.;
    for(int i = 0; i < 4; i++) {
        cntr = ps4[i] / 2.;
        p = q.xz - cntr * s;
        ip = floor(p / s) + 0.5;
        p -= ip * s;
        vec2 idi = (ip + cntr) * s;
        float h1 = (ip.y - 0.5 - float(i / 2) / 2.) * GSCALE.y + 1.;
        h1 += (ip.x - 0.5) * GSCALE.x + 1.;
        if(i == 0 || i == 3) h1 -= GSCALE.x / 2.;
        float qy = mod(q.y - GSCALE.x / 2., GSCALE.x * 2.) - GSCALE.x;
        float face1Ext = sBox(vec3(p, qy), vec3(dim.x / 2.), 0.07);
        face1Ext = smax(face1Ext, length(vec3(p, qy)) - GSCALE.x / 2. * 1.55, 0.1);
        qy = mod(q.y + GSCALE.x / 2., GSCALE.x * 2.) - GSCALE.x;
        float face2Ext = sBox(vec3(p, qy), vec3(dim.x / 2.), 0.07);
        face2Ext = smax(face2Ext, length(vec3(p, qy)) - GSCALE.x / 2. * 1.55, 0.1);
        face1Ext = min(face1Ext, face2Ext);
        face1Ext = max(face1Ext, (q.y - h1 * 2. + 0.01));
        vec4 di = vec4(face1Ext, idi, h1);
        if(di.x < d) { d = di.x; id = di.yz; height = di.w; }
    }
    return vec4(d, id, height);
}

// Map function
float map(vec3 p) {
    vec3 q = p;
    q.yz *= rot2(3.14159 / 4.);
    q.xy *= rot2(-3.14159 / 5.);
    float wall = q.y - 0.7071 + 0.1;
    vec4 d4 = blocks(p);
    gID = d4.yzw;
    q = p - gOff - lTotDist * GSCALE.x;
    q.y -= gBounce;
    q -= lPivot;
    if(abs(dirI.x) > 0.5) q.xy = lRot * q.xy;
    else q.yz = lRot * q.yz;
    q += lPivot;
    q.xy = rot2(mod(lTotDist.x, 2.) * PI) * q.xy;
    q.yz = rot2((mod(lStartYZ + lTotDist.z, 2.)) * PI) * q.yz;
    gTxP = q;
    float bx = sBox(q, vec3(GSCALE.x / 2.), 0.07);
    bx = smax(bx, length(q) - GSCALE.x / 2. * 1.55, 0.1);
    objID = (wall < d4.x && wall < bx) ? 2 : (d4.x < bx) ? 0 : 1;
    return min(wall, min(d4.x, bx));
}

// Trace function
float trace(vec3 ro, vec3 rd) {
    float t = 0., d;
    for(int i = 0; i < 72; i++) {
        d = map(ro + rd * t);
        if(d * d < DELTA * DELTA || t > FAR) break;
        t += i < 32 ? d * 0.5 : d * 0.9;
    }
    return min(t, FAR);
}

// Simplified normal and bump functions
vec3 getNormal(in vec3 p) {
    const vec2 e = vec2(0.001, 0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}
float getDots(vec3 p, vec3 n) {
    vec3 aN = abs(n);
    vec3 idF = vec3(n.x < -0.25 ? 0. : 5., n.y < -0.25 ? 1. : 4., n.z < -0.25 ? 2. : 3.);
    float face = aN.x > 0.5 ? idF.x : aN.y > 0.5 ? idF.y : idF.z;
    vec2 tuv = p.xy;
    float dots = 1e5;
    const float dSz = 0.0;
    const float dsp = 0.12;
    if(face == 0.) dots = length(tuv);
    else if(face == 1.) dots = min(length(tuv - dsp), length(tuv + dsp));
    else if(face == 2.) dots = min(length(tuv), min(length(tuv - dsp), length(tuv + dsp)));
    else if(face == 3.) {
        tuv = abs(tuv) - dsp;
        dots = length(tuv);
    }
    else if(face == 4.) dots = min(length(tuv), length(abs(tuv) - dsp));
    else if(face == 5.) {
        tuv.y = abs(tuv.y) - dsp;
        dots = min(length(tuv), length(vec2(abs(tuv.x) - (dsp + 0.02), tuv.y)));
    }
    return smoothstep(0., 0.06, dots - dSz);
}
float bumpSurf3D(in vec3 txP, in vec3 n) {
    vec3 txN = n;
    vec3 tuv = vec3(0.);
    if(svObjID == 0) {
        float rndXY = hash21(svGID.yz);
        float rndYZ = hash21(svGID.yz + 0.37);
        float rndZX = hash21(svGID.yz + 0.71);
        vec3 rSn = txN;
        rSn.xy *= rot2(floor(rndXY * 36.) * PI / 2.);
        rSn.yz *= rot2(floor(rndYZ * 36.) * PI / 2.);
        rSn.xz *= rot2(floor(rndZX * 36.) * PI / 2.);
        vec3 aN = abs(txN);
        tuv = aN.x > 0.5 ? txP.yzx * vec3(1., 1., -1.) : aN.y > 0.5 ? txP.zxy * vec3(1., 1., -1.) : txP.xyz * vec3(1., 1., -1.);
        tuv = mod(tuv, GSCALE.x) - GSCALE.x / 2.;
        txN = rSn;
    }
    if(svObjID == 1) {
        if(abs(svPiv.x) > 0.01) txN.xy = svMat * txN.xy;
        else txN.yz = svMat * txN.yz;
        txN.xy = rot2(mod(lTotDist.x, 2.) * PI) * txN.xy;
        txN.yz = rot2((mod(lStartYZ + lTotDist.z, 2.)) * PI) * txN.yz;
        vec3 aN = abs(txN);
        tuv = aN.x > 0.5 ? txP.yzx : aN.y > 0.5 ? txP.zxy : txP.xyz;
    }
    float d = 1.;
    if(svObjID < 2) d = getDots(tuv, txN);
    return d;
}
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor, inout float ref) {
    const vec2 e = vec2(0.001, 0);
    vec3 v0 = e.xyy, v1 = e.yxy, v2 = e.yyx;
    if(svObjID == 1) {
        p = svTxP;
        if(abs(svPiv.x) > 0.01) {
            v0.xy = svMat * v0.xy; v1.xy = svMat * v1.xy; v2.xy = svMat * v2.xy;
        } else {
            v0.yz = svMat * v0.yz; v1.yz = svMat * v1.yz; v2.yz = svMat * v2.yz;
        }
        v0.xy = rot2(mod(lTotDist.x, 2.) * PI) * v0.xy;
        v0.yz = rot2((mod(lStartYZ + lTotDist.z, 2.)) * PI) * v0.yz;
        v1.xy = rot2(mod(lTotDist.x, 2.) * PI) * v1.xy;
        v1.yz = rot2((mod(lStartYZ + lTotDist.z, 2.)) * PI) * v1.yz;
        v2.xy = rot2(mod(lTotDist.x, 2.) * PI) * v2.xy;
        v2.yz = rot2((mod(lStartYZ + lTotDist.z, 2.)) * PI) * v2.yz;
    }
    ref = bumpSurf3D(p, nor); // Ensure ref is set
    vec3 grad = (vec3(bumpSurf3D(p - v0, nor), bumpSurf3D(p - v1, nor), bumpSurf3D(p - v2, nor)) - ref) / e.x;
    grad -= nor * dot(nor, grad);
    return normalize(nor + grad * bumpfactor);
}

// Main rendering with BCS post-processing
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
    float tm = iTime / 24.;
    vec3 ro = vec3(0., 5. + tm, -5. + tm);
    vec3 lk = ro + vec3(0.18, -0.15, 0.2);
    vec3 lp = ro + vec3(2.5, 1., 2.25);
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x));
    vec3 up = cross(fwd, rgt);
    vec3 rd = normalize(uv.x * rgt + uv.y * up + fwd);
    vec3 cam = ro, sp = ro;
    float gSh = 1., objRef = 1.;
    vec3 col = vec3(0.);
    float alpha = 1.;
    moveCube(tm);
    for(int j = 0; j < PASSES; j++) {
        vec3 colL = vec3(0.);
        float t = trace(sp, rd);
        svObjID = objID;
        svGID = gID;
        svTxP = gTxP;
        svPiv = gPiv;
        svMat = gMat;
        sp += rd * t;
        if(t < FAR) {
            vec3 sn = getNormal(sp);
            float bumpShade = 0.0; // Initialize bumpShade to avoid uninitialized warning
            sn = doBumpMap(sp, sn, 0.1, bumpShade);
            vec3 ld = lp - sp;
            float lDist = length(ld);
            ld /= max(lDist, 0.0001);
            float dif = max(dot(ld, sn), 0.);
            float spe = pow(max(dot(reflect(rd, sn), ld), 0.), 8.);
            float fre = clamp(1. + dot(rd, sn), 0., 1.);
            dif = pow(dif, 4.) * 2.;
            vec3 oCol;
            if(svObjID == 0) {
                vec3 tx = tex3D(iChannel0, sp * 0.5, sn);
                tx = smoothstep(-0.05, 0.5, tx);
                oCol = tx * vec3(0.9, 1., 1.2);
                objRef = mix(0.125, 0.25, smoothstep(0., 0.1, bumpShade));
            } else if(svObjID == 1) {
                vec3 tx = tex3D(iChannel0, svTxP * 0.5, sn);
                tx = smoothstep(-0.05, 0.55, tx);
                oCol = tx * vec3(1., 0.42, 0.28) * 2.6;
                objRef = mix(0.125, 0.25, smoothstep(0., 0.1, bumpShade));
            } else {
                oCol = vec3(0.);
                objRef = 0.;
            }
            colL = oCol * (dif + vec3(1., 0.7, 0.5) * spe * 16. + 0.1);
            colL *= bumpShade;
            col += min(colL, 1.) * alpha;
            rd = reflect(rd, sn);
            sp += sn * DELTA * 1.1;
        }
        if(objRef < 0.001 || t >= FAR) break;
        alpha *= objRef;
    }

    // Apply BCS post-processing
    vec3 finalColor = col;
    finalColor = finalColor * BRIGHTNESS; // Apply brightness
    finalColor = (finalColor - 0.5) * CONTRAST + 0.5; // Apply contrast
    vec3 luminance = vec3(0.299, 0.587, 0.114); // Standard luminance weights
    float luma = dot(finalColor, luminance);
    finalColor = mix(vec3(luma), finalColor, SATURATION); // Apply saturation

    fragColor = vec4(sqrt(max(finalColor, 0.)), 1.);
}