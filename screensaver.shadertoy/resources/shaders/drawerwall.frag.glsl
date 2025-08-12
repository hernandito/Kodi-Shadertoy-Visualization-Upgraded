#ifdef GL_ES
precision mediump float;
#endif

// === CONFIG ===
#define FAR 40.0
#define DELTA 0.001
#define PASSES 1
#define GSCALE vec2(1.0/7.50) * vec2(2.0, 1.0)
#define ARRANGEMENT 1
#define SHOW_TRIMMINGS

#define BRIGHTNESS .80
#define CONTRAST 1.0
#define SATURATION 1.0

float objID;
float blockPartID;
vec3 gID;

mat2 rot2(float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
float hash21(vec2 p){ return fract(sin(dot(p, vec2(27.609, 57.583))) * 43758.5453); }

vec3 tex3D(sampler2D t, vec3 p, vec3 n){
    n = max(abs(n) - 0.2, 0.001);
    n /= length(n);
    vec3 tx = texture2D(t, p.yz).xyz;
    vec3 ty = texture2D(t, p.zx).xyz;
    vec3 tz = texture2D(t, p.xy).xyz;
    return mat3(tx*tx, ty*ty, tz*tz) * n;
}

vec3 getTex(sampler2D tex, vec2 p){
    vec3 tx = texture2D(tex, fract(p/4.0 + 0.5)).xyz;
    return tx*tx;
}

float hm(vec2 p){ return dot(getTex(iChannel1, p), vec3(0.299, 0.587, 0.114)); }

float opExtrusion(float sdf, float pz, float h, float sf){
    vec2 w = vec2(sdf, abs(pz) - h) + sf;
    return min(max(w.x, w.y), 0.0) + length(max(w, 0.0)) - sf;
}

float sBoxS(vec2 p, vec2 b, float sf){
    p = abs(p) - b + sf;
    return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0) - sf;
}

vec4 blocks(vec3 q){
    const vec2 dim = GSCALE;
    const vec2 s = dim*2.0;
    float d = 1e5;
    vec2 p, ip, id = vec2(0.0), cntr = vec2(0.0);
    float height = 0.0;
    blockPartID = 0.0;

    vec2 ps4[4];
#if ARRANGEMENT == 0
    ps4[0] = vec2(-0.5, 0.5); ps4[1] = vec2(0.5, 0.5); ps4[2] = vec2(0.5, -0.5); ps4[3] = vec2(-0.5, -0.5);
#elif ARRANGEMENT == 1
    ps4[0] = vec2(-0.5, 0.5); ps4[1] = vec2(0.5, 0.5); ps4[2] = vec2(1.0, -0.5); ps4[3] = vec2(0.0, -0.5);
#else
    ps4[0] = vec2(-0.5, 0.5); ps4[1] = vec2(0.5, 0.5); ps4[2] = vec2(0.75, -0.5); ps4[3] = vec2(-0.25, -0.5);
#endif

    const float hs = 0.125;

    for(int i=0; i<4; i++){
        cntr = ps4[i] / 2.0;
#if ARRANGEMENT == 2
        cntr.x -= floor((q.y/s.y - cntr.y))/4.0;
#endif
        p = q.xy;
        ip = floor(p/s - cntr) + 0.5;
        vec2 idi = (ip + cntr) * s;
        p -= idi;

        float h1 = hm(idi);
        h1 = floor(h1*7.999)/7.0;
        h1 *= hs;

        float face1 = sBoxS(p, dim/2.0 - 0.02*dim.x, 0.02);
        float face1Ext = opExtrusion(face1, (-q.z - h1), h1, 0.005);

#ifdef SHOW_TRIMMINGS
        float face2Ext = opExtrusion(length(p) - 0.016, (-q.z - h1 - 0.008), h1 + 0.008, 0.005);
        vec2 tr = vec2(face1 + 0.0025, (-q.z - h1*2.0 - 0.005));
        face2Ext = min(face2Ext, length(tr) - 0.005);
        float blPtID = face1Ext < face2Ext ? 0.0 : 1.0;
        face1Ext = min(face1Ext, face2Ext);
#else
        float blPtID = 0.0;
#endif

        vec4 di = vec4(face1Ext, idi, h1);
        if(di.x < d){
            d = di.x;
            id = di.yz;
            height = di.w;
            blockPartID = blPtID;
        }
    }
    return vec4(d, id, height);
}

float map(vec3 p){
    p.z = abs(p.z - 0.25) - 0.75;
    float wall = -p.z + 0.01;
    vec4 d4 = blocks(p);
    gID = d4.yzw;
    objID = wall < d4.x ? 1.0 : 0.0;
    return min(wall, d4.x);
}

float trace(vec3 ro, vec3 rd){
    float t = 0.0, d;
    for(int i=0; i<80; i++){
        d = map(ro + rd*t);
        if(d*d < DELTA*DELTA || t > FAR) break;
        t += d*0.9;
    }
    return min(t, FAR);
}

float softShadow(vec3 ro, vec3 lp, vec3 n, float k){
    const int iter = 24;
    ro += n*0.0015;
    vec3 rd = lp - ro;
    float shade = 1.0;
    float t = 0.0;
    float end = max(length(rd), 0.0001);
    rd /= end;
    for(int i=0; i<iter; i++){
        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        t += clamp(d, 0.01, 0.25);
        if(d < 0.0 || t > end) break;
    }
    return max(shade, 0.0);
}

float calcAO(vec3 p, vec3 n){
    float sca = 2.0, occ = 0.0;
    for(int i=0; i<5; i++){
        float hr = float(i + 1)*0.15/5.0;
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0.0, 1.0);
}

vec3 getNormal(vec3 p){
    const vec2 e = vec2(0.001, 0.0);
    float mp0 = map(p + e.xyy);
    float mp1 = map(p - e.xyy);
    float mp2 = map(p + e.yxy);
    float mp3 = map(p - e.yxy);
    float mp4 = map(p + e.yyx);
    float mp5 = map(p - e.yyx);
    return normalize(vec3(mp0 - mp1, mp2 - mp3, mp4 - mp5));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (fragCoord - iResolution.xy*0.5) / iResolution.y;
    vec3 ro = vec3(iTime/24.0, 0.0, 0.0);
    vec3 lk = ro + vec3(0.02, 0.01, 0.1);
    vec3 lp = ro + vec3(-0.5, 1.0, 0.25);

    float FOV = 1.0;
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0.0, -fwd.x));
    vec3 up = cross(fwd, rgt);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);

    vec3 cam = ro, sp = ro;
    float gSh = 1.0, objRef = 0.0;
    vec3 col = vec3(0.0);

    for(int j=0; j<PASSES; j++){
        vec3 colL = vec3(0.0);
        float t = trace(sp, rd);
        float svObjID = objID;
        vec3 svGID = gID;
        float svBPID = blockPartID;
        sp += rd*t;

        if(t < FAR){
            vec3 sn = getNormal(sp);
            float sz0 = 2.0;
            vec3 ld = lp - sp;
            float lDist = length(ld);
            ld /= max(lDist, 0.0001);
            if(j == 0) gSh = softShadow(sp, lp, sn, 12.0);
            float ao = calcAO(sp, sn);
            float sh = min(gSh + ao*0.25, 1.0);
            float att = 1.0/(1.0 + lDist*lDist*0.025);
            float dif = max(dot(ld, sn), 0.0);
            dif = pow(dif, 4.0)*2.0;

            vec3 oCol;
            if(svObjID == 0.0){
                vec3 tx = tex3D(iChannel0, sp*sz0, sn);
                vec3 tx2 = getTex(iChannel1, svGID.xy);
                tx = smoothstep(0.0, 0.5, tx);
                tx2 = smoothstep(0.0, 0.5, tx2);
                if(svBPID == 1.0){
                    oCol = tx*vec3(1.0, 0.9, 0.7);
                } else {
                    oCol = tx2*tx*2.5;
                }
            } else {
                oCol = vec3(0.0);
            }

            colL = oCol*(dif + 0.125);
            colL *= sh*ao*att;
        }

        float td = length(sp - cam);
        vec3 fogCol = vec3(0.0);
        colL = mix(colL, fogCol, smoothstep(0.0, 0.95, td/FAR));
        col = mix(col, colL, 1.0/float(1 + j));
        if(objRef < 0.001 || t >= FAR) break;
    }

    // === BCS adjustments ===
    col = col * BRIGHTNESS;
    col = (col - 0.5) * CONTRAST + 0.5;
    float luminance = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luminance), col, SATURATION);

    // === VIGNETTE + DITHERING (GLSL ES 1.00 safe) ===
    vec2 vuv = fragCoord / iResolution.xy;
    vuv *= 1.0 - vuv.yx;
    float vignetteIntensity = 25.0;
    float vignettePower = 0.60;
    float vig = vuv.x * vuv.y * vignetteIntensity;
    vig = pow(vig, vignettePower);

    float ditherStrength = 0.05;
    float noise = fract(sin(dot(fragCoord ,vec2(12.9898,78.233))) * 43758.5453);
    vig = clamp(vig + (noise - 0.5) * ditherStrength, 0.0, 1.0);

    col *= vig;

    fragColor = vec4(sqrt(max(col, 0.0)), 1.0);
}
