#define Rot(a)   mat2(cos(a - vec4(0,11,33,0)))
#define antialiasing(n) n/min(iResolution.y,iResolution.x)
#define S(d) 1.-smoothstep(-1.2,1.2, (d)*iResolution.y )
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define deg45 .707
#define R45(p) (( p + vec2(p.y,-p.x) ) *deg45)
#define Tri(p,s) max(R45(p).x,max(R45(p).y,B(p,s)))
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )
#define PUV(p)vec2(log(length(p)),atan(p.y/p.x))

// Define for the paper's median color
#define PAPER_COLOR vec3(0.9, 0.9, 0.85) // Example: a light, slightly warm gray for paper

// Define for the black lines color
#define LINE_COLOR vec3(.1,.1,.25) // Black color for the lines

// Define for global animation speed
#define GLOBAL_ANIMATION_SPEED 0.20 // Adjust this value to control the overall animation speed


// Paper noise functions
float rand2(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 applyPaperNoise(vec3 color, vec2 uv, float intensity, float scale) {
    float noise = (rand2(uv * scale) - 0.5) * 0.07;
    return color + intensity * noise;
}


// thx, iq! https://iquilezles.org/articles/distfunctions2d/
float sdHexagon( in vec2 p, in float r )
{
    const vec3 k = vec3(-0.866025404,0.5,0.577350269);
    p = abs(p);
    p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
}

// Getting the hex uv logic from the Shane's implementation here: https://www.shadertoy.com/view/Xljczw
const vec2 s = vec2(1.7320508, 1);
vec4 getHex(vec2 p){
    vec4 hC = floor(vec4(p, p - vec2(1, .5))/s.xyxy) + .5;
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + .5);
}

float Hash21(vec2 p) {
    p = fract(p*vec2(234.56,789.34));
    p+=dot(p,p+34.56);
    return fract(p.x+p.y);
}

float stripe(vec2 p){
    p*=Rot(radians(30.));
    p+=iTime*0.1 * GLOBAL_ANIMATION_SPEED;
    p.x = mod(p.x,0.08)-0.04;
    float d = abs(p.x)-0.01;
    return d;
}

float dots(vec2 p){
    p*=Rot(radians(30.));
    p+=iTime*0.1 * GLOBAL_ANIMATION_SPEED;
    p = mod(p,0.08)-0.04;
    float d = length(p)-0.015;
    return d;
}

// principal value of logarithm of z
// https://gist.github.com/ikr7/d31b0ead87c73e6378e6911e85661b93
vec2 clog (vec2 z) {
    return vec2(log(length(z)), atan(z.y, z.x));
}

// The following code will return the Droste Zoom UV.
// by roywig https://www.shadertoy.com/view/Ml33R7
vec2 drosteUV(vec2 p){
    float speed = 0.25 * GLOBAL_ANIMATION_SPEED;
    float animate = mod(iTime*speed,2.07);
    float rate = sin(iTime*0.5 * GLOBAL_ANIMATION_SPEED);
    //p = clog(p)*mat2(1,.11,rate*0.5,1);
    p = clog(p);
    p = exp(p.x-animate) * vec2( cos(p.y), sin(p.y));
    vec2 c = abs(p);
    vec2 duv = .5+p*exp2(ceil(-log2(max(c.y,c.x))-2.));
    return duv;
}

vec2 pmod(vec2 p, float s, float space){
    float modVal = s*(2.0+space);
    p = mod(p,modVal)-(modVal*0.5);
    return p;
}

float drostePattern1(vec2 p, float s, float space){
    p*=Rot(radians(-20.*iTime * GLOBAL_ANIMATION_SPEED));
    p = drosteUV(p);
    p = pmod(p,s,space);
    float d = abs(sdHexagon(p,s))-0.015;
    return d;
}

float drostePattern2(vec2 p, float s, float space){
    p*=Rot(radians(20.*iTime * GLOBAL_ANIMATION_SPEED));
    p = drosteUV(p);
    p = pmod(p,s,space);
    p*=Rot(radians(45.));
    float d = abs(B(p,vec2(s*0.75)))-0.015;
    return d;
}

float drawHexTruchet(vec2 p){
    p.y-=iTime*0.1 * GLOBAL_ANIMATION_SPEED;
    p*=5.;
    p*=Rot(radians(90.));
    float thickness = 0.01;
    vec4 hgr = getHex(p);
    vec4 prevHgr = hgr;
    float n = Hash21(hgr.zw);
    
    vec2 gr = prevHgr.xy;
    float d = abs(sdHexagon(gr,0.5))-thickness;
    if(n<0.6){
        d = abs(gr.y)-thickness;
        d = max(gr.x,d);
        
        gr *= Rot(radians(60.));
        float d2 = max(-gr.x,abs(gr.y)-thickness);
        d = min(d,d2);

        gr = prevHgr.xy;
        gr *= Rot(radians(-60.));
        d2 = max(-gr.x,abs(gr.y)-thickness);
        d = min(d,d2);
            
        if(n<0.3){
            gr = prevHgr.xy;
            
            d2 = abs(length(gr-vec2(0.3,-0.52))-0.3)-thickness*3.;
            d = min(d,d2);
            
            d2 = abs(length(gr-vec2(-0.3,0.52))-0.3)-thickness*3.;
            d = min(d,d2);
            
            gr.x+=0.3;
            gr.y+=0.25;
            d2 = B(gr,vec2(0.15,thickness*3.));
            d = min(d,d2);
            gr = prevHgr.xy;
            
            gr.x+=0.22;
            gr.y+=0.12;
            gr*=Rot(radians(60.));
            d2 = B(gr,vec2(0.2,thickness*3.));
            gr = prevHgr.xy;
            gr.x+=0.1;
            gr.y+=0.33;
            d2 = max(-B(gr,vec2(0.2,0.05)),d2);
            gr = prevHgr.xy;
            gr.x+=0.15;
            gr.y-=0.08;
            d2 = max(-B(gr,vec2(0.2,0.05)),d2);
            d = min(d,d2);
            
            gr = prevHgr.xy;
            gr.x-=0.38;
            gr.y-=0.15;
            gr*=Rot(radians(-60.));
            d2 = B(gr,vec2(0.19,thickness*3.));
            d = min(d,d2);
            
            gr = prevHgr.xy;
            d2 = B(gr,vec2(0.31,thickness*3.));
            d = min(d,d2);
        } else {
            gr = prevHgr.xy;
            
            d2 = abs(length(gr-vec2(0.3,0.52))-0.3)-thickness*3.;
            d = min(d,d2);
            
            d2 = abs(length(gr-vec2(-0.3,-0.52))-0.3)-thickness*3.;
            d = min(d,d2);
            
            gr.x+=0.3;
            gr.y-=0.25;
            d2 = B(gr,vec2(0.15,thickness*3.));
            d = min(d,d2);
            gr = prevHgr.xy;
            
            gr.x+=0.22;
            gr.y-=0.12;
            gr*=Rot(radians(-60.));
            d2 = B(gr,vec2(0.2,thickness*3.));
            gr = prevHgr.xy;
            gr.x+=0.1;
            gr.y-=0.33;
            d2 = max(-B(gr,vec2(0.2,0.05)),d2);
            gr = prevHgr.xy;
            gr.x+=0.15;
            gr.y+=0.08;
            d2 = max(-B(gr,vec2(0.2,0.05)),d2);
            d = min(d,d2);
            
            gr = prevHgr.xy;
            gr.x-=0.38;
            gr.y+=0.15;
            gr*=Rot(radians(60.));
            d2 = B(gr,vec2(0.19,thickness*3.));
            d = min(d,d2);
            
            gr = prevHgr.xy;
            d2 = B(gr,vec2(0.31,thickness*3.));
            d = min(d,d2);
        }
        
        gr = prevHgr.xy;
        d2 = abs(sdHexagon(gr,0.5))-thickness;
        d = min(d,d2);
    } else {
        if(n<=0.8){
            float d2 = abs(length(gr-vec2(0.3,-0.52))-0.3)-thickness*3.;
            d = min(d,d2);

            d2 = abs(length(gr-vec2(-0.3,0.52))-0.3)-thickness*3.;
            d = min(d,d2);
            
            gr*=Rot(radians(60.));
            d2 = abs(gr.x)-thickness*3.;
            d = min(d,d2);
            
            gr = prevHgr.xy;
            if(n>=0.7){
                d2 = max(sdHexagon(gr*1.1,0.5),dots(gr));
                d = min(d2,d);
            } else {
                d2 = max(sdHexagon(gr*1.1,0.5),drostePattern1(gr,0.1,0.5));
                d = min(d2,d);
            }
        } else {
            float d2 = abs(length(gr-vec2(0.3,0.52))-0.3)-thickness*3.;
            d = min(d,d2);
            
            d2 = abs(length(gr-vec2(-0.3,-0.52))-0.3)-thickness*3.;
            d = min(d,d2);
            
            gr*=Rot(radians(-60.));
            d2 = abs(gr.x)-thickness*3.;
            d = min(d,d2);
            
            gr = prevHgr.xy;
            if(n>=0.95){
                d2 = max(sdHexagon(gr*1.1,0.5),stripe(gr));
                d = min(d2,d);
            } else {
                d2 = max(sdHexagon(gr*1.1,0.5),drostePattern2(gr,0.1,0.5));
                d = min(d2,d);
            }
        }
    }
    
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (fragCoord-0.5*iResolution.xy)/iResolution.y;
    vec2 uv = fragCoord.xy / iResolution.xy; // Compute UV coordinates

    vec3 col = PAPER_COLOR; // Initialize with the paper color
    float d = drawHexTruchet(p);
    col = mix(col, LINE_COLOR, S(d)); // Mix with the black line color
    
    // Apply paper noise
    col = applyPaperNoise(col, uv, 1.125, 1.0); // Adjust intensity and scale as needed
    
    fragColor = vec4(col,1.0);
}