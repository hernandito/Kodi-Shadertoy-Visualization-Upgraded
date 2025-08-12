// Define BCS parameters
#define BRIGHTNESS 1.0    // Adjust brightness (1.0 is neutral, >1 increases, <1 decreases)
#define CONTRAST 1.30      // Adjust contrast (1.0 is neutral, >1 increases, <1 decreases)
#define SATURATION 1.0    // Adjust saturation (1.0 is neutral, >1 increases, <1 decreases)

vec2 r;
float td(vec3 u) // distance to tree
{
    float d = 1e9;
    for (int i = 0; i < 7; ++i) // number of subdivisions
    {
        u.y = sqrt(max(0., u.y));
        d = min(d, (u.y < .5 ? length(u.xz) : distance(u, vec3(0, .5, 0))) * pow(2., -float(i)));
        u.y -= .5;
        if (abs(u.z) > abs(u.x))
            u.xz = u.zx;
        float s = sign(u.x);
        u.xy *= mat2(-r.x, r.y * s, r.y * s, r.x);
        u *= 2.;
    }
    return d;
}

void mainImage( out vec4 c, in vec2 uv )
{
    vec2 R = iResolution.xy;
    uv -= R * .75;
    uv /= R.y * 1.5;

    // angle of branches
    float a = 1. - cos(1.5 + iTime * .25 + iMouse.y / R.y * 6.3) * .2;
    r = cos(vec2(a, a - 1.57));

    // camera y rotation
    float ry = 2.7 - iMouse.x / R.x * 6.3 + iTime * .15;
    vec3 f = vec3(-cos(ry), 0, sin(ry));

    // ray setup
    vec3 p = vec3(f + vec3(0, uv.y + .8, 0) + uv.x * vec3(f.z, 0, -f.x));
    vec3 d = normalize(p - 5. * f - vec3(0, 2., 0));

    c = vec4(0);
    p += d * .5;
    for (int i = 0; i < 64; ++i)
    {
        float s = td(p) + 3e-4;
        c.xyz += (p + .75) / s;
        p += d * s;
    }
    c *= c;
    c /= c + 3e7;

    // Apply BCS post-processing
    vec3 color = c.xyz;
    // Brightness
    color = color * BRIGHTNESS;
    // Contrast
    color = (color - 0.5) * CONTRAST + 0.5;
    // Saturation
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(luminance), color, SATURATION);
    c.xyz = clamp(color, 0.0, 1.0);
}