// Adjustable BCS parameters for postprocessing
#define BRIGHTNESS 0.10  // Adjusts overall brightness (-1.0 to 1.0, 0.0 = no change)
// Example: BRIGHTNESS 0.2  // Brightens the scene
// Example: BRIGHTNESS -0.2 // Darkens the scene

#define CONTRAST 1.0    // Adjusts contrast (0.0 to 2.0, 1.0 = no change)
// Example: CONTRAST 1.5    // Increases contrast (darker darks, brighter lights)
// Example: CONTRAST 0.5    // Decreases contrast (more washed out)

#define SATURATION 1.0  // Adjusts saturation (0.0 to 2.0, 1.0 = no change)
// Example: SATURATION 1.5  // More vibrant colors
// Example: SATURATION 0.5  // Less vibrant, 0.0 = grayscale

vec3 saturate(vec3 a){return clamp(a,0.,1.);}
float opS( float d2, float d1 ){return max(-d1,d2);}
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
float rand(float n){
    return fract(cos(n*89.42)*343.42);
}

float dtoa(float d, float amount)
{
    return clamp(1.0 / (clamp(d, 1.0/amount, 1.0)*amount), 0.,1.);
}

float sdColumn(vec2 uv, float xmin, float xmax)
{
    return max(xmin - uv.x, uv.x - xmax);
}

float sdAxisAlignedRect(vec2 uv, vec2 tl, vec2 br)
{
    vec2 d = max(tl - uv, uv - br);
    return length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y));
}

float smoothstep4(float e1, float e2, float e3, float e4, float val)
{
    return min(smoothstep(e1,e2,val), 1.-smoothstep(e3,e4,val));
}

// --- Horizontal motion with ease-in/ease-out using triangle wave with smooth corners ---
float horizontalMotion(float t) {
    float speed = 14.25; // seconds per direction before reversal
    float cycle = mod(t, speed * 2.0);
    float x = cycle / speed; // range [0, 2]
    float tri = x < 1.0 ? x : 2.0 - x; // triangle wave from 0 to 1 to 0
    float eased = smoothstep(0.0, 1.0, tri); // ease in/out
    return mix(-0.25, 0.25, eased); // move between -25% and +25% of screen width
}

// Original stroke boundaries, modified to extend right edge
const float left = 1.82;
const float right = 3.5;  // Increased to push right edge well off-screen (was 2.08)

vec3 texturize(vec2 uv, vec3 inpColor, float dist)
{
    float falloffY = 1.0 - smoothstep4(-0.5, 0.1, 0.4, 1., uv.y);
    float falloffX = smoothstep(left, right, uv.x) * 0.6;
    dist -= falloffX * pow(falloffY, 0.6) * 0.09;

    float amt = 13. + (max(falloffX, falloffY) * 600.);
    return mix(inpColor, vec3(0.), dtoa(dist, amt));
}

float map(vec2 uv, float hMotion)
{
    uv.x += hMotion; // shared horizontal offset

    uv.x += rand(uv.y) * 0.006; // subtle analog distortion
    uv.x += sin(iTime * 0.2 + uv.y * 4.0) * 0.0015; // flicker

    return sdColumn(uv, left, right);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord;
    uv = (uv / iResolution.y * 2.0) - 1.;

    // Analog screen warp
    uv.x += cos(uv.y * (uv.x + 1.0) * 3.0) * 0.003;
    uv.y += cos(uv.x * 6.0) * 0.00007;

    vec3 col = vec3(0.941, 0.839, 0.608); // paper color

    // --- Shared horizontal motion ---
    float motionOffset = horizontalMotion(iTime);

    // --- Black ink brush stroke ---
    float dist = map(uv, motionOffset);
    float flicker = 0.95 + 0.05 * sin(iTime * 0.4);
    vec3 strokeColor = texturize(uv + vec2(motionOffset, 0.0), col, dist);
    col = mix(col, strokeColor, flicker);

    // --- Red-orange square with hand-drawn animation effect ---
    dist = sdAxisAlignedRect(uv, vec2(-0.68), vec2(-0.55));
    float amt = 90. + rand(uv.y) * 100. + rand(uv.x / 4.) * 90.;

    // Wiggling square
    float vary = sin(uv.x * uv.y * 50. + iTime * 2.0) * 0.0047;
    dist = opS(dist - 0.028 + vary, dist - 0.019 - vary);
    col = mix(col, vec3(0.99, 0.4, 0.0), dtoa(dist, amt) * 0.7);
    col = mix(col, vec3(0.85, 0.0, 0.0), dtoa(dist, 700.));

    // --- Vignette ---
    uv -= 1.0;
    float vignetteAmt = 1. - dot(uv * 0.5, uv * 0.12);
    col *= vignetteAmt;

    // --- Grain ---
    col.rgb += (rand(uv) - 0.5) * 0.07;
    col.rgb = saturate(col.rgb);

    // --- BCS Adjustments in Postprocessing ---
    // Brightness: Add a uniform offset
    col += BRIGHTNESS;
    
    // Contrast: Scale around the midpoint (0.5)
    col = (col - 0.5) * CONTRAST + 0.5;
    
    // Saturation: Adjust color intensity based on luminance
    float lum = dot(col, vec3(0.299, 0.587, 0.114)); // Standard luminance weights
    col = mix(vec3(lum), col, SATURATION);
    
    // Ensure final color stays in valid range
    col = saturate(col);

    fragColor = vec4(col, 1.0);
}