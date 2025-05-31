#pragma precision highp float // Encourage high precision if available

/*
    "The Universe Within" - by Martijn Steinrucken aka BigWIngs 2018
    Adapted for Kodi with modifications:
    + Removed iChannel0 (sound input)
    + Removed iMouse dependency
    + Unrolled loop to fix dynamic array indexing for GLSL ES compatibility
    + Faster initial brightness ramp (5 seconds)
    + Faster fade cycle (1 second total)
    + Thinner lines with scaled-down glow
    + Slower animation (iTime * 0.04)
    + Dynamic line thickness based on depth
    + Added color palette options (fixed, cycle specified, cycle spectrum)
    + Adjusted randomization and brightness for Kodi compatibility
    + Removed random color option
    + Reduced line thickness for closest lines by half
    + Added INVERT_COLORS mode (background becomes the chosen color, lines/stars are black)
    + Added MONOCHROME option for INVERT_COLORS (background becomes user-defined color)
    + Reduced star twinkle exponent to smooth out sudden on/off in inverted mode
*/

//#define SIMPLE

// Color mode options (uncomment one):
#define COLOR_MODE 0 // 0 = Fixed color, 1 = Cycle specified colors, 2 = Cycle full spectrum

// Fixed color selection (used when COLOR_MODE = 0):
#define FIXED_COLOR 1 // 0 = Green, 1 = Amber, 2 = Yellow, 3 = Cyan

// Uncomment to invert colors (background becomes the chosen color, lines/stars are black)
//#define INVERT_COLORS

// Uncomment to make INVERT_COLORS mode monochrome (background becomes MONOCHROME_COLOR)
//#define MONOCHROME

// Define the monochrome background color (RGB, range 0.0 to 1.0 per component)
#define MONOCHROME_COLOR vec3(0.80, 0.8, 0.8) // Default: light grey (vec3(0.8, 0.8, 0.8))

#define S(a, b, t) smoothstep(a, b, t)
#define NUM_LAYERS 4.

// Color palette inspired by old computer terminals
const vec3 COLOR_GREEN = vec3(0.2, 0.8, 0.2); // Not too bright green
const vec3 COLOR_AMBER = vec3(0.9, 0.6, 0.1); // Amber
const vec3 COLOR_YELLOW = vec3(0.9, 0.8, 0.2); // Warm yellow
const vec3 COLOR_CYAN = vec3(0.3, 0.7, 0.7); // Muted cyan

float N21(vec2 p) {
    vec3 a = fract(vec3(p.xyx) * vec3(213.897, 653.453, 253.098));
    a += dot(a, a.yzx + 79.76);
    return fract((a.x + a.y) * a.z);
}

vec2 GetPos(vec2 id, vec2 offs, float t) {
    float n = N21(id + offs);
    float n1 = fract(n * 11.7); // Adjusted for more initial variation
    float n2 = fract(n * 97.3); // Adjusted for more initial variation
    float a = t + n;
    return offs + vec2(sin(a * n1), cos(a * n2)) * 0.45; // Slightly increased range for more randomization
}

float GetT(vec2 ro, vec2 rd, vec2 p) {
    return dot(p - ro, rd); 
}

float LineDist(vec3 a, vec3 b, vec3 p) {
    return length(cross(b - a, p - a)) / length(p - a);
}

float df_line(in vec2 a, in vec2 b, in vec2 p) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);    
    return length(pa - ba * h);
}

float line(vec2 a, vec2 b, vec2 uv, float z) {
    // Thickness parameters: adjust these to fine-tune line thickness
    // r1: outer radius (controls the outer edge of the line's falloff)
    // r2: inner radius (controls the core where the line is at full brightness)
    // z ranges from 0 (far) to 1 (near); interpolate thickness accordingly
    float r1 = mix(0.02, 0.0075, z); // Far: 0.02, Near: 0.0075
    float r2 = mix(0.005, 0.0015, z); // Far: 0.005, Near: 0.0015
    
    float d = df_line(a, b, uv);
    float d2 = length(a - b);
    float fade = S(1.5, .5, d2);
    fade += S(.05, .02, abs(d2 - .75)) * 1.2; // Slightly increased for more variation
    
    return S(r1, r2, d) * fade;
}

float NetLayer(vec2 st, float n, float t, float z) {
    vec2 id = floor(st) + n;
    st = fract(st) - .5;
   
    vec2 p[9];
    int i = 0;
    for (float y = -1.; y <= 1.; y++) {
        for (float x = -1.; x <= 1.; x++) {
            p[i++] = GetPos(id, vec2(x, y), t);
        }
    }
    
    float m = 0.;
    float sparkle = 0.;
    
    // Unroll the loop to avoid dynamic array indexing
    // i = 0
    m += line(p[4], p[0], st, z);
    float d0 = length(st - p[0]);
    float s0 = (.0025 / (d0 * d0)); // Reduced from .005 to reduce glow
    s0 *= S(1., .7, d0);
    float pulse0 = sin((fract(p[0].x) + fract(p[0].y) + t) * 5.) * .4 + .6;
    pulse0 = pow(pulse0, 5.); // Reduced from 20 to 5 for smoother twinkling
    s0 *= pulse0;
    sparkle += s0;
    
    // i = 1
    m += line(p[4], p[1], st, z);
    float d1 = length(st - p[1]);
    float s1 = (.0025 / (d1 * d1));
    s1 *= S(1., .7, d1);
    float pulse1 = sin((fract(p[1].x) + fract(p[1].y) + t) * 5.) * .4 + .6;
    pulse1 = pow(pulse1, 5.);
    s1 *= pulse1;
    sparkle += s1;
    
    // i = 2
    m += line(p[4], p[2], st, z);
    float d2 = length(st - p[2]);
    float s2 = (.0025 / (d2 * d2));
    s2 *= S(1., .7, d2);
    float pulse2 = sin((fract(p[2].x) + fract(p[2].y) + t) * 5.) * .4 + .6;
    pulse2 = pow(pulse2, 5.);
    s2 *= pulse2;
    sparkle += s2;
    
    // i = 3
    m += line(p[4], p[3], st, z);
    float d3 = length(st - p[3]);
    float s3 = (.0025 / (d3 * d3));
    s3 *= S(1., .7, d3);
    float pulse3 = sin((fract(p[3].x) + fract(p[3].y) + t) * 5.) * .4 + .6;
    pulse3 = pow(pulse3, 5.);
    s3 *= pulse3;
    sparkle += s3;
    
    // i = 4 (skip self, p[4] to p[4])
    // No line, but compute sparkle
    float d4 = length(st - p[4]);
    float s4 = (.0025 / (d4 * d4));
    s4 *= S(1., .7, d4);
    float pulse4 = sin((fract(p[4].x) + fract(p[4].y) + t) * 5.) * .4 + .6;
    pulse4 = pow(pulse4, 5.);
    s4 *= pulse4;
    sparkle += s4;
    
    // i = 5
    m += line(p[4], p[5], st, z);
    float d5 = length(st - p[5]);
    float s5 = (.0025 / (d5 * d5));
    s5 *= S(1., .7, d5);
    float pulse5 = sin((fract(p[5].x) + fract(p[5].y) + t) * 5.) * .4 + .6;
    pulse5 = pow(pulse5, 5.);
    s5 *= pulse5;
    sparkle += s5;
    
    // i = 6
    m += line(p[4], p[6], st, z);
    float d6 = length(st - p[6]);
    float s6 = (.0025 / (d6 * d6));
    s6 *= S(1., .7, d6);
    float pulse6 = sin((fract(p[6].x) + fract(p[6].y) + t) * 5.) * .4 + .6;
    pulse6 = pow(pulse6, 5.);
    s6 *= pulse6;
    sparkle += s6;
    
    // i = 7
    m += line(p[4], p[7], st, z);
    float d7 = length(st - p[7]);
    float s7 = (.0025 / (d7 * d7));
    s7 *= S(1., .7, d7);
    float pulse7 = sin((fract(p[7].x) + fract(p[7].y) + t) * 5.) * .4 + .6;
    pulse7 = pow(pulse7, 5.);
    s7 *= pulse7;
    sparkle += s7;
    
    // i = 8
    m += line(p[4], p[8], st, z);
    float d8 = length(st - p[8]);
    float s8 = (.0025 / (d8 * d8));
    s8 *= S(1., .7, d8);
    float pulse8 = sin((fract(p[8].x) + fract(p[8].y) + t) * 5.) * .4 + .6;
    pulse8 = pow(pulse8, 5.);
    s8 *= pulse8;
    sparkle += s8;
    
    // Additional lines between points
    m += line(p[1], p[3], st, z);
    m += line(p[1], p[5], st, z);
    m += line(p[7], p[5], st, z);
    m += line(p[7], p[3], st, z);
    
    float sPhase = (sin(t + n) + sin(t * .1)) * .3 + .5; // Slightly increased range for variation
    sPhase += pow(sin(t * .1) * .5 + .5, 50.) * 2.5; // Slightly increased for more sparkle variation
    m += sparkle * sPhase;
    
    return m;
}

// HSV to RGB conversion for full spectrum cycling
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - iResolution.xy * .5) / iResolution.y;
    
    float t = iTime * .04; // Slowed from .1 to .04 for slower rotation
    
    float s = sin(t);
    float c = cos(t);
    mat2 rot = mat2(c, -s, s, c);
    vec2 st = uv * rot;  
    
    float m = 0.;
    for (float i = 0.; i < 1.; i += 1. / NUM_LAYERS) {
        float z = fract(t + i);
        float size = mix(15., 1., z);
        float fade = S(0., .6, z) * S(1., .8, z);
        m += fade * NetLayer(st * size, i, iTime * .04, z); // Slowed from iTime to iTime * .04
    }
    
    // Color selection based on COLOR_MODE
    vec3 baseCol;
    if (COLOR_MODE == 0) {
        // Fixed color
        if (FIXED_COLOR == 0) baseCol = COLOR_GREEN;
        else if (FIXED_COLOR == 1) baseCol = COLOR_AMBER;
        else if (FIXED_COLOR == 2) baseCol = COLOR_YELLOW;
        else baseCol = COLOR_CYAN;
    }
    else if (COLOR_MODE == 1) {
        // Cycle through specified colors (yellow -> green -> cyan -> amber -> yellow)
        float cycleTime = iTime * 0.016; // Match original cycling speed
        float phase = mod(cycleTime, 4.0);
        if (phase < 1.0) {
            baseCol = mix(COLOR_YELLOW, COLOR_GREEN, phase);
        } else if (phase < 2.0) {
            baseCol = mix(COLOR_GREEN, COLOR_CYAN, phase - 1.0);
        } else if (phase < 3.0) {
            baseCol = mix(COLOR_CYAN, COLOR_AMBER, phase - 2.0);
        } else {
            baseCol = mix(COLOR_AMBER, COLOR_YELLOW, phase - 3.0);
        }
    }
    else {
        // Cycle through full spectrum (COLOR_MODE == 2)
        float hue = mod(iTime * 0.016, 1.0); // Match original cycling speed
        baseCol = hsv2rgb(vec3(hue, 0.8, 0.9)); // Saturation and value slightly reduced for a softer look
    }
    
    // Compute final color with optional inversion and monochrome
    vec3 col;
#ifdef INVERT_COLORS
    // Inverted: background is baseCol (or monochrome), lines/stars are black
#ifdef MONOCHROME
    // Monochrome: use user-defined MONOCHROME_COLOR
    col = MONOCHROME_COLOR * (1.0 - m);
#else
    // Use the chosen color
    col = baseCol * (1.0 - m);
#endif
#else
    // Normal: background is black, lines/stars are baseCol
    col = baseCol * m;
#endif
    
    #ifdef SIMPLE
    uv *= 10.;
    col = vec3(1) * NetLayer(uv, 0., iTime * .04, 0.);
    uv = fract(uv);
    #else
    col *= 1. - dot(uv, uv); // Apply vignette (darken corners)
    t = mod(iTime, 230.);
    col *= S(0., 5., t) * S(229.5, 229., t); // Faster initial ramp (5s), faster fade (1s cycle)
    #endif
    
    fragColor = vec4(col, 1);
}