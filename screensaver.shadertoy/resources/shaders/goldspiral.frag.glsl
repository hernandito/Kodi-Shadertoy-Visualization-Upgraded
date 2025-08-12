#define PI 3.14159265
#define TAU 6.2831853

// Field pattern -- Box: 0, Petal: 1.
#define PATTERN 1

// Color scheme -- Chrome: 0, Gold: 1.
#define COLOR 1

// Add a frame border to the objects. It's interesting, but a
// little too busy for this example, so it's off by default.
//#define FRAME

// Max ray distance.
#define FAR 20.0

// --- Post-processing and Animation Control Parameters ---
// Adjust brightness (1.0 is default, >1.0 brighter, <1.0 darker)
#define BRIGHTNESS .98
// Adjust contrast (1.0 is default, >1.0 more contrast, <1.0 less contrast)
#define CONTRAST 1.03
// Adjust saturation (1.0 is default, >1.0 more saturated, <1.0 desaturated)
#define SATURATION 1.15

// Adjust overall animation speed (1.0 is default, >1.0 faster, <1.0 slower)
#define ANIMATION_SPEED .10

// Standard 2D rotation function.
mat2 myRot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash function.
float myHash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// IQ's extrusion formula for SDFs.
float opExtrusion(in float sdf, in float pz, in float h){
    const float sf = 0.015;
    vec2 w = vec2( sdf, abs(pz) - h - sf/2.0);
    return min(max(w.x, w.y), 0.0) + length(max(w + sf, 0.0)) - sf;
}

// IQ's box SDF formula.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rf;
}

// Global tile scale.
const vec2 tile_scale = vec2(1.0, TAU/6.0)/3.5;

// Polar spiral transformation.
vec2 spiral(vec2 p){
    float r = length(p);
    float ang = atan(p.y, p.x);
    ang = mod(ang + 2.0/(r + 0.45), TAU);
    p = vec2(cos(ang), sin(ang))*r;
    return p;
}

// Basic spiral transform function with animation and grid ID output.
vec2 transf(vec2 p, out vec2 out_gIP){
    p = spiral(p);
    p -= vec2(1.0, -1.0)*iTime*ANIMATION_SPEED/4.0; // Apply ANIMATION_SPEED
    vec2 ip = floor(p/tile_scale);
    p -= (ip + 0.5)*tile_scale;
    out_gIP = ip;
    return p;
}

// 3D Value Noise function.
float myN3D(vec3 p){
    const vec3 s = vec3(1.0, 113.0, 237.0);
    vec3 ip = floor(p); p -= ip;
    vec4 h = vec4(0.0, s.x, s.y, s.z) + dot(ip, s);
    h = fract(sin(mod(h, 6.2831589))*43758.5453);
    p *= p*(3.0 - 2.0*p);
    h.yzx = mix(h.yzx, h.wzy, p.z);
    h.xy = mix(h.xy, h.yz, p.y);
    return mix(h.x, h.y, p.x);
}

// Fractal Brownian Motion (FBM) noise function for 3D.
float myGradN3D(vec3 p){ return myN3D(p)*0.533 + myN3D(p*2.0)*0.267 + myN3D(p*4.0)*0.133 + myN3D(p*8.0)*0.067; }

// 2D distance field calculation, returning distance and grid ID.
vec4 dist2D(vec2 p){
    vec2 local_gIP;
    #if PATTERN == 1
    p = transf(p, local_gIP);
    float d2 = sBoxS(p, tile_scale/2.0, 0.0);
    #else
    p = spiral(p);
    p = p - vec2(1.0, -1.0)*iTime*ANIMATION_SPEED/4.0; // Apply ANIMATION_SPEED
    local_gIP = floor(p/tile_scale);
    float scl = TAU*2.0;
    #ifdef FRAME
    float d2 = -abs(sin(p.x*scl)*cos(p.y*scl))/scl - 0.02;
    #else
    float d2 = -abs(sin(p.x*scl)*cos(p.y*scl))/scl*4.0 - 0.02;
    #endif
    #endif
    return vec4(d2, local_gIP.x, local_gIP.y, 0.0);
}

// Wrapper for 2D distance calculation.
float distObj(vec3 uv){
    return dist2D(uv.xy).x;
}

// Main scene mapping function, returning distance, object ID, and warped value.
vec4 map(vec3 p, out int out_objID, out vec3 out_gVal){
    float fl = -p.z;
    vec4 d2_info = dist2D(p.xy);
    float d2 = d2_info.x;
    out_gVal = vec3(d2, d2_info.y, d2_info.z);
    d2 += 0.06;
    #ifdef FRAME
    float fr2 = abs(d2 + 0.015) - 0.015;
    d2 += 0.015;
    #endif
    float h = 0.04;
    float d = opExtrusion(d2, p.z + h, h);
    d += d2*0.25;
    #ifdef FRAME
    h += 0.01;
    float fr = opExtrusion(fr2, p.z + h, h);
    #else  
    float fr = 1e5;
    #endif
    out_objID = fl < d && fl < fr ? 0 : d < fr ? 1 : 2;
    return vec4(min(fl, min(d, fr)), 0.0, 0.0, 0.0);
}

// Basic raymarcher function.
float trace(in vec3 ro, in vec3 rd, out int out_objID, out vec3 out_gVal){
    float t = 0.0;
    float d;
    int local_objID = 0;
    vec3 local_gVal = vec3(0.0);
    for(int i = 0; i < 96; i++){
        vec4 map_result = map(ro + rd*t, local_objID, local_gVal);
        d = map_result.x;
        if(abs(d) < 0.001 || t > FAR) break;
        t += d*0.7;
    }
    out_objID = local_objID;
    out_gVal = local_gVal;
    return min(t, FAR);
}

// Standard normal calculation function.
vec3 normal(in vec3 p) {
    float sgn = 1.0;
    vec3 e = vec3(0.002, 0.0, 0.0), mp = e.zzz;
    for(int i = 0; i < 6; i++){
        int local_objID;
        vec3 local_gVal;
        mp.x += map(p + sgn*e, local_objID, local_gVal).x*sgn;
        sgn = -sgn;
        if(mod(float(i), 2.0) == 1.0){ mp = mp.yzx; e = e.zxy; }
    }
    return normalize(mp);
}

// Soft shadow calculation.
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){
    const int maxIterationsShad = 32;
    ro += n*(0.0015 + myHash21(ro.xy + ro.yz + n.xz)*0.01);
    vec3 rd = lp - ro;
    float shade = 1.0;
    float t = 0.0;
    float end = max(length(rd), 0.0001);
    rd /= end;
    for (int i = 0; i < maxIterationsShad; i++){
        int local_objID;
        vec3 local_gVal;
        float d = map(ro + rd*t, local_objID, local_gVal).x;
        shade = min(shade, k*d/t);
        if (d < 0.0 || t > end) break;
        t += clamp(d, 0.01, 0.2);
    }
    return max(shade, 0.0);
}

// Ambient Occlusion calculation.
float calcAO(in vec3 p, in vec3 n){
    float sca = 2.0, occ = 0.0;
    for( int i = 0; i < 5; i++ ){
        float hr = float(i + 1)*0.125/5.0;
        int local_objID;
        vec3 local_gVal;
        float d = map(p + n*hr, local_objID, local_gVal).x;
        occ += (hr - d)*sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0.0, 1.0);
}

// Surface curvature calculation. 
float curve(in vec3 p, in float spr, in float amp, in float offs){
    spr /= 450.0;
    float sgn = 1.0;
    vec3 e = vec3(0.002, 0.0, 0.0);
    int local_objID;
    vec3 local_gVal;
    float d = -map(p, local_objID, local_gVal).x*6.0;
    for(int i = 0; i < 6; i++){
        d += map(p + sgn*e, local_objID, local_gVal).x;
        sgn = -sgn;
        if(mod(float(i), 2.0) == 1.0){ e = e.zxy; }
    }
    return smoothstep(-1.0, 1.0, d/(e.x*e.x)*amp/64.0 + offs);
}

// Procedural environment texture.
vec3 envTex(vec3 p){
    float ns = myGradN3D(p)*0.57 + myGradN3D(p*2.0)*0.28 + myGradN3D(p*4.0)*0.15;
    ns = smoothstep(0.45, 0.65, ns);
    vec3 refTx = pow(vec3(ns), vec3(1.0, 2.0, 8.0));
    refTx = mix(refTx.zyx, refTx, smoothstep(0.3, 0.7, myGradN3D(p*2.5)));
    return refTx;
}

// Procedural grunge texture. Spacing d2
vec3 GrungeTex(vec2 p) {
    float n = myHash21(p * 10.0) * 0.5 + myHash21(p * 20.0 + 0.1) * 0.3 + myHash21(p * 40.0 + 0.2) * 0.2;
    return vec3(n);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = (fragCoord - iResolution.xy*0.5)/iResolution.y;
    vec3 ro = vec3(cos(iTime/4.0)*0.1, sin(iTime/4.0)*0.1, -1.5);
    vec3 lk = vec3(0.0);
    vec3 lp = lk + vec3(0.25, 0.5, -1.0);
    float FOV = 1.0;
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(cross(vec3(0.0, 1.0, 0.0), fwd));
    vec3 up = cross(fwd, rgt);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    int main_objID;
    vec3 main_gVal;
    float t = trace(ro, rd, main_objID, main_gVal);
    int svObjID = main_objID;
    vec3 svVal = main_gVal;
    vec3 col = vec3(0.0);
    if(t < FAR){
        vec3 sp = ro + rd*t;
        vec3 sn = normal(sp);
        vec3 ld = lp - sp;
        float lDist = max(length(ld), 0.001);
        ld /= lDist;
        float sh = softShadow(sp, lp, sn, 16.0);
        float ao = calcAO(sp, sn);
        float spr = 4.0, amp = 1.0, offs = 0.0;
        float crv = curve(sp, spr, amp, offs);
        float atten = 1.0/(1.0 + lDist*0.05);
        float diff = max( dot(sn, ld), 0.0);
        diff = pow(diff, 4.0)*2.0;
        float spec = pow(max(dot(reflect(ld, sn), rd), 0.0), 32.0);
        float Schlick = pow( 1.0 - max(dot(rd, normalize(rd + ld)), 0.0), 5.0);
        float freS = mix(0.15, 1.0, Schlick);
        vec3 texCol = vec3(0.6);
        vec3 txP = sp;
        float sf_val = 1.5/iResolution.y;
        float ew = 0.005;
        if(svObjID > 0){
            float rnd = myHash21(svVal.yz + 0.1);
            vec3 cCol = 0.5 + 0.45*cos(TAU*rnd/6.0 - crv*0.1 + vec3(0.0, 1.0, 2.0)*1.0);
            texCol = cCol;
            #if PATTERN == 0
            texCol *= 0.65;
            #endif
            if(svObjID==2) texCol = mix(texCol, vec3(1.0), 0.25);
        }
        else {
            texCol = vec3(0.5, 0.275, 0.125);
        }
        vec3 tx3 = GrungeTex(txP.xy*2.0);
        vec3 tx = tx3.xyz;
        vec3 grunge_modified_texCol = texCol * tx * 3.0;
        texCol = grunge_modified_texCol;

        // Apply greyscale if COLOR is 0 (Chrome)
        #if COLOR == 0
        float gr = dot(texCol, vec3(0.299, 0.587, 0.114)); // Calculate luminance
        texCol = mix(texCol, vec3(gr), 0.8); // Mix original color with grayscale version
        #endif

        vec3 hv = normalize(ld - rd);
        vec3 ref = reflect(rd, sn);
        vec3 q = ref*3.0;
        q.xy *= myRot2(iTime*ANIMATION_SPEED/2.0); // Apply ANIMATION_SPEED
        vec3 refTx = envTex(q);
        refTx = refTx*refTx*2.0;
        float spRef = pow(max(dot(hv, sn), 0.0), 8.0);
        float rf = (svObjID == 0)? 0.25 : 1.0;
        col = texCol * (diff*sh + 0.25 + vec3(1.0, 0.97, 0.92)*spec*freS*8.0*sh);
        col *= crv + 0.25;
        col *= ao*atten;
    }
    col = mix(col, vec3(0.0), smoothstep(0.0, 0.99, t/FAR));
    vec2 uv_vignette = fragCoord/iResolution.xy;
    col *= pow(16.0*uv_vignette.x*uv_vignette.y*(1.0 - uv_vignette.x)*(1.0 - uv_vignette.y) , 1.0/16.0);

    // --- Post-processing: Brightness, Contrast, Saturation ---
    // Apply Brightness
    col += (BRIGHTNESS - 1.0);

    // Apply Contrast
    col = ((col - 0.5) * CONTRAST) + 0.5;

    // Apply Saturation
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(luma), col, SATURATION);

    fragColor = vec4(sqrt(max(col, 0.0)), 1.0);
}
