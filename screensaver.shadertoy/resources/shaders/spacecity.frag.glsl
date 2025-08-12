precision mediump float;

// Warped Extruded Skewed Grid

#define SKEW_GRID

// Snap the pylons to discreet height units.
//#define QUANTIZE_HEIGHTS

// Flattening the grid in order to discern the 2D face pattern more clearly.
//#define FLAT_GRID

// Grid positioning independant of the camera path.
//#define PTH_INDPNT_GRD

// Grayscale, for that artsy look.
#define GRAYSCALE

// Reverse the color palette.
//#define REVERSE_PALETTE

// Max ray distance.
#define FAR 20.0

// --- GLOBAL PARAMETERS ---
#define ANIMATION_SPEED 0.085 // Controls the overall animation speed (1.0 = normal speed)
#define FOV_ANGLE 1.40       // Field of View angle (e.g., 1.0 for normal, smaller for zoom in)

// --- POST-PROCESSING DEFINES (BCS) ---
#define BRIGHTNESS 1.0    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.05      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)


float objID;

mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

float hash31(vec3 p){
    return fract(sin(dot(p, vec3(12.989, 78.233, 57.263)))*43758.5453);
}

vec2 path(in float z){
    return vec2(3.0*sin(z*0.1) + 0.5*cos(z*0.4), 0.0);
}

vec3 getTex(in vec2 p){
    vec3 tx = texture(iChannel0, p/8.0).xyz;
    return tx*tx;
}

float hm(in vec2 p){ return dot(getTex(p), vec3(0.299, 0.587, 0.114)); }

float opExtrusion(in float sdf, in float pz, in float h, in float sf){
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
      return min(max(w.x, w.y), 0.0) + length(max(w, 0.0)) - sf;
}

float sBoxS(in vec2 p, in vec2 b, in float sf){
  p = abs(p) - b + sf;
  return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0) - sf;
}

vec2 skewXY(vec2 p, vec2 s){
    return mat2(1.0, -s.y, -s.x, 1.0)*p;
}

vec2 unskewXY(vec2 p, vec2 s){
    float det = 1.0 - s.x * s.y;
    mat2 inv_mat = mat2(1.0, s.y, s.x, 1.0) / max(det, 1e-6);
    return inv_mat * p;
}

vec2 gP;

// Helper function to get ps4 elements without array constructors
vec2 get_ps4_element(int index) {
    if (index == 0) return vec2(-0.5, 0.5);
    if (index == 1) return vec2(0.5);
    if (index == 2) return vec2(0.5, -0.5);
    return vec2(-0.5); // Default for index 3
}

vec4 blocks(vec3 q){
    const vec2 scale = vec2(1.0/5.0);
    const vec2 dim = scale;
    const vec2 s = dim*2.0;

    #ifdef SKEW_GRID
    const vec2 sk = vec2(-0.5, 0.5);
    #else
    const vec2 sk = vec2(0.0);
    #endif

    float d = 1e5;
    vec2 p, ip;
    vec2 id = vec2(0.0);
    vec2 cntr = vec2(0.0);
    // Removed array constructor for ps4
    
    #ifdef FLAT_GRID
    const float hs = 0.0;
    #else
    const float hs = 0.4;
    #endif
    float height = 0.0;

    gP = vec2(0.0);

    for(int i = 0; i<4; i++){
        // Use helper function to get ps4 elements
        cntr = get_ps4_element(i)/2.0 -  get_ps4_element(0)/2.0;
        p = skewXY(q.xz, sk);
        ip = floor(p/max(s, 1e-6) - cntr) + 0.5;
        p -= (ip + cntr)*s;
        p = unskewXY(p, sk);
        vec2 idi = ip + cntr;
        
        vec2 idi1 = idi;
        vec2 idi2 = idi + unskewXY(dim*0.5, sk);

        idi = unskewXY(idi*s, sk);

        float h1 = hm(idi1);
        #ifdef QUANTIZE_HEIGHTS
        h1 = floor(h1*20.999)/20.0;
        #endif
        h1 *= hs;
        float face1 = sBoxS(p, 2.0/5.0*dim - 0.02*scale.x, 0.015);
        float face1Ext = opExtrusion(face1, q.y + h1, h1, 0.006);

        float h2 = hm(idi2);
        #ifdef QUANTIZE_HEIGHTS
        h2 = floor(h2*20.999)/20.0;
        #endif
        h2 *= hs;
        float face2 = sBoxS(p - unskewXY(dim*0.5, sk), 1.0/5.0*dim - 0.02*scale.x, 0.015);
        float face2Ext = opExtrusion(face2, q.y + h2, h2, 0.006);

        vec4 di = face1Ext<face2Ext? vec4(face1Ext, idi1, h1) : vec4(face2Ext, idi2, h2);

        if(di.x<d){
            d = di.x;
            id = di.yz;
            height = di.w;
            gP = p;
        }
    }
    return vec4(d, id, height);
}

float getTwist(float z){ return z*0.08; }

vec3 gID;
vec4 gGlow = vec4(0.0);

float map(vec3 p){
    p.xy -= path(p.z);
    p.xy *= rot2(getTwist(p.z));
    p.y = abs(p.y) - 1.25;
    float fl = -p.y + 0.01;

    #ifdef PTH_INDPNT_GRD
    p.xy += path(p.z);
    #endif

    vec4 d4 = blocks(p);
    gID = d4.yzw;

    float rnd = hash21(gID.xy);
    gGlow.w = smoothstep(0.992, 0.997, sin(rnd*6.2831 + iTime*ANIMATION_SPEED/4.0)*0.5 + 0.5); // Use ANIMATION_SPEED

    objID = fl<d4.x? 1.0 : 0.0;

    return min(fl, d4.x);
}

float trace(in vec3 ro_in, in vec3 rd_in){
    float t = 0.0;
    float d;
    gGlow = vec4(0.0);
    t = hash31(ro_in.zxy + rd_in.yzx)*0.25;

    for(int i = 0; i<128; i++){
        d = map(ro_in + rd_in*t);
        float ad = abs(d + (hash31(ro_in + rd_in) - 0.5)*0.05);
        const float dst = 0.25;
        if(ad<dst){
            gGlow.xyz += gGlow.w*(dst - ad)*(dst - ad)/(1.0 + t);
        }
        if(abs(d)<0.001*(1.0 + t*0.05) || t>FAR) break;
        t += i<32? d*0.4 : d*0.7;
    }
    return min(t, FAR);
}

// Helper function to get e6 elements without array constructors
vec3 get_e6_element(int index, vec2 e_normal_step) {
    if (index == 0) return e_normal_step.xyy;
    if (index == 1) return e_normal_step.yxy;
    return e_normal_step.yyx; // Default for index 2
}

vec3 getNormal(in vec3 p){
    const vec2 e_normal_step = vec2(0.001, 0.0);
    float sgn = 1.0;
    float mp[6];
    // Removed array constructor for e6
    for(int i = 0; i<6; i++){
        // Use helper function to get e6 elements
        mp[i] = map(p + sgn*get_e6_element(i/2, e_normal_step));
        sgn = -sgn;
        if(sgn>2.0) break;
    }
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}

float softShadow(vec3 ro_in, vec3 lp_in, vec3 n_in, float k){
    const int iter = 24;
    ro_in += n_in*0.0015;
    vec3 rd_shadow = lp_in - ro_in;
    float shade = 1.0;
    float t = 0.0;
    float end = max(length(rd_shadow), 0.0001);
    rd_shadow /= max(end, 1e-6);

    for (int i = 0; i<iter; i++){
        float d = map(ro_in + rd_shadow*t);
        shade = min(shade, k*d/max(t, 1e-6));
        t += clamp(d, 0.01, 0.25);
        if (d<0.0 || t>end) break;
    }
    return max(shade, 0.0);
}

float calcAO(in vec3 p, in vec3 n)
{
    float sca = 3.0;
    float occ = 0.0;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*0.15/5.0;
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0.0, 1.0);
}

// Declare Fragcolor globally as it's expected to be the output variable for Kodi
// (based on user feedback that `gl_FragColor` doesn't work, but `Fragcolor` does).
// iTime and iResolution are assumed to be implicitly available as built-in uniforms.
vec4 Fragcolor; 

void mainImage(out vec4 fragColor, in vec2 fragCoord){ // Renamed kodiMain to mainImage
    // Use gl_FragCoord for input screen coordinates
    vec2 uv = (gl_FragCoord.xy - iResolution.xy*0.5)/max(iResolution.y, 1e-6);

    vec3 ro_main = vec3(0.0, 0.0, iTime*ANIMATION_SPEED*1.5); // Use ANIMATION_SPEED
    ro_main.xy += path(ro_main.z);
    vec2 roTwist = vec2(0.0, 0.0);
    roTwist *= rot2(-getTwist(ro_main.z));
    ro_main.xy += roTwist;

    vec3 lk = vec3(0.0, 0.0, ro_main.z + 0.25);
    lk.xy += path(lk.z);
    vec2 lkTwist = vec2(0.0, -0.1);
    lkTwist *= rot2(-getTwist(lk.z));
    lk.xy += lkTwist;

    vec3 lp = vec3(0.0, 0.0, ro_main.z + 3.0);
    lp.xy += path(lp.z);
    vec2 lpTwist = vec2(0.0, -0.3);
    lpTwist *= rot2(-getTwist(lp.z));
    lp.xy += lpTwist;

    float FOV = FOV_ANGLE; // Use FOV_ANGLE parameter
    float a = getTwist(ro_main.z);
    a += (path(ro_main.z).x - path(lk.z).x)/(ro_main.z - lk.z)/4.0;
    vec3 fw = normalize(lk - ro_main);
    vec3 up = vec3(sin(a), cos(a), 0.0);
    vec3 cu = normalize(cross(up, fw));
    vec3 cv = cross(fw, cu);

    vec3 rd = normalize(uv.x*cu + uv.y*cv + fw/max(FOV, 1e-6));

    float t = trace(ro_main, rd);

    vec3 svGID = gID;
    float svObjID = objID;
    vec2 svP = gP;
    vec3 svGlow = gGlow.xyz;

    vec3 col = vec3(0.0);

    if(t < FAR){
        vec3 sp = ro_main + rd*t;
        vec3 sn = getNormal(sp);
        vec3 texCol;

        vec3 txP = sp;
        txP.xy -= path(txP.z);
        txP.xy *= rot2(getTwist(txP.z));
        #ifdef PTH_INDPNT_GRD
        txP.xy += path(txP.z);
        #endif

        if(svObjID<0.5){
            vec3 tx = getTex(svGID.xy);
            texCol = smoothstep(-0.5, 1.0, tx)*vec3(1.0, 0.8, 1.8);

            const float lvls = 8.0;
            float yDist = (1.25 + abs(txP.y) + svGID.z*2.0);
            float hLn = abs(mod(yDist  + 0.5/lvls, 1.0/lvls) - 0.5/lvls);
            float hLn2 = abs(mod(yDist + 0.5/lvls - 0.008, 1.0/lvls) - 0.5/lvls);

            if(yDist - 2.5<0.25/lvls) hLn = 1e5;
            if(yDist - 2.5<0.25/lvls) hLn2 = 1e5;

            texCol = mix(texCol, texCol*2.0, 1.0 - smoothstep(0.0, 0.003, hLn2 - 0.0035));
            texCol = mix(texCol, texCol/2.5, 1.0 - smoothstep(0.0, 0.003, hLn - 0.0035));

            float fDot = length(txP.xz - svGID.xy) - 0.0086;
            texCol = mix(texCol, texCol*2.0, 1.0 - smoothstep(0.0, 0.005, fDot - 0.0035));
            texCol = mix(texCol, vec3(0.0), 1.0 - smoothstep(0.0, 0.005, fDot));
        }
        else {
            texCol = vec3(0.0);
        }

        vec3 ld = lp - sp;
        float lDist = max(length(ld), 0.001);
        ld /= max(lDist, 1e-6);

        float sh = softShadow(sp, lp, sn, 16.0);
        float ao = calcAO(sp, sn);
        sh = min(sh + ao*0.25, 1.0);

        float atten = 3.0/(1.0 + lDist*lDist*0.5);

        float diff = max( dot(sn, ld), 0.0);
        diff *= diff*1.35;

        float spec = pow(max(dot(reflect(ld, sn), rd ), 0.0), 32.0);

        float fre = pow(clamp(1.0 - abs(dot(sn, rd))*0.5, 0.0, 1.0), 4.0);

        col = texCol*(diff + ao*0.25 + vec3(1.0, 0.4, 0.2)*fre*0.25 + vec3(1.0, 0.4, 0.2)*spec*4.0);
        col *= ao*sh*atten;
    }

    svGlow.xyz *= mix(vec3(4.0, 1.0, 2.0), vec3(4.0, 2.0, 1.0), min(svGlow.xyz*3.5, 1.25));
    col *= 0.25 + svGlow.xyz*8.0;

    vec3 fog =  mix(vec3(4.0, 1.0, 2.0), vec3(4.0, 2.0, 1.0), rd.y*0.5 + 0.5);
    fog = mix(fog, fog.zyx, smoothstep(0.0, 0.35, uv.y - 0.35));
    col = mix(col, fog/1.5, smoothstep(0.0, 0.99, t*t/max(FAR*FAR, 1e-6)));

    #ifdef GRAYSCALE
    col = mix(col, vec3(1.0)*dot(col, vec3(0.299, 0.587, 0.114)), 0.75);
    #endif

    #ifdef REVERSE_PALETTE
    col = col.zyx;
    #endif

    // --- Apply BCS adjustments ---
    vec3 finalColor = col;
    // Brightness
    finalColor += (BRIGHTNESS - 1.0);

    // Contrast
    finalColor = (finalColor - 0.5) * CONTRAST + 0.5;

    // Saturation
    float luminance = dot(finalColor, vec3(0.2126, 0.7152, 0.0722)); // Standard Rec. 709 luminance
    vec3 grayscale = vec3(luminance);
    finalColor = mix(grayscale, finalColor, SATURATION);

    Fragcolor = vec4(sqrt(max(finalColor, 0.0)), 1.0);
    fragColor = Fragcolor; // Assign to the output parameter as well
}
