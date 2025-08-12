// Add precision qualifiers for floats and samplers
precision highp float;
precision highp int;
precision highp sampler2D;

// BCS adjustment parameters
#define BRIGHTNESS 0.4  // Default: 1.0 (no change), Range: 0.0 to 2.0
#define CONTRAST 1.025    // Default: 1.0 (no change), Range: 0.0 to 2.0
#define SATURATION 1.30  // Default: 1.0 (no change), Range: 0.0 to 2.0

/*
    Weaved 3D Truchet
    -----------------
    
    Mapping a square Truchet pattern onto an overlapping, interwoven hexagonal Truchet object... 
    or if you prefer a more lively description, it's an abstract representation of pythons. :) 
    I can thank BigWIngs's "Hexagonal Truchet Weaving" example for the idea to do this.

    I produced a relatively simple scene, just to give people an idea, but it's possible to
    create some really cool organic structures this way.

    Coding the main object wasn't particularly difficult, but bump mapping the square Truchet
    pattern onto it was a little tiresome. I originally applied the pattern directly to the 
    object via the distance field equation, but I don't think slower machines would have
    enjoyed running it. Therefore, I took the surface pattern outside the raymarching loop and 
    bump mapped it.    That, of course, added to the complexity, but sped things up considerably. 
    My fast machine    can run it in fullscreen fine, but the example was targetted toward the 
    800 by 450 canvas -- which I'm hoping average systems will be able to run it in.
 
    Procedurally speaking, this is just a 3D application of a standard hexagonal weave, which 
    I explained in my "Arbitrary Weave" example. For anyone interested in producing one, I'd 
    suggest starting with a 2D pattern, then taking it from there. Feel free to use this as a 
    guide, but I doubt it'll be needed.

    The comments, code and logic were a little rushed, so I'll get in and tidy it up in due 
    course.


    2D Weaved Truchet examples:

    // The original: Much less code, so if you're getting a handle on how to make
    // a random hexagonal weave pattern, this is the one you should be looking at.
    BigWIngs - Hexagonal Truchet Weaving 
    https://www.shadertoy.com/view/llByzz

    // My version of BigWIngs's example above. The code in this particular example was
    // based on it.
    Arbitrary Weave - Shane
    https://www.shadertoy.com/view/MtlBDs
*/

#define FAR 15.0

float objID = 0.0; // Object ID - Ground: 0; Truchet: 1.

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n ){
    
    n = max(abs(n), 0.001);
    n /= dot(n, vec3(1.0));
    vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
    
}


// Compact, self-contained version of IQ's 3D value noise function. I have a transparent noise
// example that explains it, if you require it.
float n3D(vec3 p){
    
    const vec3 s = vec3(7.0, 157.0, 113.0);
    vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0.0, s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3.0 - 2.0*p); //p *= p*p*(p*(p * 6.0 - 15.0) + 10.0);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}


// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z){ 
    return vec2(sin(z * 0.15)*2.4, 0.0);
}

// Standard float to float hash -- Based on IQ's original.
float hash(float n){ return fract(sin(n)*43758.5453); }


// Standard vec2 to float hash -- Based on IQ's original.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(141.187, 289.973)))*43758.5453); }


// vec2 to vec2 hash.
vec2 hash22(vec2 p) { 
    float n = sin(dot(p, vec2(41.0, 289.0)));
    return fract(vec2(262144.0, 32768.0)*n); 
}

// Smooth maximum, based on IQ's smooth minimum.
float smax(float a, float b, float s){
    float h = clamp(.5 + .5*(a - b)/s, 0.0, 1.0);
    return mix(b, a, h) + h*(1.0 - h)*s;
}

// Helper vector. If you're doing anything that involves regular triangles or hexagons, the
// 30-60-90 triangle will be involved in some way, which has sides of 1, sqrt(3) and 2.
const vec2 s = vec2(1.0, 1.7320508);

// This function returns the hexagonal grid coordinate for the grid cell, and the corresponding 
// hexagon cell ID -- in the form of the central hexagonal point.
vec4 getHex(vec2 p){
    vec4 hC = floor(vec4(p, p - vec2(.5, 1.0))/s.xyxy) + vec4(.5, .5, 1.0, 1.5);
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + vec2(0.0, -.5))*s );
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw);
}

// Very basic square Truchet routine.
float sTruchet(vec2 p){
    vec2 ip = floor(p);
    float rnd = hash21(ip);
    p -= ip + .5;
    p.y *= (rnd >.5)? -1.0 : 1.0;
    p = p.x>-p.y ? p : -p; 
    float d = abs(length(p - .5) - .5) - .15;
    return mix(max(-d, 0.0)*.35, smoothstep(0.0, .125, d), .5);
}

// Poloidal distance function.
float polDist(vec2 p){
    return length(p);
}

// Toroidal distance function.
float torDist(vec2 p){
    return length(p);
}

// Shade, pattern and random ID globals.
vec4 gHgt, gA, gA2, gD;

vec4 Truchet(vec2 p){
    gHgt = vec4(0.0);
    vec4 h = getHex(p);
    vec2 rnd = hash22(h.zw + .673);
    p = h.xy;
    const float rSm = .8660254/3.0;
    const float rLg = .8660254;
    float a;
    float rFactor = floor(rnd.x*6.0)*3.14159265/3.0;
    p = r2(rFactor)*p;
    float hDir = rnd.y>.5? -1.0: 1.0;
    vec4 d;
    vec2 p1, p2, p3;
    p1 = p - vec2(1.0, 0.0); 
    a = atan(p1.y, p1.x);
    gA.x = a*3.0;
    d.x = torDist(p1) - rLg;
    d.x = abs(d.x);
    gHgt.x = (cos(a*6.0) + 1.0)*.05*hDir;
    p2 = p - r2(3.14159265/3.0)*vec2(1.0, 0.0);
    a = atan(p2.y, p2.x);
    gA.y = a*3.0;
    d.y = torDist(p2) - rLg;
    d.y = abs(d.y);
    gHgt.y = -(cos(a*6.0) + 1.0)*.05*hDir;
    p3 = p - r2(-3.14159265/3.0)*vec2(0.0, .57735);
    a = atan(p3.y, p3.x);
    gA.z = a;
    d.z = torDist(p3) - rSm;
    d.z = abs(d.z);
    return d;
}

// Distance field function.
float m(vec3 p){
    p.y += 1.5;
    float fl = .25 + p.y;
    const float sc = 1.0;
    vec4 d = Truchet(p.xz*sc);
    d.x = polDist(vec2(d.x/sc, p.y + gHgt.x));
    d.y = polDist(vec2(d.y/sc, p.y + gHgt.y));    
    d.z = polDist(vec2(d.z/sc, p.y + gHgt.z));  
    d.xyz -= .16/sc;
    gD = d;
    float ob = min(min(d.x, d.y), d.z);
    fl = smax(fl, -ob*2.0, .5) - .2;
    objID = fl<ob? 0.0 : 1.0;
    return min(fl, ob);
}

// This is an exact duplicate of the distance function with some "atan" calculations.
float m2(vec3 p){
    p.y += 1.5;
    float fl = .25 + p.y;
    const float sc = 1.0;
    vec4 d = Truchet(p.xz*sc);
    gA2.x = atan(p.y + gHgt.x, d.x/sc);
    gA2.y = atan(p.y + gHgt.y, d.y/sc);
    gA2.z = atan(p.y + gHgt.z, d.z/sc);
    d.x = polDist(vec2(d.x/sc, p.y + gHgt.x));
    d.y = polDist(vec2(d.y/sc, p.y + gHgt.y));    
    d.z = polDist(vec2(d.z/sc, p.y + gHgt.z));  
    d.xyz -= .16/sc;
    gD = d;
    float ob = min(min(d.x, d.y), d.z);
    fl = smax(fl, -ob*2.0, .5) - .2;
    objID = fl<ob? 0.0 : 1.0;
    return min(fl, ob);
}

// The bump function.
float bumpFunc(vec3 p, vec3 n){
    float d = m2(p);
    float c = 0.0;
    if(objID<.5) {      
        c = sTruchet(p.xz*6.0);
    }
    else {
        float a;
        float a2;
        if(gD.x<gD.y && gD.x<gD.z){
            a = gA.x;
            a2 = gA2.x;
        }
        else if(gD.y<gD.z){
            a = gA.y;
            a2 = gA2.y;
        }
        else {
            a = gA.z;
            a2 = gA2.z;
        }
        c = sTruchet(vec2(a2*8.0, a*12.0)/6.283);
    }
    return c;
}

// Standard function-based bump mapping function with some edging thrown into the mix.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor, inout float edge, inout float crv){
    vec2 e = vec2(1.0/iResolution.y, 0.0); 
    float f = bumpFunc(p, n);
    float fx = bumpFunc(p - e.xyy, n);
    float fy = bumpFunc(p - e.yxy, n);
    float fz = bumpFunc(p - e.yyx, n);
    float fx2 = bumpFunc(p + e.xyy, n);
    float fy2 = bumpFunc(p + e.yxy, n);
    float fz2 = bumpFunc(p + e.yyx, n);
    vec3 grad = vec3(fx - fx2, fy - fy2, fz - fz2)/(e.x*2.0);  
    edge = abs(fx + fy + fz + fx2 + fy2 + fz2 - 6.0*f);
    edge = smoothstep(0.0, 1.0, edge/e.x*2.0);
    grad -= n*dot(n, grad);            
    return normalize(n + grad*bumpfactor);
}

// Standard normal function.
vec3 nr(in vec3 p) {
    const vec2 e = vec2(0.002, 0.0);
    return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy), m(p + e.yyx) - m(p - e.yyx)));
}

// Cheap shadows.
float shad(vec3 ro, vec3 lp, float k, float t){
    const int maxIterationsShad = 24; 
    vec3 rd = lp - ro;
    float shade = 1.0;
    float dist = .001*(t*.125 + 1.0);
    float end = max(length(rd), 0.0001);
    rd /= end;
    for (int i=0; i<maxIterationsShad; i++){
        float h = m(ro + rd*dist);
        shade = min(shade, smoothstep(0.0, 1.0, k*h/dist));
        dist += clamp(h, .01, .2); 
        if (h<0.0 || dist > end) break; 
    }
    return min(max(shade, 0.0), 1.0); 
}

// Ambient occlusion.
float cAO(in vec3 p, in vec3 n)
{
    float sca = 1.0, occ = 0.0;
    for(float i=0.0; i<5.0; i++){
        float hr = .01 + i*.5/4.0;          
        float dd = m(n * hr + p);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0.0, 1.0);     
}

// Standard hue rotation formula.
vec3 rotHue(vec3 p, float a){
    vec2 cs = sin(vec2(1.570796, 0.0) + a);
    mat3 hr = mat3(0.299,  0.587,  0.114,  0.299, 0.587,  0.114,  0.299,  0.587,  0.114) +
              mat3(0.701, -0.587, -0.114, -0.299,  0.413, -0.114, -0.300, -0.588,  0.886) * cs.x +
              mat3(0.168,  0.330, -0.497, -0.328,  0.035,  0.292,  1.250, -1.050, -0.203) * cs.y;
    return clamp(p*hr, 0.0, 1.0);
}

// Simple environment mapping.
vec3 eMap(vec3 rd, vec3 sn){
    vec3 sRd = rd;
    rd.xy -= iTime*.25;
    rd *= 3.0;
    float c = n3D(rd)*.57 + n3D(rd*2.0)*.28 + n3D(rd*4.0)*.15;
    c = smoothstep(0.5, 1.0, c);
    vec3 col = pow(vec3(1.5, 1.0, 1.0)*c, vec3(1.0, 2.5, 12.0)).zyx;
    return mix(col, col.yzx, sRd*.25 + .25); 
}

// Standard Shadertoy entry point
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 u = (fragCoord - iResolution.xy*.5) / iResolution.y;
    vec3 lk = vec3(0.0, 0.0, iTime*.10);  // Adjusted to slow animation
    vec3 o = lk + vec3(0.0, .3, -.25);
    vec3 l = o + vec3(0.0, .5, 2.0);
    lk.xy += path(lk.z);
    o.xy += path(o.z);
    l.xy += path(l.z);
    float FOV = 3.14159/3.0;
    vec3 forward = normalize(lk-o);
    vec3 right = normalize(vec3(forward.z, 0.0, -forward.x)); 
    vec3 up = cross(forward, right);
    vec3 r = normalize(forward + FOV*u.x*right + FOV*u.y*up);
    float d, t = 0.0;
    for(int i=0; i<96;i++){
        d = m(o + r*t);
        if(abs(d)<.001*(t*.125 + 1.0) || t>FAR) break;
        t += d;
    }
    t = min(t, FAR);
    float svID = objID;
    vec3 col = vec3(0.0);
    if(t<FAR){
        vec3 p = o + r*t, n = nr(p);
        float edge2 = 0.0, crv2 = 1.0, bf = .25; 
        n = doBumpMap(p, n, bf, edge2, crv2);
        float sh = shad(p + n*.002, l, 16.0, t);
        float ao = cAO(p, n);
        l -= p;
        d = max(length(l), 0.001);
        l /= d;
        float txSc = .5;
        vec3 tx = tex3D(iChannel0, (p*txSc), n);
        tx = smoothstep(0.0, .5, tx);
        col = tx;
        float fBm = n3D(p*128.0)*.66 + n3D(p*256.0)*.34;
        col *= mix(vec3(0.0), vec3(1.0), fBm*2.0*.5 + .5);
        if(svID>.5){
            col *= mix(vec3(2.0, 1.0, .3), vec3(.1, 0.0, 0.0), bumpFunc(p, n)*1.5);
        }
        else {
            col *= vec3(.8, .6, .4);
        }
        float df = max(dot(l, n), 0.0);
        df = pow(df, 4.0)*2.0;
        float sp = pow(max(dot(reflect(-l, n), -r), 0.0), 32.0);
        col = col*(df + .5*ao) + vec3(1.0, .97, .92)*sp*2.0;
        vec3 em = eMap(reflect(r, n), n);
        col += em*1.5;
        col *= 1.0 - edge2*.65;
        col *= 1.0/(1.0 + d*d*.1);
        col *= (sh + ao*.3)*ao;
    }
    vec3 fogCol = vec3(0.0);
    col = mix(col, fogCol, smoothstep(0.0, .95, t/FAR));
    u = fragCoord/iResolution.xy;
    col = mix(col, vec3(0.0), (1.0 - pow(16.0*u.x*u.y*(1.0-u.x)*(1.0-u.y), 0.25))*.5);

    // Apply BCS adjustments
    col = ((col - 0.5) * max(CONTRAST, 0.0) + 0.5) * BRIGHTNESS;
    vec3 luminance = vec3(0.299, 0.587, 0.114);
    float luma = dot(col, luminance);
    col = mix(vec3(luma), col, SATURATION);

    fragColor = vec4(pow(col, vec3(1.0/2.2)), 1.0);
}