/**

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Woven Truchet Experiment
    06/29/2025  @byt3_m3chanic
    
    Started this on my iPad with KodeLife and ported to 
    shadertoy for some extra love.
    
    Was mostly practice but with some abs tricks for the over
    and under parts. Otherwise pretty basic truchet with some
    forced rotations to give the parts a good spin!

*/

// Ground plane overlay parameters
#define ENABLE_GROUND_PLANE 1    // Toggle ground plane: 1 to enable overlay, 0 to use original texture
#define GROUND_OVERLAY_COLOR vec3(1.0)  // Overlay color: default white
#define GROUND_OVERLAY_ALPHA 0.65   // Overlay transparency: 0.0 to 1.0, updated to 0.65

// BCS post-processing parameters
#define BRIGHTNESS 0.80    // Brightness: 1.0 for default, >1.0 to brighten, <1.0 to darken
#define CONTRAST 1.0      // Contrast: 1.0 for default, >1.0 to increase, <1.0 to decrease
#define SATURATION 0.20    // Saturation: 1.0 for default, >1.0 to intensify, <1.0 to desaturate

#define R iResolution
#define T iTime*.3

#define MIN_DIST 1e-3
#define MAX_DIST 20.

#define PI  3.14159265
#define PI2 6.28318530

float hash21(vec2 p) { return fract(sin(dot(p, vec2(24.32, 59.31))) * 4732.3234); }
mat2 rot(float a) { return mat2(cos(a), sin(a), -sin(a), cos(a)); }

float opx(float d, float z, float h) {
    vec2 w = vec2(d, abs(z) - h);
    return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}

float rab(float d) {
    return abs(abs(abs(d) - .08) - .04) - .015;
}

vec2 gid, sid;
vec3 hit, hp;
const float size = .55;
const float halfSize = size / 2.;
const float P3 = PI2 / size;

vec2 map(vec3 p) {
    vec2 res = vec2(1e5, 0);
    p.y -= .725;
    vec3 q = p;
    
    vec2 id = floor((p.xz + halfSize) / size);
    float checker = mod(id.x + id.y, 2.) * 2. - 1.;
    p.xz = mod(p.xz + halfSize, size) - halfSize;

    float ht = .04, ho = .0095, gp = ht * .75;
    float rnd = hash21(id);

    if (rnd > .5) p.x = -p.x;
    if (checker > .5) p.xz *= rot(1.5707);

    vec2 r = length(p.xz - halfSize) < length(p.xz + halfSize) ? p.xz - halfSize : p.xz + halfSize;

    float d = length(r) - halfSize;
    d = rab(d);
    d = opx(d, p.y, ho);

    rnd = fract(rnd * 43.234);

    if (rnd > .425) {
        float b = gp + gp * cos(p.x * P3);
        if (p.z < 0.) b = -b;

        float dz = length(p.z);
        dz = rab(dz);
        dz = opx(dz, p.y - b, ho);

        float dx = length(p.x);
        dx = rab(dx);
        dx = opx(dx, p.y, ho);

        d = min(dz, dx);
    }

    if (d < res.x) {
        res = vec2(d, 1.);
        hit = q;
        gid = id;
    }

    float f = q.y + .125;
    if (f < res.x) {
        res = vec2(f, 2.);
        hit = q;
    }

    return res;
}

vec3 normal(vec3 p, float t) {
    float e = MIN_DIST * t;
    vec2 h = vec2(1, -1) * .5773;
    return normalize(
        h.xyy * map(p + h.xyy * e).x +
        h.yyx * map(p + h.yyx * e).x +
        h.yxy * map(p + h.yxy * e).x +
        h.xxx * map(p + h.xxx * e).x
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2. * fragCoord.xy - R.xy) / max(R.x, R.y);

    // Use distant view parameters for full screen
    vec3 ro = vec3(0, 0, 3.5); // Distant view
    vec3 rd = normalize(vec3(uv, -1));

    mat2 rx = rot(-1. + .25 * sin(T * .1)); // Left view rotation
    mat2 ry = rot(.68 + .4 * cos(T * .12)); // Left view rotation
    ro.zy *= rx; ro.zx *= ry;
    rd.zy *= rx; rd.zx *= ry;

    float speed = T * .2;
    ro.xz += speed;

    vec3 p = ro;
    float d = 0., m = 0.;

    for (int i = 0; i < 142; i++) {
        vec2 t = map(p);
        d += (i < 42 ? t.x * .4 : t.x);
        m = t.y;
        p = ro + rd * d;
        if (abs(t.x) < d * MIN_DIST || d > MAX_DIST) break;
    }

    sid = gid;
    hp = hit;

    vec3 color = vec3(0);

    if (d < MAX_DIST) {
        vec3 n = normal(p, d);
        vec3 lpos = vec3(2. + speed, 6, 3. + speed);
        vec3 l = normalize(lpos - p);
        float diff = clamp(dot(n, l), .1, .8);

        float shdw = 1.;
        for (float t = .01; t < 14.; ) {
            float h = map(p + l * t).x;
            if (h < MIN_DIST) { shdw = 0.; break; }
            shdw = min(shdw, 8. * h / t);
            t += h;
            if (shdw < MIN_DIST || t > 25.) break;
        }
        diff = mix(diff, diff * shdw, .75);

        vec3 baseColor = vec3(.5);

        if (m == 1.) {
            baseColor = .45 + .45 * sin(PI2 * ((hp.z + hp.x) * .045) + vec3(3, 2, 1));
        }
        if (m == 2.) {
            if (ENABLE_GROUND_PLANE == 1) {
                float scale = 22.5;
                float px = scale / R.x;
                vec2 f = fract(hp.xz * scale) - .5;
                vec2 nid = floor(hp.xz * scale);
                float rnd = hash21(nid);
                if (rnd > .6) f.x = -f.x;

                vec2 q = length(f - .5) < length(f + .5) ? f - .5 : f + .5;
                float d = length(q) - .5;
                if (fract(rnd * 43.343) > .75) d = min(length(f.x), length(f.y));
                float e = abs(d) - .1;

                d = abs(abs(d) - .16) - .08;

                vec3 k = .45 + .45 * sin(PI2 * ((hp.z + hp.x) * .045) + vec3(3, 2, 1));
                vec3 tex = texture(iChannel0, hp.xz).rgb;
                baseColor = mix(tex, k * tex, smoothstep(px, -px, d));

                d = length(abs(f) - .5) - .12;
                baseColor = mix(baseColor, baseColor * .5, smoothstep(px, -px, abs(d) - .05));

                baseColor = mix(baseColor, baseColor + .2, smoothstep(px, -px, e + .03));
                
                // Add white semi-transparent overlay
                vec3 overlay = GROUND_OVERLAY_COLOR;
                baseColor = mix(baseColor, overlay, GROUND_OVERLAY_ALPHA);
            } else {
                // Original ground plane logic without overlay
                float scale = 22.5;
                float px = scale / R.x;
                vec2 f = fract(hp.xz * scale) - .5;
                vec2 nid = floor(hp.xz * scale);
                float rnd = hash21(nid);
                if (rnd > .6) f.x = -f.x;

                vec2 q = length(f - .5) < length(f + .5) ? f - .5 : f + .5;
                float d = length(q) - .5;
                if (fract(rnd * 43.343) > .75) d = min(length(f.x), length(f.y));
                float e = abs(d) - .1;

                d = abs(abs(d) - .16) - .08;

                vec3 k = .45 + .45 * sin(PI2 * ((hp.z + hp.x) * .045) + vec3(3, 2, 1));
                vec3 tex = texture(iChannel0, hp.xz).rgb;
                baseColor = mix(tex, k * tex, smoothstep(px, -px, d));

                d = length(abs(f) - .5) - .12;
                baseColor = mix(baseColor, baseColor * .5, smoothstep(px, -px, abs(d) - .05));

                baseColor = mix(baseColor, baseColor + .2, smoothstep(px, -px, e + .03));
            }
        }

        color += (diff * baseColor);
    }

    // Apply BCS in post-processing
    color = clamp(color, vec3(.01), vec3(1));
    color *= BRIGHTNESS; // Adjust brightness
    color = (color - 0.5) * CONTRAST + 0.5; // Adjust contrast
    vec3 luminance = vec3(0.299, 0.587, 0.114); // Standard luminance weights
    float luma = dot(color, luminance);
    color = mix(vec3(luma), color, SATURATION); // Adjust saturation
    fragColor = vec4(pow(color, vec3(.4545)), 1);
}