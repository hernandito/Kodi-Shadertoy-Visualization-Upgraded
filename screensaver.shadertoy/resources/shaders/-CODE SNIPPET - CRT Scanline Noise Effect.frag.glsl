Please add a CRT effect to my shader with the following components:

    A dark background color (default vec4(.0, .1, .2, 1.)) with a subtle noise effect.
    Thin horizontal scan lines applied as a post-processing effect.
    A screen vignette effect with a slight reddish tint.
    Define the background color as #define BACKGROUND_COLOR at the top for easy tweaking. Use the implementation provided below. Insert the definitions and noise function at the top of the shader, place the background initialization before any rendering code, and apply the vignette and scanline effects after all rendering as post-processing steps.
	
// --- CRT Effect Definitions ---
// Add these at the top of the shader
#define MACRO_TIME iTime
#define MACRO_RES iResolution.xy
#define MACRO_SMOOTH(a, b, c) smoothstep(a, b, c)
#define BACKGROUND_COLOR vec4(.0, .1, .2, 1.) // Tweakable dark background color

// Noise function for the background
float hash2(vec2 p) {  
    vec3 p3 = fract(vec3(p.xyx) * .2831);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// --- CRT Effect Application ---
// Add this in the mainImage function, before rendering other elements
vec2 U = fragCoord;
vec2 V = 1. - 2. * U / MACRO_RES;

// 1. Dark Background with Noise
fragColor = BACKGROUND_COLOR;
fragColor += .06 * hash2(MACRO_TIME + V * vec2(1462.439, 297.185));

// Add your rendering (e.g., shapes, text) here, combining with fragColor...

// 2. Vignette Effect (Apply after rendering)
fragColor *= 1.25 * vec4(1. - MACRO_SMOOTH(.1, 1.8, length(V * V)));
fragColor += .14 * vec4(pow(1. - length(V * vec2(.5, .35)), 3.), .0, .0, 1.);

// 3. Horizontal Scanline Effect (Apply last)
float scanLine = 0.75 + .35 * sin(fragCoord.y * 1.9);
fragColor *= scanLine;