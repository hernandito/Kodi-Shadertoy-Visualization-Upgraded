// Author: bitless
// Title: Magnetic field indicators
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

//Force field function based on https://www.shadertoy.com/view/Xl2Gz1 by Gijs

#define SCALE 10.

vec4 hex(vec2 uv)
{
    vec2    rf = vec2(1.,1.73),
            h = rf/2.,
            a = mod(uv,rf)-h,
            b = mod(uv-h,rf)-h,
            c = dot(a,a)<dot(b,b) ? a : b,
            d = (uv-c)/SCALE;
    return vec4(c.x,c.y,d.x,d.y); //local cell coord , cell center 
}

void mainImage( out vec4 C, in vec2 P)
{
    vec2 r = iResolution.xy
        ,uv = (P+P-r)/r.y;
    uv += uv * length(uv)*-.15;

    vec4    hx = hex(uv*SCALE); //hex grid
    float 	l = length(hx.xy);//dist to cell center
    
    vec2    d =  vec2(cos(iTime)*.35,sin(iTime)*.35),
            d0 = d + vec2(cos(iTime*.7)*.4,sin(iTime*.7)*.4) - hx.zw, //red pole
            d1 = d - vec2(cos(iTime*.7)*.4,sin(iTime*.7)*.4) - hx.zw, //blue pole
            f = d0/dot(d0,d0)-d1/dot(d1,d1); //force field vector
    
    float   dp = abs(dot(hx.xy*vec2(-1.,1),f.yx))/length(f), 
            df = abs(dot(hx.xy,f))/length(f);
            
    C = smoothstep (.08,.004, dp*df) // X shape
         *smoothstep(.5,.45,l) 
         *(smoothstep(.15,.2,l) + smoothstep(.25,.0,l)) //center circle
         *(vec4(1.,0.2,0.,.5)*dot(f,hx.xy)*length(d1) //red light
            +vec4(0.,0.,1.,1.)*(-dot(f,hx.xy))*length(d0) //blue light
            +vec4(.2,.2,.2,1.)); //neutral light
}