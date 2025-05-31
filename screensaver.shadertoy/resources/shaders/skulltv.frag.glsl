/*
    "Deadly Halftones" by Julien Vergnaud @duvengar-2018
    Adapted for Kodi as a single GLSL file (GLSL 120)
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
*/



// --- Common Code ---
#define T iTime
#define R iResolution.xy
#define S(a, b, c) smoothstep(a, b, c)
#define PI acos(-1.)
#define CEL rem(R)
#define LOWRES 320.

float rem(vec2 iR) {
    float slices = floor(iR.y / LOWRES);
    if (slices < 1.) return 4.;  
    else if (slices == 1.) return 6.;
    else if (slices == 2.) return 8.;
    else if (slices >= 3.) return 10.;
    else if (slices >= 4.) return 12.;
    return 10.; // Fallback
}

float hash2(vec2 p) {  
    vec3 p3 = fract(vec3(p.xyx) * .2831);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

mat3 m = mat3( .00,  .80,  .60,
              -.80,  .36, -.48,
              -.60, -.48,  .64 );

float hash(float n) {
    return fract(sin(n) * 4121.15393) + .444;   
}

float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 157.0 + 113.0 * p.z;
    return mix(mix(mix(hash(n + 00.00), hash(n + 1.000), f.x),
                   mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
               mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                   mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

// --- Helper Functions ---
#define IT 64
#define PR .0005

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return max(min(d.x, min(d.y, d.z)), .0) + length(max(d, .0));
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float smax(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
    return mix(b, a, h) + k * h * (1.0 - h);
}

float sdSkull(vec3 p, float s) {
    float ss = noise(p * 9.);
    ss = mix(s, ss * .5, .1);
    vec3 sp = vec3(p.x, p.y, abs(p.z));
    float shape = sdSphere(p - vec3(.0, .05, .0), s * .95 * cos(cos(p.y * 11.) * p.z * 2.3));
    shape = smin(shape, sdSphere(p - vec3(.10, 0.23, 0.00), s * .82), .09);
    shape = smin(shape, sdSphere(p - vec3(-.1, 0.24, 0.00), s * .82), .09);
    shape = smin(shape, sdSphere(sp - vec3(.25, 0.07, 0.10), s * .36 * cos(p.y * 7.0)), .02);
    shape = smax(shape, -sdSphere(sp - vec3(.15, -.01, 0.31), s * .28 * cos(p.x * .59)), .02);
    shape = smin(shape, sdSphere(sp - vec3(.22, -.13, .18), s * .11), .09);
    shape = max(shape, -sdSphere(p - vec3(.0, .05, .0), s * .90 * cos(cos(p.y * 11.) * p.z * 2.3)));
    shape = smax(shape, -sdSphere(p - vec3(.10, 0.23, 0.00), s * .74), .02);
    shape = smax(shape, -sdSphere(p - vec3(-.1, 0.24, 0.00), s * .74), .02);
    shape = smax(shape, -sdSphere(p - vec3(.0, 0.24, 0.00), s * .74), .02);
    shape = smax(shape, -sdSphere(sp - vec3(.32, -.04, .140), s * .28 * cos(p.y * 10.)), .03);
    float temp = sdSphere(p - vec3(cos(.0) * .220, -.05, sin(.0) * .3), s * .35 * cos(sin(p.y * 22.) * p.z * 24.));
    temp = smax(temp, -sdSphere(sp - vec3(.32, -.04, .140), s * .35 * cos(p.y * 10.)), .02);
    temp = smax(temp, -sdSphere(p - vec3(.0, .05, .0), s * .90 * cos(cos(p.y * 11.) * p.z * 2.3)), .02);
    shape = smin(shape, temp, .015);
    shape = smax(shape, -sdSphere(p - vec3(cos(.0) * .238, -.09, sin(.0) * .3), s * .3 * cos(sin(p.y * 18.) * p.z * 29.)), .002);
    shape = smax(shape, -sdSphere(p - vec3(-.15, -0.97, .0), s * 2.5), .01);
    shape = smax(shape, -sdSphere(p - vec3(-.23, -0.57, .0), abs(ss) * 1.6), .01);
    temp = smax(sdSphere(p - vec3(.13, -.26, .0), .45 * s), -sdSphere(p - vec3(.125, -.3, .0), .40 * s), .01);
    temp = smax(temp, -sdSphere(p - vec3(-.2, -.1, .0), .9 * s), .03);
    temp = smax(temp, -sdSphere(p - vec3(.13, -.543, .0), .9 * s), .03);
    temp = max(temp, -sdSphere(p - vec3(.0, .02, .0), s * .90 * cos(cos(p.y * 11.) * p.z * 2.3)));
    shape = smin(shape, temp, .07);
    temp = sdSphere(p - vec3(.26, -.29, .018), .053 * s);
    temp = min(temp, sdSphere(p - vec3(.26, -.29, -.018), .053 * s));
    temp = min(temp, sdSphere(sp - vec3(.25, -.29, .05), .05 * s));
    temp = min(temp, sdSphere(sp - vec3(.235, -.29, .08), .05 * s));
    temp = min(temp, sdSphere(sp - vec3(.215, -.28, .1), .05 * s));
    temp = max(temp, -sdSphere(p - vec3(.16, -.35, .0), .33 * s));
    temp = min(temp, sdSphere(sp - vec3(.18, -.28, .115), .05 * s));
    temp = min(temp, sdSphere(sp - vec3(.14, -.28, .115), .06 * s));
    temp = min(temp, sdSphere(sp - vec3(.11, -.28, .115), .06 * s));
    temp = min(temp, sdSphere(sp - vec3(.08, -.28, .115), .06 * s));
    shape = smin(shape, temp, .03);
    temp = sdSphere(p - vec3(.1, -.32, .0), .43 * s);
    temp = smax(temp, -sdSphere(p - vec3(.1, -.32, .0), .37 * s), .02);
    temp = smax(temp, -sdSphere(p - vec3(.1, -.034, .0), 1.03 * s), .02);
    temp = smax(temp, -sdSphere(p - vec3(.0, -.4, .0), .35 * s), .02);
    temp = smin(temp, sdBox(sp - vec3(.04 - .03 * cos(p.y * 20.2), -.23, .27 + sin(p.y) * .27), vec3(cos(p.y * 4.) * .03, .12, .014)), .13);
    temp = max(temp, -sdSphere(sp - vec3(.0, .153, .2), .85 * s));
    temp = smin(temp, sdSphere(sp - vec3(.2, -.45, 0.05), .05 * s), .07);
    shape = smin(shape, temp, .02);
    temp = sdSphere(p - vec3(.23, -.34, .018), .053 * s);
    temp = min(temp, sdSphere(p - vec3(.23, -.34, -.018), .053 * s));
    temp = min(temp, sdSphere(sp - vec3(.22, -.34, .048), .053 * s));
    temp = min(temp, sdSphere(sp - vec3(.20, -.34, .078), .053 * s));
    temp = min(temp, sdSphere(sp - vec3(.17, -.35, .098), .053 * s));
    temp = min(temp, sdSphere(sp - vec3(.14, -.35, .11), .053 * s));
    temp = min(temp, sdSphere(sp - vec3(.11, -.35, .11), .053 * s));
    temp = min(temp, sdSphere(sp - vec3(.08, -.35, .11), .053 * s));
    shape = 1.5 * smin(shape, temp, .025);
    return shape;
}

vec2 map(vec3 pos) {
    return vec2(.5 * sdSkull(pos, .35), 39.);
}

vec2 castRay(vec3 ro, vec3 rd) {
    int i = 0;
    float close = 1.0;
    float far = 3.0;
    float p = PR * close;
    float id = .0;
    while (i++ < IT) {
        vec2 res = map(ro + rd * close);
        if (abs(res.x) < p || close > far) break;
        close += res.x;
        id = res.y;
    }
    return vec2(close, id);
}

vec3 calcNormal(vec3 pos) {
    vec2 e = vec2(1., -1.) * PR;
    return normalize(e.xyy * map(pos + e.xyy).x +
                     e.yyx * map(pos + e.yyx).x +
                     e.yxy * map(pos + e.yxy).x +
                     e.xxx * map(pos + e.xxx).x);
}

vec3 renderSkull(vec2 p, vec3 ro, vec3 rd) {
    vec2 res = castRay(ro, rd);
    float t = res.x;
    float m = res.y;
    vec3 col = vec3(0.988, 0.949, 0.0); // Bone-colored white
    col = mix(col, vec3(.0), 1. - exp(-0.02 * pow(t, 9.5)));
    return clamp(col, .0, 1.0);
}

mat3 setCamera(vec3 ro) {
    vec3 cw = normalize(-ro);
    vec3 cp = vec3(sin(.0), cos(.0), .0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

float make_dot(vec2 uv, float r, float c) {
    return smoothstep(r - .1, r, min(length((uv - vec2(c / 2.)) * 2.), r));
}

// --- Shadertoy Entry Point ---
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 U = fragCoord;
    float amp = sin(T) * 0.5 + 0.5; // Procedural replacement for sound
    vec2 V = 1. - 2. * U / R;
    vec2 off = vec2(S(.0, amp * CEL * .5, cos(T + U.y / R.y * 5.0)), .0) - vec2(.5, .0);

    // Buffer A: Raymarched Skull   245.0/255.0, 245.0/255.0, 220.0/255.0
    vec2 p = (-R.xy + 2.0 * fragCoord) / R.y;
    vec3 ro = vec3(1.6 * cos(iTime * .6), .0, 1.6 * sin(iTime * .6));
    mat3 ca = setCamera(ro);
    vec3 rd = ca * normalize(vec3(p.xy, 2.));
    vec3 col = renderSkull(p, ro, rd);
    col = pow(col, vec3(0.25));

    // Buffer B: Halftone Postprocessing
    float pixel_color = .45 * (col.x + col.y + col.z);
    float dot_radius = pixel_color;
    vec2 modU = mod(fragCoord, CEL);
    vec4 dot_color = vec4(make_dot(modU, ceil(dot_radius * CEL), CEL));
    vec4 bufferBResult = 1. - dot_color;

    // Image Tab: Final Postprocessing
    float r = bufferBResult.x;
    float g = bufferBResult.x;
    float b = bufferBResult.x;
    fragColor = vec4(.0, .1, .2, 1.);
    fragColor += .06 * hash2(T + V * vec2(1462.439, 297.185));
    fragColor += vec4(r, g, b, 1.);
    fragColor *= 1.25 * vec4(1. - S(.1, 1.8, length(V * V)));

    // Enhanced Horizontal Scan Lines as Top Layer
    float scanLine = 0.75 + .35 * sin(fragCoord.y * 1.9); // Adjusted frequency and amplitude
    fragColor *= scanLine;

    fragColor += .14 * vec4(pow(1. - length(V * vec2(.5, .35)), 3.), .0, .0, 1.);
}


