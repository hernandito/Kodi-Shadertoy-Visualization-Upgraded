// Sinh: fractal with 3D vis - Kodi OpenGL ES 1.0 Compatible Version (Robustness Enhanced)

// =========================================================================
// USER-TUNABLE PARAMETERS
// =========================================================================

// Anti-Aliasing (1 = Off, 2 = 2x2 samples per pixel)
#define AA 1 

// Global Speed Control (Multiplies original camera speed constants 0.3 & 0.5)
#define CAM_ANIM_SPEED 0.10 

// Fractal Color Speed (Multiplies iTime for color shifting)
#define FRACTAL_COLOR_SPEED 0.40

// Post-Processing Brightness (1.0 = normal)
#define BRIGHTNESS 1.0 

// Post-Processing Contrast (1.0 = normal)
#define CONTRAST 1.01 

// Post-Processing Saturation (1.0 = normal, 0.0 = grayscale)
#define SATURATION 1.30 

// Shadow Strength (Lower value = softer shadows, helps hide artifacts when AA=1)
#define SHADOW_STRENGTH 16.0

// =========================================================================
// ROBUSTNESS & CORE CONFIGURATION
// =========================================================================
#define Pi 3.14159265
#define S 500 // steps
#define E .0001 // precision

vec2 U,O;

// Robust Tanh Conversion Method (Included for general stability, as requested)
vec4 tanh_approx(vec4 x) { 
    const float EPSILON = 1e-6; 
    return x / (1.0 + max(abs(x), EPSILON)); 
}

// Manually implement hyperbolic functions not supported in GLSL ES 1.0
float manual_sinh(float x) { 
    return (exp(x) - exp(-x)) * 0.5; 
}
float manual_cosh(float x) { 
    return (exp(x) + exp(-x)) * 0.5; 
}

vec2 sh(vec2 z){
    return vec2(manual_sinh(z.x)*cos(z.y), manual_cosh(z.x)*sin(z.y+.01));
}

vec2 mul(vec2 a,vec2 b){return vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);}

vec2 f(vec2 z,vec2 c){
    for(int i=0;i<65;i++){ 
        vec2 s=sh(z);
        z=abs(mul(mul(s,s),mul(s,s)))+c;
        if(dot(z,z)>12.25)return vec2(float(i),dot(z,z));
    }
    return vec2(65.,dot(z,z));
}

vec2 r2(vec2 p,float a){return p*cos(a)+vec2(-p.y,p.x)*sin(a);}

vec2 m(vec3 p){
    float d1=length(p-vec3(0,0,3.25))-3.25;
    float d2=p.z;
    return vec2(min(d1,d2),d1<d2?0.:1.);
}

vec3 n(vec3 p){
    U=vec2(.001,0);
    return normalize(vec3(m(p+U.xyy).x-m(p-U.xyy).x,
                          m(p+U.yxy).x-m(p-U.yxy).x,
                          m(p+U.yyx).x-m(p-U.yyx).x));
}

vec2 ray(vec3 o,vec3 d){
    float t=.001;
    for(int i=0;i<S;i++){ 
        vec2 h=m(o+t*d);
        if(h.x<E*(t*.125+1.))return vec2(t,h.y);
        if(t>100.)break;
        t+=h.x;
    }
    return vec2(-1);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void mainImage(out vec4 O,vec2 I){
    // CRITICAL: Explicitly initialize screen color accumulator
    vec3 sc = vec3(0.0); 
    
    // CAMERA ANIMATION
    float t_cam = iTime * CAM_ANIM_SPEED;
    float d=mix(15.,10.,smoothstep(.2,.8,.5+.5*sin(t_cam*.5)));
    vec3 ro=vec3(.1,d,d);

    ro.xy=r2(ro.xy,t_cam*.3);
    
    vec3 fw=normalize(-ro);
    vec3 rt=normalize(cross(fw,vec3(0,0,1)));
    vec3 up=cross(rt,fw);
    
    for(int i=0;i<AA;i++)for(int j=0;j<AA;j++){
        U=vec2(float(i),float(j))/float(AA);
        vec2 uv=(2.*(I+U)-iResolution.xy)/iResolution.y;
        vec3 rd=normalize(uv.x*rt+uv.y*up+1.5*fw);
        
        vec2 t=ray(ro,rd);
        if(t.x<0.)continue;
        
        vec3 p=ro+t.x*rd;
        vec3 N=t.y<.5?normalize(p-vec3(0,0,2.25)):vec3(0,0,1);
        
        vec2 fp=t.y<.5?6.825*p.xy/(6.825-p.z):p.xy;
        
        // FRACTAL COLOR ANIMATION
        float t_color = iTime * FRACTAL_COLOR_SPEED;
        
        U=fp*.05;
        float cv=mix(2.197,2.99225,.01+.01*sin(.1*36.0));
        float os=.00004+.02040101*(sin(.1*36.0)+.1);
        vec2 zi=f(U,vec2(os,cv));
        float ls=zi.y;
        
        vec3 c1=.5+.5*cos(3.+t_color+vec3(0,.5,1)+Pi*vec3(2.*ls));
        vec3 c2=.5+.5*cos(4.1+t_color+Pi*vec3(ls));
        vec3 c3=4.5+.5*cos(3.+t_color+vec3(1,.5,0)+Pi*vec3(2.*sin(ls)));
        vec3 bc=sqrt(c1*c2*c3)*vec3(.5,.25,.05);
        
        // Lighting and Shadow Calculations 
        vec3 lp=vec3(1,0,20);
        vec3 ld=normalize(lp-p);
        float ln=max(.001,length(lp-p));
        
        // AO (Explicitly initialized)
        float ao = 0.0;
        float s = 1.0;
        for(int k=0;k<15;k++){
            float h=.01+.15*float(k)*.25;
            ao+=(h-m(p+h*N).x)*s;
            s*=.85;
        }
        ao=max(.2,1.-ao);
        
        // Shadow (Explicitly initialized)
        float sd = 1.0;
        float ts = .01;
        for(int k=0;k<30;k++){
            float h=m(p+.001*N+ld*ts).x;
            sd=min(sd,SHADOW_STRENGTH*h/ts);
            ts+=max(.001,min(h,.1));
            if(h<E||ts>ln)break;
        }
        sd=min(max(0.,sd)+ao*.2,1.);
        
        float df=max(0.,dot(N,ld));
        float at=1./(1.+ln*.01+ln*ln*.002);
        float sp=pow(max(dot(reflect(-ld,N),-rd),0.),20.);
        float fr=max(0.,1.+dot(rd,N));
        
        vec3 c=bc*(df+.5*ao);
        c+=bc*vec3(.8,1.,.3)*sp*8.;
        c+=bc*vec3(1.2,1.,.8)*fr*fr*6.;
        c*=at*sd*ao;
        //vig
        c*=max(0.,min(1.1,55./dot(p,p))-.1);
        
        sc+=c; // Accumulate color
    }
    
    // Final color calculation
    vec3 final_color = max(vec3(0),sc/float(AA*AA));
    
    // =========================================================================
    // POST-PROCESSING: BCS ADJUSTMENT
    // =========================================================================
    
    // 1. Contrast
    final_color = (final_color - 0.5) * CONTRAST + 0.5;

    // 2. Saturation
    float l = luminance(final_color);
    final_color = mix(vec3(l), final_color, SATURATION);

    // 3. Brightness
    final_color *= BRIGHTNESS;

    // Output with gamma correction (sqrt)
    O=vec4(sqrt(final_color),1);
}
