// Author: bitless
// Title: A lonely sphere running over a field of voxels

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

// Special thanks to Shane for the "Isometric Height Map"
// https://www.shadertoy.com/view/flcSzX. 
// I got some ideas there to improve my code.

// --- Adjustable Parameters ---
#define CAMERA_OFFSET 0.0 // Camera offset to show more of the effect (default 0.0, increase to move up, e.g., 1.0 to 2.0)
#define ANIM_SPEED 1.0 // Overall animation speed (default 1.0, range: 0.0 to 2.0 for stopped to double speed)
#define BRIGHTNESS 0.0 // Brightness adjustment for post-processing (default 0.0, positive to brighten, negative to darken)
#define CONTRAST 1.10 // Contrast adjustment for post-processing (default 1.0, > 1.0 increases contrast, < 1.0 decreases)
#define SATURATION 1.0 // Saturation adjustment for post-processing (default 1.0, > 1.0 increases saturation, < 1.0 decreases)

#define h21(p) ( fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453) ) //hash21
#define rot(a)   mat2(cos(a + vec4(0,11,33,0)))                             //rotate 2d
#define p(t, a, b, c, d) ( a + b*cos( 6.28318*(c*t+d) ) )                   //iq's palette

float noise( in vec2 f ) //gradient noise
{
    vec2 i = floor( f );
    f -= i;
    
    vec2 u = f*f*(3.-2.*f);

    return mix( mix( h21( i + vec2(0,0) ), 
                     h21( i + vec2(1,0) ), u.x),
                mix( h21( i + vec2(0,1) ), 
                     h21( i + vec2(1,1) ), u.x), u.y);
}

vec3 hexToSqr (vec2 st) //hexagonal cell coords to square face coords 
{ 
    vec3 r;
    if (st.y > 0.-abs(st.x)*.57777)
        if (st.x > 0.) 
            r = vec3((vec2(st.x,(st.y+st.x/1.73)*.86)*2.),3); //right face
        else
            r = vec3(-(vec2(st.x,-(st.y-st.x/1.73)*.86)*2.),2); //left face
    else 
        r = vec3 (-(vec2(st.x+st.y*1.73,-st.x+st.y*1.73)),1); //top face
    return r;
}

vec2 toSqr  (vec2 lc)
{
    return vec2((lc.x+lc.y)*.5,(lc.x-lc.y)*0.28902);
}

float T; // global timer (to be initialized in mainImage)
vec2 sp; // sphere position on isometric plane
vec2 sh[7]; // coordinate offsets for voxel neighbors
float sm; // smoothness factor (to be initialized in mainImage)

void initSh() {
    sh[0] = vec2(0, -2);
    sh[1] = vec2(.5, -1);
    sh[2] = vec2(-.5, -1);
    sh[3] = vec2(0, 0);
    sh[4] = vec2(.5, 1);
    sh[5] = vec2(-.5, 1);
    sh[6] = vec2(0, 2);
}

void voxel(vec2 uv, vec2 id, vec2 lc, vec2 shOffset, float T, vec2 sp, inout vec4 C)
{
    vec2 ic = vec2((uv.x + uv.y * 1.73), (uv.x - uv.y * 1.73)); // isometric coordinates

    uv += shOffset * vec2(-1, .28902);
    vec2 ii = floor(vec2((uv.x + uv.y * 1.73), (uv.x - uv.y * 1.73))); // isometric grid cell's id
    float th = mix(                                                                                     // sphere track depth
                    mix(1., noise(ii * .5) * .3, smoothstep(4., 1., abs(ii.x + 15. - noise(vec2(ii.y * .1, 0.)) * 15.))), // sphere track
                    smoothstep(2., 4., length(ii + sp - vec2(-.5, T + .5))),                                     // spot under sphere
                    smoothstep(2., -1., ii.y - T)) 
         , s = pow(noise(vec2(h21(ii) * ii + iTime * ANIM_SPEED * .5)), 8.) * .75 // small picks of altitude 
         , hg = (pow(noise(ii * .2 * rot(1.) - iTime * ANIM_SPEED * .02), 4.) - .5) * 2.     // large noise
                 + s;

    hg = (hg + 1.) * th - 1.;   // voxel altitude
    float sz = 1.1 + s * 1.5 * th; // voxel size variation
    
    vec3 vx = hexToSqr(lc - vec2(shOffset.x, (shOffset.y - (hg * 2. - 1.) / sz) * 0.28902));  // voxel sides coords and side id
    vx.xy *= sz;
    
    vec4 V = vec4(p(ii.y * .05 + hg * .3 * th, vec3(.9), vec3(.7), vec3(.26), vec3(.0, .1, .2)), 1.); // voxel color
    
    float f = mix(.3, (.9 - vx.z * .15), smoothstep(.45 + sm, .45 - sm, max(abs(vx.x - .5), abs(vx.y - .5)))); // sides of voxel 
    f = mix(f, 1. - length(vx.xy - vec2(.6) * 1.2), smoothstep(.4 + sm, .4 - sm, length(vx.xy - .5))); // circles on sides
    f = mix(f, .4, smoothstep(.04 + sm, -sm, abs(length(vx.xy - .5) - .4))); // circles edge
    f -= f * smoothstep(5., 3., length(ic + sp - vec2(-.5, T + .5))) * .5; // shadow under sphere
    f += (hg + 1.) * .07; // highlighting high-altitude voxels    
    C = mix(C, V * f, smoothstep(1. + sm, 1. - sm, max(vx.x, vx.y))); // mix colors with voxel mask 
}

void Draw(vec2 uv, float T, inout vec4 C)
{
    sp = vec2((1. - noise(vec2(T * ANIM_SPEED * .1, 0.))) * 15., 0.); // sphere position on isometric plane
    vec2 st = vec2((uv.x + uv.y * 1.73), (uv.x - uv.y * 1.73)) // isometric coordinates
         , sc = toSqr(st + sp) - uv + vec2(.0, 2. + noise(vec2(iTime * ANIM_SPEED * 5., 0.)) * .2) // sphere center
         , vc = uv; // coordinates for voxels 

    if (length(vc + sc) < 3.) // change coords for distortion effect on sphere
    {
        vc += sc;
        vc += vc * (pow(length(vc * .35), 4.)) - sc; 
        sm = sm + .07;  // add small blur 
    }
    vc += toSqr(vec2(0., T));

    vec2 id = floor(vec2((vc.x + vc.y * 1.73), (vc.x - vc.y * 1.73))); // cell id
    float n = mod(id.x + id.y + 1., 2.);  // even and odd cells

    st = vec2((1. - n) * .5 - vc.x, vc.y * 1.73 - n * .5); 
    id = floor(st) * vec2(1., 2.) + vec2(n * .5, n); // corrected cell id
    vec2 lc = fract(st) - vec2(.5);  // local cell coordinates
    lc.y *= .57804;

    for (int i = 0; i < 7; i++) voxel(vc, id, lc, sh[i], T, sp, C); // draw voxel and his neighbors
    
    uv += sc;

    if (length(uv) < 3.) // add some colors for sphere
    {
        C = mix(C, 
            vec4(0, .02, .05, 1),  
            noise(vec2(-uv.x, (uv.y + uv.x / 1.73) * .86) * 1.0 * rot(-T * ANIM_SPEED * .15)) * .1); // reverted to previous smoked mirror effect
        C += smoothstep(1.0, -3., uv.y) * length(uv) * .02; // reverted light gradient
    }
    
    C = mix(C, vec4(0), smoothstep(.02 + sm, .02 - sm, abs(length(uv) - 3.)) * .25); // small outline of sphere
}

void mainImage(out vec4 C, in vec2 g)
{
    vec2 rz = iResolution.xy
        , uv = (g + g - rz) / -rz.y;
    uv += vec2(0.0, CAMERA_OFFSET); // Adjusted camera offset to show more of the effect
    uv *= 1. + sin(iTime * ANIM_SPEED * .3) * .25; // camera scale
    sm = 3. / iResolution.y;
    
    T = -iTime * ANIM_SPEED * 4. - ((sin(iTime * ANIM_SPEED * .5) + 1.) * 5.); // local timer with speed variation

    initSh(); // Initialize the sh array
    C = vec4(0);

    Draw(uv * 5., T, C);

    uv *= 5.;
    // Apply post-processing adjustments (Brightness, Contrast, Saturation)
    C.rgb = (C.rgb - 0.5) * CONTRAST + 0.5; // Contrast adjustment
    C.rgb += BRIGHTNESS; // Brightness adjustment
    float lum = dot(C.rgb, vec3(0.299, 0.587, 0.114)); // Luminance for saturation
    C.rgb = mix(vec3(lum), C.rgb, SATURATION); // Saturation adjustment
    C = pow(C, vec4(1. / 1.4));
}