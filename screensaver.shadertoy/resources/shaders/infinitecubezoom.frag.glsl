// Author: bitless
// Title: Infinite Cube Zoom with Depth of Field Toggle
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

#define PI 3.1415926
#define hash1( n ) fract(sin(n)*43758.5453)
#define hue(v) ( .6 + .6 * cos( 6.3*(v) + vec4(0,23,21,0) ) )
#define BRIGHTNESS 0.0 // Brightness adjustment for post-processing (default 0.0, positive to brighten, negative to darken)
#define CONTRAST 1.0 // Contrast adjustment for post-processing (default 1.0, > 1.0 increases contrast, < 1.0 decreases)
#define SATURATION 1.0 // Saturation adjustment for post-processing (default 1.0, > 1.0 increases saturation, < 1.0 decreases)
#define DOF_ENABLED 0 // Depth of Field toggle (1 to enable, 0 to disable)
#define DOF_STRENGTH 2.0 // Depth of Field strength (default 2.0, increase for stronger blur towards edges)
#define DOF_FOCAL_RANGE 0.2 // Focal range around center where image is in focus (default 0.2, increase for larger in-focus area)
#define DOF_MAX_BLUR 0.02 // Maximum blur radius at edges (default 0.02, increase for more blur)

float grad(float a) {
    float sm = .005;
    float f = 1./3.;
    a = mod(a+1.,2.);
    return mix(
                    mix(.45 //SIDE1
                       ,.65 //SIDE2
                       , smoothstep (sm,-sm,abs(1.+f-a)-f)) 
                    ,.95 // BOTTOM-TOP
                    , smoothstep (f+sm, f-sm, 1.-abs(1.-a))); 
}

void mainImage( out vec4 fragColor, in vec2 g)
{
    vec2 r = iResolution.xy
        , st = (g+g-r)/r.y;
    st += st * length(st)*.1;

    float a = atan(st.x,st.y)/PI
        , T = iTime*0.1;

    float g1 = grad(a)
        , g2 = grad(a+1.);

    float l = dot(abs(st),normalize(vec2(1.,1.73)));
    l = log2(max(l,abs(st.x)))-T;
    float fl = fract(l);
    
    float sm = fwidth(l)*1.5;

    vec4 c = hue(a+T*.1)
        , c2 = mix(hue(hash1(floor(l)-1.)),c,.3)
        , c3 = mix(hue(hash1(floor(l)+1.)),c,.3);
    c = mix(hue(hash1(floor(l))),c,.3);

    if (mod(l,2.)<1.) {
        c *= g1;
        c2 *= g2;
        c = mix(
                mix(c2,c,smoothstep(-sm,sm,fl-.005))
                ,c2*.75
                ,smoothstep (.4, 0., fl)*0.25)
           * (1.-smoothstep(.1,0.,abs(mod(a+1.,2./3.)-1./3.))*.25);
    } else {
        c *= g2;
        c2 *= g1;
        c3 *= g1;
        c = mix(
                mix(c2,c,smoothstep(-sm,sm,fl-.005))
                ,c3*.5
                ,smoothstep (.7, 1., fl)*.2);
    }

    // Apply post-processing adjustments (Brightness, Contrast, Saturation)
    c.rgb = (c.rgb - 0.5) * CONTRAST + 0.5; // Contrast adjustment
    c.rgb += BRIGHTNESS; // Brightness adjustment
    float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114)); // Luminance for saturation
    c.rgb = mix(vec3(lum), c.rgb, SATURATION); // Saturation adjustment

#if DOF_ENABLED
    // Apply Depth of Field effect
    vec2 uv = g / iResolution.xy; // Normalized UV coordinates for sampling
    float dist = length(st); // Distance from center in normalized space
    float blur = clamp((dist - DOF_FOCAL_RANGE) * DOF_STRENGTH, 0.0, DOF_MAX_BLUR); // Blur radius based on distance
    vec4 blurredColor = vec4(0.0);
    float samples = 0.0;
    int sampleCount = 5; // Number of samples in each direction (5x5 grid)
    for (int i = -sampleCount; i <= sampleCount; i++) {
        for (int j = -sampleCount; j <= sampleCount; j++) {
            vec2 offset = vec2(float(i), float(j)) * blur / float(sampleCount);
            vec2 sampleUV = uv + offset;
            // Compute sample position in st-space to determine its color
            vec2 sampleSt = (sampleUV * iResolution.xy * 2.0 - iResolution.xy) / iResolution.y;
            sampleSt += sampleSt * length(sampleSt) * .1;

            float sampleA = atan(sampleSt.x, sampleSt.y) / PI;
            float sampleL = dot(abs(sampleSt), normalize(vec2(1., 1.73)));
            sampleL = log2(max(sampleL, abs(sampleSt.x))) - T;
            float sampleFl = fract(sampleL);
            float sampleSm = fwidth(sampleL) * 1.5;

            vec4 sampleC = hue(sampleA + T * .1)
                 , sampleC2 = mix(hue(hash1(floor(sampleL) - 1.)), sampleC, .3)
                 , sampleC3 = mix(hue(hash1(floor(sampleL) + 1.)), sampleC, .3);
            sampleC = mix(hue(hash1(floor(sampleL))), sampleC, .3);

            float sampleG1 = grad(sampleA)
                , sampleG2 = grad(sampleA + 1.);

            if (mod(sampleL, 2.) < 1.) {
                sampleC *= sampleG1;
                sampleC2 *= sampleG2;
                sampleC = mix(
                        mix(sampleC2, sampleC, smoothstep(-sampleSm, sampleSm, sampleFl - .005))
                        , sampleC2 * .75
                        , smoothstep(.4, 0., sampleFl) * 0.25)
                   * (1. - smoothstep(.1, 0., abs(mod(sampleA + 1., 2./3.) - 1./3.)) * .25);
            } else {
                sampleC *= sampleG2;
                sampleC2 *= sampleG1;
                sampleC3 *= sampleG1;
                sampleC = mix(
                        mix(sampleC2, sampleC, smoothstep(-sampleSm, sampleSm, sampleFl - .005))
                        , sampleC3 * .5
                        , smoothstep(.7, 1., sampleFl) * .2);
            }

            // Apply BCS to the sample
            sampleC.rgb = (sampleC.rgb - 0.5) * CONTRAST + 0.5;
            sampleC.rgb += BRIGHTNESS;
            float sampleLum = dot(sampleC.rgb, vec3(0.299, 0.587, 0.114));
            sampleC.rgb = mix(vec3(sampleLum), sampleC.rgb, SATURATION);

            blurredColor += sampleC;
            samples += 1.0;
        }
    }
    blurredColor /= samples;

    // Mix the original color (in focus) with the blurred color based on distance
    c = mix(c, blurredColor, clamp((dist - DOF_FOCAL_RANGE) * DOF_STRENGTH, 0.0, 1.0));
#endif

    fragColor = c;
}