// "Smiley Tutorial" by Martijn Steinrucken aka BigWings - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
//
// This Smiley is part of my ShaderToy Tutorial series on YouTube:
// Part 1 - Creating the Smiley - https://www.youtube.com/watch?v=ZlNnrpM0TRg
// Part 2 - Animating the Smiley - https://www.youtube.com/watch?v=vlD_KOrzGDc&t=83s

#define S(a, b, t) smoothstep(a, b, t)
#define B(a, b, blur, t) S(a-blur, a+blur, t)*S(b+blur, b-blur, t)
#define sat(x) clamp(x, 0., 1.)

// -----------------------------------------------------------------------------
// ADJUSTABLE PARAMETERS
// Adjust these values to fine-tune the shader's appearance.
// -----------------------------------------------------------------------------

// === Overall Scale Control ===
// Adjust this value to control the overall size of the smiley face.
// Values > 1 make it bigger, values < 1 make it smaller.
const float overallScale = 0.50; // EDIT THIS VALUE. Default: 1.0 (original size)

// === BCS Parameters ===
// Brightness: -1.0 to 1.0 (0.0 = no change, positive brightens, negative darkens)
const float post_brightness = -0.05; // EDIT THIS VALUE. Default: no change
// Contrast: 0.0 to 2.0 (1.0 = no change, higher increases contrast, lower reduces)
const float post_contrast = 1.20;   // EDIT THIS VALUE. Default: no change
// Saturation: 0.0 to 2.0 (1.0 = no change, 0.0 = grayscale, higher increases saturation)
const float post_saturation = 1.150; // EDIT THIS VALUE. Default: no change

// === Edge Sharpening ===
//  This is not a single parameter, but rather adjustments within the existing
//  smoothstep functions.  See comments marked "// SHARPEN" below.

// === Drop Shadow Parameters ===
const vec2 shadowOffset = vec2(0.02, -0.05); // Offset of the shadow (x, y)
const float shadowBlur = 0.08;              // Blur radius of the shadow
const vec3 shadowColor = vec3(0.0, 0.0, 0.0); // Color of the shadow (e.g., black)
const float shadowOpacity = 0.9;            // Opacity of the shadow (0.0 to 1.0)

// -----------------------------------------------------------------------------
// END ADJUSTABLE PARAMETERS
// -----------------------------------------------------------------------------

// === Apply BCS Adjustments to a vec4 Color ===
vec4 applyBCS(vec4 col) {
    // Apply brightness
    col.rgb = clamp(col.rgb + post_brightness, 0.0, 1.0);

    // Apply contrast
    col.rgb = clamp((col.rgb - 0.5) * post_contrast + 0.5, 0.0, 1.0);

    // Apply saturation
    vec3 grayscale = vec3(dot(col.rgb, vec3(0.299, 0.587, 0.114))); // Luminance
    col.rgb = mix(grayscale, col.rgb, post_saturation);

    return col;
}

float remap01(float a, float b, float t) {
    return sat((t-a)/(b-a));
}

float remap(float a, float b, float c, float d, float t) {
    return sat((t-a)/(b-a)) * (d-c) + c;
}

vec2 within(vec2 uv, vec4 rect) {
    return (uv-rect.xy)/(rect.zw-rect.xy);
}

vec4 Brow(vec2 uv, float smile) {
    float offs = mix(.2, 0., smile);
    uv.y += offs;

    float y = uv.y;
    uv.y += uv.x*mix(.5, .8, smile)-mix(.1, .3, smile);
    uv.x -= mix(.0, .1, smile);
    uv -= .5;

    vec4 col = vec4(0.);

    float blur = .1;

    float d1 = length(uv);
    float s1 = S(.45, .45-blur, d1); // SHARPEN: reduced blur
    float d2 = length(uv-vec2(.1, -.2)*.7);
    float s2 = S(.5, .5-blur, d2); // SHARPEN: reduced blur

    float browMask = sat(s1-s2);

    float colMask = remap01(.7, .8, y)*.75;
    colMask *= S(.6, .9, browMask); // SHARPEN: no change needed
    colMask *= smile;
    vec4 browCol = mix(vec4(.4, .2, .2, 1.), vec4(1., .75, .5, 1.), colMask);

    uv.y += .15-offs*.5;
    blur += mix(.0, .1, smile);
    d1 = length(uv);
    s1 = S(.45, .45-blur, d1); // SHARPEN: reduced blur
    d2 = length(uv-vec2(.1, -.2)*.7);
    s2 = S(.5, .5-blur, d2); // SHARPEN: reduced blur
    float shadowMask = sat(s1-s2);

    col = mix(col, vec4(0.,0.,0.,1.), S(.0, 1., shadowMask)*.5); // SHARPEN: no change needed

    col = mix(col, browCol, S(.2, .4, browMask)); // SHARPEN: no change needed

    return col;
}

vec4 Eye(vec2 uv, float side, vec2 m, float smile) {
    uv -= .5;
    uv.x *= side;

    float d = length(uv);
    vec4 irisCol = vec4(.3, .5, 1., 1.);
    vec4 col = mix(vec4(1.), irisCol, S(.1, .7, d)*.5);     // gradient in eye-white // SHARPEN: no change needed
    col.a = S(.5, .48, d);          // eye mask // SHARPEN: reduced blur

    col.rgb *= 1. - S(.45, .5, d)*.5*sat(-uv.y-uv.x*side);    // eye shadow // SHARPEN: no change needed

    d = length(uv-m*.4);                                     // offset iris pos to look at mouse cursor
    col.rgb = mix(col.rgb, vec3(0.), S(.3, .28, d));        // iris outline // SHARPEN: reduced blur

    irisCol.rgb *= 1. + S(.3, .05, d);                      // iris lighter in center // SHARPEN: no change needed
    float irisMask = S(.28, .25, d); // SHARPEN: reduced blur
    col.rgb = mix(col.rgb, irisCol.rgb, irisMask);        // blend in iris

    d = length(uv-m*.45);                                     // offset pupile to look at mouse cursor

    float pupilSize = mix(.4, .16, smile);
    float pupilMask = S(pupilSize, pupilSize*.85, d); // SHARPEN: reduced blur
    pupilMask *= irisMask;
    col.rgb = mix(col.rgb, vec3(0.), pupilMask);        // blend in pupil

    float t = iTime*3.;
    vec2 offs = vec2(sin(t+uv.y*25.), sin(t+uv.x*25.));
    offs *= .01*(1.-smile);

    uv += offs;
    float highlight = S(.1, .09, length(uv-vec2(-.15, .15))); // SHARPEN: reduced blur
    highlight += S(.07, .05, length(uv+vec2(-.08, .08))); // SHARPEN: reduced blur
    col.rgb = mix(col.rgb, vec3(1.), highlight);            // blend in highlight

    return col;
}

vec4 Mouth(vec2 uv, float smile) {
    uv -= .5;
    vec4 col = vec4(.5, .18, .05, 1.);

    uv.y *= 1.5;
    uv.y -= uv.x*uv.x*2.*smile;

    uv.x *= mix(2.5, 1., smile);

    float d = length(uv);
    col.a = S(.5, .48, d); // SHARPEN: reduced blur

    vec2 tUv = uv;
    tUv.y += (abs(uv.x)*.5+.1)*(1.-smile);
    float td = length(tUv-vec2(0., .6));

    vec3 toothCol = vec3(1.)*S(.6, .35, d); // SHARPEN: reduced blur
    col.rgb = mix(col.rgb, toothCol, S(.4, .37, td)); // SHARPEN: reduced blur

    td = length(uv+vec2(0., .5));
    col.rgb = mix(col.rgb, vec3(1., .5, .5), S(.5, .2, td)); // SHARPEN: reduced blur
    return col;
}

vec4 Head(vec2 uv) {
    vec4 col = vec4(.9, .65, .1, 1.);

    float d = length(uv);

    col.a = S(.5, .49, d); // SHARPEN: reduced blur

    float edgeShade = remap01(.35, .5, d);
    edgeShade *= edgeShade;
    col.rgb *= 1.-edgeShade*.5;

    col.rgb = mix(col.rgb, vec3(.6, .3, .1), S(.47, .48, d)); // SHARPEN: reduced blur

    float highlight = S(.41, .405, d); // SHARPEN: reduced blur
    highlight *= remap(.41, -.1, .75, 0., uv.y);
    highlight *= S(.18, .19, length(uv-vec2(.21, .08))); // SHARPEN: reduced blur
    col.rgb = mix(col.rgb, vec3(1.), highlight);

    d = length(uv-vec2(.25, -.2));
    float cheek = S(.2,.01, d)*.4; // SHARPEN: reduced blur
    cheek *= S(.17, .16, d); // SHARPEN: reduced blur
    col.rgb = mix(col.rgb, vec3(1., .1, .1), cheek);

    return col;
}

vec4 Smiley(vec2 uv, vec2 m, float smile) {
    vec4 col = vec4(0.);

    if(length(uv)<.5) {           // only bother about pixels that are actually inside the head
        float side = sign(uv.x);
        uv.x = abs(uv.x);
        vec4 head = Head(uv);
        col = mix(col, head, head.a);

        if(length(uv-vec2(.2, .075))<.175) {
            vec4 eye = Eye(within(uv, vec4(.03, -.1, .37, .25)), side, m, smile);
            col = mix(col, eye, eye.a);
        }

        if(length(uv-vec2(.0, -.15))<.3) {
            vec4 mouth = Mouth(within(uv, vec4(-.3, -.43, .3, -.13)), smile);
            col = mix(col, mouth, mouth.a);
        }

        if(length(uv-vec2(.185, .325))<.18) {
            vec4 brow = Brow(within(uv, vec4(.03, .2, .4, .45)), smile);
            col = mix(col, brow, brow.a);
        }
    }

    return applyBCS(col); // Apply BCS here
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t = iTime;

    vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= .5;
    uv.x *= iResolution.x/iResolution.y;

    // Apply overall scale
    uv /= overallScale;

    vec2 m = iMouse.xy / iResolution.xy;
    m -= .5;

    if(m.x<-.49 && m.y<-.49) {          // make it that he looks around when the mouse hasn't been used
        float s = sin(t*.5);
        float c = cos(t*.38);

        m = vec2(s, c)*.4;
    }

    if(length(m) > .707) m *= 0.;         // fix bug when coming back from fullscreen

    float d = dot(uv, uv);
    uv -= m*sat(.23-d);

    float smile = sin(t*.5)*.5+.5;
    vec4 smileyColor = Smiley(uv, m, smile); // Renamed 'col' to 'smileyColor' for clarity

    // Dark grey background
    // Note: This is a constant dark grey color. You can adjust the RGB values (0.0 to 1.0)
    // For example, vec4(0.1, 0.1, 0.1, 1.0) is a very dark grey.
    // vec4(0.2, 0.2, 0.2, 1.0) is a slightly lighter dark grey.
    vec4 backgroundColor = vec4(0.129, 0.169, 0.239, 1.0);

    // Calculate drop shadow
    vec2 shadowUv = uv - shadowOffset;
    float shadowMask = S(0.5 + shadowBlur, 0.5 - shadowBlur, length(shadowUv)); // Mask for the shadow
    shadowMask *= (1.0 - S(0.5, 0.49, length(uv))); // Ensure shadow is only behind the head, not on top

    vec3 finalColor = mix(backgroundColor.rgb, shadowColor, shadowMask * shadowOpacity);
    finalColor = mix(finalColor, smileyColor.rgb, smileyColor.a); // Blend smiley on top of shadow/background

    // Vignette effect
    vec2 vignetteUv = fragCoord.xy / iResolution.xy;
    vignetteUv *= 1.0 - vignetteUv.yx; // Transform UV for vignette
    float vignetteIntensity = 45.0; // Intensity of vignette
    float vignettePower = 0.20; // Falloff curve of vignette
    float vig = vignetteUv.x * vignetteUv.y * vignetteIntensity;
    vig = pow(vig, vignettePower);

    // Apply dithering to reduce banding
    const float ditherStrength = 0.05; // Strength of dithering (0.0 to 1.0)
    int x = int(mod(fragCoord.x, 2.0));
    int y = int(mod(fragCoord.y, 2.0));
    float dither = 0.0;
    if (x == 0 && y == 0) dither = 0.25 * ditherStrength;
    else if (x == 1 && y == 0) dither = 0.75 * ditherStrength;
    else if (x == 0 && y == 1) dither = 0.75 * ditherStrength;
    else if (x == 1 && y == 1) dither = 0.25 * ditherStrength;
    vig = clamp(vig + dither, 0.0, 1.0);

    finalColor *= vig; // Apply vignette by multiplying the color

    fragColor = vec4(finalColor, 1.0);
}