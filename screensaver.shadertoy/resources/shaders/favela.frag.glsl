// Favela by Julien Vergnaud @duvengar-2018 (Kodi Version with Animation Speed and Scale)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
///////////////////////////////////////////////////////////////////////////////////////////
// Based on the Minimal Hexagonal Grid example from @Shane.

// Minimal Hexagonal Grid - Shane
// https://www.shadertoy.com/view/Xljczw
///////////////////////////////////////////////////////////////////////////////////////////////////

const vec2 s = vec2(1, 1.7320508);

float hex(in vec2 p)
{
    p = abs(p);
    return max(dot(p, s *.5), p.x );
}

vec4 getHex(vec2 p)
{  
    vec4 hC = floor(vec4(p, p - vec2(.5, 1)) / s.xyxy) + .5;
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    return dot(h.xy, h.xy) < dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + vec2(.5, 1));
}
/////////////////////////////////////////////////////////////////////////////////////////////////////

// Define noise functions for Kodi GLSL ES compatibility
float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash2(i + vec2(0.0, 0.0)), hash2(i + vec2(1.0, 0.0)), u.x),
               mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    for (int i = 0; i < 6; ++i) {
        v += a * noise(p);
        p = p * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

#define M(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define S(a, b, c) smoothstep(a, b, c)
#define SAT(a) clamp(a, 0.0, 1.0)
#define T iTime
#define PI acos(-1.0)
#define TWO_PI (PI * 2.0)
#define GRID_SCALE 0.125  // Increased from 0.4 to show fewer, larger cubes
#define BLUR 0.02
#define ANIM_SPEED 0.50  // Animation speed multiplier (1.0 = original speed)
const float LOWRES = 50.0;

float rem(vec2 iR)
{
    float slices = 10.0 * floor(iR.y / LOWRES);
    return sqrt(slices);
}

float stripes(vec2 uv, mat2 rot, float num, float amp, float blr)
{
    uv *= rot;
    float v = smoothstep(amp + blr, amp - blr, length(fract(uv.x * num) - 0.5));
    float h = smoothstep(amp + blr, amp - blr, length(fract(uv.x * num) - 0.5));
    return h;
}

float dfDiamond(vec2 h) {
    h *= s;									// rescale diamond vertically with the helper vector
    vec2 p = vec2(abs(h.x), abs(h.y));
    float d = (p.x + p.y) / 0.5; 
    return d;
}

float rect(vec2 uv, vec2 p, float w, float h, float b)
{
    uv += p;
    float rv = S(h, h + b, length(uv.x));
    float rh = S(w, w + b, length(uv.y));
    return rv + rh;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // set up pixel coord
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    uv *= 1.1;                                                   // scale up the pixels domain
    uv *= M(PI);                                                 // rotate the pixels domain

    // variables
    float motion = (T * ANIM_SPEED) * 0.5;    // Adjusted with ANIM_SPEED
    float SCALE = rem(iResolution.xy) * GRID_SCALE;    // Use GRID_SCALE instead of SIZE
    float blr = fwidth(uv.x) * length(uv) * 8.0;
    vec2 pos = uv - motion;					   // position
    vec3 lights = vec3(0.0);
    vec3 blights = vec3(0.0);
    float sun = cos((T * ANIM_SPEED) * 0.3);  // Adjusted with ANIM_SPEED

    // Hexagons grid
    vec4 h = getHex(pos + SCALE * uv + s.yx); // hexagons center
    float eDist = hex(h.xy);                   // hexagon edge distance
    float eDist2 = hex(h.xy + vec2(0.0, 0.25));
    float cDist = length(h.xy);

    float tilt = hash2(h.zw * 2376.345791);     // random value depending on cell ids

    // sorting the hexagons
    float hills = 0.0;
    float red = 0.0;
    float flip = 0.0;
    float empty = 0.0;
    float tex = 0.0;
    float wnds = 0.0;
    float tree = 0.0;
    float doors = 0.0;

    float ff = cos(5.0 * sin(h.z - h.w) * tilt);
    if (ff > 0.0)
    {
        flip = 1.0;
        h.xy *= M(PI);
        empty = ff > 0.99 ? 1.0 : 0.0;
    }

    vec2 pol = vec2(atan(h.x, h.y) / TWO_PI + 0.5, length(uv));
    vec2 ang = vec2(0.333333, 0.666666);

    if (pol.x <= ang.x || tilt >= 0.7)
    {
        wnds = 1.0;
        if (tilt >= 0.9)
        {
            doors = 1.0;
        }
    }

    if (flip == 0.0 && noise(h.zw) * 0.5 > 0.3)
    {
        hills = 1.0;
        tree = tilt > 0.5 ? 1.0 : 0.0;
    }

    // create the windows elements
    vec2 pat = h.xy;
    vec2 pat2 = h.xy - (vec2(flip == 1.0 ? 0.05 : -0.05, flip == 1.0 ? 0.03 : -0.03));
    vec2 pat3 = h.xy - (vec2(flip == 0.0 ? 0.05 : -0.05, flip == 1.0 ? 0.05 : -0.05));

    float s1 = stripes(pat, M(0.0) * M(0.02), flip == 1.0 ? 2.0 : 4.0, 0.3, blr);
    float s2 = stripes(pat, M(TWO_PI * 0.666) * M(0.02), 4.0, 0.3, blr);
    float s3 = stripes(pat, M(TWO_PI * 0.333) * M(0.02), 4.0, 0.3, blr);
    float s4 = stripes(pat, M(0.0) * M(0.02), flip == 1.0 ? 4.0 : 2.0, 0.3, blr);

    float m1 = stripes(pat2, M(0.0) * M(0.02), flip == 1.0 ? 2.0 : 4.0, 0.3, blr);
    float m2 = stripes(pat2, M(TWO_PI * 0.333) * M(0.02), 4.0, 0.3, blr);

    float ml1 = stripes(pat3, M(0.0) * M(0.02), flip == 1.0 ? 4.0 : 4.0, 0.3, blr);
    float ml2 = stripes(pat3, M(TWO_PI * 0.666) * M(0.02), 4.0, 0.3, blr);

    float windowsR = min(s1, s3);
    float windowsL = min(s4, s2);

    float maskR = min(m1, m2);
    float maskL = min(ml1, ml2);

    float winnerR = min(windowsR, maskR);
    float winnerL = min(windowsL, maskL);

    float wbevelR = min(windowsR, windowsR - winnerR);
    float wbevelL = min(windowsL, windowsL - winnerL);

    float blr2 = BLUR * 8.0;
    float bs1 = stripes(pat, M(0.0) * M(0.02), flip == 1.0 ? 2.0 : 4.0, 0.3, blr2);
    float bs2 = stripes(pat, M(TWO_PI * 0.666) * M(0.02), 4.0, 0.3, blr2);
    float bs3 = stripes(pat, M(TWO_PI * 0.333) * M(0.02), 4.0, 0.3, blr2);
    float bs4 = stripes(pat, M(0.0) * M(0.02), flip == 1.0 ? 4.0 : 2.0, 0.3, blr2);

    float bm1 = stripes(pat2, M(0.0) * M(0.02), flip == 1.0 ? 2.0 : 4.0, 0.3, blr2);
    float bm2 = stripes(pat2, M(TWO_PI * 0.333) * M(0.02), 4.0, 0.3, blr2);

    float bml1 = stripes(pat3, M(0.0) * M(0.02), flip == 1.0 ? 4.0 : 4.0, 0.3, blr2);
    float bml2 = stripes(pat3, M(TWO_PI * 0.666) * M(0.02), 4.0, 0.3, blr2);

    float bwindowsR = min(bs1, bs3);
    float bwindowsL = min(bs4, bs2);

    float bmaskR = min(bm1, bm2);
    float bmaskL = min(bml1, bml2);

    float bwinnerR = min(bwindowsR, bmaskR);
    float bwinnerL = min(bwindowsL, bmaskL);

    // shading the cubes faces
    vec3 col = vec3(1.0);
    float n1 = 0.5 - fbm((uv - motion * 0.24) * 20.0);
    float n2 = 0.5 - fbm((uv - motion * 0.31) * 5.0);
    col += 0.4 * (max(n1, n2));

    vec3 paint = vec3(cos(h.z + h.w * 0.2), cos(tilt) * 0.3, noise(h.zw));

    vec2 facespos = h.xy;
    facespos *= M(TWO_PI * ang.x);

    vec2 fa = facespos;
    float shw = 0.7 * S(1.1 + blr, 1.0 - blr, dfDiamond(facespos - vec2(0.0, 0.3)));
    facespos *= M(TWO_PI * ang.x);

    vec2 fb = facespos;
    shw += 0.2 * S(1.1 + blr, 1.0 - blr, dfDiamond(facespos - vec2(0.0, 0.3)));
    col -= shw;

    float fao = clamp(smoothstep(1.0, 0.0, eDist), 0.0, 1.0);
    fao = flip == 0.0 || empty == 1.0 ? 0.65 * fao : 0.65 * (1.0 - fao);
    col -= fao;
    col = mix(col, vec3(0.7, 0.3, 0.0), 0.45);

    if (pol.x <= ang.x)
    {
        if (hills == 0.0)
        {
            col = tilt > 0.2 ? col : col + 0.3 * paint;
            vec2 dir = cos((T * ANIM_SPEED) + h.z) > 0.0 ? M(PI / 3.0) * h.xy : -M(PI / 3.0) * h.xy; // Adjusted with ANIM_SPEED
            float blink = S(1.0, 0.9, fract(dir.x * 2.0) * 3.333 - 0.5) - 0.5;

            float on = S(-1.0, 1.0, sun);
            float light = (-1.0 + tilt * floor(on * 10.0) > 0.0 ? blink : -1.0);
            light = empty == 1.0 ? -0.5 : light;
            float lum = light > 0.0 ? -0.1 : 0.3;

            col -= tilt > 0.0 ? lum * wbevelR : 0.0;
            col += tilt > 0.0 ? light * winnerR : 0.0;

            lights += tilt > 0.0 ? light * winnerR : 0.0;
            blights += tilt > 0.8 && flip == 1.0 ? light * bwinnerR : 0.0;

            float t1 = stripes(pat - vec2(0.01, 0.0), M(0.0) * M(0.02), 8.0, 0.05, blr * 2.0);
            float tt = stripes(pat - vec2(fract(M(-PI * 0.666) * pat * 8.0).x > 0.5 ? 0.20 : 0.01, 0.00), M(0.0) * M(0.02), 8.0, 0.05, blr * 2.0);
            float t2 = stripes(pat - vec2(-0.19, 0.01), M(TWO_PI * 0.333) * M(0.02), 16.0, 0.05, blr * 2.0);
            col += hills == 0.0 ? 0.1 * (t2 + tt) * pow(noise((uv - motion * 0.15) * 20.0), 1.5) : 0.0;
        }
        else
        {
            col = mix(col, vec3(0.52, 0.13, 0.01), 0.5);
            col = mix(col, vec3(0.5, 0.45, 0.1), 1.0 - S(0.1, 0.3, length(h.y - fb.y)));
        }
    }

    if (pol.x >= ang.y)
    {
        col += tilt > 0.2 ? vec3(0.0) : 0.3 * paint;
        vec2 dir = cos((T * ANIM_SPEED) + h.z) > 0.0 ? M(PI) * h.xy : -M(PI) * h.xy; // Adjusted with ANIM_SPEED
        float blink = S(1.0, 0.9, fract(dir.x * 2.0) * 3.333 - 0.5) - 0.5;
        float on = S(-1.0, 1.0, sun);
        float light = 0.5 * (-1.0 + tilt * floor(on * 10.0) > 0.0 ? blink : -1.0);
        col = hills == 1.0 ? mix(col, vec3(0.52, 0.13, 0.01), 0.5) : col;
        col = hills == 1.0 ? mix(col, vec3(0.5, 0.45, 0.1), 1.0 - S(0.1, 0.3, length(h.y - fa.y))) : col;
        col += tilt > 0.8 && flip == 1.0 ? light * winnerL : 0.0;
        col += tilt > 0.8 && flip == 1.0 ? light * 0.3 * wbevelL : 0.0;
        lights += tilt > 0.8 && flip == 1.0 ? light * winnerL : 0.0;
        blights += tilt > 0.8 && flip == 1.0 ? light * bwinnerL : 0.0;

        float t1 = stripes(pat - vec2(0.01, 0.0), M(0.0) * M(0.02), 8.0, 0.05, blr * 2.0);
        float tt = stripes(pat - vec2(fract(M(-PI * 0.333) * pat * 8.0).x > 0.5 ? 0.20 : 0.01, 0.00), M(0.0) * M(0.02), 8.0, 0.05, blr * 2.0);
        float t2 = stripes(pat - vec2(-0.19, 0.01), M(TWO_PI * 0.666) * M(0.02), 16.0, 0.05, blr * 2.0);

        col += hills == 0.0 ? 0.15 * (t2 + tt) * pow(noise((uv - motion * 0.15) * 20.0), 1.5) : 0.0;

        vec2 pos1 = vec2(0.25, 0.0);
        vec2 pos2 = vec2(0.215, 0.0);
        float door = stripes(pat + pos1, M(0.0) * M(0.02), 1.0, 0.05, blr);
        float doorcut = 1.0 - stripes(pat + pos1, M(TWO_PI * 0.666) * M(0.02), 1.0, 0.18, blr);
        float maskcut = 1.0 - stripes(pat + pos2, M(TWO_PI * 0.666) * M(0.02), 1.0, 0.18, blr);
        float doormask = stripes(pat + pos2, M(0.0) * M(0.02), 1.0, 0.05, blr);
        door = min(door, doorcut);
        doormask = min(doormask, maskcut);
        float dbevel = SAT(min(door, door - doormask));
        col += doors == 1.0 && flip == 0.0 && hills == 0.0 ? dbevel * 0.2 : 0.0;
        col += doors == 1.0 && flip == 0.0 && hills == 0.0 ? doormask * 0.4 : 0.0;
    }

    if (pol.x > ang.x && pol.x < ang.y)
    {
        if (hills == 1.0)
        {
            col += 0.1 * vec3(0.5, 0.45, 0.1);
            float grass = 1.0 - S(1.1 + blr, 0.5 - blr, dfDiamond(h.xy - vec2(0.0, 0.3)));
            col = mix(vec3(0.5, 0.45, 0.1), col, 1.0 - grass);
        }
    }

    vec2 ang2 = ang + vec2(-0.1665, 0.1665);
    if (pol.x <= ang2.x || pol.x >= ang2.y)
    {
    }

    if (tree == 1.0)
    {
        float tw = 0.07;
        float crown = S(0.25 + blr, 0.25, eDist2);

        float trunk = S(tw + blr, tw, hex(h.xy - vec2(0.0, 0.0)));
        trunk = max(trunk, S(tw + (blr * 0.5), tw, hex(h.xy - vec2(0.0, 0.5 * tw * 2.5))));
        trunk = max(trunk, S(tw + (blr * 0.5), tw, hex(h.xy - vec2(0.0, 0.5 * tw * 5.0))));
        trunk = max(trunk, S(tw + (blr * 0.5), tw, hex(h.xy - vec2(0.0, 0.5 * tw * 7.5))));

        float a = pol.x < 0.5 ? 2.5 : 0.5;
        col = mix(col, vec3(0.5, 0.3, 0.2), trunk * a);
        col = mix(col, vec3(0.55, 0.6, 0.3), crown);

        float shw = 0.2 * S(0.5 + (blr * 3.0), 0.5 - blr, dfDiamond(fb + vec2(0.22, 0.02)));
        shw += 0.35 * S(0.5 + (blr * 3.0), 0.5 - blr, dfDiamond(fa - vec2(0.22, -0.02)));

        col -= shw;
    }
    if (hills == 1.0)
    {
        col -= fao * 0.2;
    }

    vec2 frh = fract(h.xy * 2.0);
    float d1 = S(0.8 + blr, 0.8 - blr, dfDiamond(h.xy - vec2(0.0, flip * 0.3)));
    float d2 = S(0.8 + blr, 0.8 - blr, dfDiamond(h.xy - vec2(0.0, flip * 0.2)));

    if (hills == 1.0)
    {
        col += 0.08 * (0.6 - hash2(uv * 34869.54334));
    }

    if (hills == 0.0 && flip == 1.0)
    {
        if (empty == 0.0)
        {
            float shw = pol.x < 0.5 ? 0.33 : 0.15;
            col -= shw * (d1 - min(d1, min(d1, d2))); // inner bevel
            if (tilt > 0.7)
            {
                vec2 wtp = vec2(0.0, -0.2);
                vec2 wtp2 = vec2(0.0, -0.58);
                vec2 wtp3 = vec2(0.0, -0.25);
                float watertank = S(0.02, 0.02 - (blr * 0.5), dot(h.xy * s + wtp, h.xy * s + wtp));
                float watertanktop = S(0.02, 0.02 - (blr * 0.5), dot(h.xy * s + wtp2, h.xy * s + wtp2));
                float watertanktop2 = S(0.016, 0.016 - (blr * 0.5), dot(h.xy * s + wtp2, h.xy * s + wtp2));
                float watertankside = 1.0 - rect(h.xy, wtp3, 0.1, 0.125, blr);
                watertank = max(watertank, watertanktop);
                watertank = min(d1, watertank);
                watertankside = SAT(watertankside);
                float wtglobal = max(watertank, min(d1, watertankside));

                col = mix(col, vec3(0.2, 0.32, 0.45), wtglobal);
                col -= watertanktop2 * 0.15;
                col += max(watertank, watertankside) * S(0.0, 0.15, length(h.x - 0.05)) * 0.15;
            }
            else
            {
                if (tilt > 0.3)
                {
                    vec2 fanpos = vec2(-0.1, -0.35);
                    float fan = S(0.125, 0.125 - blr, hex(h.xy + fanpos));
                    col = mix(col, vec3(1.0), fan);
                    col = mix(col, 0.95 * vec3(0.9, 0.75, 0.6), fan);
                    float ff1 = dfDiamond(fa.xy + vec2(0.35, 0.015));
                    float ff2 = dfDiamond(fb.xy - vec2(0.255, -0.19));
                    col -= vec3(0.45 * S(0.26, 0.26 - (blr * 2.0), ff1));
                    col -= vec3(0.2 * S(0.26, 0.26 - (blr * 2.0), ff2));
                }
            }
        }
        else
        {
            float shw = pol.x < 0.5 ? 0.4 : 0.15;
            col -= shw * d1;                    // empty houses
        }
    }

    // postprocessing
    col /= 1.1 - 0.2;
    col += mix(0.15 * S(0.0, 6.0, length(uv * s)), -0.8 * S(0.0, 6.0, length(uv * s)), sun);
    col = clamp(col, vec3(0.15), vec3(1.0));
    vec3 day = col;
    vec3 night = col;
    night = mix(day, vec3(0.2, 0.5, 0.9), 0.5);

    night = pow(night, vec3(3.0));
    night += SAT(lights);
    night += SAT(blights) * 4.0;

    vec3 final = mix(day, night, S(-1.0, 1.0, sun));

    // color output
    fragColor = vec4(final, 1.0);
} // Closing brace for mainImage