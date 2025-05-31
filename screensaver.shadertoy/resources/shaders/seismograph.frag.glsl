// Shadertoy-compatible seismograph shader for Kodi screensaver
// Green lines on black with drop shadow below each waveform line

#define NUM_LINES 18           // Number of seismograph lines
#define LINE_SPACING 0.1      // Vertical spacing between lines
#define AMPLITUDE 0.15         // Base amplitude
#define TIME_SCALE 0.250         // Time multiplier for faster motion
#define LINE_THICKNESS 0.001   // Thickness of waveform line
#define FILL_ALPHA 0.1         // Transparency for fill area
#define SHADOW_ALPHA 0.15      // Max alpha of shadow
#define SHADOW_FADE 0.015      // How far the shadow fades downward

float rand(float x) {
    return fract(sin(x * 12.9898) * 43758.5453);
}

// Seismograph waveform generator
float seismoWave(float x, float time, float lineOffset) {
    float freq = 3.0 + sin(time * 0.5 + lineOffset) * 2.0;
    float t = x * freq + time + lineOffset * 2.0;
    float wave = sin(t * 3.1415) * sin(t * 0.5) + sin(t * 2.5);
    wave += 0.3 * sin(t * 7.0 + sin(time + lineOffset * 3.0)); // higher freq jitter
    wave *= (0.3 + 0.7 * sin(time * 0.25 + lineOffset * 1.3)); // magnitude variation
    return wave * AMPLITUDE;
}

// Get waveform line color (single-color version: adjust here or extend)
vec3 getLineColor(int index) {
    float t = float(index) / float(NUM_LINES - 1);
    return mix(vec3(0.3, 0.3, 0.4), vec3(0.26, 0.26, 0.26), t);  // Low-saturation green range
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    vec2 centeredUV = uv * 2.0 - 1.0;
    centeredUV.x *= aspect;

    float time = iTime * TIME_SCALE;
    vec3 color = vec3(0.0);

    for (int i = 0; i < NUM_LINES; i++) {
        float yOffset = 1.0 - float(i) * LINE_SPACING - 0.2;
        float wave = seismoWave(centeredUV.x, time, float(i));
        float lineY = yOffset + wave;

        vec3 lineColor = getLineColor(i);

        // Drop shadow below line (fades downward)
        float shadowDist = centeredUV.y - lineY;
        if (shadowDist > 0.0 && shadowDist < SHADOW_FADE) {
            float shadowAlpha = SHADOW_ALPHA * (1.0 - shadowDist / SHADOW_FADE);
            color += lineColor * shadowAlpha;
        }

        // Main waveform line
        float dist = abs(centeredUV.y - lineY);
        float brightness = smoothstep(LINE_THICKNESS * 1.5, LINE_THICKNESS, dist);
        color += lineColor * brightness;

        // Transparent fill below the line
        if (centeredUV.y < lineY) {
            color += lineColor * FILL_ALPHA;
        }
    }

    fragColor = vec4(color, 1.0);
}
