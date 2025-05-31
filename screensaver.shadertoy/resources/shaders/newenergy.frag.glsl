
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 grid = floor(uv * 2.0);
    vec2 localUV = fract(uv * 2.0) * 2.0 - 1.0;
    localUV.x *= iResolution.x / iResolution.y;





    float t = iTime * 0.1;  // You slowed time here

    float totalGlow = 0.0;
    int layers = 10;

    for (int i = 0; i < layers; i++) {
        float layerOffset = float(i) * 0.12;
        float cycleTime = t + layerOffset;
        float cycleLength = 3.0;
        float cyclePhase = mod(cycleTime, cycleLength);
        float progress = cyclePhase / cycleLength;

        float fade = smoothstep(0.0, 0.2, progress) * (1.0 - smoothstep(0.7, 1.0, progress));

        float scale = 0.4 + cyclePhase;
        vec2 p = localUV / scale;

        float a = 1.0;
        float x2 = p.x * p.x;
        float y2 = p.y * p.y;
        float shape = (x2 + y2)*(x2 + y2) - a*a*(x2 - y2);
        float d = abs(shape);

        float thickness = 0.1;
        float glow = exp(-8.0 * d / thickness);

        totalGlow += glow * fade;
    }

    // Classic green
    vec3 color = vec3(0.1, .40, 0.1) * totalGlow;

    // ----- CRT Effects -----

    // Horizontal scan lines
float scanlineFreq = .60;    // How many lines (increase = more lines)
float scanlineAmp  = 0.25;    // How dark (increase = more pronounced)

float scanline = sin(fragCoord.y * scanlineFreq) * scanlineAmp;
color *= 1.0 - scanline;

    // Vertical falloff (simulate phosphor fade from beam movement)
    color *= smoothstep(0.0, 0.5, uv.y) * smoothstep(1.0, 0.5, uv.y);

    // Vignette for curved glass
    vec2 vignetteUV = uv * 2.0 - 1.0;
    float vignette = 1.0 - dot(vignetteUV, vignetteUV) * 0.35;
    color *= clamp(vignette, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}
