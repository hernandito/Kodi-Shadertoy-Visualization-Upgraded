#define AA_FALLOFF 0.8
#define GRID_WIDTH 0.035
#define CURVE_WIDTH 7.50
#define FUNC_SAMPLE_STEP 0.08
#define SCOPE_RATE 0.2

float sinc(float x) {
    return (x == 0.0) ? 1.0 : sin(x) / x;
}

float triIsolate(float x) {
    return abs(-1.0 + fract(clamp(x, -0.5, 0.5)) * 2.0);
}

// ECG Heartbeat (Top Line)
float heartbeat(float x) {
    float prebeat  = -sinc((x - 0.4) * 40.0) * 0.6 * triIsolate((x - 0.4) * 1.0);
    float mainbeat =  (sinc((x - 0.5) * 50.0)) * 1.4 * triIsolate((x - 0.5) * 0.7);
    float postbeat =  sinc((x - 0.85) * 15.0) * 0.6 * triIsolate((x - 0.85) * 0.6);
    return (prebeat + mainbeat + postbeat) * triIsolate((x - 0.625) * 0.8);
}

float func_ecg(float x) {
    return 0.5 * heartbeat(mod((x + 0.25), 1.8));
}

// Respiratory Rate (Middle Line)
float func_resp(float x) {
    float breathRate = 0.25; // 15 breaths/min = 0.25 Hz
    return 0.3 * sin(2.0 * 3.14159 * breathRate * x);
}

// Pulse Oximetry (Bottom Line) - SpO2/Pleth Waveform (Smoothed)
float func_pulse(float x) {
    float pulsePeriod = 1.8; // Matches ECG period
    float t = mod((x + 0.25), pulsePeriod) / pulsePeriod; // Normalize to [0, 1]

    // Key points
    float peakHeight = 0.4; // Peak amplitude
    float plateauHeight = 0.2; // Plateau amplitude (dicrotic notch)
    float riseEnd = 0.2; // End of sharp rise
    float plateauStart = 0.25; // Start of plateau
    float plateauEnd = 0.4; // End of plateau
    float fallEnd = 0.6; // End of fall back to baseline

    if (t < riseEnd) {
        // Smooth rise to peak using smoothstep
        float riseT = t / riseEnd; // Map t from [0, 0.2] to [0, 1]
        return peakHeight * smoothstep(0.0, 1.0, riseT);
    } else if (t < plateauStart) {
        // Smooth transition to plateau using smoothstep
        float transitionT = (t - riseEnd) / (plateauStart - riseEnd); // Map t from [0.2, 0.25] to [0, 1]
        return mix(peakHeight, plateauHeight, smoothstep(0.0, 1.0, transitionT));
    } else if (t < plateauEnd) {
        // Plateau (dicrotic notch) - flat
        return plateauHeight;
    } else if (t < fallEnd) {
        // Smooth fall to baseline using smoothstep
        float fallT = (t - plateauEnd) / (fallEnd - plateauEnd); // Map t from [0.4, 0.6] to [0, 1]
        return plateauHeight * (1.0 - smoothstep(0.0, 1.0, fallT));
    } else {
        // Flat baseline
        return 0.0;
    }
}

float aaStep(float a, float b, float x) {
    x = clamp(x, a, b);
    return (x - a) / (b - a);
}

void blend(inout vec4 baseCol, vec4 color, float alpha) {
    baseCol = vec4(mix(baseCol.rgb, color.rgb, alpha * color.a), 1.0);
}

void drawGrid(inout vec4 baseCol, vec2 xy, float stepSize, vec4 gridCol, float pp) {
    // ADJUSTABLE: Grid thickness - change the multiplier (0.0 means infinitely thin lines)
    // Increase this value (e.g., to 1.0 or 2.0) to make grid lines thicker
    float gridThicknessMultiplier = 0.0;
    float hlw = GRID_WIDTH * pp * gridThicknessMultiplier;
    float mul = 1.0 / stepSize;
    vec2 gf = abs(vec2(-0.5) + fract((xy + vec2(stepSize) * 0.5) * mul));
    float g = 1.0 - aaStep(hlw * mul, (hlw + pp * AA_FALLOFF) * mul, min(gf.x, gf.y));
    blend(baseCol, gridCol, g);
}

void drawCircle(inout vec4 baseCol, vec2 xy, vec2 center, float radius, vec4 color, float pp) {
    float r = length(xy - center);
    float c = 1.0 - aaStep(0.0, radius + pp * AA_FALLOFF, r);
    blend(baseCol, color, c * c);
}

void drawFuncECG(inout vec4 baseCol, vec2 xy, float pulseX, vec4 curveCol, float fadeLength, float pp) {
    // ADJUSTABLE: Glow radius multiplier - increase this (e.g., to 3.0 or 5.0) for a wider glow
    float glowRadiusMultiplier = 1.0;
    float hlw = CURVE_WIDTH * pp * 0.5;
    float glowHlw = hlw * glowRadiusMultiplier; // Wider radius for the glow
    float left = xy.x - glowHlw - pp * AA_FALLOFF;
    float right = xy.x + glowHlw + pp * AA_FALLOFF;
    float closest = 100000.0;
    for (float x = left; x <= right; x += pp * FUNC_SAMPLE_STEP) {
        if (x > pulseX) continue;
        vec2 diff = vec2(x, func_ecg(x)) - xy;
        float dSqr = dot(diff, diff);
        closest = min(dSqr, closest);
    }

    // Fading mechanism: The line fades out as it moves left across the screen
    // - dist: Distance from the leading edge (pulseX) to the current pixel (xy.x)
    // - fadeLength: The distance over which the line fades out (set above in mainImage)
    // - fade: Normalized fade value (1.0 at pulseX, 0.0 at pulseX - fadeLength)
    // - pow(fade, 0.4): Applies a non-linear fade for a smoother transition
    // ADJUSTABLE: Change fadeLength in mainImage to control how quickly the line fades (larger value = slower fade)
    // ADJUSTABLE: Change the pow exponent (0.4) to adjust the fade curve (smaller value = more gradual fade, larger value = sharper fade)
    float dist = pulseX - xy.x;
    float fade = clamp(1.0 - dist / fadeLength, 0.0, 1.0);
    fade = pow(fade, 0.4);

    // Glow pass: Wider, more transparent line that fades to transparent
    float glow = 1.0 - aaStep(0.0, glowHlw + pp * AA_FALLOFF, sqrt(closest));
    // ADJUSTABLE: Glow intensity - increase this (e.g., to 0.5 or 1.0) for a brighter glow
    float glowIntensity = 0.3;
    blend(baseCol, curveCol, glow * glow * fade * glowIntensity);

    // Main line pass: Draw the sharp line on top
    float c = 1.0 - aaStep(0.0, hlw + pp * AA_FALLOFF, sqrt(closest));
    blend(baseCol, curveCol, c * c * fade);
}

void drawFuncResp(inout vec4 baseCol, vec2 xy, float pulseX, vec4 curveCol, float fadeLength, float pp) {
    // ADJUSTABLE: Glow radius multiplier - increase this (e.g., to 3.0 or 5.0) for a wider glow
    float glowRadiusMultiplier = 1.0;
    float hlw = CURVE_WIDTH * pp * 0.5;
    float glowHlw = hlw * glowRadiusMultiplier;
    float left = xy.x - glowHlw - pp * AA_FALLOFF;
    float right = xy.x + glowHlw + pp * AA_FALLOFF;
    float closest = 100000.0;
    for (float x = left; x <= right; x += pp * FUNC_SAMPLE_STEP) {
        if (x > pulseX) continue;
        vec2 diff = vec2(x, func_resp(x)) - xy;
        float dSqr = dot(diff, diff);
        closest = min(dSqr, closest);
    }

    // Fading mechanism: The line fades out as it moves left across the screen
    // - dist: Distance from the leading edge (pulseX) to the current pixel (xy.x)
    // - fadeLength: The distance over which the line fades out (set above in mainImage)
    // - fade: Normalized fade value (1.0 at pulseX, 0.0 at pulseX - fadeLength)
    // - pow(fade, 0.4): Applies a non-linear fade for a smoother transition
    // ADJUSTABLE: Change fadeLength in mainImage to control how quickly the line fades (larger value = slower fade)
    // ADJUSTABLE: Change the pow exponent (0.4) to adjust the fade curve (smaller value = more gradual fade, larger value = sharper fade)
    float dist = pulseX - xy.x;
    float fade = clamp(1.0 - dist / fadeLength, 0.0, 1.0);
    fade = pow(fade, 0.4);

    // Glow pass
    float glow = 1.0 - aaStep(0.0, glowHlw + pp * AA_FALLOFF, sqrt(closest));
    // ADJUSTABLE: Glow intensity - increase this (e.g., to 0.5 or 1.0) for a brighter glow
    float glowIntensity = 0.3;
    blend(baseCol, curveCol, glow * glow * fade * glowIntensity);

    // Main line pass
    float c = 1.0 - aaStep(0.0, hlw + pp * AA_FALLOFF, sqrt(closest));
    blend(baseCol, curveCol, c * c * fade);
}

void drawFuncPulse(inout vec4 baseCol, vec2 xy, float pulseX, vec4 curveCol, float fadeLength, float pp) {
    // ADJUSTABLE: Glow radius multiplier - increase this (e.g., to 3.0 or 5.0) for a wider glow
    float glowRadiusMultiplier = 1.0;
    float hlw = CURVE_WIDTH * pp * 0.5;
    float glowHlw = hlw * glowRadiusMultiplier;
    float left = xy.x - glowHlw - pp * AA_FALLOFF;
    float right = xy.x + glowHlw + pp * AA_FALLOFF;
    float closest = 100000.0;
    for (float x = left; x <= right; x += pp * FUNC_SAMPLE_STEP) {
        if (x > pulseX) continue;
        vec2 diff = vec2(x, func_pulse(x)) - xy;
        float dSqr = dot(diff, diff);
        closest = min(dSqr, closest);
    }

    // Fading mechanism: The line fades out as it moves left across the screen
    // - dist: Distance from the leading edge (pulseX) to the current pixel (xy.x)
    // - fadeLength: The distance over which the line fades out (set above in mainImage)
    // - fade: Normalized fade value (1.0 at pulseX, 0.0 at pulseX - fadeLength)
    // - pow(fade, 0.4): Applies a non-linear fade for a smoother transition
    // ADJUSTABLE: Change fadeLength in mainImage to control how quickly the line fades (larger value = slower fade)
    // ADJUSTABLE: Change the pow exponent (0.4) to adjust the fade curve (smaller value = more gradual fade, larger value = sharper fade)
    float dist = pulseX - xy.x;
    float fade = clamp(1.0 - dist / fadeLength, 0.0, 1.0);
    fade = pow(fade, 0.4);

    // Glow pass
    float glow = 1.0 - aaStep(0.0, glowHlw + pp * AA_FALLOFF, sqrt(closest));
    // ADJUSTABLE: Glow intensity - increase this (e.g., to 0.5 or 1.0) for a brighter glow
    float glowIntensity = 0.3;
    blend(baseCol, curveCol, glow * glow * fade * glowIntensity);

    // Main line pass
    float c = 1.0 - aaStep(0.0, hlw + pp * AA_FALLOFF, sqrt(closest));
    blend(baseCol, curveCol, c * c * fade);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;

    float z = 2.3;
    float graphRange = 0.4 + pow(1.2, z * z * z);

    // Background
    float t = length(0.5 - uv) * 1.414;
    t = t * t * t;
    vec4 col = mix(vec4(0.0), vec4(0.01, 0.025, 0.0347, 1.0), t);

    float rate = SCOPE_RATE;
    float time = iTime * rate;

    // === ECG (Top Line) ===
    // ADJUSTABLE: Vertical scale of the waveform - increase this (e.g., to 10.0 or 12.0) to make the waveform smaller (less vertical space)
    vec2 graphSize_ecg = vec2(aspect * graphRange, 6.0);
    float graphLeft_ecg = 0.5 - graphSize_ecg.x * 0.5;
    float graphWidth_ecg = graphSize_ecg.x;
    float scrollSpeed_ecg = graphWidth_ecg * 0.3;
    float pulseX_ecg = graphLeft_ecg + mod(time * scrollSpeed_ecg, graphWidth_ecg);
    // ADJUSTABLE: Fade length for ECG - increase this (e.g., to 1.0) for a slower fade-out
    float fadeLength_ecg = graphWidth_ecg * 0.74;

    // ADJUSTABLE: Position of the ECG line - change 0.75 to move the line (e.g., 0.7 to move it down)
    vec2 graphCenter_ecg = vec2(0.5, 0.7); // 25% from the top
    vec2 graphPos_ecg = vec2(graphCenter_ecg.x - graphSize_ecg.x * 0.5, -graphCenter_ecg.y * graphSize_ecg.y);
    vec2 xy_ecg = graphPos_ecg + uv * graphSize_ecg;
    float pp_ecg = graphSize_ecg.y / iResolution.y;

    // Grid for ECG
    // ADJUSTABLE: Grid brightness - change the alpha (0.02) to adjust brightness (e.g., 0.05 for brighter)
    // ADJUSTABLE: Grid spacing - change the stepSize values (0.05, 0.1, 1.0) for finer/coarser grid
    drawGrid(col, xy_ecg, 0.05, vec4(1.0, 1.0, 1.0, 0.02), pp_ecg);
    drawGrid(col, xy_ecg, 0.1, vec4(1.0, 1.0, 1.0, 0.02), pp_ecg);
    drawGrid(col, xy_ecg, 1.0, vec4(1.0, 1.0, 1.0, 0.02), pp_ecg);

    // ADJUSTABLE: Color of the ECG line (top graph)
    // Current color: Cyan (R=0.0, G=1.0, B=0.7, A=1.0)
    // Change the RGB values to adjust the color (A should remain 1.0 for full opacity)
    // Examples:
    // - Green: vec4(0.0, 1.0, 0.0, 1.0)
    // - Red: vec4(1.0, 0.0, 0.0, 1.0)
    // - White: vec4(1.0, 1.0, 1.0, 1.0)
    vec4 pulseCol_ecg = vec4(0.0, 1.0, 0.0, 1.0);
    drawFuncECG(col, xy_ecg, pulseX_ecg, pulseCol_ecg, fadeLength_ecg, pp_ecg);
    float dotY_ecg = func_ecg(pulseX_ecg);
    drawCircle(col, xy_ecg, vec2(pulseX_ecg, dotY_ecg), CURVE_WIDTH * pp_ecg, vec4(0.0, 1.0, 0.7, 1.5), pp_ecg);

    // === Respiratory Rate (Middle Line) ===
    // ADJUSTABLE: Vertical scale of the waveform - increase this (e.g., to 10.0 or 12.0) to make the waveform smaller
    vec2 graphSize_resp = vec2(aspect * graphRange, 8.0);
    float graphLeft_resp = 0.5 - graphSize_resp.x * 0.5;
    float graphWidth_resp = graphSize_resp.x;
    float scrollSpeed_resp = graphWidth_resp * 0.3;
    float pulseX_resp = graphLeft_resp + mod(time * scrollSpeed_resp, graphWidth_resp);
    // ADJUSTABLE: Fade length for Respiratory Rate - increase this (e.g., to 1.0) for a slower fade-out
    float fadeLength_resp = graphWidth_resp * 0.74;

    // ADJUSTABLE: Position of the Respiratory Rate line - change 0.5 to move the line (e.g., 0.55 to move it up)
    vec2 graphCenter_resp = vec2(0.5, 0.5); // 50% from the top
    vec2 graphPos_resp = vec2(graphCenter_resp.x - graphSize_resp.x * 0.5, -graphCenter_resp.y * graphSize_resp.y);
    vec2 xy_resp = graphPos_resp + uv * graphSize_resp;
    float pp_resp = graphSize_resp.y / iResolution.y;

    // Grid for Respiratory Rate
    // ADJUSTABLE: Grid brightness, spacing - same as above
    drawGrid(col, xy_resp, 0.05, vec4(1.0, 1.0, 1.0, 0.0), pp_resp);
    drawGrid(col, xy_resp, 0.1, vec4(1.0, 1.0, 1.0, 0.0), pp_resp);
    drawGrid(col, xy_resp, 1.0, vec4(1.0, 1.0, 1.0, 0.0), pp_resp);

    // ADJUSTABLE: Color of the Respiratory Rate line (middle graph)
    // Current color: Yellow (R=1.0, G=1.0, B=0.0, A=1.0)
    // Change the RGB values to adjust the color (A should remain 1.0 for full opacity)
    // Examples:
    // - Orange: vec4(1.0, 0.5, 0.0, 1.0)
    // - Blue: vec4(0.0, 0.0, 1.0, 1.0)
    // - White: vec4(1.0, 1.0, 1.0, 1.0)
    vec4 pulseCol_resp = vec4(1.0, 1.0, 0.0, 1.0);
    drawFuncResp(col, xy_resp, pulseX_resp, pulseCol_resp, fadeLength_resp, pp_resp);
    float dotY_resp = func_resp(pulseX_resp);
    drawCircle(col, xy_resp, vec2(pulseX_resp, dotY_resp), CURVE_WIDTH * pp_resp, vec4(1.0, 1.0, 0.0, 1.5), pp_resp);

    // === Pulse Oximetry (Bottom Line) ===
    // ADJUSTABLE: Vertical scale of the waveform - increase this (e.g., to 10.0 or 12.0) to make the waveform smaller
    vec2 graphSize_pulse = vec2(aspect * graphRange, 5.0);
    float graphLeft_pulse = 0.5 - graphSize_pulse.x * 0.5;
    float graphWidth_pulse = graphSize_pulse.x;
    float scrollSpeed_pulse = graphWidth_pulse * 0.3;
    float pulseX_pulse = graphLeft_pulse + mod(time * scrollSpeed_pulse, graphWidth_pulse);
    // ADJUSTABLE: Fade length for Pulse Oximetry - increase this (e.g., to 1.0) for a slower fade-out
    float fadeLength_pulse = graphWidth_pulse * 0.7;

    // ADJUSTABLE: Position of the Pulse Oximetry line - change 0.25 to move the line (e.g., 0.3 to move it up)
    vec2 graphCenter_pulse = vec2(0.5, 0.25); // 75% from the top
    vec2 graphPos_pulse = vec2(graphCenter_pulse.x - graphSize_pulse.x * 0.5, -graphCenter_pulse.y * graphSize_pulse.y);
    vec2 xy_pulse = graphPos_pulse + uv * graphSize_pulse;
    float pp_pulse = graphSize_pulse.y / iResolution.y;

    // Grid for Pulse Oximetry
    // ADJUSTABLE: Grid brightness, spacing - same as above
    drawGrid(col, xy_pulse, 0.05, vec4(1.0, 1.0, 1.0, 0.02), pp_pulse);
    drawGrid(col, xy_pulse, 0.1, vec4(1.0, 1.0, 1.0, 0.02), pp_pulse);
    drawGrid(col, xy_pulse, 1.0, vec4(1.0, 1.0, 1.0, 0.02), pp_pulse);

    // ADJUSTABLE: Color of the Pulse Oximetry line (bottom graph)
    // Current color: Magenta (R=1.0, G=0.0, B=1.0, A=1.0)
    // Change the RGB values to adjust the color (A should remain 1.0 for full opacity)
    // Examples:
    // - Purple: vec4(0.5, 0.0, 1.0, 1.0)
    // - Cyan: vec4(0.0, 1.0, 1.0, 1.0)
    // - White: vec4(1.0, 1.0, 1.0, 1.0)
    vec4 pulseCol_pulse = vec4(1.0, 0.0, 1.0, 1.0);
    drawFuncPulse(col, xy_pulse, pulseX_pulse, pulseCol_pulse, fadeLength_pulse, pp_pulse);
    float dotY_pulse = func_pulse(pulseX_pulse);
    drawCircle(col, xy_pulse, vec2(pulseX_pulse, dotY_pulse), CURVE_WIDTH * pp_pulse, vec4(1.0, 0.0, 1.0, 1.5), pp_pulse);

    fragColor = col;
}