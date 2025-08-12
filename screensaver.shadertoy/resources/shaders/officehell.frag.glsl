// Author: bitless
// Title: Office Hell
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.
//				 _____      ___    ___                        __  __          ___    ___      
//				/\  __`\  /'___\ /'___\ __                   /\ \/\ \        /\_ \  /\_ \     
//				\ \ \/\ \/\ \__//\ \__//\_\    ___     __    \ \ \_\ \     __\//\ \ \//\ \    
//				 \ \ \ \ \ \ ,__\ \ ,__\/\ \  /'___\ /'__`\   \ \  _  \  /'__`\\ \ \  \ \ \   
//				  \ \ \_\ \ \ \_/\ \ \_/\ \ \/\ \__//\  __/    \ \ \ \ \/\  __/ \_\ \_ \_\ \_ 
//				   \ \_____\ \_\  \ \_\  \ \_\ \____\ \____\    \ \_\ \_\ \____\/\____\/\____\
//				    \/_____/\/_/   \/_/   \/_/\/____/\/____/     \/_/\/_/\/____/\/____/\/____/
//                                                                              
//				The Eights circle of Hell, Bolgia Four.
//				A place for those sinners who have fun with shaders during working hours.
//				(My cell is #42LZYCDR, welcome)                                                                              

// --- Global Animation Speed Control ---
// Adjusts the overall speed of the animation.
// 1.0 is normal speed. Values > 1.0 speed up, < 1.0 slow down.
#define ANIMATION_SPEED 0.10 // Default speed

// --- Global View Scale ---
// Adjusts the overall scale of the pattern.
// Higher values (e.g., 2.0) will make the pattern appear smaller, showing more repetitions.
// Lower values (e.g., 0.5) will make the pattern appear larger, showing fewer repetitions.
#define VIEW_SCALE 1.75 // Default scale

// --- Palette Adjustment Parameter ---
// This vec3 controls the phase offset for the R, G, B channels in the hue calculation.
// Adjust these values to change the overall color scheme of the pattern.
// Default: vec3(0,-2.*PI/3.,2.*PI/3.) gives the original blueish tones.
// Example: vec3(0., 0.5, 1.0) for a more reddish-greenish palette.
#define PALETTE_PHASE_OFFSET vec3(0.,-2.*PI/3.,2.*PI/3.)

// --- Line Thickness Control ---
// Adjusts the overall thickness of the black lines in the effect.
// 1.0 is default thickness. Values > 1.0 make lines thicker, < 1.0 make them thinner.
#define LINE_THICKNESS_MULTIPLIER 0.30 // Default thickness

// --- Sinner (Human Icon) Fill Color ---
// Adjusts the fill color of the human-like figures in the scene.
// Default: vec3(.8,.7,.7) for a pinkish tone.
#define SINNER_FILL_COLOR vec3(1.0, 0.09, 0.09) // Default pinkish color

// --- Wall Hue Grayscale Toggle ---
// Set to 1.0 to make the wall hue grayscale, 0.0 for original color.
#define WALL_HUE_GRAYSCALE_TOGGLE 1.0 // Default: 0.0 (color)

// --- Vignette Controls ---
// Controls the size of the bright central area of the vignette.
// Smaller values mean a smaller bright area (more pronounced vignette).
#define VIGNETTE_RADIUS 2.0 // Adjusted default: 0.25 (smaller bright area)

// Controls the softness of the vignette's fade.
// Larger values mean a softer, more gradual fade.
#define VIGNETTE_SOFTNESS 0.65 // Adjusted default: 0.35 (slightly softer fade)

// Controls how dark the edges of the vignette become.
// 0.0 is no darkening, 1.0 is full black.
#define VIGNETTE_INTENSITY 0.5 // Default: 0.5

float WT = 0.08333333; //wall thickness
float WH = 0.33333333; //wall height
float DS = 0.33333333; //door size
float sm; //smoothing
float l = 5.; 
#define WF (WT+WH)
#define CLR .1 //Colorness
#define LT (.02 * LINE_THICKNESS_MULTIPLIER) // Line thickness, scaled by multiplier
#define LS (.01 * LINE_THICKNESS_MULTIPLIER) // Line thickness, scaled by multiplier
#define FloorColor vec3(.52,.52,.52)
#define WallColor vec3(.8,.8,.7)
#define LineColor vec3(.1,.1,.1)
#define lx lc+vec2(lc.y,0.)
#define ly lc+vec2(0.,lc.x)
#define SinPro .12 //count of sinners 
#define PI 3.1415926

// Original hue function
vec3 calculate_hue(float v) {
    vec3 h_color = .6 +.6*cos(2.*PI*(v)+PALETTE_PHASE_OFFSET);
    // Apply grayscale toggle
    if (WALL_HUE_GRAYSCALE_TOGGLE > 0.5) { // Use float comparison for toggle
        float luminance = dot(h_color, vec3(0.299, 0.587, 0.114));
        h_color = vec3(luminance);
    }
    return h_color;
}
#define hue(v) calculate_hue(v) // Use the new function for hue

#define hash2(p) (fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453))

float bx (vec2 lc, float l_val, float r_val, float d_val, float u_val, float w_val) // Renamed 'l', 'r', 'd', 'u' to avoid conflicts
{
    vec2 c = vec2((r_val-l_val)/2.+l_val,(u_val-d_val)/2.+d_val)
         ,s = vec2(r_val,u_val)-c;
    return smoothstep (s.x-w_val+sm,s.x-w_val, abs(lc.x-c.x))*smoothstep (s.y-w_val+sm,s.y-w_val, abs(lc.y-c.y));
}
vec4 SolidWall (vec2 lc, bool s_bool, vec3 h) { // Renamed 's' to 's_bool'
    vec3 r;
    float a = bx(lc+vec2(lc.y,0.),0.,1.,0.,WH+WT,0.);
    r = mix (LineColor, mix(WallColor,h,CLR), bx(lc+vec2(lc.y,0.),0.,1.1,0.,WH+LS,LT)*(s_bool?1.:.7));
    r = mix (r, WallColor,bx(lc+vec2(lc.y,0.),0.,1.1,WH,WF,LT))
        * (1.-.4*smoothstep(.1,.0,lc.y))                             
        * (s_bool?1.-.35*smoothstep(.4,0.,lc.x+lc.y)*smoothstep(WH+sm,WH,lc.y):1.);
    return vec4(r,a);
}
vec4 DoorWall (vec2 lc, bool s_bool, vec3 h) { // Renamed 's' to 's_bool'
    float WS = (1.-DS-WT)/2.;
    float a = (bx(lx,0.,WS+WT,0.,WF,0.)*bx(lc,0.,WS,0.,WF,0.)
            +bx(lx,1.-WS-WT,1.,0.,WF,0.)*bx(lc,1.-WS-WF,1.,0.,WF,0.))
            *(1.-bx(lx,WS+WT,1.-WS-WT,0.,1.,0.));
    vec3 r = mix (LineColor, mix(WallColor,h,CLR),bx(lx,-.1,WS,0.,WH+LS,LT)*(s_bool?1.:.7) //1
                            +bx(lx,1.-WS-WT,1.1,0.,WH+LS,LT)*(s_bool?1.:.7)); //4
    r = mix (r, WallColor,bx(lc,-.1,WS-WH,WH,WF,LT)  //2
                            +bx(ly,WS-WH-LS,WS,WS-LS,WS+WT,LT)  //3
                            +bx(lc,1.-WS-WF,1.1,WH,WF,LT)) //5
        * (1.-.4*smoothstep(.1,.0,lc.y))                            
        * (s_bool?1.-.35*smoothstep(.4,.0,lc.x+lc.y)*smoothstep(WH+sm,WH,lc.y):1.);
    return vec4(r,a);
}
vec4 NbrWall (vec2 lc, bool s_bool, vec3 h) { // Renamed 's' to 's_bool'
    float a = bx(lx,1.-WF,1.,0.,WF,0.)*smoothstep(1.-WF-sm,1.-WF,lc.x);
    vec3 r = mix (LineColor, WallColor,bx(lc,1.-WF,1.-WH,-.1,1.,LT)); //1
    r = mix (r, mix(WallColor,h,CLR),bx(ly,1.-WH-LS,1.,-.1,1.,LT)*(s_bool?1.-.4*smoothstep(.4,0.,1.-lc.x-lc.y):.7)); //2
    r = mix (r, WallColor,bx(lc,0.,1.,WH,WF,LT))       //3
        * (1.-.4*smoothstep(.1,.0,1.-lc.x));
    return vec4(r,a);
}
vec4 NbrDrWall (vec2 lc, bool s_bool, vec3 h) { // Renamed 's' to 's_bool'
    float WS = (1.-DS-WT)/2.;
    float a = bx(lx,1.-WS-WT+LS,1.,0.,WH+LT*.95,0.)*smoothstep(1.-WF-sm,1.-WF,lc.x);
    vec3 r = mix (LineColor, WallColor,bx(lc,1.-WF,1.-WH,WH-WS,1.,LT) //1
                                        +bx(lx,1.-WS-WT,1.-WS+LS,-.1,WH-WS+LS,LT)); //2
    r = mix (r, mix(WallColor,h,CLR),bx(ly,1.-WH-LS,1.,1.-WS,1.,LT)*(s_bool?1.-.4*smoothstep(.4,.0,1.-lc.x-lc.y):.7)) //3
        * (1.-.4*smoothstep(.1,.0,1.-lc.x));
    return vec4(r,a);
}
ivec2 CellType(vec2 fr) {
    float t = floor(hash2(fr)*2.);
    return ivec2(t, mod(t+1.,2.));    
}
vec4 InnerWall(int t, vec2 lc, bool s_bool, vec3 h) { // Renamed 's' to 's_bool'
    return (t ==0)? SolidWall (lc, s_bool, h)
                    :DoorWall (lc, s_bool, h);
}
vec4 OuterWall(int t, vec2 lc, bool s_bool, vec3 h) { // Renamed 's' to 's_bool'
    return (t==0)? NbrWall (lc, s_bool, h)
                    :NbrDrWall (lc, s_bool, h);
}
float sdLine(vec2 p,vec2 a,vec2 b )
{
    vec2 pa = p-a
        ,ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1.);
    return length(pa-ba*h);
}
float NoiseSin(float x, float a, float f, float t_val ){ // Renamed 't' to 't_val'
    float y = sin(a * f);
    t_val = .075*(iTime*ANIMATION_SPEED*t_val); // Apply ANIMATION_SPEED
    y += sin(x*f*2.1 + t_val)*4.5
        + sin(x*f*10.72 + t_val*1.121)*.50;
    y *= a*.06;
    return y;
}
vec4 Sinner(vec2 fr, vec2 lc, float a){
    vec3 res;
    if (hash2(fr.yx) < SinPro) {
        float r = hash2(fr);
        float s_val = 3.; // Renamed 's' to 's_val'
        lc = lc*vec2(s_val*1.3,s_val)+vec2(-2.,-2.7)+vec2(NoiseSin(lc.x,.1,40.,50.))*smoothstep(2.,0.,l);
        lc.x += hash2(vec2(iTime*ANIMATION_SPEED))*0.25*smoothstep(2.,0.,l); // Apply ANIMATION_SPEED
        vec2 df = .5*sin( iTime*ANIMATION_SPEED*(r+.5) + vec2(4.,2.5) + (r+.5)*5.)*smoothstep(0.,3.,l); // Apply ANIMATION_SPEED
        float f,sh;
        lc += df;
        sh = (smoothstep(.5,.0,length(lc*vec2(1.,1.4)+vec2(0.,0.125)))+smoothstep(.9,.0,length(lc*vec2(1.,1.4)+vec2(-0.4321,0.125))))*a*.65;
        f = length(lc+vec2(0.,-.1))-.05; //head
        f = min(f,sdLine(lc,vec2(0.,-.16),vec2(0.,-.5))-.07);//body
        f = min(f,sdLine(lc,vec2(-.08,-.16),vec2(-.25,-.5)));//left hand
        f = min(f,sdLine(lc,vec2(.08,-.16),vec2(.25,-.5)));//right hand
        f = min(f,sdLine(lc,vec2(-.07,-.5),vec2(-.08,-.9)));//left leg
        f = min(f,sdLine(lc,vec2(.07,-.5),vec2(.08,-.9)));//right leg
        res = mix(LineColor,SINNER_FILL_COLOR,smoothstep(.05+sm*2.,.05,f)*a); // Uses SINNER_FILL_COLOR
        a = max(sh,smoothstep(.1+sm*2.,.1,f)*a);
    }    else a = 0.;
        return vec4(res,a);
}
void mainImage(out vec4 fragColor, in vec2 g)
{
    vec2 r = iResolution.xy
        ,uv = (g+g-r)/r.y;

    // Apply the global view scale
    uv *= VIEW_SCALE;
    
    vec2 C = vec2(sin(iTime*ANIMATION_SPEED/20.),cos(iTime*ANIMATION_SPEED/20.))*5.; //camera shift, apply ANIMATION_SPEED
    vec2 CCell = (C * mat2(1.,-1.5,1.,1.5)*2.); //central cell 
    vec3 Res ;
    float lg = 5.;
    for (int i = -3; i<4; i++) //distance from central cell to closes sinner
        for (int j = -3; j <4; j++)
            if (hash2((floor(CCell)+vec2(i,j)).yx) < SinPro) 
            {
                lg = min (lg, length(CCell-floor(CCell+vec2(i,j))));
            }
    uv += uv * pow(length(uv),2.)*.1*smoothstep(5.,0.,lg); //camera distortion
    vec2 rc = uv * (smoothstep(0.,5.,lg)/2.5+.25) + C; //rectangle coords
    vec2 ic = rc * mat2(1.,-1.5,1.,1.5);    //isometric coords
    ic *= 2.;
    sm = fwidth(length(ic))*.8; //smoothness
    vec2 fr = floor(ic); //cell number
    vec2 lc = fract(ic);//local cell coordinates
    vec2 tc = abs(lc-vec2(.5)+vec2(WT,-WT));
    Res = mix(FloorColor,hue (hash2(fr)),CLR*smoothstep(WT/2.,WT/2.+sm,lc.y)*smoothstep(1.-WT/2.,1.-WT/2.-sm,lc.x)); //floor color
    Res += floor(mod(max(tc.x,tc.y)*(1.-WT)*38.,2.))*.05;//floor texture
    l = length(CCell-ic)+(4.*smoothstep(0.,5.,lg));
    // Removed wall height distortion
    // WH = WH + (NoiseSin(ic.x,.25,2.,200.)+NoiseSin(ic.y,.25,2.,200.))*(smoothstep(2.,0.,l)); 
//    WT = WT + abs((NoiseSin(ic.x,.25,.1,20.)+NoiseSin(ic.y,.25,.1,20.)))*(smoothstep(2.,0.,l));//*(smoothstep(2.,0.,l)); //wall thickness waves
    // Removed door size distortion
    // DS = DS + (sin(iTime*ANIMATION_SPEED*10.+ic.y*5.))*.2*(smoothstep(2.,0.,l)); 
    float f,m,m1; //floor shadow and wall masks
    vec4 cr;
    ivec2 t = CellType(fr);
    f = smoothstep(0.,sm,1.-lc.y);
    f*= 1.-.5*smoothstep(.1,0.,1.-lc.y);
    f = (CellType(fr+vec2(0.,1.)).y == 0) ?
        max(f,smoothstep (DS/2.,DS/2.-sm,abs(lc.x-.5+WT/2.))) 
        :f;
    f*= 1.-.5*smoothstep(.1+WT,WT,1.-lc.x);
    f = (t.x == 0) ?
        max(f,smoothstep (DS/2.,DS/2.-sm,abs(lc.y-.5-WT/2.)))
        :f;
    f *= max(1.-smoothstep(WF,WT,lc.y)*.5,smoothstep (DS/2.+(.5-abs(.5-lc.y))*.5,DS/2.-.01,abs(lc.x-.5-lc.y*.5+WT/2.)));
    Res *= f;
    f = smoothstep(0.,sm,lc.x);
    f *= 1.-.5*smoothstep(WH+WT,0.,lc.x);
    f = (CellType(fr+vec2(-1.,0.)).x == 0) ?
        max(f,smoothstep (DS/2.+(.5-abs(.5-lc.x))*.5,DS/2.-.01,abs(lc.y-.5-lc.x*.5-WT/2.)))
        :f;
    Res *= f;
    vec3 h;
    h = hue(hash2(fr+vec2(0.,-1.)));
    Res = mix(Res,h,smoothstep(WT/2.+sm,WT/2.,lc.y)*CLR);
    cr = InnerWall(t.x, lc, true, h);
    Res = mix(Res, cr.xyz, cr.a);
    m = cr.a;
    h = hue(hash2(fr+vec2(1.,0.)));
    Res = mix(Res,h,smoothstep(1.-WT/2.-sm,1.-WT/2.,lc.x)*CLR);
    cr = InnerWall(t.y, 1.-lc.yx, false, h);
    Res = mix(Res, cr.xyz, cr.a);
    m = max(m, cr.a);
    h = hue(hash2(fr+vec2(1.,-1.)));
    t = CellType(fr+vec2(0.,-1.));
    cr = OuterWall(t.y, lc, false, h);
    Res = mix(Res, cr.xyz, cr.a);
    m1 = cr.a;
    t = CellType(fr+vec2(1.,0.));
    cr = OuterWall(t.x, 1.-lc.yx, true, h);
    Res = mix(Res, cr.xyz, cr.a);
    m1 = max(m1,cr.a);
    lc = fract(rc*vec2(2.,3.) + vec2(0.,.5));
    lc = (mod(fr.x+fr.y,2.) != 0.)? lc = fract(rc*vec2(2.,3.) + vec2(.5,-.0)) : lc;
    m = 1. - m;
    m1 = 1. - m1;
    vec4 s_sinner = Sinner (fr, lc,m); // Renamed 's' to 's_sinner'
    Res = mix(Res, s_sinner.xyz,s_sinner.a);
    s_sinner = Sinner (fr+vec2(1.,0.), lc+vec2 (-.5,.5),m1);
    Res = mix(Res, s_sinner.xyz,s_sinner.a);
    s_sinner = Sinner (fr+vec2(0.,-1.), lc+vec2 (.5,.5),m1);
    Res = mix(Res, s_sinner.xyz,s_sinner.a);
    s_sinner = Sinner (fr+vec2(1.,-1.), lc+vec2 (.0,1.),1.);
    Res = mix(Res, s_sinner.xyz,s_sinner.a);
    
    // Original vignette calculation removed.
    // Res *= 1.-.5*smoothstep (3.5/l, 5./l, length(ic - CCell));
    
    // Apply static vignette
    float vignette_factor = smoothstep(VIGNETTE_RADIUS, VIGNETTE_RADIUS + VIGNETTE_SOFTNESS, length(uv));
    Res *= (1.0 - vignette_factor * VIGNETTE_INTENSITY);

    // Removed red overlay
    // vec3 Res1 = vec3(max(max(Res.r,Res.g),Res.b),0.,0.);
    // Res = mix (Res1,Res,smoothstep(0.,3.,lg));
    fragColor = vec4(Res,1.);
}
