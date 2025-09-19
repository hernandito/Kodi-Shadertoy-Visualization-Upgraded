// Shadertoy uniforms: iTime, iResolution
precision highp float;

// ---------------- USER PARAMETERS ----------------
#define BRIGHTNESS .9
#define CONTRAST   1.20
#define SATURATION .14
// -------------------------------------------------

// A robust BCS function
vec3 bcs_final(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    
    // Using a luminance formula that is more robust for saturation iTime
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color = mix(grayscale, color, saturation);
    
    return color;
}

// Based on http://www.oscars.org/science-technology/sci-tech-projects/aces
//https://www.shadertoy.com/view/Xc3yzM
vec3 aces_tonemap(vec3 color){
    mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
    );
    mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
    );
    vec3 v = m1 * color;
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
        
    return m2 * (a / b);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 u = fragCoord.xy;
    float i = 0.0;
    float a = 0.0;
    float d = 0.0;
    float s = 0.0;
    float t = iTime * 0.05 + 10.0;
    float r = 0.0;

    vec3 p = iResolution;
    u = (u + u - p.xy) / p.y;

    vec4 o = vec4(0.0);

    for (i = 0.0; i++ < 100.0; ) {
        s = 0.001 + abs(s) * 0.04;
        d += s;

        o.r += (d * 1.5 - 5.0 / s) * 0.55;
        o.b += sin(d * 0.1 ) * 7.0 / s;
        o.g += sin(d * 0.1 + 10.0) * 0.9 / s * 2.0;

        p = vec3(u * d, d + t * 0.09);
        s = min(0.9 - 0.4 * smoothstep(0.0, 1.0, sin(iTime * 0.25)), 9.0);

        for (a = 0.4; a < 1.5; a += a) {
            p.x = abs(p.x);
            p += cos(p.yzx * 0.8 + p.x * 0.1) * 0.5;

            r = t * 0.5;

            mat2 rot = mat2(cos(r), -sin(r), sin(r),  cos(r));
            p.xy *= rot;
            s += abs(sin(p.x * 5.0 * a)) * 1.7 * -abs(sin(abs(p.y * 2.0 - 12.0) * a) / a);
        }
    }

    o.rgb = pow(aces_tonemap(o.rgb * o.rgb / 5.2e9 * (length(u))), vec3(1.0 / 2.2));
    
    // Apply BCS post-processing adjustments
    o.rgb = bcs_final(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);

    fragColor = o;
}
