#define P 6.283185307
const float div = 4.9, spiralspeed = P/35.;
vec3 c, map;
float t, roomId;
int matid=0, doorpart=0;

// --- Color Parameters ---
#define COLOR_BLACK     vec3(.00, 0.0, 0.0)      // Adjust this for the darker base color
#define COLOR_WHITE_GRAY vec3(1, 0.949, 0.765)  // Adjust this for the lighter base color
// --- End Color Parameters ---

mat2 rot(in float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

float box(in vec3 p, in vec3 s, in float r) { return length(max(abs(p) - s,0.)) - r; }
float box(in vec2 p, in vec2 s) { p = abs(p) - s; return max(p.x,p.y); }
float cyl(in vec3 p, in float h, in float r) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.) + length(max(d,0.));
}

float door(in vec3 p, in vec3 s, in float opened) {
    p.x -= s.x; p.xz *= rot(opened); p.x += s.x;
    float ddbis = -max(box(vec3(p.x, mod(abs(p.y + .2) - .2, 1.285) - .6425, abs(p.z) - .03), s*vec3(1.,.5,1.), .01), box(p, s*vec3(.725,.85,1.), .02));
    float dd = box(p, s, .01);
    p.z = abs(p.z); p.x += .435;
    float ddd = min(length(max(abs(vec2(length(p.xy) - .012, p.z - .075)) - vec2(.01,.0),0.)) - .015, length(max(abs(vec2(length(p.xy) - .01, p.z - .012)) - vec2(.02,.0),0.)) - .015);
    ddd = min(ddd, cyl(p.yzx, .015, .075));
    float d = min(max(dd, ddbis), ddd);
    doorpart = d == dd ? 1 : 0;
    return d;
}

float df(in vec3 p) {
    p.xy *= rot(cos(p.z*spiralspeed)*1.75);
    
    float pz = p.z;
    float Pz = floor(p.z/div + .4)*div;
    roomId = floor(p.z/div + .5);
    p.z = mod(pz, div) - div*.5;
    
    float pz2 = pz/(div*2.) + 0.24 ;
    p.xy = mix(p.xy,p.yx,mod(floor(pz2),2.))*sign(mod(floor(pz2 + .5),2.) - .5);
    map = p;
    
    const vec3 doorSize = vec3(.5, 1.125, .01);
    float wall = box(p.xy, vec2(1.5));
    p.y += doorSize.y/3.;
    
    float dap = abs(Pz - c.z + div/2.);
    float door = door(p, doorSize, P*.35*(cos(clamp( (dap*dap*dap)*.0125 ,-3.14,3.14))*.5 + .5));
    
    float endwall = abs(p.z) - .01;

    float plaintesFond = max(endwall, p.y + 1.05) - .025;
    float doorShape = box(p.xy, doorSize.xy);
    float doorShapeExtr = max(doorShape - .05, abs(p.z) - .035);
    float walls = min(abs(wall) - .01, max(max(endwall, min(min(endwall, doorShapeExtr), plaintesFond)),  -doorShape));
        
    float plaintes = max(-wall, p.y + 1.02) - .025;
    
    float d = min(min(walls, door), plaintes);
    
    matid = d == plaintesFond || d == doorShapeExtr ? 3 : d == door ? 1 : d == walls  ? 2 : 3;
    
    return d;
}

#define LIM .001
#define MAX_D 20.
#define MAX_IT 50
struct rmRes { vec3 pos; int it; bool hit; };
rmRes rm(in vec3 c, in vec3 r) {
    vec3 p = c;
    int it;
    bool hit = false;
    for(int i = 0; i < MAX_IT; i++) {
        float d = df(p);
        if(d < LIM) { hit = true; break; }
        if(distance(c,p) > MAX_D) break;
        p += d*r;
        it = i;
    }
    rmRes res;
    res.pos = p;
    res.it = it;
    res.hit = hit;
    return res;
}

vec3 plane2sphere(in vec2 p) {
    float t = -4./(dot(p,p) + 4.);
    return vec3(-p*t, 1. + 2.*t);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 st = (fragCoord.xy - iResolution.xy*.5)/iResolution.x;
    t = iTime < 0.01 ? 98. : -iTime*.25 ;
        
    c = vec3(0.,0.,t);
    vec3 r = -plane2sphere(st*5.);
    r.xz *= rot(cos(t*spiralspeed/3.)*.75);
    r.xy *= rot(-cos(t*spiralspeed)*1.75);

    rmRes res = rm(c,r);
    
    // Original base colors are now controlled by defines
    vec3 n = COLOR_BLACK;
    vec3 b = COLOR_WHITE_GRAY;

    float whichroom = step(.5,fract(roomId/2.));
    vec3 c1 = mix(n,b,whichroom), c2 = mix(b,n,whichroom);
    vec3 color = c2;
    
    if(res.hit)
        if(matid == 1) color = doorpart == 1 ? c2 : c1;
        else if(matid == 2) color = c2;
        else {
            if(map.y < -1.45) {
                if(map.z > .1 || map.z < 0.) {
                    map.xz *= rot(3.14*.25);
                    map.xz *= 10.;
                    color = mix(c1,c2,step(0.,cos(map.x)*cos(map.z)));         
                } else
                    color = c2;
            } else color = c1;
        }
    
    float l = length(st);
    fragColor = vec4(color - l*l*.5,1.0);
}