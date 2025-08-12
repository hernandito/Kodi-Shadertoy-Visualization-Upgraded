// Converted from WIP GLSL fragment shader to ShaderToy

// --- CRT Effect Definitions ---
// Add these at the top of the shader
#define MACRO_TIME iTime
#define MACRO_RES iResolution.xy
#define MACRO_SMOOTH(a, b, c) smoothstep(a, b, c)
#define BACKGROUND_COLOR vec4(.0, .1, .2, 1.) // Tweakable dark background color

// Adjust this value to control scanline thickness/density.
// Increase to make scanlines thinner/more numerous (e.g., 1.5, 2.0).
// Decrease to make scanlines thicker/less frequent (e.g., 0.5).
#define SCANLINE_DENSITY_MULTIPLIER 1.5 // Default value set to slightly thinner than original iTime

// Noise function for the background
float hash2(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .2831);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float hash(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

vec3 noiseOffset(vec3 id, float t) {
    float seed = hash(id);
    return vec3(
        sin(seed * 6.0 + t * 0.4),
        cos(seed * 4.5 + t * 0.35),
        sin(seed * 2.5 + t * 0.3)
    ) * 0.15;
}

mat3 rotY(float a) {
    float s = sin(a), c = cos(a);
    return mat3(c,0.0,-s, 0.0,1.0,0.0, s,0.0,c);
}
mat3 rotX(float a) {
    float s = sin(a), c = cos(a);
    return mat3(1.0,0.0,0.0, 0.0,c,-s, 0.0,s,c);
}

vec3 shiftColor(float t) {
    float r = 0.5 + 0.5 * sin(t + 0.0);
    float g = 0.5 + 0.5 * sin(t + 2.0);
    float b = 0.5 + 0.5 * sin(t + 4.0);
    return vec3(r, g, b);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 u_resolution = iResolution.xy;
    float u_time = iTime*.3;

    vec2 vUv = fragCoord / u_resolution;
    vec2 screenUV = vUv * 2.0 - 1.0;
    float curveAmount = 0.5;
    vec2 warpedUV = screenUV + screenUV * length(screenUV) * curveAmount;
    vec2 uv = (warpedUV * 0.5 + 0.5 - 0.5) * vec2(u_resolution.x / u_resolution.y, 1.0);
    vec2 centerUv = warpedUV * 0.5;
    vec2 screenUv = warpedUV * 0.5 + 0.5;

    float t = u_time;
    vec3 ro = vec3(0.0, 0.0, 7.0);
    vec3 rd = normalize(vec3(uv, -1.5));

    // --- CRT Effect Application: 1. Dark Background with Noise ---
    vec2 U = fragCoord;
    vec2 V = 1. - 2. * U / MACRO_RES;

    fragColor = BACKGROUND_COLOR; // Initialize fragColor with background
    fragColor.rgb += .06 * hash2(MACRO_TIME + V * vec2(1462.439, 297.185)); // Add noise to background

    vec3 baseVerts[8];
    baseVerts[0] = vec3(-1.0,-1.0,-1.0);
    baseVerts[1] = vec3( 1.0,-1.0,-1.0);
    baseVerts[2] = vec3( 1.0, 1.0,-1.0);
    baseVerts[3] = vec3(-1.0, 1.0,-1.0);
    baseVerts[4] = vec3(-1.0,-1.0, 1.0);
    baseVerts[5] = vec3( 1.0,-1.0, 1.0);
    baseVerts[6] = vec3( 1.0, 1.0, 1.0);
    baseVerts[7] = vec3(-1.0, 1.0, 1.0);

    // Initialize edges array element by element - this is the most compatible way for GLSL ES 1.0
    int edges[24];
    edges[0] = 0; edges[1] = 1; edges[2] = 1; edges[3] = 2;
    edges[4] = 2; edges[5] = 3; edges[6] = 3; edges[7] = 0;
    edges[8] = 4; edges[9] = 5; edges[10] = 5; edges[11] = 6;
    edges[12] = 6; edges[13] = 7; edges[14] = 7; edges[15] = 4;
    edges[16] = 0; edges[17] = 4; edges[18] = 1; edges[19] = 5;
    edges[20] = 2; edges[21] = 6; edges[22] = 3; edges[23] = 7;

    vec3 finalColor = vec3(0.0); // This will hold the rendered cube and glow

    for (int pass = 0; pass < 1; pass++) {
        float delay = float(pass) * 0.2;
        float trailTime = t - delay;
        float fade = exp(-2.8 * delay);
        vec3 edgeColor = shiftColor(trailTime * 1.5) * fade;

        vec3 verts[8];
        mat3 rot = rotY(trailTime) * rotX(trailTime * 0.6);

        // Populate verts array element by element within the loop
        verts[0] = rot * (baseVerts[0] + noiseOffset(vec3(0.0), trailTime *10.0 + 25.0 * sin(t*0.75)));
        verts[1] = rot * (baseVerts[1] + noiseOffset(vec3(1.0), trailTime *10.0 + 25.0 * sin(t*0.75)));
        verts[2] = rot * (baseVerts[2] + noiseOffset(vec3(2.0), trailTime *10.0 + 25.0 * sin(t*0.75)));
        verts[3] = rot * (baseVerts[3] + noiseOffset(vec3(3.0), trailTime *10.0 + 25.0 * sin(t*0.75)));
        verts[4] = rot * (baseVerts[4] + noiseOffset(vec3(4.0), trailTime *10.0 + 25.0 * sin(t*0.75)));
        verts[5] = rot * (baseVerts[5] + noiseOffset(vec3(5.0), trailTime *10.0 + 25.0 * sin(t*0.75)));
        verts[6] = rot * (baseVerts[6] + noiseOffset(vec3(6.0), trailTime *10.0 + 25.0 * sin(t*0.75)));
        verts[7] = rot * (baseVerts[7] + noiseOffset(vec3(7.0), trailTime *10.0 + 25.0 * sin(t*0.75)));

        float glow = 0.0;
        float tGlow = 0.0;

        for (int i = 0; i < 64; i++) {
            vec3 p = ro + rd * tGlow;
            float d = 999.0;
            for (int j = 0; j < 12; j++) {
                vec3 a = verts[edges[j * 2]];
                vec3 b = verts[edges[j * 2 + 1]];
                d = min(d, sdCapsule(p, a, b, 0.025));
            }
            glow += exp(-15.0 * d) * exp(-0.2 * tGlow) * 0.04;
            if (tGlow > 10.0) break;
            tGlow += 0.1;
        }

        float glowNoise = fract(sin(dot(vUv * 300.0, vec2(12.9898,78.233))) * 43758.5453);
        glow *= 0.95 + 0.1 * glowNoise;

        float tHit = 0.0;
        bool hit = false;
        for (int i = 0; i < 64; i++) {
            vec3 p = ro + rd * tHit;
            float d = 999.0;
            for (int j = 0; j < 12; j++) {
                vec3 a = verts[edges[j * 2]];
                vec3 b = verts[edges[j * 2 + 1]];
                d = min(d, sdCapsule(p, a, b, 0.025));
            }
            if (d < 0.001) {
                finalColor += edgeColor;
                hit = true;
                break;
            }
            tHit += d;
            if (tHit > 10.0) break;
        }

        glow = pow(glow, 0.15);
        finalColor += glow * edgeColor;
    }

    // Add the rendered cube and glow on top of the new background
    fragColor.rgb += finalColor;

    float border = smoothstep(0.4, 0.48, length((vUv - 0.5) * 2.0));
    vec3 frameShadow = vec3(0.0) * border;
    fragColor.rgb += frameShadow;

    // --- CRT Effect Application: 2. Vignette Effect (Apply after rendering) ---
    fragColor *= 1.25 * vec4(1. - MACRO_SMOOTH(.1, 1.8, length(V * V)));
    fragColor += .14 * vec4(pow(1. - length(V * vec2(.5, .35)), 3.), .0, .0, 1.);

    // --- CRT Effect Application: 3. Horizontal Scanline Effect (Apply last) ---
    // Scanline density adjusted by SCANLINE_DENSITY_MULTIPLIER
    float scanLine = 0.75 + .35 * sin(fragCoord.y * 1.9 * SCANLINE_DENSITY_MULTIPLIER);
    fragColor *= scanLine;

    // Ensure final color values are within a valid range
    fragColor = clamp(fragColor, 0.0, 1.0);
}