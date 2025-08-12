/**
 Just fooling around basically. Some sort of bloodstream.


// Adjustable BCS parameters for post-processing
#define BRIGHTNESS 1.10  // Range: 0.0 to 2.0 (1.0 = no change)
#define CONTRAST 2.10    // Range: 0.0 to 2.0 (1.0 = no change)
#define SATURATION 1.0  // Range: 0.0 to 2.0 (1.0 = no change)
#define ANIMATION_SPEED 0.50  // Range: 0.0 to any positive value (1.0 = default speed)






const float BEAT = 3.0;


// Adjustable colors
#define BASE_COLOR vec3(1.0, 0.3, 0.1)  // Base color tint (default: reddish hue)
#define BASE_PULSE_AMOUNT 0.05          // Pulsing intensity for green and blue (default: 0.05)
#define SPECULAR_COLOR vec3(0.4, 0.7, 0.7)  // Specular highlight color (default: cyan-ish)
#define RIM_COLOR vec3(0.8, 0.8, 1.0)   // Rim lighting color (default: pale blue)






*/



/**
 Just fooling around basically. Some sort of bloodstream.
*/

/**
 Just fooling around basically. Some sort of bloodstream.
*/

// Adjustable BCS parameters for post-processing
#define BRIGHTNESS 1.10       // Range: 0.0 to 2.0 (1.0 = no change)
#define CONTRAST 2.10         // Range: 0.0 to 2.0 (1.0 = no change)
#define SATURATION 1.0       // Range: 0.0 to 2.0 (1.0 = no change)

// Adjustable animation speed
#define ANIMATION_SPEED 0.50  // Range: 0.0 to any positive value (1.0 = default speed)

// Adjustable colors
#define BASE_COLOR vec3(0.839, 0.114, 0)  // Base color tint (default: reddish hue)
#define BASE_PULSE_AMOUNT 0.05          // Pulsing intensity for green and blue (default: 0.05)
#define SPECULAR_COLOR vec3(0.4, 0.7, 0.7)  // Specular highlight color (default: cyan-ish)
#define RIM_COLOR vec3(0.8, 0.8, 1.0)   // Rim lighting color (default: pale blue)

// https://iquilezles.org/articles/smin
float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float cells(vec2 uv)  // Trimmed down.
{
    uv = mix(sin(uv + vec2(1.57, 0)), sin(uv.yx * 1.4 + vec2(1.57, 0)), .75);
    return uv.x * uv.y * .3 + .7;
}

const float BEAT = 3.0;

float fbm(vec2 uv)
{
    float f = 200.0;
    vec2 r = vec2(.9, .45);
    vec2 tmp;
    float T = 100.0 + iTime * 1.3 * ANIMATION_SPEED;
    T += sin(iTime * BEAT * ANIMATION_SPEED) * .1;
    // layers of cells with some scaling and rotation applied.
    for (int i = 1; i < 8; ++i)
    {
        float fi = float(i);
        uv.y -= T * .5;
        uv.x -= T * .4;
        tmp = uv;
        uv.x = tmp.x * r.x - tmp.y * r.y;
        uv.y = tmp.x * r.y + tmp.y * r.x;
        float m = cells(uv);
        f = smin(f, m, .07);
    }
    return 1. - f;
}

vec3 g(vec2 uv)
{
    vec2 off = vec2(0.0, .03);
    float t = fbm(uv);
    float x = t - fbm(uv + off.yx);
    float y = t - fbm(uv + off);
    float s = .0025;
    vec3 xv = vec3(s, x, 0);
    vec3 yv = vec3(0, y, s);
    return normalize(cross(xv, -yv)).xzy;
}

vec3 ld = normalize(vec3(1.0, 2.0, 3.));

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= vec2(0.5);
    float a = iResolution.x / iResolution.y;
    uv.y /= a;
    vec2 ouv = uv;
    float B = sin(iTime * BEAT * ANIMATION_SPEED);
    uv = mix(uv, uv * sin(B), .035);
    vec2 _uv = uv * 25.;
    float f = fbm(_uv);

    // base color
    fragColor = vec4(f);
    vec3 baseTint = vec3(BASE_COLOR.r, BASE_COLOR.g + B * BASE_PULSE_AMOUNT, BASE_COLOR.b + B * BASE_PULSE_AMOUNT);
    fragColor.rgb *= baseTint;

    vec3 v = normalize(vec3(uv, 1.));
    vec3 grad = g(_uv);

    // spec
    vec3 H = normalize(ld + v);
    float S = max(0., dot(grad, H));
    S = pow(S, 4.0) * .2;
    fragColor.rgb += S * SPECULAR_COLOR;

    // rim
    float R = 1.0 - clamp(dot(grad, v), .0, 1.);
    fragColor.rgb = mix(fragColor.rgb, RIM_COLOR, smoothstep(-.2, 2.9, R));

    // edges
    fragColor.rgb = mix(fragColor.rgb, vec3(0.), smoothstep(.45, .55, (max(abs(ouv.y * a), abs(ouv.x)))));

    // Post-processing: BCS adjustments
    // 1. Brightness: Multiply the color by the brightness factor
    fragColor.rgb *= BRIGHTNESS;

    // 2. Contrast: Adjust contrast around the midpoint (0.5)
    fragColor.rgb = (fragColor.rgb - 0.5) * CONTRAST + 0.5;

    // 3. Saturation: Convert to grayscale and mix with original color
    float gray = dot(fragColor.rgb, vec3(0.299, 0.587, 0.114)); // Luminance
    fragColor.rgb = mix(vec3(gray), fragColor.rgb, SATURATION);

    // 4. Ensure colors stay in valid range after adjustments
    fragColor.rgb = clamp(fragColor.rgb, 0.0, 1.0);
}