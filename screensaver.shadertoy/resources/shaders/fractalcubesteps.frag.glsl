#define ZERO 0
#define FAR 40.
#define DELTA .001
#define PASSES 2
#define GSCALE vec2(1., .8660254)/4.
#define BRIGHTNESS 3.4  // Adjust brightness (1.0 = no change, >1.0 brighter, <1.0 darker)
#define CONTRAST 1.02    // Adjust contrast (1.0 = no change)
#define SATURATION 1.0  // Adjust saturation (1.0 = no change)
#define ANIMATION_SPEED .2  // Adjust animation speed (1.0 = normal speed)

float objID;
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
float hash21(vec2 p){ return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }
vec3 getTex(sampler2D tex, vec2 p){
    vec3 tx = texture2D(tex, p).xyz;
    return tx*tx;
}
float sBoxS(in vec3 p, in vec3 b, in float sf){
    p = abs(p) - b + sf;
    return length(max(p, 0.)) + min(max(max(p.x, p.y), p.z), 0.) - sf;
}
float blockPartID;
vec3 gCoord;
vec4 gID;

float map(vec3 p){
    p.z = abs(p.z + 1.) - 1.;
    float wall = -p.z + .16;
    vec2 s = GSCALE*vec2(1, 2);
    float bx = 1e5, sf = .001, gap = .003;
    float sc0 = s.x*sqrt(2.)/2.;
    for(int i = 0; i < 2; i++){
        vec3 q = p;
        vec2 cntr = i == 0 ? vec2(.5) : vec2(0);
        vec2 ip = floor(q.xy/s - cntr) + cntr + .5;
        q.xy -= (ip)*s;
        q.yz *= rot2(.61547518786);
        q.xz *= rot2(3.14159/4.);
        float bxi = sBoxS(q, vec3(sc0/2. - gap), sf);
        if(bxi < bx){
            bx = bxi;
            gID.yz = (ip);
            blockPartID = 0.;
            gCoord = q;
        }
    }
    vec2 s2 = GSCALE*2.;
    float offsD = 0., dir = 1.;
    for(int i = 0; i < 2; i++){
        sc0 /= 2.;
        s2 /= 2.;
        offsD += s.x/8./pow(2., float(i));
        vec3 q = p - vec3(0, 1, -1)*offsD;
        vec2 cntr = vec2(0);
        if(dir*mod(floor(q.y/s2.y), 2.) < dir*.5) cntr.x -= .5;
        vec2 ip2 = floor(q.xy/s2 - cntr) + cntr + .5;
        q.xy -= (ip2)*s2;
        if(hash21(ip2 + .03) < .2) break;
        q.yz *= rot2(.61547518786);
        q.xz *= rot2(3.14159/4.);
        float bxi = sBoxS(q, vec3(sc0/2. - gap), sf);
        sf *= .7;
        dir = -1.;
        if(bxi < bx){
            bx = bxi;
            gID.yz = (ip2);
            blockPartID = float(i + 1);
            gCoord = q;
        }
    }
    gID.x = bx;
    objID = bx < wall ? 0. : 1.;
    return min(bx, wall);
}

float trace(vec3 ro, vec3 rd){
    float t = 0., d;
    for(int i = 0; i < 80; i++){
        d = map(ro + rd*t);
        if(abs(d) < DELTA || t > FAR) break;
        t += d*.9;
    }
    return min(t, FAR);
}

float softShadow(vec3 ro, vec3 lp, vec3 n, float k){
    const int iter = 32;
    vec3 rd = lp - ro;
    ro += n*.0015;
    float shade = 1.;
    float t = 0.;
    float end = max(length(rd), 0.0001);
    rd /= end;
    for(int i = 0; i < iter; i++){
        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        t += clamp(d, .01, .1);
        if(d < 0. || t > end) break;
    }
    return max(shade, 0.);
}

float calcAO(in vec3 p, in vec3 n){
    float sca = 2.5, occ = 0.;
    for(int i = 0; i < 5; i++){
        float hr = float(i + 1)*.15/5.;
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .8;
        if(sca > 1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

vec3 getNormal(in vec3 p){
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = vec3(0.);
    for(float i = 0.0; i < 6.0; i += 1.0){
        mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if(mod(i, 2.0) == 1.0){ mp = mp.yzx; e = e.zxy; }
    }
    return normalize(mp);
}

float fPat(vec2 p, float sc, vec2 gIP){
    p *= rot2(3.14159/4.);
    sc *= 5.5*.7071;
    p *= sc;
    vec2 ip = floor(p);
    p -= ip + .5;
    float rnd = hash21(ip + gIP*.123 + .01);
    if(rnd < .5) p.y = -p.y;
    vec2 ap = abs(p - .5);
    float d = abs((ap.x + ap.y)*.7071 - .7071);
    ap = abs(p);
    d = min(d, abs((ap.x + ap.y)*.7071 - .7071));
    d -= .125;
    return d/sc;
}

float fPat2(vec2 p, float sc){
    sc *= 11.;
    p *= sc;
    p *= rot2(3.14159/2.);
    p = fract(p + .5) - .5;
    p = abs(p);
    float d = -(max(p.x, p.y) - (.5 - .125/2.));
    return d/sc;
}

float bumpSurf3D(in vec3 p, in vec3 n){
    map(p);
    vec3 txP = gCoord;
    vec3 txN = n;
    txN.yz *= rot2(.61547518786);
    txN.xz *= rot2(3.14159/4.);
    vec2 uv = abs(txN.x)>.5? txP.zy : abs(txN.y)>.5? txP.xz : txP.xy;
    vec2 scale = GSCALE;
    float sc = scale.x/sqrt(2.)/2. - .003;
    sc /= exp2(blockPartID);
    vec2 auv = abs(uv);
    float fdf = abs(max(auv.x, auv.y) - sc) - .002;
    float pat2 = fPat2(uv/1.03 + .25, 2.);
    sc *= exp2(blockPartID);
    pat2 = smoothstep(0., .0002/sc/1., pat2);
    pat2 = mix(0., pat2, (1. - smoothstep(0., .0002/sc, fdf - .02 + .002 + .009)));
    return pat2;
}

vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor){
    const vec2 e = vec2(.001, 0);
    vec3 p4[4];
    p4[0] = p;
    p4[1] = p - e.xyy;
    p4[2] = p - e.yxy;
    p4[3] = p - e.yyx;
    vec4 b4;
    for(int i = 0; i < 4; i++){
        b4[i] = bumpSurf3D(p4[i], n);
        if(n.x > 1e5) break;
    }
    vec3 grad = (b4.yzw - b4.x)/e.x;
    grad -= n*dot(n, grad);
    return normalize(n + grad*bumpfactor);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    vec2 ra = vec2(1, iResolution.x/iResolution.y);
    uv *= 1. + (dot(uv*ra, uv*ra)*.05 - .025);
    vec3 ro = vec3(iTime * ANIMATION_SPEED / 6., 0, -1); // Apply animation speed
    vec3 lk = ro + vec3(.01*0., .01*0., .1);
    vec3 lp = ro + vec3(.25, .25, .7);
    float FOV = 1.;
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x));
    vec3 up = cross(fwd, rgt);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    vec3 sp = ro;
    float gSh = 1.;
    float objRef = 1.;
    vec3 col = vec3(0.);
    float alpha = 1.;
    for(int j = 0; j < PASSES; j++){
        vec3 colL = vec3(0.);
        float t = trace(sp, rd);
        float svObjID = objID;
        vec4 svGID = gID;
        float svBPID = blockPartID;
        vec3 svCoord = gCoord;
        sp += rd*t;
        if(t < FAR){
            vec3 sn = getNormal(sp);
            sn = doBumpMap(sp, sn, .03);
            vec3 reflection = reflect(rd, sn);
            vec3 ld = lp - sp;
            float lDist = length(ld);
            ld /= max(lDist, .0001);
            float sh = 1.;
            if(j == 0) sh = softShadow(sp, lp, sn, 8.);
            float ao = calcAO(sp, sn);
            gSh = min(sh, gSh);
            float att = 1./(1. + lDist*lDist*.05);
            float dif = max(dot(ld, sn), 0.);
            float spe = pow(max(dot(reflection, ld), 0.), 32.);
            float fre = clamp(1. + dot(rd, sn), 0., 1.);
            dif = pow(dif, 4.)*2.;
            float Schlick = pow(1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
            float freS = mix(.25, 1., Schlick);
            vec3 oCol;
            if(svObjID == 0.){
                vec2 scale = GSCALE;
                float sc = scale.x/sqrt(2.)/2. - .003;
                float sc2 = sc/exp2(svBPID);
                vec3 txP = svCoord;
                vec3 txN = sn;
                txN.yz *= rot2(.61547518786);
                txN.xz *= rot2(3.14159/4.);
                vec2 uv = abs(txN.x)>.5? txP.zy : abs(txN.y)>.5? txP.xz : txP.xy;
                float faceID = abs(txN.x)>.5? 0. : abs(txN.y)>.5? 1. : 2.;
                vec3 tx = getTex(iChannel0, uv + hash21(svGID.yz));
                tx = smoothstep(0., .5, tx);
                float rndF = hash21(svGID.yz + svBPID/6. + .08);
                rndF = smoothstep(.92, .97, sin(6.2831*rndF + iTime)*.5 + .5);
                vec3 blCol = mix(vec3(3.2, .7, .3), vec3(3.4, .4, .6), hash21(svGID.yz + .32));
                blCol = mix(blCol, blCol.zyx, step(.5, hash21(svGID.yz + .21)));
                vec3 glCol = smoothstep(0., 1., 1. - length(uv)/sc2)*blCol*6.;
                float pat2 = fPat2(uv, 1./.125);
                vec3 metCol = vec3(1.1, .9, 1.1);
                oCol = tx/2.*metCol;
                oCol = mix(oCol, glCol, rndF + .01);
                oCol = mix(oCol, vec3(0), (1. - smoothstep(0., .0003/sc2, pat2))*.9);
                float pat = fPat(uv, 1./.125, svGID.yz + faceID/6. + svBPID/6.);
                pat2 = fPat2(uv/1.03 + .25, 2.);
                vec3 eCol = mix(tx*.5 + .5, tx*.5 + .3 + blCol*.15, rndF)/3.;
                eCol = mix(eCol, vec3(0), (1. - smoothstep(0., .0002/sc, pat2))*.5);
                eCol *= metCol;
                oCol = mix(oCol, oCol/8., (1. - smoothstep(0., .0002/sc, pat)));
                vec2 auv = abs(uv);
                float fdf = abs(max(auv.x, auv.y) - sc2) - .002;
                oCol = mix(oCol, vec3(0), (1. - smoothstep(0., .0002/sc, fdf - .02 + .002)));
                oCol = mix(oCol, eCol, (1. - smoothstep(0., .0002/sc, fdf - .02 + .002 + .009)));
                float faceRef = mix(.25, .5, (1. - smoothstep(0., .0002/sc, pat)));
                objRef = mix(faceRef, .1, (1. - smoothstep(0., .0002/sc, fdf - .02 + .002 + .009)));
            } else {
                oCol = vec3(0);
                objRef = .0;
            }
            colL = oCol*(dif*gSh + .1 + vec3(1, .8, .5)*spe*1.*gSh);
            colL *= ao*att;
            rd = reflection;
            sp += sn*DELTA*1.1;
        }
        col += colL*alpha;
        if(objRef < .001 || t >= FAR) break;
        alpha *= objRef;
    }
    // Apply BCS adjustments
    vec3 color = col * BRIGHTNESS; // Apply brightness first
    color = mix(vec3(0.5), color, CONTRAST); // Contrast
    color = mix(vec3(dot(vec3(0.299, 0.587, 0.114), color)), color, SATURATION); // Saturation
    fragColor = vec4(sqrt(max(color, 0.)), 1.);
}