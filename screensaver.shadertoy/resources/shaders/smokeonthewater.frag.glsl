/* phreax/jiagual 2025 */

mat2 rot(float x) { return mat2(cos(x), -sin(x), sin(x), cos(x)); }
vec3 pal(float x) { return .5 + .5 * cos(5.28 * x - vec3(0, 2, 4)); }

// === Adjustable Post-Processing Parameters ===
// BRIGHTNESS:
//   1.0 = no change
//   >1.0 = brighter
//   <1.0 = darker
const float BRIGHTNESS = 1.00;

// CONTRAST:
//   1.0 = no change
//   >1.0 = higher contrast (more vivid)
//   <1.0 = lower contrast (flatter image)
const float CONTRAST = 1.250;

// SATURATION:
//   1.0 = normal color
//   >1.0 = more intense colors
//   0.0 = grayscale
const float SATURATION = 0.0;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;

    vec3 col = vec3(0);
    vec3 rd = vec3(uv, 1);
    vec3 p = vec3(0);
    float t = 0.;
    float tt = iTime * .1;

    for (float i = 0.; i < 1e2; i++) {
        vec3 p = t * rd + rd;
        p.z += tt;
        p = abs(p) - .3;
        p.xy *= rot(p.z);
        p = abs(p) - .3;
        for (float j = 0.; j < 3.; j++) {
            float a = exp(j) / exp2(j);
            p += cos(4. * p.yzx * a + tt - length(p.xy) * 5.) / a;
        }
        float d = 0.01 + abs((p - vec3(0, 1, 0)).y - 1.) / 10.;
        col += pal(t * .7) * 1e-3 / d;
        t += d / 4.;
    }

    // Tone mapping and gamma correction
    col *= col * .1 / (1.0 + abs(col * .1));
    col = pow(col, vec3(.45));

    // === Post-Processing ===

    // Apply brightness
    col *= BRIGHTNESS;

    // Apply contrast
    col = (col - 0.5) * CONTRAST + 0.5;

    // Apply saturation
    float luminance = dot(col, vec3(0.2126, 0.7152, 0.0722)); // perceived brightness
    col = mix(vec3(luminance), col, SATURATION);

    fragColor = vec4(col, 1.0);
}
