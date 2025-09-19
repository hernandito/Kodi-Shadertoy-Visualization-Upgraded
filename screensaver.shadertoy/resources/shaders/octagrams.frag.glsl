// "Octgrams ++" — neon kaleidoscope boxes (volumetric SDF look)
// preserves the original lattice feel; adds 8-fold polar symmetry,
// nicer camera, palette, and gentle bloom-ish accumulation.

// Shadertoy uniforms: iTime, iResolution
precision highp float;

// ---------------- USER PARAMETERS ----------------
#define ANIMATION_SPEED 0.05

#define BRIGHTNESS 0.7
#define CONTRAST   1.70

// Change this value to adjust the primary color
#define MAIN_COLOR vec3(.5, 0.275, 0.04)
// -------------------------------------------------

float gTime = 0.0;

// ---------- utils
mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }

// Simplified BCS function without saturation
vec3 bcs_final(vec3 color, float brightness, float contrast) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    return color;
}

float sdBox(vec3 p, vec3 b){
    vec3 q = abs(p)-b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float hash21(vec2 p){
    p = fract(p*vec2(123.34,456.21));
    p += dot(p,p+34.45);
    return fract(p.x*p.y);
}

// iq-style cosine palette
vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d){
    return a + b*cos(6.28318*(c*t + d));
}

// 8-fold polar kaleidoscope fold in XZ plane
vec3 octFoldXZ(vec3 p){
    // convert to polar
    float r = length(p.xz);
    float a = atan(p.z, p.x);      // [-pi, pi]
    float k = 8.0;
    float seg = 6.28318530718 / k;
    // fold angle into central wedge [-seg/2, seg/2]
    a = mod(a + seg*0.5, seg) - seg*0.5;
    // optional star pinch for an "octagram" vibe
    float star = 0.22 + 0.08*sin(4.0*a);
    r *= (1.0 - star*0.45);
    vec2 xz = vec2(cos(a), sin(a))*r;
    p.x = xz.x; p.z = xz.y;
    return p;
}

// single “box glyph”
float boxGlyph(vec3 p, float s){
    // slight rotation wobble
    p.xy *= rot(0.35 + 0.25*sin(gTime*0.7));
    p.yz *= rot(0.15 + 0.20*cos(gTime*0.5));
    float d = sdBox(p, vec3(0.4, 0.4, 0.10))*s;
    // turn shell negative so abs(d) gives a glowing hull
    return -d;
}

// clustered glyphs, animated like your original
float boxSet(vec3 p){
    vec3 o = p;
    float wob = sin(gTime*0.4);
    float sc  = 2.0 - abs(wob)*1.5;

    float d1, d2, d3, d4, d5, d6;

    p = o; p.y += wob*2.5;  d1 = boxGlyph(p, sc);
    p = o; p.y -= wob*2.5;  d2 = boxGlyph(p, sc);
    p = o; p.x += wob*2.5;  d3 = boxGlyph(p, sc);
    p = o; p.x -= wob*2.5;  d4 = boxGlyph(p, sc);
    p = o;                d5 = boxGlyph(p, 0.5)*6.0;
    p = o;                d6 = boxGlyph(p, 0.5)*6.0;

    return max(max(max(max(max(d1,d2),d3),d4),d5),d6);
}

// scene distance-as-density map
float map(vec3 p){
    // periodize space (tiling)
    p = mod(p-2.0, 4.0) - 2.0;

    // fold to octagonal wedge in XZ
    p = octFoldXZ(p);

    return boxSet(p);
}

// soft raymarch (accumulating glow)
vec3 render(vec3 ro, vec3 rd, float time_param){
    float t = 0.05;
    float ac = 0.0;
    float lum = 0.0;

    // subtle random per-pixel step jitter to reduce banding
    float j = hash21(gl_FragCoord.xy/iResolution.xy)*0.5 + 0.5;

    for(int i=0;i<100;i++){
        vec3 pos = ro + rd*t;
        gTime = time_param - float(i)*0.01;    // trail time (like original)

        float d = map(pos);

        // turn SDF into a soft density field
        float ad = max(abs(d), 0.005);

        // two accumulation channels: narrow core + wider bloom skirt
        float core  = exp(-ad*26.0);
        float skirt = exp(-ad*8.0)*0.12;

        ac  += core;
        lum += skirt;

        // march forward (slower near features for detail)
        t += ad*(0.45 + 0.15*j);

        // cheap early out
        if(t>60.0) break;
    }

    // base neon palette driven by accumulated density
    float hue = 0.18 + 0.08*sin(time_param*0.7) + 0.35*pow(clamp(ac*0.02,0.0,1.0),0.6);
    vec3 base = pal(hue,
        vec3(0.25,0.18,0.20),
        vec3(0.65,0.55,0.75),
        vec3(0.60,0.45,0.30),
        vec3(0.10,0.75,0.90)
    );

    // colorize by density
    vec3 col = base*(0.015*ac) + MAIN_COLOR*0.6*(0.6+0.4*lum);

    // gentle vignette + exposure + gamma
    float v = pow(1.0 - dot(gl_FragCoord.xy/iResolution.xy - 0.5, gl_FragCoord.xy/iResolution.xy - 0.5)*2.2, 0.7);
    col *= v;

    col = 1.0 - exp(-col*1.8); // filmic-ish
    col = pow(col, vec3(0.4545));

    return col;
}

// ---------- main
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    float time_scaled = iTime * ANIMATION_SPEED;
    
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / min(iResolution.x, iResolution.y);

    // camera: smooth orbit with slight bob
    float R  = mix(2.5, 4.0, 0.5+0.5*sin(time_scaled*0.23));
    vec3  ro = vec3(R*cos(time_scaled), 0.2 + 0.4*sin(time_scaled*0.37), R*sin(time_scaled));

    // look-at origin with soft roll
    vec3  ta = vec3(0.0, 0.0, 0.0);
    vec3  ww = normalize(ta - ro);
    vec3  uu = normalize(cross(vec3(0.0,1.0,0.0), ww));
    vec3  vv = cross(ww, uu);

    // small dynamic FOV
    float fov = 1.6 + 0.15*sin(time_scaled*0.31);
    vec3 rd = normalize(uu*uv.x + vv*uv.y + ww*fov);

    // subtle barrel roll over time
    float roll = 0.12*sin(time_scaled*0.19);
    rd.xz *= rot(roll);
    
    vec3 col = render(ro, rd, time_scaled);

    // Apply BCS post-processing adjustments
    col = bcs_final(col, BRIGHTNESS, CONTRAST);
    
    //---------------------------------------------------------
    // Vignette and Dithering
    //---------------------------------------------------------
    vec2 uv_vig = fragCoord.xy / iResolution.xy;
    uv_vig *= 1.0 - uv_vig.yx; // Transform UV for vignette
    float vignetteIntensity = 45.0; // Intensity of vignette
    float vignettePower = 0.80; // Falloff curve of vignette
    float vig = uv_vig.x * uv_vig.y * vignetteIntensity;
    vig = pow(vig, vignettePower);

    // Apply dithering to reduce banding
    const float ditherStrength = 0.0; // Strength of dithering (0.0 to 1.0)
    int x = int(mod(fragCoord.x, 2.0));
    int y = int(mod(fragCoord.y, 2.0));
    float dither = 0.0;
    if (x == 0 && y == 0) dither = 0.25 * ditherStrength;
    else if (x == 1 && y == 0) dither = 0.75 * ditherStrength;
    else if (x == 0 && y == 1) dither = 0.75 * ditherStrength;
    else if (x == 1 && y == 1) dither = 0.25 * ditherStrength;
    vig = clamp(vig + dither, 0.0, 1.0);

    col *= vig; // Apply vignette by multiplying the color
    //---------------------------------------------------------
    
    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
  "title": "Octgrams ++",
  "description": "Neon 8-fold kaleidoscope boxes with volumetric glow",
  "model": "person"
}
*/