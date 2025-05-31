#define PI 3.14159265359

float vmin(vec2 v) {
    return min(v.x, v.y);
}

float vmax(vec2 v) {
    return max(v.x, v.y);
}

float ellip(vec2 p, vec2 s) {
    float m = vmin(s);
    return (length(p / s) * m) - m;
}

float halfEllip(vec2 p, vec2 s) {
    p.x = max(0., p.x);
    float m = vmin(s);
    return (length(p / s) * m) - m;
}

float fBox(vec2 p, vec2 b) {
    return vmax(abs(p) - b);
}

float dvd_d(vec2 p) {
    float d = halfEllip(p, vec2(.8, .5));
    d = max(d, -p.x - .5);
    float d2 = halfEllip(p, vec2(.45, .3));
    d2 = max(d2, min(-p.y + .2, -p.x - .15));
    d = max(d, -d2);
    return d;
}

float dvd_v(vec2 p) {
    vec2 pp = p;
    p.y += .7;
    p.x = abs(p.x);
    vec2 a = normalize(vec2(1,-.55));
    float d = dot(p, a);
    float d2 = d + .3;
    p = pp;
    d = min(d, -p.y + .3);
    d2 = min(d2, -p.y + .5);
    d = max(d, -d2);
    d = max(d, abs(p.x + .3) - 1.1);
    return d;
}

float dvd_c(vec2 p) {
    p.y += .95;
    float d = ellip(p, vec2(1.8,.25));
    float d2 = ellip(p, vec2(.45,.09));
    d = max(d, -d2);
    return d;
}

float dvd(vec2 p) {
    p.y -= .345;
    p.x -= .035;
    p *= mat2(1,-.2,0,1);
    float d = dvd_v(p);
    d = min(d, dvd_c(p));
    p.x += 1.3;
    d = min(d, dvd_d(p));
    p.x -= 2.4;
    d = min(d, dvd_d(p));
    return d;
}

// Noise function
float noise(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Layered noise function with an additional layer to reduce grid patterns
float layeredNoise(vec2 st, float t) {
    // Layer 1: Base scale
    float n1 = noise(st + t);
    // Layer 2: Medium scale
    vec2 st2 = st * 2.0;
    float n2 = noise(st2 + t);
    // Layer 3: Fine scale
    vec2 st3 = st * 4.0;
    float n3 = noise(st3 + t);
    // Layer 4: Finer scale to break up grid patterns
    vec2 st4 = st * 8.0;
    float n4 = noise(st4 + t);
    // Combine layers with weights
    return 0.4 * n1 + 0.3 * n2 + 0.2 * n3 + 0.1 * n4;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (-iResolution.xy + 2.0 * fragCoord) / iResolution.y;

    vec2 screenSize = vec2(iResolution.x / iResolution.y, 1.) * 2.;

    // Tunable parameters for the DVD logo
    float speed = 0.2;
    vec3 logoColor = vec3(0.9, 0.6, 0.1); // Orangish-yellow
    float logoScale = 0.115;
    vec2 logoSize = vec2(2., 0.85) * logoScale;

    // Tunable parameters for the noise
    float darknessLevel = 0.3; // 0.0 = normal noise, 1.0 = completely black
    float noiseScale = 200.0;  // Larger values = smaller grains (tuned for 4K)
    float noiseSpeed = 2.0;    // Controls flicker speed (lower = slower)

    // Tunable parameters for the drop shadow
    float shadowAlpha = 0.5;    // 0.0 = fully transparent, 1.0 = fully opaque
    vec2 shadowOffset = vec2(0.02, -0.02); // Offset distance in normalized coordinates
    float shadowFalloff = 2.0;  // Higher values = sharper falloff, lower = softer

    // Tunable parameters for the vignette
    float vignetteIntensity = 3.0; // Increased to make edges darker (closer to black)
    float vignetteSize = 2.5;      // Larger values = smaller vignette (darkening closer to edges)
    float vignetteSoftness = 1.40; // Larger values = softer transition

 // Background selection parameters
    int backgroundType = 0;        // 0 = noise, 1 = black, 2 = user-defined color
    vec3 backgroundColor = vec3(0.2, 0.3, 0.5); // User-defined color (e.g., dark blue)

    // Cap iTime to a 5-minute cycle to prevent floating-point issues
    float t = mod(iTime, 300.0);
    vec2 dir = normalize(vec2(9., 16));

    // Calculate bounds considering the logo size
    vec2 bounds = screenSize * 0.5 - logoSize;

    // Smooth movement with bouncing
    vec2 move = dir * t * speed;
    vec2 moveWrapped = mod(move, 4.0 * bounds);
    vec2 moveAbs = abs(moveWrapped - 2.0 * bounds) - bounds;
    move = clamp(moveAbs, -bounds, bounds);

    // Set the background based on backgroundType
    vec4 col;
    if (backgroundType == 0) {
        // Noise background
        vec2 st = fragCoord.xy / iResolution.xy * noiseScale;
        // Add a small random offset to break up patterns (time-based)
        vec2 timeOffset = vec2(noise(vec2(t, t)), noise(vec2(t + 1.0, t + 1.0)));
        st += timeOffset * 0.1;
        // Add a static per-pixel offset to further reduce grid patterns
        vec2 staticOffset = vec2(noise(st + vec2(10.0, 20.0)), noise(st + vec2(30.0, 40.0)));
        st += staticOffset * 0.05;
        // Compute two noise samples at different time steps
        float t1 = t * noiseSpeed;
        float t2 = (t + 0.016) * noiseSpeed;
        float n1 = layeredNoise(st, t1);
        float n2 = layeredNoise(st, t2);
        // Use noise for blending to add more randomness
        float blend = noise(vec2(t, t + 2.0));
        float noiseValue = mix(n1, n2, blend);
        // Apply darkness level
        noiseValue = noiseValue * (1.0 - darknessLevel);
        col = vec4(vec3(noiseValue), 1.0);
    } else if (backgroundType == 1) {
        // Solid black background
        col = vec4(vec3(0.0), 1.0);
    } else {
        // User-defined color background
        col = vec4(backgroundColor, 1.0);
    }

    // Apply vignette (darkening only)
    vec2 uv = fragCoord.xy / iResolution.xy; // 0 to 1 coordinates
    uv = uv * 2.0 - 1.0; // -1 to 1 coordinates
    float vignette = length(uv) / vignetteSize; // Distance from center
    vignette = smoothstep(0.0, vignetteSoftness, vignette); // Smooth transition
    vignette = 1.0 - vignette * vignetteIntensity; // Invert and scale for darkening
    col.rgb *= vignette; // Multiply to darken the background

    // Drop shadow
    float dShadow = dvd((p - move - shadowOffset) / logoScale);
    dShadow /= fwidth(dShadow);
    dShadow = 1.0 - clamp(dShadow, 0.0, 1.0);
    // Apply falloff to the shadow
    dShadow = smoothstep(0.0, shadowFalloff, dShadow);
    // Blend the shadow with the background
    vec3 shadowColor = vec3(0.0); // Black shadow
    col.rgb = mix(col.rgb, shadowColor, dShadow * shadowAlpha);

    // DVD logo with original anti-aliasing
    float d = dvd((p - move) / logoScale);
    d /= fwidth(d);
    d = 1.0 - clamp(d, 0.0, 1.0);

    // Blend the logo on top of the noise and shadow
    col.rgb = mix(col.rgb, logoColor, d);

    fragColor = col;
}

/** SHADERDATA
{
    "title": "DVD with Selectable Background, Drop Shadow, and Vignette",
    "description": "",
    "model": "person"
}
*/