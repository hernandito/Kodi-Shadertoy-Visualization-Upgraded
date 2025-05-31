#define POST_PROCESS
#define AA 3

// Global variable for animation speed control
float animationSpeed = 0.3; // Default speed, can be adjusted here

// Editable parameters for contrast, brightness, and saturation
uniform float uContrast;    //  will be set externally
uniform float uBrightness; //  will be set externally
uniform float uSaturation; //  will be set externally


// float hash function
float hash(float n) { return fract(sin(n) * 4568.7564); }

// vec2 to float hash
float hash(vec2 x) {
    float n = dot(x, vec2(127.1, 311.7));
    return fract(sin(n) * 4568.7564);
}

// planes intersection function
float intersect(vec3 ro, vec3 rd, out float ofj) {
    float t = 1e10; // final distance

    for (int i = 0; i < 8; i++) { // 7 layers
        float fj = float(i); // i in float

        float h = (-fj * 2. - ro.z) / rd.z; // plane ray intersection distance
        vec3 p = ro + rd * h; // point on plane

        p.x += 1.2 * fj; // offset

        // dunes height
        float d = p.y + (.07 * abs(sin(p.x * 4.)) -
                           .1 * abs(sin(p.x * 1.5 + .2))) - .006 * fj * fj;

        h *= -sign(d); // cut the plane
        if (h > 0. && h < t) { // hit
            t = h;
            ofj = fj;
        }
    }

    // output
    return t < 1e10 ? t : -1.;
}

const vec3 sunDir = normalize(vec3(0, .14, -1)); // sun direction
const vec3 sunCol = vec3(1, .7, .3); // sun color

// skybox
vec3 sky(vec3 rd) {
    // gradient
    vec3 col = mix(vec3(.05, .15, .4), vec3(.4, .7, .9),
                    clamp(exp(-11. * rd.y - .4), 0., 1.));

    // stars
    vec2 p = fract(rd.xy * 16.);
    p.x += hash(floor(rd.xy * 16.)) - .5;
    p.y += hash(floor(rd.xy * 16.) + 2.3) - .2;

    col = mix(col, vec3(4),
                    rd.y * rd.y * step(length(p - .4), .03));

    return col;
}

vec3 render(vec3 ro, vec3 rd) {
    vec3 bgCol = sky(rd); // background
    float sun = clamp(dot(rd, sunDir), 0., 1.); // sun glare
    vec3 col = bgCol;

    // distance and layer
    float fj, t = intersect(ro, rd, fj);

    if (t > 0.) { // we hit the surface
        vec3 p = ro + rd * t; // hit point

        col = vec3(1, .6, .4) * exp(p.y * 1.8);

        // fog
        float fog = 1. - exp(-fj * fj * fj * .05);
        col = mix(col, bgCol * .7, fog);
    } else {
        col += 2. * sunCol * step(.999, sun); // sun
    }

    // sung glare
    col += .4 * sunCol * sunCol * pow(sun, 32.);
    col += .7 * sunCol * sunCol * pow(sun, 256.);

    return col;
}

// camera function
mat3 setCamera(vec3 ro, vec3 ta) {
    vec3 w = normalize(ta - ro); // forward vector
    vec3 u = normalize(cross(w, vec3(0, 1, 0))); // side vector
    vec3 v = cross(u, w); // up vector
    return mat3(u, v, w);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    //float time = iTime * .5; // Original time
    float time = iTime * animationSpeed; // Modified time for speed control
    vec3 ro = vec3(.4 * time, .5, 1.5); // rya origin
    // rotation
    float an = time * .8;
    ro += .1 * vec3(sin(an), cos(an), 0);

    vec3 ta = vec3(.4 * time, .4, 0); // target
    mat3 ca = setCamera(ro, ta); // camera matrix

    vec3 tot = vec3(0); // accumulated color

    for (int m = 0; m < AA; m++)
        for (int n = 0; n < AA; n++) {
            vec2 off = vec2(m, n) / float(AA) - .5; // AA offset
            // normalized pixel coordinates
            vec2 p = (fragCoord + off - .5 * iResolution.xy) / iResolution.y;

            vec3 rd = ca * normalize(vec3(p, 1.5)); // ray durection
            vec3 col = render(ro, rd); // render

            tot += col;
        }
    tot /= float(AA * AA);

#ifdef POST_PROCESS
    tot = 1.35 * tot / (1. + .7 * tot); // tonemapping
    tot = pow(tot, vec3(.4545)); // gamma correction

    tot = clamp(tot, 0., 1.);
    tot = tot * .3 + .7 * tot * tot * (3. - 2. * tot); // contrast

    // color grading
    vec3 n = vec3(1.5, 1.2, .8);
    tot = pow(tot, n) / (pow(tot, n) + pow(1. - tot, n));
    tot = tot * 1.2 - .2; // contrast

    vec2 q = fragCoord / iResolution.xy;
    tot *= .5 + .5 * pow(24. * q.x * q.y * (1. - q.x) * (1. - q.y), .1); // vignette
    tot *= .95 + .05 * hash(q * 3.567 + fract(iTime)); // film grain
#endif

    // output
    fragColor = vec4(tot, 1.0);
}
