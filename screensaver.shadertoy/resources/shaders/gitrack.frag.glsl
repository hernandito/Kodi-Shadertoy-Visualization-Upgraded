// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

precision highp float; // Ensure high precision for calculations

#define PI 3.14159265

// --- Global Animation Speed Control ---
// Adjusts the overall speed of the animation.
// 1.0 is normal speed. Values > 1.0 speed up, < 1.0 slow down.
#define ANIMATION_SPEED .70 // Default speed

// --- Post-Processing BCS Parameters (Adjust these for final image look) ---
#define BRIGHTNESS -0.150          // Adjusts the overall brightness. 0.0 is no change.
#define CONTRAST 1.00            // Adjusts the overall contrast. 1.0 is no change.
#define SATURATION 0.50          // Adjusts the overall saturation. 1.0 is no change.

float smin(float a, float b, float k)
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(float a, float b, float k)
{
    return smin(a, b, -k);
}

vec3 path(float p)
{
    // Apply ANIMATION_SPEED to time-dependent components
    return vec3(sin(p*0.15)*cos(p*0.2)*2.0, 0.0, 0.0); // Ensure float literals
}


// From Shane: https://www.shadertoy.com/view/lstGRB
float noise(vec3 p)
{
    const vec3 s = vec3(7.0, 157.0, 113.0); // Ensure float literals
    vec3 ip = floor(p);
    vec4 h = vec4(0.0, s.yz, s.y + s.z) + dot(ip, s); // Ensure float literal 0.0
    p -= ip;    
    p = p*p*(3.0 - 2.0*p); // Ensure float literals
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);    
}

float fbm(vec3 p)
{
    return noise(p*4.0)+noise(p*8.0)*0.5; // Ensure float literals
}

float map(vec3 p)
{    
    p-=path(p.z);
    float d0=noise(p*1.2+vec3(0.0,iTime*ANIMATION_SPEED,0.0))-0.6; // Apply ANIMATION_SPEED to iTime
    d0=smax(d0,1.2+sin(p.z*0.1)*0.2-noise(p*3.0)*0.3-length(p.xy),1.0); // Ensure float literals
    d0=smin(d0,abs(p.y+1.1),0.3); // Ensure float literals    
    return d0;
}

vec3 get_normal(in vec3 p)    
{
    const vec2 e = vec2(0.005, 0.0); // Ensure float literals
    return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),    map(p + e.yyx) - map(p - e.yyx)));
}

float intersect(vec3 ro, vec3 rd)
{
    float t=0.01; // Ensure float literal
    float d=map(ro+t*rd);
    for(int i=0;i<96;++i)
    {
        if(abs(d)<0.005||t>100.0) // Ensure float literal
            continue;
        t+=step(d,1.0)*d*0.2+d*0.5; // Ensure float literals
        d=map(ro+t*rd);
    }
    if(t>100.0)t=-1.0; // Ensure float literal
    return t;
}

float shadow(vec3 ro, vec3 rd, float dist)
{
    float res=1.0; // Ensure float literal
    float t=0.05; // Ensure float literal
    float h;
    
    for(int i=0;i<12;i++)
    {
        if(t>dist*0.9) continue; // Ensure float literal
        h=map(ro+rd*t);
        res = min(6.0*h/t, res); // Ensure float literal
        t+=h;
    }
    return max(res, 0.0); // Ensure float literal
}                                                               

// density from aiekick: https://www.shadertoy.com/view/lljyWm
float density(vec3 p, float ms)    
{
    vec3 n = get_normal(p);    
    return map(p-n*ms)/ms;
}

vec3 tonemap(vec3 x)    
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

/**
 * @brief Applies Brightness, Contrast, and Saturation adjustments to a color.
 *
 * @param color The input RGB color.
 * @param brightness The brightness adjustment.
 * @param contrast The contrast adjustment.
 * @param saturation The saturation adjustment.
 * @return The adjusted RGB color.
 */
vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color += brightness;

    // Apply contrast
    // Midpoint for contrast adjustment is 0.5 (gray).
    color = ((color - 0.5) * contrast) + 0.5;

    // Apply saturation
    // Convert to grayscale (luminance)
    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    // Interpolate between grayscale and original color based on saturation
    color = mix(vec3(luminance), color, saturation);

    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q=fragCoord.xy/iResolution.xy;
    vec2 p=q*2.0-1.0; // Ensure float literals
    p.x*=iResolution.x/iResolution.y;
    vec3 ro=vec3(0.0,0.0,-iTime*2.0*ANIMATION_SPEED); // Apply ANIMATION_SPEED to iTime
    vec3 ta=ro+vec3(0.0,0.0,-1.0); // Ensure float literals
    
    vec3 lp0=ro+vec3(0.0,-0.4,-1.5); // Ensure float literals
    
    ro+=path(ro.z);
    ta+=path(ta.z);
    lp0+=path(lp0.z);
    
    vec3 f=normalize(ta-ro);
    vec3 r=normalize(cross(f,vec3(0.0,1.0,0.0))); // Ensure float literal
    vec3 u=normalize(cross(r,f));
    
    vec3 rd=normalize(mat3(r,u,f)*vec3(p.xy,PI/2.0)); // Ensure float literal
    vec3 col=vec3(0.6,0.8,1.1); // Ensure float literals

    float t=intersect(ro,rd);
    if(t>-0.5) // Ensure float literal
    {
        vec3 pos=ro+t*rd;
        vec3 n=get_normal(pos);
        
        vec3 mate=2.0*vec3(.9,0.3,.9); // Ensure float literal
                
        vec3 ld0=lp0-pos;
        float ldist=length(ld0);
        ld0/=ldist;
        vec3 lc0=vec3(1.2,0.8,0.5); // Corrected from vec1 to vec3
        
        float sha=shadow(pos+0.01*n, ld0, ldist); // Ensure float literal
        float dif=max(0.0,dot(n,ld0))*sha*sha; // Ensure float literal
        float bac=max(0.0,dot(n,-ld0)); // Ensure float literal
        float amb=max(0.0,dot(n,vec3(0.0,1.0,0.0))); // Ensure float literal
        float spe=pow(clamp(dot(ld0, reflect(rd, n)), 0.0, 1.0), 32.0); // Ensure float literals
        float fre=clamp(1.0+dot(rd,n), .0, 1.0); // Ensure float literal
        float sca=1.0-density(pos,.5); // Ensure float literal
        
        vec3 Lo=(2.5*dif*lc0+ // Ensure float literal
                  5.0*spe*vec3(1.0)*sha+ // Ensure float literal
                  pow(fre,8.0)*vec3(1.1,0.4,0.2))/(ldist); // Ensure float literals
        Lo+=0.3*amb*vec3(0.5,0.8,1.0); // Ensure float literals    
        Lo+=0.3*bac*lc0; // Ensure float literal
        
        Lo+=vec3(1.2,0.2,0.0)*sca; // Ensure float literals
        Lo+=vec3(0.0,1.0,1.0)*(1.0-pow(fbm(pos*0.4+vec3(0.0,iTime*0.5*ANIMATION_SPEED,0.0)),0.5)); // Apply ANIMATION_SPEED to iTime // Ensure float literals
        Lo*=Lo;
        col=mate*Lo*0.2; // Ensure float literal
    }
    col=mix(col, 0.6*vec3(2.3,0.6,1.1), 1.0-exp(-0.0034*t*t) ); // Ensure float literals
    col=tonemap(col);
    col=pow(clamp(col,0.0,1.0),vec3(0.45)); // Ensure float literals    
    col=pow(col,vec3(0.95,0.9,0.85)); // Ensure float literals
    col*=pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1); // Ensure float literals

    // Apply BCS adjustments
    col = applyBCS(col, BRIGHTNESS, CONTRAST, SATURATION);

    fragColor.xyz=col;
    fragColor.w=1.0; // Ensure alpha is set to 1.0
}
