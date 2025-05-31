// ─── USER PARAMETER ───────────────────────────────────────
// 1.0 = normal speed, 0.5 = half speed, 2.0 = double speed, etc.
float animationSpeed = 0.50;

// Fork of "generative art deco 3" by morisil. https://shadertoy.com/view/mdl3WX
// 2022-10-28 00:47:55

// Fork of "generative art deco 2" by morisil. https://shadertoy.com/view/ftVBDz
// 2022-10-27 22:34:54

// Fork of "generative art deco" by morisil. https://shadertoy.com/view/7sKfDd
// 2022-09-28 11:25:15

// Copyright Kazimierz Pogoda, 2022 - https://xemantic.com/
// (copyright and license text omitted for brevity)

const float SHAPE_SIZE = .70;
const float CHROMATIC_ABBERATION = .01;
const float ITERATIONS = 10.;
const float INITIAL_LUMA = .5;

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

mat2 rotate2d(float _angle){
    return mat2(cos(_angle), -sin(_angle),
                sin(_angle),  cos(_angle));
}

float sdPolygon(in float angle, in float distance) {
    float segment = TWO_PI / 4.0;
    return cos(floor(.5 + angle / segment) * segment - angle) * distance;
}

float getColorComponent(in vec2 st, in float modScale, in float blur, in float t) {
    vec2 modSt = mod(st, 1.0 / modScale) * modScale * 2.0 - 1.0;
    float dist  = length(modSt);
    float angle = atan(modSt.x, modSt.y) + sin(t * .08) * 9.0;
    float shapeMap = smoothstep(
        SHAPE_SIZE + blur,
        SHAPE_SIZE - blur,
        sin(dist * 3.0) * .5 + .5
    );
    return shapeMap;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // scaled time
    float t = iTime * animationSpeed;

    // animate blur
    float blur = .4 + sin(t * .52) * .2;

    // normalize to square viewport
    vec2 st = (2.0 * fragCoord - iResolution.xy)
              / min(iResolution.x, iResolution.y);
    vec2 origSt = st;

    // apply rotating / scaling transforms
    st *= rotate2d(sin(t * .14) * .3);
    st *= (sin(t * .15) + 2.0) * .3;
    st *= log(length(st * .428)) * 1.1;

    float modScale = 1.0;

    vec3 color = vec3(0.0);
    float luma = INITIAL_LUMA;

    // iterative layering
    for (float i = 0.0; i < ITERATIONS; i++) {
        vec2 center = st + vec2(sin(t * .12), cos(t * .13));

        vec3 shapeColor = vec3(
            getColorComponent(center - st * CHROMATIC_ABBERATION, modScale, blur, t),
            getColorComponent(center,                     modScale, blur, t),
            getColorComponent(center + st * CHROMATIC_ABBERATION, modScale, blur, t)
        ) * luma;

        // warp and rotate for next octave
        st *= 1.1 + getColorComponent(center, modScale, .04, t) * 1.2;
        st *= rotate2d(sin(t * .05) * 1.33);

        color = clamp(color + shapeColor, 0.0, 1.0);

        // fade out higher octaves
        luma *= .6;
        blur *= .63;
    }

    // color grading
    const float GRADING_INTENSITY = .4;
    vec3 topGrading = vec3(
        1.0 + sin(t * 1.13 * .3) * GRADING_INTENSITY,
        1.0 + sin(t * 1.23 * .3) * GRADING_INTENSITY,
        1.0 - sin(t * 1.33 * .3) * GRADING_INTENSITY
    );
    vec3 bottomGrading = vec3(
        1.0 - sin(t * 1.43 * .3) * GRADING_INTENSITY,
        1.0 - sin(t * 1.53 * .3) * GRADING_INTENSITY,
        1.0 + sin(t * 1.63 * .3) * GRADING_INTENSITY
    );
    float origDist = length(origSt);
    vec3 colorGrading = mix(topGrading, bottomGrading, origDist - .5);

    fragColor = vec4(pow(color.rgb, colorGrading), 1.0);
    fragColor *= smoothstep(2.1, .7, origDist);
}
