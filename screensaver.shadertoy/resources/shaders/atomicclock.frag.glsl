// Changed to highp for potentially better animation precision
precision highp float; 

/** License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License 
    
    Digital Clock Display Demo 

    Better number generation, cute static tv effect with 
    sun/moon am/pm display and time as waveforms for 
    NERV facilities biometric realness. 
    
    06/02/2025 @byt3_m3chanic 

*/ 

#define R   iResolution 
#define T   iTime // iTime is used here for animation tests
#define M   iMouse 

#define PI  3.1415926 
#define PI2 6.2831853 

// globals
// Removed 'tmod' as it was unused.
float h1,h2,m1,m2,s1,s2; 

mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); } 
float hash21(vec2 a) { return fract(sin(dot(a, vec2(27.69, 57.53)))*458.53); } 

//@iq box and triangle sdf shapes 
float box( in vec2 p, in vec2 b ){ 
    vec2 d = abs(p)-b; 
    return length(max(d,0.0))+min(max(d.x,d.y),0.0); // Explicit floats
} 
float tro( in vec2 p, in vec2 q ){ 
    p.x = abs(p.x); 
    vec2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 ); // Explicit floats
    vec2 b = p - q*vec2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 ); // Explicit floats
    float s_sign = -sign( q.y ); // Renamed 's' to 's_sign' to avoid conflict
    vec2 d_vec = min( vec2( dot(a,a), s_sign*(p.x*q.y-p.y*q.x) ), // Renamed 'd' to 'd_vec'
                  vec2( dot(b,b), s_sign*(p.y-q.y)  )); 
    return -sqrt(d_vec.x)*sign(d_vec.y); 
} 
const vec2 ts = vec2(0.05,0.0025); // Explicit floats
const vec2 ss = vec2(0.0025,0.025); // Explicit floats
const float rd = 0.035; // Explicit float

float getDig(vec2 p, int n) { 
    float d = 100000.0; // Changed 1e5 to 100000.0 for robustness
    
    // Explicit float literals for vector components and arithmetic
    if(n==0||n==2||n==3||n>4) d= min(d, box(p-vec2(0.0,0.125),ts)-rd); 
    if(n!=1&&n!=2&&n!=3&&n!=7) d = min(d,box(p+vec2(0.1,-0.060),ss)-rd); 
    if(n!=5&&n!=6) d = min(d,box(p-vec2(0.1,0.060),ss)-rd); 
    if(n!=0&&n!=1&&n!=7) d = min(d,box(p,ts)-rd); 
    if(n==2||n==6||n==8||n==0) d = min(d,box(p+vec2(0.1,0.060),ss)-rd); 
    if(n!=2) d = min(d,box(p+vec2(-0.1,0.060),ss)-rd); 
    if(n!=1&&n!=4&&n!=7) d = min(d,box(p+vec2(0.0,0.125),ts)-rd); 
    
    return d; 
} 

float getdp(vec2 p) { 
    vec2 q = vec2(p.x,abs(p.y)-0.06); // Explicit float
    float d_val = length(q)-rd; // Renamed 'd' to 'd_val' to avoid ambiguity
    return d_val; 
} 

//@iq hsv to rgb 
vec3 hsv( vec3 a ) { 
    vec3 c = a + vec3(T*0.1,0.0,0.0); // Explicit floats
    vec3 rgb = clamp(abs(mod(c.x*2.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0,0.0,1.0); // Explicit floats
    return c.z * mix(vec3(1.0),rgb,c.y); // Explicit float 1.0
} 

void mainImage( out vec4 fragColor, in vec2 F ) 
{ 
    // time precal 
    float idate = iDate.w; // Keeping iDate.w for digital clock and AM/PM logic

    int sec = int(mod(idate,60.0)); // Explicit float 60.0
    int minute = int(mod(idate/60.0,60.0)); // Explicit float 60.0
    int hour_12_raw = int(mod(idate/3600.0,12.0)); // Original hour calculation (0-11)
    int ampm = int(mod(idate/3600.0,24.0)); // For AM/PM check (0-23)
    
    // global digits 
    float num = float(hour_12_raw); // Use raw 0-11 hour for now
    if(num == 0.0) num = 12.0; // Handle 00:xx as 12:xx AM
    
    h1 = floor(mod(num / pow(10.0,1.0),10.0)); // Explicit floats
    h2 = floor(mod(num / pow(10.0,0.0),10.0)); // Explicit floats
    
    num = float(minute); 
    m1 = floor(mod(num / pow(10.0,1.0),10.0)); // Explicit floats
    m2 = floor(mod(num / pow(10.0,0.0),10.0)); // Explicit floats
    
    num = float(sec); 
    s1 = floor(mod(num / pow(10.0,1.0),10.0)); // Explicit floats
    s2 = floor(mod(num / pow(10.0,0.0),10.0)); // Explicit floats
    // end precal 
        
    vec2 uv = (2.0 * F.xy-R.xy)/max(R.x,R.y); // Explicit float 2.0
    // reduce size if large resolution 
    if(R.x/R.y > 1.78) uv*=1.5; // Explicit float 1.78, 1.5
    
    uv -= vec2(0.08,0.01); // Explicit floats
    vec2 nv = uv,tv = (uv+19.0); // Explicit float 19.0
    nv.x-=0.2; // Explicit float 0.2
    
    vec3 C = vec3(0.0); // Explicit float 0.0
    float ps = (uv.y*1.15)+T*0.04; // Explicit floats
    vec3 pry = hsv(vec3(ps,0.9,0.4)); // Explicit floats
    vec3 tri = hsv(vec3(ps-0.1,0.6,0.6)); // Explicit floats
    vec3 snd = hsv(vec3(ps+0.1,0.9,0.25)); // Explicit floats
    vec3 bkg = hsv(vec3(ps,0.8,0.12)); // Explicit floats
    
    float px = fwidth(uv.x*25.0); // Explicit float 25.0
    // background 
    vec2 h_bg = fract(tv*25.0)-0.5; // Explicit floats
    vec2 id_bg=floor(tv*25.0); // Explicit float 25.0
    float f_bg=box(h_bg,vec2(0.5)); // Explicit float 0.5
    C = mix(C,bkg,smoothstep(px,-px,f_bg=abs(f_bg)-0.005)); // Explicit float 0.005

    // 7 segment time display 
    vec2 p_dig = nv*0.65; // Explicit float 0.65
    p_dig += vec2(0.55,0.0); // Explicit floats
    px = fwidth(uv.x); // Recalculate px, as it's scope is within mainImage
    
    float d_min_dig = getDig(p_dig,int(h1)); 
    d_min_dig = min(d_min_dig, getDig(p_dig-vec2(0.3,0.0),int(h2))); // Explicit floats
    d_min_dig = min(d_min_dig, getdp(p_dig-vec2(0.538,0.0))); // Explicit float 0.538
    
    vec2 p1_dig = nv*1.45; // Explicit float 1.45
    p1_dig -= vec2(0.3,0.215); // Explicit floats
    
    d_min_dig = min(d_min_dig, getDig(p1_dig-vec2(0.0,0.0),int(m1))); // Explicit floats
    d_min_dig = min(d_min_dig, getDig(p1_dig-vec2(0.3,0.0),int(m2))); // Explicit floats

    vec2 p2_dig = nv*1.45; // Explicit float 1.45
    p2_dig -= vec2(0.3,-0.215); // Explicit floats
    d_min_dig = min(d_min_dig, getDig(p2_dig-vec2(0.0,0.0),int(s1))); // Explicit floats
    d_min_dig = min(d_min_dig, getDig(p2_dig-vec2(0.3,0.0),int(s2))); // Explicit floats

    float d1_dig=abs(abs(d_min_dig)-0.006)-0.002; // Explicit floats
    C = mix(C,snd*0.4,smoothstep(0.03+px,-px,d1_dig)); // Explicit floats
    C = mix(C,pry,smoothstep(px,-px,d1_dig)); 
    C = mix(C,tri,smoothstep(px,-px,d_min_dig+0.015)); // Explicit float 0.015

    // display time as wave cycles - NOW USING T (iTime) for animation
    vec2 xuv = uv; 
    // Wave 1
    float ln_wave = abs(length(xuv.y+0.445+(0.02)*sin(mod(T,1.0)*PI2+(xuv.x*60.0))))-0.0025; // Using T (iTime)
    C = mix(C,snd*0.4,smoothstep(0.02+px,-px,ln_wave)); // Explicit float 0.02
    C = mix(C,snd,smoothstep(px,-px,ln_wave)); 
    
    // Wave 2
    ln_wave = abs(length(xuv.y+0.442+(0.04)*sin(mod(T,60.0)*PI2+(xuv.x*(float(minute)+1.0)))))-0.0025; // Using T (iTime)
    C = mix(C,snd*0.4,smoothstep(0.025+px,-px,ln_wave)); // Explicit float 0.025
    C = mix(C,pry,smoothstep(px,-px,ln_wave)); 
    
    // Wave 3
    num = float(hour_12_raw); // num is still based on iDate.w, but its value is static for wave calculation
    if(num == 0.0) num = 12.0; // Explicit floats
    ln_wave = abs(length(xuv.y+0.44+(0.06)*sin(mod(T,60.0)*PI2+(xuv.x*(num+1.0)))))-0.0025; // Using T (iTime)
    C = mix(C,tri*0.4,smoothstep(0.025+px,-px,ln_wave)); // Explicit floats
    C = mix(C,tri,smoothstep(px,-px,ln_wave));  
    
    // sun or moon display 
    vec2 muv=xuv-vec2(-0.885,0.39); // Explicit floats
    float mn_display = length(muv)-0.095; // Explicit float 0.095
    float spl_display = 100000.0; // Use 100000.0 instead of 1e5 for ES 1.00 to be safe
    float amt = 8.0; // Explicit float 8.0
    mat2 r78 = rot(PI2/amt); 
    if(ampm<12){ // Integer comparison is fine here.
        for(float i_loop = 0.0; i_loop < amt; i_loop++){ // Explicit float 0.0, and loop condition uses float `amt`
            spl_display=min(spl_display,tro(muv+vec2(0.0,0.125),vec2(0.05,0.1))); // Explicit floats
            muv*=r78; 
        } 
        mn_display=min(mn_display,spl_display); 
    } else { 
        mn_display=min(-mn_display,length(muv-vec2(0.075,0.0))-0.091); // Explicit floats
    } 
    mn_display=abs(abs(mn_display)-0.006)-0.002; // Explicit floats
    C = mix(C,pry*0.5,smoothstep(0.025+px,-px,mn_display)); // Explicit float 0.025, 0.5
    C = mix(C,tri,smoothstep(px,-px,mn_display));  

    // line fading - FIX: Replaced % with mod() and ensuring type consistency and precision-safe comparison
    // This was previously line 211, now should be around 210 due to removed line/variables
    if(abs(mod(floor(F.y), 4.0)) < 0.001 && R.x > 800.0 ) C = C*0.4; // Explicit floats, epsilon for comparison
    
    // fake tv static 
    float nx = hash21(uv+floor(T*20.0)); // Explicit float 20.0
    C = mix(C,clamp(C-0.085,vec3(0.0),vec3(1.0)),hash21(nx+uv+fract(floor(T*20.0)*453.27))); // Explicit floats
    
    // Output to screen 
    C=pow(C,vec3(0.4545)); // Explicit float 0.4545
    fragColor = vec4(C,1.0); // Explicit float 1.0
}