// Author: bitless
// Title: Rusty metal cubes

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

#define maxd .48    //disk max diameter
#define mind .1     //disk min diameter
#define cnum 10.    //num of disks

// --- Global Animation Speed Control ---
// Adjusts the overall speed of the animation.
// 1.0 is normal speed. Values > 1.0 speed up, < 1.0 slow down.
#define ANIMATION_SPEED .5 // Default speed

// --- Global View Scale ---
// Adjusts the overall scale of the pattern.
// Higher values (e.g., 2.0) will make the pattern appear smaller, showing more repetitions.
// Lower values (e.g., 0.5) will make the pattern appear larger, showing fewer repetitions.
#define VIEW_SCALE 1.25 // Default scale

// --- Post-Processing BCS Parameters (Adjust these for final image look) ---
#define BRIGHTNESS 0.20          // Adjusts the overall brightness. 0.0 is no change.
#define CONTRAST 1.40            // Adjusts the overall contrast. 1.0 is no change.
#define SATURATION 1.0          // Adjusts the overall saturation. 1.0 is no change.


#define p(t, a, b, c, d) ( a + b*cos( 6.28318*(c*t+d) ) )             //iq's palette
#define rot(a)    mat2(cos(a + vec4(0,11,33,0)))                      //rotate 2d
#define h21(a) ( fract(sin(dot(a.xy,vec2(12.9898,78.233)))*43758.5453123) ) //hash21

//  Minimal Hexagonal Grid - Shane
//  https://www.shadertoy.com/view/Xljczw
vec4 getHex(vec2 p) //hex grid coords 
{
    vec2 s = vec2(1., 1.7320508); // Ensure float literals
    vec4 hC = floor(vec4(p, p - vec2(.5, 1.))/s.xyxy) + .5; // Ensure float literals
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s); // Ensure float literals
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + .5); // Ensure float literals
}

vec3 HexToSqr (vec2 st) //hexagonal cell coords to square face coords 
{ 
    vec3 r;
    if (st.y > 0.-abs(st.x)*0.57777)
        if (st.x > 0.) 
            r = vec3(fract(vec2(-st.x,(st.y+st.x/1.73)*0.86)*2.),2.); //right face
        else
            r = vec3(fract(vec2(st.x,(st.y-st.x/1.73)*0.86)*2.),3.); //left face
        else
            r = vec3(fract(vec2((st.x+st.y*1.73),(st.x-st.y*1.73))),1.); //upper face
    return r;
} 

float sinc( float x, float k, float l_sinc) // Renamed 'l' to 'l_sinc' to avoid conflict
{
    float h = k*x;
    return sin(x*l_sinc)*h*exp(1.0-h);
}

vec4 Tex (vec4 hx, vec3 sqr, vec2 sh) //face texture
{
    float r = h21(hx.zw*vec2(sqr.z))*5.;
    vec2 uv = ((sqr.xy + vec2(r))  - sh)*.5* rot(r);
    vec4 t = texture2D(iChannel0, uv); // Changed to texture2D
    // Palette parameters: a, b, c, d
    // a: Base color vec3(.18,.38,.32) - dark teal/greenish
    // b: Amplitude vec3(.46,.42,.58) - range of color variation
    // c: Frequency vec3(.11,.20,.22) - how fast colors change
    // d: Phase offset vec3(.14,.16,.13) - starting point/hue for R, G, B
    // This is the primary location to adjust the palette.
    vec3 palette_color = p(h21(vec2(hx.zw))*1.75,vec3(.18,.38,.32),vec3(.46,.42,.58),vec3(.11,.20,.22),vec3(.14,.16,.13))*.125;
    return mix(vec4(palette_color,1.),t,.1);  
}

void tile(vec4 hx,inout vec4 C) 
{
    vec3 sqr = HexToSqr(hx.xy);
    vec2    st = sqr.xy - .5  //face square coordinates
            ,shift;  //disk shift
    float   n = sqr.z         //face id
            ,sm = 3./iResolution.y  //smoothness
            ,h = -sinc (mod(iTime*ANIMATION_SPEED+h21(hx.wz*vec2(n))*20., 10.), .75,3.5)*.3 //bump stright, apply ANIMATION_SPEED
            ,df =  abs(h) * .8
            ,b = (4.-n)*1.2+.8; //face lightness

    C = Tex(hx,sqr,vec2(max(h,0.)*sin(1.2)*1.5)*vec2(1.,-1.))*b*(1.-max(h,0.)*5.);
    
    for (float i = 0.; i < cnum; i++)
    {
        float k = (h < 0.) ? cnum - 1. - i : i;
        float diam = mind + (maxd-mind)/cnum*k;
        shift = vec2(h*sin((cnum-1.-k)/cnum*1.2)*1.5)*vec2(1,-1);
        vec4 col = Tex(hx,sqr,shift)*b;

        if (h < 0.) //outer disks
        {
            C = mix(C, vec4(0.), smoothstep (diam+df,diam-sm,length(st-shift))*.2); //shadow;
            C = mix(C, col * (1. - (cnum-k)/cnum*h*5.), smoothstep (diam+sm,diam-sm,length(st-shift))); //disk
            C = mix(C, vec4(max(-st.y,-.1)*2.), smoothstep (.01,.0,abs(length(st-shift)-diam))*df); //disk edge
        }
        else //inner disks
        {
            C = mix(C, col* (1. - (cnum - 1. -i )/cnum*h*5.) , smoothstep (diam-sm,diam+sm,length(st-shift))); //disk
            C = mix(C, vec4(st.y), smoothstep (.01,.0,abs(length(st-shift)-diam))*df); //disk edge
        }
    }
    C = mix(C, vec4(0.),(smoothstep(.4,.5,-st.x)+smoothstep(.4,.5,st.y))*.3); //ambient occlusion
    C = mix(C, vec4(1.),(smoothstep(.45,.5,st.x)+smoothstep(.45,.5,-st.y))*.08); //edge bevel
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
vec4 applyBCS(vec4 color, float brightness, float floatrast, float saturation) {
    // Apply brightness
    color.rgb += brightness;

    // Apply floatrast
    // Midpoint for floatrast adjustment is 0.5 (gray).
    color.rgb = ((color.rgb - 0.5) * floatrast) + 0.5;

    // Apply saturation
    // Convert to grayscale (luminance)
    float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    // Interpolate between grayscale and original color based on saturation
    color.rgb = mix(vec3(luminance), color.rgb, saturation);

    return color;
}


void mainImage( out vec4 C, in vec2 g)
{
    vec2 rz = iResolution.xy
        ,uv = (g+g-rz)/-rz.y;
    
    // Apply global view scale
    uv *= VIEW_SCALE;

    uv *= 1.2+sin(iTime*ANIMATION_SPEED*.3)*.25; //camera scale, apply ANIMATION_SPEED
    uv += uv * pow(length(uv),2.)*.025 + vec2(sin(iTime*ANIMATION_SPEED*.2)+5.,-cos(iTime*ANIMATION_SPEED*.2)+9.); //lens distortion and camera moving, apply ANIMATION_SPEED
    
    vec4 hx = getHex(uv);
    C = -C; // This line seems to be a placeholder or a remnant from a different context.
            // It effectively negates the initial color of C, which is undefined at this point.
            // In typical Shadertoy setups, C is initialized to 0.0 or a background color.
            // Keeping it as is to match the original behavior, but noting its unusual nature.
    tile(hx,C);

    // Apply post-processing BCS adjustments
    C = applyBCS(C, BRIGHTNESS, CONTRAST, SATURATION);
}
