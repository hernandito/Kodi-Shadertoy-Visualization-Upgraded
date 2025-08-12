// "Roadway Shader" - Replicated and Simplified for Kodi & Web Compatibility

// Inspired by "Space Racing Lite" by eiffie and Kali:
// https://www.shadertoy.com/view/ldjGRh

// This shader focuses on the core roadway geometry, fractal side banks,
// and side lights, optimized for compatibility with both Shadertoy
// and Kodi's OpenGL ES 1.0 environment.

precision mediump float; // Standard precision for OpenGL ES 1.0

#define RAY_STEPS 65    // Number of steps for raymarching
#define SHADOW_STEPS 40 // Enabled: Number of steps for shadow raymarching
#define ITERATIONS 5    // Iterations for fractal detail
#define MAX_DIST 40.0   // Maximum raymarch distance (User Adjusted)

#define LIGHT_COLOR vec3(1.0, 0.85, 0.6) // Main light color
#define AMBIENT_COLOR vec3(0.7, 0.85, 1.0) // Ambient scene color
#define SUN_COLOR vec3(1.0, 0.8, 0.5) // Color for sun glow (background)
#define TUBE_COLOR vec3(1.0, 0.6, 0.25) * 1.2 // Color for side tube lights
#define VIRTUAL_LIGHT_COLOR vec3(0.6, 0.75, 1.0) // Virtual light color, similar to original turbines

#define SPECULAR 0.4 // Base specular amount
#define DIFFUSE  2.0
#define AMBIENT  0.4

#define BRIGHTNESS 0.9 // User Adjusted
#define GAMMA 1.10
#define SATURATION 1.1 // User Adjusted
#define CONTRAST 1.15 // User Adjusted

// New Parameters for Virtual Light fine-tuning
#define VIRTUAL_LIGHT_REACH -3.5 // How far ahead of the camera the light source is
#define VIRTUAL_LIGHT_FALLOFF_DISTANCE 0.05 // Controls how quickly light diminishes with distance (smaller = faster falloff)
#define VIRTUAL_LIGHT_FALLOFF_POWER 12.0 // Controls the sharpness/softness of the light's edge (higher = sharper)
#define VIRTUAL_LIGHT_INTENSITY 1.50 // Overall brightness multiplier for the virtual light
#define VIRTUAL_LIGHT_SPREAD 0.125 // How "spread out" the light beam is (modulates diffuse)

// New Parameter for Specular Highlight Strength
#define SPECULAR_STRENGTH 0.2 // Multiplier for the overall specular highlights (default 0.7)

#define DETAIL 0.003 // Raymarch detail threshold (User Adjusted)
#define SPEED 0.5    // Animation speed

// Time variable 't' derived from iTime (standard Shadertoy/GLSL convention)
#define t iTime * SPEED

#define LIGHTDIR normalize(vec3(0.6, -0.2, -1.0)) // Direction of the main light source

// ------------------------------------------------------------------
//    Global Variables
// ------------------------------------------------------------------

// Removed explicit declarations for iResolution, iTime, iMouse, iChannel0.
// Kodi's Shadertoy wrapper is expected to provide these implicitly as built-in variables.
// Using 'iTime' for time variable name for broader compatibility.

float FOLD = 2.0; // Controls fractal fold and track width
const vec2 tubepos = vec2(0.35, 0.0); // Light tubes position relative to FOLD
mat2 trmx = mat2(1.0); // Transformation matrix for fractal (initialized)
float det = 0.0; // Detail level (varies with distance, initialized)
float minT = 1000.0; // Minimum distance trap for tube glows (initialized)
float tubeinterval = 0.0; // Tube tiling for glow and lighting (initialized)
mat2 fractrot = mat2(1.0); // Rotation matrix for fractal (initialized)

// ------------------------------------------------------------------
//    General functions
// ------------------------------------------------------------------

mat2 rot(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

mat3 lookat(vec3 fw, vec3 up) {
    fw = normalize(fw);
    vec3 rt = normalize(cross(fw, normalize(up)));
    return mat3(rt, cross(rt, fw), fw);
}

float smin(float a, float b, float k) {
    return -log(exp(-k * a) + exp(-k * b)) / k;
}

// ------------------------------------------------------------------
//    Track Geometry
// ------------------------------------------------------------------

// The track path, a series of curves
vec3 path(float ti) {
    float freq = 0.5;
    ti *= freq;
    float x = cos(cos(ti * 0.35682) + ti * 0.2823) * cos(ti * 0.1322) * 1.5;
    float y = sin(ti * 0.166453) * 4.0 + cos(cos(ti * 0.125465) + ti * 0.17354) * cos(ti * 0.05123) * 2.0;
    vec3 p = vec3(x, y, ti / freq);
    return p;
}

// Distance function for the tunnel/track ceiling
float tunnel(float z) {
    return abs(100.0 - mod(z + 15.0, 200.0)) - 30.0;
}

// ------------------------------------------------------------------
//    Distance Functions (DEs)
// ------------------------------------------------------------------

// DE for tubes
float tubes(vec3 pos) {
    pos.x = abs(pos.x) - tubepos.x - FOLD;
    pos.y += tubepos.y;
    return (length(pos.xy) - 0.05);
}

// Combined Distance Estimator for the scene (roadway and fractal banks)
float de(vec3 pos) {
    pos.xy -= path(pos.z).xy; // Transform coordinates to follow track
    FOLD = 1.7 + pow(abs(100.0 - mod(pos.z, 200.0)) / 100.0, 2.0) * 2.0; // Varies fractal fold & track width
    pos.x -= FOLD; // Shift for fractal calculation

    vec3 tpos = pos;
    tpos.z = abs(2.0 - mod(tpos.z, 4.0)); // Z-folding for fractal
    vec4 p_fractal = vec4(tpos, 1.0); // Renamed p to p_fractal to avoid conflict

    for (int i = 0; i < ITERATIONS; i++) { // Calculate fractal
        p_fractal.xz = clamp(p_fractal.xz, -vec2(FOLD, 2.0), vec2(FOLD, 2.0)) * 2.0 - p_fractal.xz;
        p_fractal = p_fractal * 2.5 / clamp(dot(p_fractal.xyz, p_fractal.xyz), 0.5, 1.0) - vec4(1.2, 0.5, 0.0, -0.5);
        p_fractal.xy *= fractrot;
    }
    pos.x += FOLD; // Shift back

    float fr = min(max(pos.y + 0.4, abs(pos.x) - 0.15 * FOLD), (max(p_fractal.x, p_fractal.y) - 1.0) / p_fractal.w); // Fractal + pit
    float tub = tubes(pos);
    minT = min(minT, tub * 0.5); // Trap min distance to tubes for glow

    float d = tub; // Start with tubes
    d = min(fr, d); // Combine with fractal roadway
    d = min(d, max(abs(pos.y - 1.35 + cos(3.1416 + pos.x * 0.8) * 0.5) - 0.1, tunnel(pos.z))); // Combine with tunnel/ceiling
    d = max(d, abs(pos.x) - FOLD * 2.0); // Boundary for scene width

    return d;
}

// ------------------------------------------------------------------
//    Shading Functions
// ------------------------------------------------------------------

// Calculates surface normal using small offsets
vec3 normal(vec3 p) {
    vec3 e = vec3(0.0, det, 0.0);
    return normalize(vec3(
            de(p + e.yxx) - de(p - e.yxx),
            de(p + e.xyx) - de(p - e.xyx),
            de(p + e.xxy) - de(p - e.xxy)
        ));
}

// Calculates shadow by raymarching from the point towards the light source
float shadow(vec3 pos, vec3 sdir) {
    float res = 1.0;
    float ph = 1.0;
    float t_shadow = 0.01; // Renamed 't' to 't_shadow' to avoid conflict
    for (int i = 0; i < SHADOW_STEPS; i++) {
        float d = de(pos + sdir * t_shadow);
        if (d < 0.001) { // Hit something
            return 0.0; // Fully shadowed
        }
        res = min(res, 10.0 * d / t_shadow); // Accumulate shadow
        t_shadow += d;
        if (t_shadow > 1.5) break; // Early exit for distant shadows
    }
    return res;
}


// Calculates Ambient Occlusion
float calcAO(vec3 pos, vec3 nor) {
    float hr, dd, aoi = 0.0, sca = 1.0, totao = 0.0;
    hr = 0.075 * aoi * aoi; dd = de(nor * hr + pos); totao += (hr - dd) * sca; sca *= 0.6; aoi++;
    hr = 0.075 * aoi * aoi; dd = de(nor * hr + pos); totao += (hr - dd) * sca; sca *= 0.55; aoi++;
    hr = 0.075 * aoi * aoi; dd = de(nor * hr + pos); totao += (hr - dd) * sca; sca *= 0.55; aoi++;
    hr = 0.075 * aoi * aoi; dd = de(nor * hr + pos); totao += (hr - dd) * sca; sca *= 0.55; aoi++;
    return clamp(1.0 - 4.0 * totao, 0.0, 1.0);
}

// Applies lighting and colors to a point
vec3 shade(vec3 p, vec3 dir, vec3 n) {
    vec3 trackoffset = -vec3(path(p.z).xy, 0.0);
    vec3 pos = p;
    vec3 col = vec3(0.5); // Base color

    pos += trackoffset; // Apply track transformation

    // Track lines (simplified)
    if (pos.y < 0.5) col += pow(max(0.0, 0.2 - abs(pos.x)) / 0.2 * abs(sin(pos.z * 2.0)), 8.0) * TUBE_COLOR * 2.0;
    pos.x = abs(pos.x);

    // Fake AO for tunnel corners
    if (tunnel(pos.z) < 0.0)
        col *= 1.0 - pow(max(0.5, 1.0 - length(pos.xy + vec2(-FOLD * 1.5, -0.85))), 5.0) * max(0.0, 1.0 + pos.y);

    if (tubes(pos) < det) col = TUBE_COLOR; // If ray hits tubes

    float ao = calcAO(p, n); // Calculate AO
    float camlight = max(0.0, dot(dir, -n)); // Camera light for ambient

    // --- Tube lights ---
    vec3 tpos1 = vec3((tubepos + vec2(FOLD, 0.0)), 0.0) + trackoffset; // Get tube positions
    vec3 tpos2 = tpos1 - vec3((tubepos.x + FOLD) * 2.0, 0.0, 0.0);

    vec3 tube1lightdir = normalize(vec3(p.xy, 0.0) + vec3(tpos1.xy, 0.0));
    vec3 tube2lightdir = normalize(vec3(p.xy, 0.0) + vec3(tpos2.xy, 0.0));

    float falloff1 = pow(max(0.0, 1.0 - 0.2 * distance(vec3(p.xy, 0.0), vec3(-tpos1.xy, 0.0))), 4.0);
    float falloff2 = pow(max(0.0, 1.0 - 0.2 * distance(vec3(p.xy, 0.0), vec3(-tpos2.xy, 0.0))), 4.0);

    float diff, spec;
    vec3 r = reflect(LIGHTDIR, n);

    // Tube 1 lighting
    diff = max(0.0, dot(tube1lightdir, -n)) * 0.5;
    diff += max(0.0, dot(normalize(tube1lightdir + vec3(0.0, 0.0, 0.2)), -n)) * 0.5;
    diff += max(0.0, dot(normalize(tube1lightdir - vec3(0.0, 0.0, 0.2)), -n)) * 0.5;
    spec = pow(max(0.0, dot(tube1lightdir + vec3(0.0, 0.0, 0.4), r)), 15.0) * 0.7;
    spec += pow(max(0.0, dot(tube1lightdir - vec3(0.0, 0.0, 0.4), r)), 15.0) * 0.7;
    float tl1 = (falloff1 * ao + diff + spec) * falloff1;

    // Tube 2 lighting
    diff = max(0.0, dot(tube2lightdir, -n)) * 0.5;
    diff += max(0.0, dot(normalize(tube2lightdir + vec3(0.0, 0.0, 0.2)), -n)) * 0.5;
    diff += max(0.0, dot(normalize(tube2lightdir - vec3(0.0, 0.0, 0.2)), -n)) * 0.5;
    spec = pow(max(0.0, dot(tube2lightdir + vec3(0.0, 0.0, 0.4), r)), 15.0) * 0.7;
    spec += pow(max(0.0, dot(tube2lightdir - vec3(0.0, 0.0, 0.4), r)), 15.0) * 0.7;
    float tl2 = (falloff2 * ao + diff + spec) * falloff2;

    vec3 tl = ((tl1 + tl2) * (0.5 + tubeinterval * 0.5)) * TUBE_COLOR;

    // --- Virtual Car Light ---
    // Position the virtual light relative to the camera's actual position ('from') and its direction ('dir')
    vec3 virtual_light_pos = p + (dir * VIRTUAL_LIGHT_REACH) + vec3(0.0, 0.1, 0.0); // Use VIRTUAL_LIGHT_REACH
    
    // Adjusted falloff using new parameters
    float light_falloff = pow(max(0.0, 1.0 - VIRTUAL_LIGHT_FALLOFF_DISTANCE * distance(p, virtual_light_pos)), VIRTUAL_LIGHT_FALLOFF_POWER); // Use new falloff params

    vec3 virtual_light_dir = normalize(virtual_light_pos - p); // Direction from shaded point to light
    float virtual_diff = max(0.0, dot(virtual_light_dir, n)); // Diffuse component

    // Apply a subtle directional falloff similar to original car lights
    virtual_diff *= clamp(1.0 - virtual_light_dir.y, 0.0, 1.0); // More diffuse when looking "up" at light

    // Apply VIRTUAL_LIGHT_SPREAD to virtual_diff, and VIRTUAL_LIGHT_INTENSITY
    vec3 cl = VIRTUAL_LIGHT_COLOR * (virtual_diff * VIRTUAL_LIGHT_SPREAD * light_falloff + light_falloff * 0.3) * VIRTUAL_LIGHT_INTENSITY;


    // --- Main light ---
    float sh = shadow(p, LIGHTDIR); // Get shadow (now calculated)

    diff = max(0.0, dot(LIGHTDIR, -n)) * sh * 1.3; // Diffuse
    float amb = (0.4 + 0.6 * camlight) * 0.6; // Ambient + camera light
    spec = pow(max(0.0, dot(dir, -r)) * sh, 20.0) * SPECULAR * SPECULAR_STRENGTH; // Specular, apply new strength
    vec3 l = (amb * ao * AMBIENT_COLOR + diff * LIGHT_COLOR) + spec * LIGHT_COLOR;

    if (col == TUBE_COLOR) l = 0.3 + vec3(camlight) * 0.7; // Special lighting for tubes

    return col * (l + cl + tl); // Apply all lights (main, virtual car, and tubes)
}

// ------------------------------------------------------------------
//    Raymarching and Scene Rendering
// ------------------------------------------------------------------

vec3 raymarch(vec3 from, vec3 dir) {
    float totdist = 0.0;
    float glow = 0.0;
    float d = 1000.0;
    vec3 p = from;

    float deta = DETAIL; // Simplified detail (backcam removed)

    for (int i = 0; i < RAY_STEPS; i++) {
        if (d > det && totdist < MAX_DIST) {
            d = de(p);
            p += d * dir;
            det = max(deta, deta * totdist * 0.5); // Scale detail with distance
            totdist += d;
            float gldist = det * 8.0; // Background glow distance
            if (d < gldist && totdist < 20.0) glow += max(0.0, gldist - d) / gldist * exp(-0.1 * totdist); // Accumulate glow
        }
    }

    tubeinterval = abs(1.0 + cos(p.z * 3.14159 * 0.5)) * 0.5; // Set light tubes interval
    float tglow = 1.0 / (1.0 + minT * minT * 5000.0); // Tubes glow
    float l = max(0.0, dot(normalize(-dir), normalize(LIGHTDIR))); // Light direction gradient
    vec3 backg = AMBIENT_COLOR * 0.4 * max(0.1, pow(l, 5.0)); // Background color
    float lglow = pow(l, 50.0) * 0.5 + pow(l, 200.0) * 0.5; // Sun glow

    vec3 col;
    if (d < 0.5) { // Hit surface
        vec3 norm = normal(p); // Get normal
        p = p - abs(d - det) * dir; // Backstep
        col = shade(p, dir, norm); // Get shading
        col += tglow * TUBE_COLOR * pow(tubeinterval, 1.5) * 2.0; // Add tube glow
        col = mix(backg, col, exp(-0.015 * pow(abs(totdist), 1.5))); // Distance fading

    } else { // Hit background
        col = backg; // Set color to background
        col += lglow * SUN_COLOR; // Add sun glow
        col += glow * pow(l, 5.0) * 0.035 * LIGHT_COLOR; // Borders glow

        // Simplified stars (from original LOW_QUALITY path)
        vec3 st = (dir * 3.0 + vec3(1.3, 2.5, 1.25)) * 0.3;
        for (int i = 0; i < 14; i++) st = abs(st) / dot(st, st) - 0.9;
        col += min(1.0, pow(min(5.0, length(st)), 3.0) * 0.0025); // Add stars
    }

    return col;
}

// ------------------------------------------------------------------
//    Main Entry Point
// ------------------------------------------------------------------

// This signature attempts to be compatible with both Shadertoy (web) and Kodi.
// Kodi's log suggests it tries to call mainImage(vec4, vec2).
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    minT = 1000.0; // Initialize min distance glow for tubes
    fractrot = rot(0.5); // Rotation matrix for fractal

    // --- Camera Setup ---
    // These variables are implicitly provided by Kodi/Shadertoy.
    // No explicit 'uniform' or 'vec2 iResolution;' declarations here.
    vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    // Simplified mouse input (no alternating camera views)
    vec2 mouse = (iMouse.xy / iResolution.xy - 0.5) * vec2(7.0, 1.5);
    if (iMouse.z < 1.0) { // If no mouse interaction, set default
        mouse = vec2(0.0, -0.05);
    }

    vec3 dir = normalize(vec3(uv * 0.8, 1.0)); // Ray direction

    vec3 campos = vec3(0.0, 0.2, -0.6); // Original relative camera position
    // Rotate camera with mouse
    campos.yz = (campos.yz) * rot(mouse.y);
    campos.xz = (campos.xz) * rot(mouse.x);

    // Calculate camera's base Z-position on the path
    float camera_path_z_base = t + campos.z;
    // Calculate actual camera position
    vec3 from = path(camera_path_z_base) + campos;

    // Define target point on the path, relative to the camera's path Z
    // This makes the camera look *along* the path, not just at a global Z point
    vec3 target_on_path = path(camera_path_z_base + 5.0); // Look 5.0 units ahead on the path

    // Adjust initial ray direction to look at the target_on_path from 'from'
    dir = lookat(normalize(target_on_path - from), vec3(0.0, 1.0, 0.0)) * normalize(dir);

    // --- Raymarch and Color ---
    vec3 color = raymarch(from, dir);

    // Color adjustments
    color = pow(abs(color), vec3(GAMMA)) * BRIGHTNESS;
    color = mix(vec3(length(color)), color, SATURATION);
    // Added: Contrast adjustment
    color = (color - 0.5) * CONTRAST + 0.5;

    // Display actual shader output
    fragColor = vec4(color, 1.0);
}
