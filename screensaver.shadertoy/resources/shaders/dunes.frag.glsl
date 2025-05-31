#define POST_PROCESS
#define AA 3

// Editable post-processing parameters
// - contrast: 1.0 = neutral, >1.0 increases contrast, <1.0 decreases (e.g., 1.5 for higher contrast)
// - brightness: 1.0 = neutral, >1.0 brighter, <1.0 darker (e.g., 1.2 for brighter)
// - saturation: 1.0 = neutral, >1.0 more saturated, <1.0 desaturated (e.g., 0.8 for muted colors)
float contrast = 1.9;
float brightness = 0.80;
float saturation = 0.90;

// Palette and timing control
// - paletteMode: 0 = day, 1 = night, 2 = transition (set manually)
int paletteMode = 0; // Default to day
// - dayDuration: Duration of day phase in seconds (e.g., 30.0)
float dayDuration = 30.0;
// - transitionDuration: Duration of transition phase in seconds (e.g., 10.0)
float transitionDuration = 10.0;
// - nightDuration: Duration of night phase in seconds (e.g., 30.0)
float nightDuration = 30.0;
// - speed: Animation speed multiplier
float speed = 0.10;

// Sun and moon definitions
const vec3 sunDir = normalize(vec3(0, .14, -1));
const vec3 sunCol = vec3(1, .7, .3);
const vec3 moonDir = normalize(vec3(0, -0.14, -1));
const vec3 moonCol = vec3(0.8, 0.9, 1.0);

// float hash function
float hash(float n) { return fract(sin(n) * 4568.7564); }

// vec2 to float hash
float hash(vec2 x) {
    float n = dot(x, vec2(127.1, 311.7));
    return fract(sin(n) * 4568.7564);
}

// planes intersection function
float intersect(vec3 ro, vec3 rd, out float ofj) {
    float t = 1e10;
    
    for (int i = 0; i < 8; i++) {
        float fj = float(i);
        float h = (-fj * 2. - ro.z) / rd.z;
        vec3 p = ro + rd * h;
        p.x += 1.2 * fj;
        float d = p.y + (.07 * abs(sin(p.x * 4.)) - .1 * abs(sin(p.x * 1.5 + .2))) - .006 * fj * fj;
        h *= -sign(d);
        if (h > 0. && h < t) {
            t = h;
            ofj = fj;
        }
    }
    return t < 1e10 ? t : -1.;
}

vec3 getSkyColor(vec3 rd, float t) {
    vec3 daySkyLow = vec3(.05, .15, .4);
    vec3 daySkyHigh = vec3(.4, .7, .9);
    vec3 nightSkyLow = vec3(0.0, 0.1, 0.3);
    vec3 nightSkyHigh = vec3(0.1, 0.2, 0.4);
    
    vec3 skyLow = daySkyLow;
    vec3 skyHigh = daySkyHigh;
    if (paletteMode == 1 || (paletteMode == 2 && t > 0.5)) {
        skyLow = nightSkyLow;
        skyHigh = nightSkyHigh;
    } else if (paletteMode == 2) {
        float progress = smoothstep(0.0, 0.5, t);
        skyLow = mix(daySkyLow, nightSkyLow, progress);
        skyHigh = mix(daySkyHigh, nightSkyHigh, progress);
    }
    
    vec3 col = mix(skyLow, skyHigh, clamp(exp(-11. * rd.y - .4), 0., 1.));
    
    // Stars (brighter at night or transition)
    vec2 p = fract(rd.xy * 16.);
    p.x += hash(floor(rd.xy * 16.)) - .5;
    p.y += hash(floor(rd.xy * 16.) + 2.3) - .2;
    float starBrightness = (paletteMode == 1 || (paletteMode == 2 && t > 0.5)) ? 6.0 : 4.0;
    col = mix(col, vec3(starBrightness), rd.y * rd.y * step(length(p - .4), .03));
    
    return col;
}

vec3 render(vec3 ro, vec3 rd, float t) {
    vec3 bgCol = getSkyColor(rd, t);
    
    // Determine active direction and color based on palette mode
    vec3 activeDir = sunDir;
    vec3 activeCol = sunCol;
    if (paletteMode == 1 || (paletteMode == 2 && t > 0.5)) {
        activeDir = moonDir;
        activeCol = moonCol;
    } else if (paletteMode == 2) {
        float progress = smoothstep(0.0, 0.5, t);
        activeDir = mix(sunDir, moonDir, progress);
        activeCol = mix(sunCol, moonCol, progress);
    }
    
    float sun = clamp(dot(rd, activeDir), 0., 1.);
    vec3 col = bgCol;
    
    float fj, tHit = intersect(ro, rd, fj);
    
    if (tHit > 0.) {
        vec3 p = ro + rd * tHit;
        vec3 duneCol = vec3(1, .6, .4);
        if (paletteMode == 1 || (paletteMode == 2 && t > 0.5)) {
            duneCol = vec3(0.5, 0.5, 0.6); // Night hue
        } else if (paletteMode == 2) {
            float progress = smoothstep(0.0, 0.5, t);
            duneCol = mix(vec3(1, .6, .4), vec3(0.5, 0.5, 0.6), progress);
        }
        col = duneCol * exp(p.y * 1.8);
        
        float fog = 1. - exp(-fj * fj * fj * (paletteMode == 1 ? 0.015 : 0.01));
        vec3 fogCol = bgCol * (paletteMode == 1 ? 0.5 : 0.7);
        col = mix(col, fogCol, fog);
    } else {
        col += 2. * activeCol * step(.999, sun);
    }
    
    col += .1 * activeCol * activeCol * pow(sun, paletteMode == 1 ? 64. : 32.);
    col += .5 * activeCol * activeCol * pow(sun, paletteMode == 1 ? 1024. : 512.);
    
    return col;
}

// camera function
mat3 setCamera(vec3 ro, vec3 ta) {
    vec3 w = normalize(ta - ro);
    vec3 u = normalize(cross(w, vec3(0, 1, 0)));
    vec3 v = cross(u, w);
    return mat3(u, v, w);
}

// Post-processing function for contrast, brightness, and saturation
vec3 applyPostProcessing(vec3 color) {
    color *= brightness;
    color = (color - 0.5) * contrast + 0.5;
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(lum), color, saturation);
    return clamp(color, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float speed = 0.30;

    vec3 ro = vec3(.4 * iTime * speed, .5, 1.5);
    float an = iTime * .8 * speed;
    ro += .1 * vec3(sin(an), cos(an), 0);
    
    vec3 ta = vec3(.4 * iTime * speed, .4, 0);
    mat3 ca = setCamera(ro, ta);
    
    vec3 tot = vec3(0);
    
    for (int m = 0; m < AA; m++)
    for (int n = 0; n < AA; n++) {
        vec2 off = vec2(m, n) / float(AA) - .5;
        vec2 p = (fragCoord + off - .5 * iResolution.xy) / iResolution.y;
        vec3 rd = ca * normalize(vec3(p, 2.0)); // Increased focal length for panoramic view
        float cycleTime = mod(iTime, dayDuration + 2.0 * transitionDuration + nightDuration) / (dayDuration + 2.0 * transitionDuration + nightDuration);
        float t = cycleTime;
        if (paletteMode == 2) {
            if (cycleTime <= dayDuration / (dayDuration + 2.0 * transitionDuration + nightDuration)) t = 0.0;
            else if (cycleTime <= (dayDuration + transitionDuration) / (dayDuration + 2.0 * transitionDuration + nightDuration)) t = (cycleTime - dayDuration / (dayDuration + 2.0 * transitionDuration + nightDuration)) / (transitionDuration / (dayDuration + 2.0 * transitionDuration + nightDuration));
            else if (cycleTime <= (dayDuration + transitionDuration + nightDuration) / (dayDuration + 2.0 * transitionDuration + nightDuration)) t = 0.5;
            else t = (cycleTime - (dayDuration + transitionDuration + nightDuration) / (dayDuration + 2.0 * transitionDuration + nightDuration)) / (transitionDuration / (dayDuration + 2.0 * transitionDuration + nightDuration)) + 0.5;
        }
        vec3 col = render(ro, rd, t);
        tot += col;
    }
    tot /= float(AA * AA);
    
    #ifdef POST_PROCESS
    tot = 1.35 * tot / (1. + .7 * tot);
    tot = pow(tot, vec3(.4545));
    tot = applyPostProcessing(tot);
    tot = clamp(tot, 0., 1.);
    tot = tot * .3 + .7 * tot * tot * (3. - 2. * tot);
    vec3 n = vec3(1.5, 1.2, .8);
    tot = pow(tot, n) / (pow(tot, n) + pow(1. - tot, n));
    tot = tot * 1.2 - .2;
    vec2 q = fragCoord / iResolution.xy;
    tot *= .5 + .5 * pow(24. * q.x * q.y * (1. - q.x) * (1. - q.y), .1);
    tot *= .95 + .05 * hash(q * 3.567 + fract(iTime));
    #endif

    fragColor = vec4(tot, 1.0);
}