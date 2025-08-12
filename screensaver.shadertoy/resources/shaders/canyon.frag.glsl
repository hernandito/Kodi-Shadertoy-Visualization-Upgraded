// Add precision qualifiers for floats and samplers
precision highp float;
precision highp int;
precision highp sampler2D;

/*
    Canyon Pass
    -----------

    Combining some cheap distance field functions with some functional and texture-based bump 
    mapping to carve out a rocky canyon-like passageway.

    There's nothing overly exciting about this example. I was trying to create a reasonably
    convincing looking rocky setting using cheap methods.

    I added in some light frosting, mainly to break the monotony of the single colored rock.
    There's a mossy option below, for anyone interested. Visually speaking, I find the moss more
    interesting, but I thought the frost showed the rock formations a little better. Besides,
    I'd like to put together a more dedicated greenery example later.
*/

// Animation and BCS adjustment parameters
#define ANIMATION_SPEED .1  // Global animation speed multiplier (default 1.0)
#define BRIGHTNESS 0.90      // Default: 1.0 (no change), Range: 0.0 to 2.0
#define CONTRAST 1.1        // Default: 1.0 (no change), Range: 0.0 to 2.0
#define SATURATION 1.0      // Default: 1.0 (no change), Range: 0.0 to 2.0
#define FOV 2.333           // Field of View (default 1.333, increase for wider view)

#define PI 3.14159265
#define FAR 60.

// Rotation matrix.
const mat2 rM = mat2(.7071, .7071, -.7071, .7071); 

// 2x2 matrix rotation.
mat2 rot2(float a){ vec2 v = sin(vec2(1.570796, 0) + a); return mat2(v, -v.y, v.x); }

// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D channel, vec3 p, vec3 n){
    n = max(abs(n) - .2, 0.001);
    n /= dot(n, vec3(1));
    vec3 tx = texture(channel, p.zy).xyz;
    vec3 ty = texture(channel, p.xz).xyz;
    vec3 tz = texture(channel, p.xy).xyz;
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
}

// Cellular tile setup.
float drawObject(in vec3 p){
    p = fract(p)-.5;
    return dot(p, p);
}

// 3D cellular tile function.
float cellTile(in vec3 p){
    vec4 d; 
    d.x = drawObject(p - vec3(.81, .62, .53));
    p.xy *= rM;
    d.y = drawObject(p - vec3(.6, .82, .64));
    p.yz *= rM;
    d.z = drawObject(p - vec3(.51, .06, .70));
    p.zx *= rM;
    d.w = drawObject(p - vec3(.12, .62, .64));
    d.xy = min(d.xz, d.yw);
    return min(d.x, d.y)*2.5;
}

// The triangle function.
vec3 tri(in vec3 x){return abs(fract(x)-.5);}

// The path is a 2D sinusoid.
vec2 path(in float z){
    float a = sin(z * 0.11);
    float b = cos(z * 0.14);
    return vec2(a*4. -b*1.5, b*1.7 + a*1.5);
}

// A fake noise looking sinusoidal field.
float map(vec3 p){
    p.xy -= path(p.z);
    vec3 w = p;
    vec3 op = tri(p*.4*3. + tri(p.zxy*.4*3.));
    float ground = p.y + 3.5 + dot(op, vec3(.222))*.3;
    p += (op - .25)*.3;
    p = cos(p*.315*1.41 + sin(p.zxy*.875*1.27));
    float canyon = (length(p) - 1.05)*.95 - (w.x*w.x)*.01;
    return min(ground, canyon);
}

// Surface bump function.
float bumpSurf3D(in vec3 p, in vec3 n){
    return cellTile(p/1.5);
}

// Standard function-based bump mapping function.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor){
    const vec2 e = vec2(0.001, 0);
    float ref = bumpSurf3D(p, nor);                 
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy, nor),
                      bumpSurf3D(p - e.yxy, nor),
                      bumpSurf3D(p - e.yyx, nor) )-ref)/e.x;                     
    grad -= nor*dot(nor, grad);          
    return normalize(nor + grad*bumpfactor);
}

// Texture bump mapping.
vec3 doBumpMap(sampler2D tx, in vec3 p, in vec3 n, float bf){
    const vec2 e = vec2(0.001, 0);
    mat3 m = mat3(tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    vec3 g = vec3(0.299, 0.587, 0.114)*m;
    g = (g - dot(tex3D(tx, p, n), vec3(0.299, 0.587, 0.114)))/e.x; g -= n*dot(n, g);
    return normalize(n + g*bf);
}

float accum;

// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){
    accum = 0.;
    float t = 0.0, h;
    for(int i = 0; i < 160; i++){
        h = map(ro+rd*t);
        if(abs(h)<0.001*(t*.25 + 1.) || t>FAR) break;
        t += h;
        if(abs(h)<0.25) accum += (.25-abs(h))/24.;
    }
    return min(t, FAR);
}

// Ambient occlusion.
float calculateAO(in vec3 p, in vec3 n){
    float sca = 1., occ = 0.;
    for(float i=0.; i<5.; i++){
        float hr = .01 + i*.5/4.;        
        float dd = map(n * hr + p);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0., 1.);    
}

// Tetrahedral normal.
vec3 calcNormal(in vec3 p){
    vec2 e = vec2(0.001, -0.001); 
    return normalize(e.xyy*map(p + e.xyy) + e.yyx*map(p + e.yyx) + e.yxy*map(p + e.yxy) + e.xxx*map(p + e.xxx));
}

// Shadows.
float shadows(in vec3 ro, in vec3 rd, in float start, in float end, in float k){
    float shade = 1.0;
    const int shadIter = 24; 
    float dist = start;
    for (int i=0; i<shadIter; i++){
        float h = map(ro + rd*dist);
        shade = min(shade, k*h/dist);
        dist += clamp(h, 0.02, 0.2);
        if ((h)<0.001 || dist > end) break; 
    }
    return min(max(shade, 0.) + 0.0, 1.0); 
}

// Very basic pseudo environment mapping.
vec3 envMap(vec3 rd, vec3 n){
    return tex3D(iChannel0, rd, n);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (fragCoord - iResolution.xy*0.5)/iResolution.y;
    vec3 camPos = vec3(0.0, 0.0, iTime*4.*ANIMATION_SPEED);
    vec3 lookAt = camPos + vec3(0, 0, 0.25);
    vec3 lightPos = camPos + vec3(-10, 20, -20);
    lookAt.xy += path(lookAt.z);
    camPos.xy += path(camPos.z);
    vec3 forward = normalize(lookAt-camPos);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x)); 
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);
    rd.xy = rot2(path(lookAt.z).x/16.)*rd.xy;
    float t = trace(camPos, rd);   
    vec3 sceneCol = vec3(0);
    if(t<FAR){
        vec3 sp = camPos + rd*t;
        vec3 sn = calcNormal(sp);
        vec3 snNoBump = sn;
        const float tSize0 = 1./2.;
        sn = doBumpMap(sp, sn, .5);
        sn = doBumpMap(iChannel0, sp*tSize0, sn, .1);
        vec3 ld = lightPos - sp;
        float lDist = max(length(ld), 0.001);
        ld /= lDist;
        float shading = shadows(sp + sn*.005, ld, .05, lDist, 8.);
        float ao = calculateAO(sp, sn);
        float atten = 1./(1. + lDist*.007);
        float diff = max(dot(sn, ld), 0.0);
        float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.0), 32.);
        float fre = pow(clamp(dot(sn, rd) + 1., 0., 1.), 1.);
        float ambience = 0.35*ao + fre*fre*.25;
        vec3 texCol = tex3D(iChannel0, sp*tSize0, sn);
        texCol = mix(texCol, vec3(.35, .55, 1)*(texCol*.5+.5)*vec3(2), ((snNoBump.y*.5 + sn.y*.5)*.5+.5)*pow(abs(sn.y), 4.)*texCol.r*fre*4.);
        sceneCol = texCol*(diff + spec + ambience);
        sceneCol += texCol*((sn.y)*.5+.5)*min(vec3(1, 1.15, 1.5)*accum, 1.);  
        sceneCol += texCol*vec3(.8, .95, 1)*pow(fre, 4.)*.5;
        vec3 sn2 = snNoBump*.5 + sn*.5;
        vec3 ref = reflect(rd, sn2);
        vec3 em = envMap(ref/2., sn2);
        ref = refract(rd, sn2, 1./1.31);
        vec3 em2 = envMap(ref/8., sn2);
        sceneCol += sceneCol*2.*(sn.y*.25+.75)*mix(em2, em, pow(fre, 4.));
        sceneCol *= atten*min(shading + ao*.35, 1.)*ao;
    }
    vec3 fog = vec3(.6, .8, 1.2)*(rd.y*.5 + .5);
    sceneCol = mix(sceneCol, fog, smoothstep(0., .95, t/FAR));
    uv = fragCoord/iResolution.xy;
    sceneCol = mix(vec3(0, .1, 1), sceneCol, pow(16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), .125)*.15 + .85);

    // Apply BCS adjustments
    sceneCol = ((sceneCol - 0.5) * max(CONTRAST, 0.0) + 0.5) * BRIGHTNESS;
    vec3 luminance = vec3(0.299, 0.587, 0.114);
    float luma = dot(sceneCol, luminance);
    sceneCol = mix(vec3(luma), sceneCol, SATURATION);

    fragColor = vec4(sqrt(clamp(sceneCol, 0., 1.)), 1.0);
}