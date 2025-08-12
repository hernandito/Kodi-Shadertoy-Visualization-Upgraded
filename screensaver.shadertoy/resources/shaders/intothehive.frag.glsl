precision highp float; // Ensure high precision for calculations

// Author: bitless
// Title: Through the hive

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

//Inigo Quiles article "Simple color palettes" 
//https://iquilezles.org/articles/palettes/
#define pal(t, a, b, c, d) ( a + b*cos( 6.28318*(c*t+d) ) )

// --- Global Animation Speed Control ---
// Adjusts the overall speed of the animation.
// 1.0 is normal speed. Values > 1.0 speed up, < 1.0 slow down.
#define ANIMATION_SPEED 0.30 // Default speed

// --- Post-Processing BCS Parameters (Adjust these for final image look) ---
#define BRIGHTNESS 0.00          // Adjusts the overall brightness. 0.0 is no change.
#define CONTRAST 1.00            // Adjusts the overall contrast. 1.0 is no change.
#define SATURATION 1.10          // Adjusts the overall saturation. 1.0 is no change.

// Hash from "Hash without Sine" by Dave_Hoskins (https://www.shadertoy.com/view/4djSRW)
float hash11(in float x) {
    x = fract(x * 0.1031);
    x *= x + 33.33;
    x *= x + x;
    return fract(x);
}

vec2 hash22(vec2 p)
{
  vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
////////////////////////////////////////////


////////////////// HEXAGONAL VORONOI///////////////
//  This code, with minor modifications, is taken from Shane's 
//  "Round Voronoi Border Refinement". 
//  https://www.shadertoy.com/view/4sdcDN
//
//  Be sure to check out his excellent shader.
//  Shane is much better at explaining how his code works 
//  than I am, so I limited my comments to just my changes.
//  

/*
float smin2(float a, float b, float r)
{
   float f = max(0., 1. - abs(b - a)/r);
   return min(a, b) - r*.25*f*f;
}

vec2 pixToHex(vec2 p)
{
    return floor(vec2(p.x + .57735*p.y, 1.1547*p.y) + 1./3.);
}

vec2 hexPt(vec2 p, float T, float layer) 
{
    vec2 t = vec2(floor(T/5.)); // every five seconds the centers of the cells change their position,
                                 // T is the phase offset from the global timer for a particular layer
    
    return mix (vec2(p.x - p.y*.5, .866025*p.y) + (hash22(p+t+layer) - .5)*.866025/2.  //current position
                ,vec2(p.x - p.y*.5, .866025*p.y) + (hash22(p+t+layer+1.) - .5)*.866025/2.  //next position
                ,smoothstep (0.,1.,mod(T,5.)));     //сhange positions in 1 seconds
}

float Voronoi(vec2 p, float min_fct, float T, float layer) 
{    
    vec2 pH = pixToHex(p);
    const vec2 hp[7] = vec2[7](vec2(-1), vec2(0, -1), vec2(-1, 0), vec2(0), vec2(1), vec2(1, 0), vec2(0, 1)); 
    vec2 minCellID = vec2(0);
    vec2 mo, o;
    
    float md = 8., lMd = 8., lMd2 = 8., lnDist, d;
    for (int i=0; i<7; i++)
    {
        vec2 h = hexPt(pH + hp[i], T, layer) - p;
        d = dot(h, h);
        if( d<md )
        {
            md = d;
            mo = h; 
            minCellID = hp[i];
        }
    }

    for (int i=0; i<7; i++)
    {
        vec2 h = hexPt(pH + hp[i] + minCellID, T, layer) - p - mo; 
        if(dot(h, h)>.01)
        {
            lnDist = dot(mo + h*.5, normalize(h));
            lMd = smin2(lMd, lnDist, min_fct);
        }
    }
    return lMd;
}
*/


// Code from Fabrice (thanks a lot)
// Smaller, faster and doesn't cause a weird bug that wasn't present on my main computer

#define H2(p)       fract( sin((p+9.0)*mat2(127.1,311.7, 269.5,183.3)) *4e4 ) // Use float literal 9.0
#define H1(p)       H2(vec2(p)).x

vec2 hexPt(vec2 p, float T, float l)  {
    vec2 t = p + floor(T/5.0) + l; // Use float literal 5.0
    return p * mat2(1.0,-.5,0.0, .866) // Use float literal 1.0, 0.0
            + ( mix( H2(t),  H2(t+1.0),  smoothstep (0.0,1.0,mod(T,5.0)) ) // Use float literal 1.0, 0.0, 5.0
                -.5  ) * .433; 
}

float Voronoi(vec2 p, float M, float T, float l)   // --- Voronoi
{    
    vec2 pH = floor( p * mat2(1.0,.6,0.0,1.0) ); // Use float literal 1.0, 0.0 // pixToHex(p)
    vec2 mo, o, C, c,h;
    
    float m = 8.0, md = m, d, f; // Use float literal 8.0
    for (int i=0; i<9; i++)
        c = vec2(mod(float(i),3.0),floor(float(i)/3.0))-1.0, // Replaced % with mod() and ensured float conversion
        h = hexPt(pH + c, T, l) - p,
        d = dot(h, h),
        d < md ? md = d, mo = h, C = c : C;

    for (int i=0; i<9; i++)
        h = hexPt(pH + vec2(mod(float(i),3.0),floor(float(i)/3.0))-1.0 + C, T, l) - p - mo, // Replaced % with mod() and ensured float conversion
        d = dot(mo + h*.5, normalize(h)),
        f = max(0.0, 1.0 - abs(d-m)/M )/2.0, // Use float literal 0.0, 1.0, 2.0
        m = min(m, d) - M*f*f;

    return m;
}

////////////////// HEXAGONAL VORONOI///////////////

/**
 * @brief Applies Brightness, Contrast, and Saturation adjustments to a color.
 *
 * @param color The input RGB color.
 * @param brightness The brightness adjustment.
 * @param contrast The contrast adjustment.
 * @param saturation The saturation adjustment.
 * @return The adjusted RGB color.
 */
vec4 applyBCS(vec4 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color.rgb += brightness;

    // Apply contrast
    // Midpoint for contrast adjustment is 0.5 (gray).
    color.rgb = ((color.rgb - 0.5) * contrast) + 0.5;

    // Apply saturation
    // Convert to grayscale (luminance)
    float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    // Interpolate between grayscale and original color based on saturation
    color.rgb = mix(vec3(luminance), color.rgb, saturation);

    return color;
}


void mainImage( out vec4 O, in vec2 g )
{
    vec2 r = iResolution.xy
        ,uv = (g+g-r)/r.y/2.0 // Use float literal 2.0
        ,xy;

    float   lcl = sin(iTime * ANIMATION_SPEED * .2) // zoom speed changing cycle, apply ANIMATION_SPEED
            ,tm = fract (iTime * ANIMATION_SPEED)     //  1-second timer between cycles, apply ANIMATION_SPEED
            ,cicle = iTime * ANIMATION_SPEED - tm       //  cycle number, apply ANIMATION_SPEED
            ,speed = 1.5+lcl*.25    //  zoom speed
            ,LAYERS =11.0;          // num of layers // Use float literal 11.0
    
    uv *= (1.0 - length(uv)*lcl*.5) // Use float literal 1.0
             /exp(tm*log(speed))    // camera zoom
             *(.3+lcl*.1);
    
    O = vec4(0.0); // Use float literal 0.0


    float T_layer, v, m, s; // Renamed T to T_layer to avoid conflict with global T
    for (float i=LAYERS; i >= 0.0; i--) //draw layers from the far side to the near side // Use float literal 0.0
    {
        T_layer = iTime * ANIMATION_SPEED + hash11(cicle+i)*5.0; //phase offset from the global timer for a particular layer, apply ANIMATION_SPEED // Use float literal 5.0
        xy = uv*pow(speed,i+1.0) + vec2(sin(iTime * ANIMATION_SPEED),cos(iTime * ANIMATION_SPEED * 2.0))*.07; //local coordinates of the layer with a zoom and a small shift, apply ANIMATION_SPEED // Use float literal 1.0, 2.0

        s = max(smoothstep(5.0,0.0,i-tm)*.01      // blur the closest layers // Use float literal 5.0, 0.0
                        +(1.0 + sin(T_layer*20.0+xy.x*10.0-xy.y*10.0))     // and changing layers (with a shaking effect) // Use float literal 1.0, 20.0, 10.0
                        *(smoothstep (1.5,0.0,mod(T_layer,5.0)))*.02    // in 1.5 seconds // Use float literal 1.5, 0.0, 5.0
                    , fwidth(xy.x));             // AA for far small layers

        v = Voronoi (xy+vec2(-.01,.01), .2, T_layer, cicle+i); //voronoi with an offset to draw the highlighted edge
        m = 1.0 + smoothstep (.04-s,.05+s, v);              //highlighted edge mask // Use float literal 1.0
        vec4 col =  pal((iTime * ANIMATION_SPEED * 2.0+i-tm)*.10,vec4(.5),vec4(.4),vec4(1.0),vec4(.1,.2,.3,1.0)) //layer color, apply ANIMATION_SPEED // Use float literal 2.0, 1.0
                        * smoothstep(LAYERS,3.0,i-tm)      // darken the farthest layers // Use float literal 3.0
                        * m;    

        v = Voronoi (xy, .2, T_layer, cicle+i); //    voronoi for current layer
        m = smoothstep (.3,.07+sin(T_layer*5.0)*.05, v) // layer shadow mask // Use float literal 5.0
            *(1.0 - tm*step(i,0.0));             // make the closest layer shadow transparent at the end of the cycle // Use float literal 1.0, 0.0
        O *= 1.0 - m*.7;    //draw layer shadow // Use float literal 1.0

        m = smoothstep (.05+s,.04-s, v)    //  layer mask // Use float literal 0.05, 0.04
            *(1.0 - tm*step(i,0.0));         //  make the closest layer shadow transparent too // Use float literal 1.0, 0.0
        O = mix (O,col,m); //draw layer
    }

    // Apply post-processing BCS adjustments
    O = applyBCS(O, BRIGHTNESS, CONTRAST, SATURATION);
}
