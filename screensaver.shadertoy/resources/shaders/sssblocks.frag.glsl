#define FAR 10.
#define PI 3.14159265358979
#define TAU 6.2831853
#define BRIGHTNESS 1.0
#define CONTRAST 1.0
#define SATURATION 1.0
#define ANIM_SPEED .1

mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

float hash21(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x*p.y);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx)*vec3(.3031, .4030, .5973));
    p3 += dot(p3, p3.yzx + 42.1237);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float hash31(vec3 p) {
    p = fract(p*vec3(.1031, .1030, .0973));
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y)*p.z);
}

vec3 hash33(vec3 p) {
    p = fract(p*vec3(.5031, .6030, .4973));
    p += dot(p, p.yxz + 142.5453);
    return fract((p.xxy + p.yxx)*p.zyx);
}

float smax(float a, float b, float k) {
    float f = max(0., 1. - abs(b - a)/k);
    return max(a, b) + k*.25*f*f;
}

vec2 path(in float z) {
    return vec2(0.0);
}

float hf(vec2 p) {
    float x = abs(p.x - path(p.y).x);
    x = min(x/2., 1.)*.7 + .3;
    float h = dot(sin(p*2. - cos(p.yx*3.)*1.5), vec2(.25)) + .5;
    return clamp(h*x, 0., 1.);
}

float sBox(vec2 p, vec2 b, in float rf) {
    vec2 d = abs(p) - b + rf;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
}

float opExtrusion(in float sdf, in float pz, in float h, in float sf) {
    vec2 w = vec2(sdf, abs(pz) - h) + sf;
    return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}

float rayLine(vec2 ro, vec2 rd, vec2 p, vec2 n) {
    float dn = dot(rd, n);
    return dn>0.? dot(p - ro, n)/max(dn, 1e-6) : 1e8;
}

float GGX_Schlick(float nv, float rough) {
    float r = .5 + .5*rough;
    float k = (r*r)/2.;
    float denom = nv*(1. - k) + k;
    return max(nv, .001)/max(denom, 1e-6);
}

float G_Smith(float nr, float nl, float rough) {
    float g1_l = GGX_Schlick(nl, rough);
    float g1_v = GGX_Schlick(nr, rough);
    return g1_l*g1_v;
}

vec3 getSpec(vec3 FS, float nh, float nr, float nl, float rough) {
    float alpha = pow(rough, 4.);
    float b = (nh*nh*(alpha - 1.) + 1.);
    float D = alpha/max((3.14159265*b*b), 1e-6);
    float G = G_Smith(nr, nl, rough);
    return FS*D*G/max((4.*max(nr, .001)), 1e-6)*3.14159265;
}

vec3 getDiff(vec3 FS, float nl, float rough, float type) {
    vec3 diff = nl*(1. - FS);
    return diff*(1. - type);
}

vec3 adjustBCS(vec3 color, float brightness, float contrast, float saturation) {
    color *= brightness;
    color = (color - 0.5) * contrast + 0.5;
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(gray), color, saturation);
    return clamp(color, 0.0, 1.0);
}

vec4 vObj = vec4(0.0);
vec3 gRd = vec3(0.0);
vec3 gDir = vec3(0.0);
float gCD = 0.0;
vec4 gVal = vec4(0.0);
vec3 gP = vec3(0.0);
vec3 gDim = vec3(0.0);

float map(vec3 p) {
    float fl = p.y + 1.;
    vec2 sc = vec2(3.)/1.;
    vec2 offs = vec2(0.0);
    vec2 q = p.xz;
    vec2 iq = floor(q/sc) + .5;
    if(mod(iq.y - .5, 2.)==1.) {
        q.x -= sc.x/2.;
        iq = floor(q/sc) + .5;
        offs.x += .5;
    }
    q -= iq*sc;
    iq += offs;
    vec2 dim = sc;
    vec2 left = -dim/2.;
    vec2 right = dim/2.;
    float mgn = .35;
    vec2 idd = vec2(0.0);
    vec2 rndOffs = hash22(iq + .07);
    const int iter = 3;
    for(int i = 0; i<iter; i++) {
        vec2 rndSplit = idd + (rndOffs + vec2(3., 5.)/float(i + 1)*117.3);
        vec2 rnd2Ani = sin(TAU*rndSplit + iTime*ANIM_SPEED*1.5)*.5*(1. - mgn*2.) + .5;
        vec2 split = mix(left, right, rnd2Ani);
        vec2 ln2 = q - split;
        vec2 stepLn = step(0., ln2);
        idd += mix(vec2(0.), vec2(1.), stepLn)/pow(2., float(i));
        left = mix(left, split, stepLn);
        right = mix(split, right, stepLn);
    }
    dim = right - left;
    vec2 cntr = mix(left, right, .5);
    q -= cntr;
    iq += cntr/sc;
    float h = hf(iq*sc);
    h = h*1.4 + .1;
    float ew = .005;
    gP = vec3(q.x, p.y - h/2. + .5, q.y);
    gDim = vec3(dim.x/2. - ew, h/2. + .5, dim.y/2. - ew);
    float d2 = sBox(gP.xz, gDim.xz, .03);
    float d = opExtrusion(d2, gP.y, gDim.y + .025, .03);
    d = smax(d, length(gP - vec3(0., gDim.y - sc.x/2. + .025, 0.)) - sc.x/2., .03);
    vec3 bxRnd = hash33(vec3(idd.x, 13., idd.y) + .43);
    if(bxRnd.x<.5) d = smax(d, -sBox(gP.yz, gDim.yz - .12, .003), .03);
    if(bxRnd.y<.5) {
        float dXZ = sBox(gP.xz, gDim.xz - .12, .003);
        d = smax(d, -dXZ, .03);
        d2 = smax(d2, -dXZ, .03);
    }
    if(bxRnd.z<.5) d = smax(d, -sBox(gP.xy, gDim.xy - .12, .003), .03);
    gVal = vec4(d, idd, h);
    vec2 rC = abs((gDir.xz*dim - q)/gRd.xz);
    gCD = min(rC.x, rC.y) + .0001;
    vObj = vec4(d, fl, 0., 0.);
    return min(d, fl);
}

float trace(vec3 ro, vec3 rd) {
    gRd = rd;
    gDir = step(0., gRd) - .5;
    float t = 0.;
    const int maxSteps = 96;
    for(int i = 0; i<maxSteps; i++) {
        float d = map(ro + rd*t);
        if(abs(d)<.001 || t>FAR) break;
        t += min(d, gCD);
    }
    return min(t, FAR);
}

float softShadow(vec3 ro, vec3 rd, vec3 n, float lDist, float k) {
    float shade = 1.;
    float t = 0.;
    ro += n*.0015 + rd*hash31(ro + rd + n)*.005;
    gRd = rd;
    gDir = step(0., gRd) - .5;
    for(int i = 0; i<48; i++) {
        float d = map(ro + rd*t);
        shade = min(shade, k*d/max(t, 1e-6));
        if(d<0. || t>lDist) break;
        t += clamp(min(d, gCD), .005, .25);
    }
    return max(shade, 0.);
}

vec3 nr(in vec3 p) {
    float sgn = 1.;
    vec3 e = vec3(.001, 0., 0.), mp = vec3(0.);
    for(int i = 0; i<6; i++) {
        mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if(mod(float(i), 2.0) == 1.0) { mp = mp.yzx; e = e.zxy; }
    }
    return normalize(mp);
}

float cao(in vec3 p, in vec3 n) {
    float sca = 2., occ = 0.;
    for(int i = 0; i<6; i++) {
        float hr = .01 + float(i)*.25/6.;
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    return clamp(1. - occ, 0., 1.);
}

float subsurface(vec3 ro, vec3 rd, float ra) {
    const int sN = 10;
    float sss = 0.;
    for(int i = 0; i<sN; i++) {
        float rnd = hash31(ro + float(i))*.1;
        float d = float(i)*ra*(1. + rnd);
        sss += clamp(map(ro + rd*d)/max(d, 1e-6), 0., 1.);
    }
    sss /= float(sN);
    return smoothstep(0., 1., sss);
}

vec3 sky(vec3 rd, vec3 ld) {
    vec3 col = mix(vec3(.45,.65, 1.), vec3(0.,.15, .5), clamp(rd.y*2., 0., 1.));
    vec3 hor = vec3(.65, .8, 1.);
    col = mix(col, hor, 1. - smoothstep(0., .15, rd.y + .1));
    return col;
}

void mainImage(out vec4 o, vec2 fc) {
    o = vec4(0.0);
    vec2 u = (fc - iResolution.xy/2.)/iResolution.y;
    u /= max(.9 - dot(u, u)*.7, 1e-5);
    vec3 lk = vec3(0., .5, iTime*ANIM_SPEED);
    vec3 ro = lk + vec3(0., 1., -1.5);
    vec3 lp = lk + vec3(1., 1., 1.)*8.;
    lk.xy += path(lk.z);
    ro.xy += path(ro.z);
    float half_angle = (30.0 * PI / 180.0) / 2.0;
    float FOV = tan(half_angle) * 4.0;
    vec3 camDir = normalize(lk - ro);
    vec3 worldUp = vec3(0., 1., 0.);
    vec3 camRight = normalize(cross(worldUp, camDir));
    vec3 camUp = cross(camDir, camRight);
    vec3 rd = normalize(camRight*u.x + camUp*u.y + camDir/FOV);
    rd.xy = r2(-path(lk.z).x/16.)*rd.xy;
    rd.xz *= r2(-TAU/8.);
    float t = trace(ro, rd);
    vec4 svVal = gVal;
    vec3 svP = gP;
    vec3 svDim = gDim;
    int objID = vObj.x<vObj.y? 0 : 1;
    vec3 sp = ro + rd*t;
    vec3 ld = normalize(vec3(1., 1., 1.));
    float lDist = FAR;
    vec3 skyCol = sky(rd, ld);
    vec3 col = skyCol;
    vec3 sunCol = vec3(1., .8, .6)*2.;
    if(t<FAR) {
        vec3 sn = nr(sp);
        float sh = softShadow(sp, ld, sn, lDist, 8.);
        float shR = softShadow(sp, reflect(rd, sn), sn, lDist, 16.);
        float ao = cao(sp, sn)*(.5 + .5*sn.y);
        vec3 sRay = ld;
        float sss = subsurface(sp - sn*.005, sRay, .05);
        float rnd = hash21(svVal.yz + .23);
        vec3 oCol = .52 + .43*cos(TAU*(rnd)/4. + rnd*.1 + vec3(0., 1., 2.)*1. + .7);
        if(objID==1) oCol = vec3(.05);
        float bou = .5 - .5*sn.y;
        float bac = clamp(dot(sn, -normalize(vec3(ld.x, 0., ld.z))), 0., 1.);
        bac = (bac*.5 + .5)*bou;
        float fresRef = .7;
        float type = 0.;
        float rough = .35;
        vec3 h = normalize(ld - rd);
        float ndl = dot(sn, ld);
        float nr = clamp(dot(sn, -rd), 0., 1.);
        float nl = clamp(ndl, 0., 1.);
        float nh = clamp(dot(sn, h), 0., 1.);
        float vh = clamp(dot(-rd, h), 0., 1.);
        vec3 f0 = vec3(.16*(fresRef*fresRef));
        f0 = mix(f0, oCol, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.);
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, rough, type);
        vec3 lin = sunCol*diff*sh;
        lin += sunCol*oCol*ao*bac;
        vec3 sssCol = vec3(.8, .25, .1);
        vec3 sss3 = sssCol*sss*(1. - diff*sh);
        lin += sunCol*sss3;
        lin += .35*skyCol*ao;
        col = oCol*lin;
        col += .2*sunCol*spec*shR;
        col += skyCol*shR*FS;
    }
    col = mix(col, skyCol, smoothstep(.4, 1., t/FAR));
    col += sunCol*pow(clamp(dot(rd, ld),0.,1.), 8.)*.7;
    col = atan(col*2.);
    col = adjustBCS(col, BRIGHTNESS, CONTRAST, SATURATION);
    o = vec4(pow(max(col, 0.), vec3(1.0/2.2)), 1.);
}