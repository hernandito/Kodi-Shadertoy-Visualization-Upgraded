// Add precision for GLSL ES 1.00 
precision mediump float;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .0005
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(iResolution.y,iResolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define Tri(p,s,a) max(-dot(p,vec2(cos(-a),sin(-a))),max(dot(p,vec2(cos(a),sin(a))),max(abs(p).x-s.x,abs(p).y-s.y)))
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )
#define ZERO 0 // Changed from (min(iFrame,0)) to a constant 0 for Kodi compatibility

// New Post-Processing Parameters
#define BRIGHTNESS 1.0     // Adjusts overall brightness (1.0 for neutral)
#define SATURATION 1.4     // Adjusts color intensity (1.0 for neutral, 0.0 for grayscale)
#define POST_CONTRAST 1.3  // Adjusts contrast (1.0 for neutral, >1.0 for more contrast)


float Hash21(vec2 p) {
    p = fract(p*vec2(234.56,789.34));
    p+=dot(p,p+34.56);
    return fract(p.x+p.y);
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdTorus( vec3 p, vec2 t )
{
    vec2 q = vec2(length(p.xy)-t.x,p.z);
    return length(q)-t.y;
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// thx iq! https://iquilezles.org/articles/distfunctions/
// tweaked as the center aligned horizontal capsule. 
float sdHorizontalCapsule( vec3 p, float w, float r )
{
  p.x-= clamp( p.x, -w*0.5, w*0.5 );
  return length( p ) - r;
}

float speaker(vec3 p){
    vec3 prevP = p;
    float d = sdBox(p, vec3(0.45,0.95,0.34))-0.03;
    float d2 = length(p-vec3(0.,-0.2,-0.53))-0.38;
    
    d = max(-d2,d);
    
    d2 = sdTorus(p-vec3(0.,-0.2,-0.36),vec2(0.36,0.03));
    d = min(d,d2);
    
    d2 = sdTorus(p-vec3(0.,-0.2,-0.32),vec2(0.32,0.025));
    d = min(d,d2);
    d2 = length(p-vec3(0.,-0.25,-0.08))-0.12;
    d = min(d,d2);
    
    d2 = sdHorizontalCapsule(p-vec3(0.,-0.75,-0.36),0.6,0.06);
    d = max(-d2,d);
    
    d2 = length(p-vec3(0.,0.55,-0.36))-0.2;
    d = max(-d2,d);
    
    d2 = sdTorus(p-vec3(0.,0.55,-0.36),vec2(0.2,0.03));
    d = min(d,d2);
    
    p.z-=-0.36;
    p.x = abs(p.x)-0.4;
    p.y = abs(p.y)-0.9;
    d2 = length(p)-0.03;
    d = min(d,d2);
    
    return d;
}

float speaker2(vec3 p){
    vec3 prevP = p;
    float d = sdBox(p, vec3(0.95,0.45,0.34))-0.03;
    float d2 = sdBox(p-vec3(0.,0.,-0.35), vec3(0.9,0.4,0.01))-0.03;
    d = max(-d2,d);
    
    p.x = abs(p.x);
    d2 = length(p-vec3(0.4,0.,-0.5))-0.36;
    d = max(-d2,d);
    
    d2 = sdTorus(p-vec3(0.4,0.,-0.3),vec2(0.34,0.03));
    d = min(d,d2);
    
    d2 = sdTorus(p-vec3(0.4,0.,-0.29),vec2(0.3,0.025));
    d = min(d,d2);
    d2 = length(p-vec3(0.45,0.,-0.08))-0.1;
    d = min(d,d2);
    
    p.z-=-0.3;
    p.x = abs(p.x)-0.86;
    p.y = abs(p.y)-0.36;
    d2 = length(p)-0.03;
    d = min(d,d2);     
    
    return d;
}

float speaker3(vec3 p){
    vec3 prevP = p;
    float d = sdBox(p, vec3(0.95,0.95,0.34))-0.03;
    
    float d2 = length(p-vec3(0.0,0.,-0.68))-0.66;
    d = max(-d2,d);
    
    d2 = sdTorus(p-vec3(0.0,0.,-0.35),vec2(0.64,0.05));
    d = min(d,d2);
    
    d2 = sdTorus(p-vec3(0.0,0.,-0.33),vec2(0.6,0.045));
    d = min(d,d2);
    
    d2 = length(p-vec3(0.0,0.,0.1))-0.2;
    d = min(d,d2);
    
    d2 = sdTorus(p-vec3(0.0,0.,-0.3),vec2(0.56,0.035));
    d = min(d,d2);     
    
    d2 = sdTorus(p-vec3(0.0,0.,-0.24),vec2(0.52,0.035));
    d = min(d,d2);          
            
    d2 = sdTorus(p-vec3(0.0,0.,-0.19),vec2(0.47,0.035));
    d = min(d,d2);  
    
    d2 = abs(length(p.xy)-0.73)-0.07;
    d = min(d,max((abs(p.z)-0.38),d2));
    
    p.z-=-0.37;
    p.x = abs(p.x)-0.86;
    p.y = abs(p.y)-0.86;
    d2 = length(p)-0.03;
    d = min(d,d2);      
    
    p = prevP;
    p.z-=-0.37;
    p.xy = DF(p.xy,3.0);
    p.xy -= vec2(0.52);
    d2 = length(p)-0.03;
    d = min(d,d2);  
    
    p = prevP;
    p.xy*=Rot(radians(sin(iTime*.2)*120.));
    p.z-=-0.37;
    p.y=abs(p.y)-0.93;
    d2 = Tri(p.xy,vec2(0.08),radians(45.));
    d = min(d,max((abs(p.z)-0.02),d2));     
    
    p = prevP;
    p.xy*=Rot(radians(90.+sin(iTime*.2)*120.));
    p.z-=-0.37;
    p.y=abs(p.y)-0.93;
    d2 = Tri(p.xy,vec2(0.08),radians(45.));
    d = min(d,max((abs(p.z)-0.02),d2));        
    
    return d;
}

float changeSpeakers(vec3 p, float start, float speed){
    float endTime = 3.0; 
    float t_anim = iTime*.2 * speed; 
    
    float current_scene_value = mod(floor(t_anim) + start, endTime);
    
    float d = 10.0; 
    if(current_scene_value < 1.0) { 
        p.x=abs(p.x)-0.5;
        d = speaker(p);
    } else if (current_scene_value >= 1.0 && current_scene_value < 2.0){
        p.y=abs(p.y)-0.5;
        d = speaker2(p);
    } else { 
        d = speaker3(p);
    }
    
    return d;
}

vec2 GetDist(vec3 p) {
    vec3 prevP = p;
    
    p.y -=iTime*.2*0.5;
    vec2 id = floor(p.xy*0.5);
    p.z-=3.;
    p.xy = mod(p.xy,2.0)-1.0;

    id*=.5;
    float rand = Hash21(id);
    
    float d = 10.;
    p.z-=rand*0.3;
    if(rand<0.3) {
        d = changeSpeakers(p,1.,0.5+rand);
    } else if(rand>=0.3 && rand<0.7) {
        d = speaker3(p);
    } else {
        p.x=abs(p.x)-0.5;
        d = speaker(p);
    }
    
    return vec2(d,0);
}

vec2 RayMarch(vec3 ro, vec3 rd, float side, int stepnum) {
    vec2 dO = vec2(0.0);
    
    for(int i=0; i<stepnum; i++) {
        vec3 p = ro + rd*dO.x;
        vec2 dS = GetDist(p);
        dO.x += dS.x*side;
        dO.y = dS.y;
        
        if(dO.x>MAX_DIST || abs(dS.x)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).x;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).x,
        GetDist(p-e.yxy).x,
        GetDist(p-e.yyx).x);
    
    return normalize(n);
}

// https://www.shadertoy.com/view/3lsSzf
float calcOcclusion( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<4; i++ ) // ZERO is now a constant 0
    {
        float h = 0.01 + 0.15*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = GetDist( opos ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}


vec3 diffuseMaterial(vec3 n, vec3 rd, vec3 p, vec3 col) {
    float occ = calcOcclusion(p,n);
    vec3 diffCol = vec3(0.0);
    vec3 lightDir = normalize(vec3(1,10,-10));
    float diff = clamp(dot(n,lightDir),0.0,1.0);
    float shadow = step(RayMarch(p+n*0.3,lightDir,1.0, 15).x,0.9);
    float skyDiff = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.0,1.0);
    float bounceDiff = clamp(0.5+0.5*dot(n,vec3(0,-1,0)),0.0,1.0);
    diffCol = col*vec3(-0.5)*diff*shadow*occ;
    diffCol += col*vec3(1.0,0.90,0.7)*skyDiff*occ;
    diffCol += col*vec3(0.1,0.1,0.1)*bounceDiff*occ;
    diffCol += col*pow(max(dot(rd, reflect(lightDir, n)), 0.0), 60.)*occ; // spec

    return diffCol;
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col){
    col = diffuseMaterial(n,rd,p,vec3(1.3));
    return col;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p);
    // Explicit float literals for vec3 constructor to avoid type interpretation issues
    vec3 r = normalize(cross(vec3(0.0, 1.0, 0.0), f));
    vec3 u = cross(f, r);
    vec3 c = p + f * z;
    vec3 i = c + uv.x * r + uv.y * u;
    vec3 d = normalize(i - p);
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    vec2 prevUV = uv;
    vec2 m =  iMouse.xy/iResolution.xy;
    
    vec3 ro = vec3(0, 0, -1.5);
    if(iMouse.z>0.){
        ro.yz *= Rot(m.y*3.14+1.);
        ro.y = max(-0.9,ro.y);
        ro.xz *= Rot(-m.x*6.2831);
    } else {
        float scene = mod(iTime*.2,15.);
        float rotY = -10.;
        float rotX = 0.;
        if(scene>=5. && scene<10.){
            rotY = 0.;
            rotX = -30.;
        } else if(scene>=10.){
            rotY = 0.;
            rotX = 30.;
        }
        
        ro.yz *= Rot(radians(rotY));
        ro.xz *= Rot(radians(rotX));
    }
    
    vec3 rd = R(uv, ro, vec3(0.0,0.0,0.0), 1.0); 
    vec2 d = RayMarch(ro, rd, 1.,MAX_STEPS);
    vec3 col = vec3(.0);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        int mat = int(d.y);
        col = materials(mat,n,rd,p,col);
    }
    
    // Original gamma correction
    col = pow( col, vec3(0.9545) );     

    // Apply BCS post-processing
    // Brightness
    col *= BRIGHTNESS;
    // Saturation (mix between grayscale and original color)
    col = mix(vec3(dot(col, vec3(0.2126, 0.7152, 0.0722))), col, SATURATION);
    // Contrast (adjust around 0.5 gray level)
    col = (col - 0.5) * POST_CONTRAST + 0.5;

    fragColor = vec4(sqrt(col),1.0);
}
