// A portal transports you from one point in space to another; but by doing so, it "connects" that space
// in a new way. In topological terms, space in the presence of portals becomes a "multiply-connected domain".
// One consequence of this is that you now need a coordinate system to describe where you are in this new space,
// so that you can still calculate the distance you traveled to school using your new shortcut, predict how
// electromagnetic waves will propagate through the gap, and create a blueprint for a structurally sound staircase
// bridging the ground at different elevations on each side.
// In this shader, it's what allows us to have a smooth color transition on the floor passing through the portal.

// A coordinate we can use is the Winding Number field, which measures how many times we've wound around the "rim" of the
// portal. This coordinate has an analogue in complex analysis, where an an integral along a contour wrapping around a singularity
// measures the number of times the path wound around it.
// To account for our portal rim, it turns out we can just stretch such a point singularity around a circle in 3D
// by utilizing a coordinate transform g: R3 -> C such that if f(x) has a singularity at a single point p in C, 
// the pre-image S of p through the transform g is the desired manifold.
// In other words, f(g(r)) is complex infinity for all r on the 3D circle.

// To ensure that the pre-image is a circle, we can make g
// the cylindrical coordinate mapping, minus the angle coordinate.
// To ensure the resulting field is still differentiable everywhere, we must also choose an analytic function that is
// symmetric about the axis of revolution. For this, we place another pole at the point reflected across this axis --
// this is analogous to adding a virtual point charge in electrostatics, a technique used
// in physics to solve for the electric field in the presence of conducting surfaces. 
// Here is a visualization of just this 2D complex function (extruded vertically rather than spun): https://www.shadertoy.com/view/3fVSzd

// =================================

#define PI radians(180.0)
#define FDIST 0.3
#define smoothness 0.04

// --- Post-processing BCS Parameters ---
// Adjust these values to control Brightness, Contrast, and Saturation.
// BRIGHTNESS: Additive value. Positive makes brighter, negative makes darker. (Default: 0.0)
#define BRIGHTNESS 0.0
// CONTRAST: Multiplicative value around 0.5 gray. >1.0 increases, <1.0 decreases. (Default: 1.0)
#define CONTRAST 1.0
// SATURATION: Mixes color with its luminance. >1.0 increases, <1.0 decreases (0.0 is grayscale). (Default: 1.0)
#define SATURATION 0.0

// --- CRT Effect Toggle ---
// Uncomment the line below to enable the CRT effect (includes noisy background and scanlines).
//#define CRT_EFFECT_ENABLED

// --- CRT Effect Definitions (used if CRT_EFFECT_ENABLED or for common calculations) ---
#define MACRO_TIME iTime
#define MACRO_RES iResolution.xy
#define MACRO_SMOOTH(a, b, c) smoothstep(a, b, c)
#define BACKGROUND_COLOR vec4(0.0, 0.1, 0.2, 1.0) // Tweakable dark background color for CRT

// Noise function for the background
float hash2(vec2 p) { 
    vec3 p3 = fract(vec3(p.xyx) * 0.2831);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// --- Helper Functions (defined before they are called) ---

float getAngle(in vec2 eye, in vec2 ro, in vec2 center) {
    vec2 cam_disp = normalize(eye.xy - center); //y is the sin(), x is the cos()
    mat2 rot = mat2(cam_disp.x, -cam_disp.y, cam_disp.y, cam_disp.x);
    vec2 ro_disp = rot * normalize(ro.xy - center);
    return atan(ro_disp.y, ro_disp.x);
}

float getWinding2D(in vec2 eye, in vec2 ro, in vec2 center1, in vec2 center2) {
    float ang = getAngle(eye, ro, center1);
    float ang2 = getAngle(eye, ro, center2);
    return ang - ang2;
}

vec2 spinProject(in vec3 p, in vec3 center, in vec3 n) {
    vec3 po = p - center;
    float d_norm = dot(po, n);
    vec3 p_rad = po - d_norm * n;
    return vec2(d_norm, length(p_rad));
}

float planeIntersect(in vec3 eye, in vec3 rd, in vec3 center, in vec3 n) {
    vec3 po = eye - center;
    float d_norm = dot(po, n);
    return -d_norm / dot(rd, n);
}

float getWinding(in vec3 eye, in vec3 ro, in vec3 center, in vec3 n, float r) {
    vec2 projected_center1 = vec2(0.0, r);
    vec2 projected_center2 = vec2(0.0, -r);
    vec3 disp = ro - eye;
    float pathlen = length(disp);
    vec3 rd = disp / pathlen;
    float t = planeIntersect(eye, rd, center, n);
    if (t > 0.0 && t < pathlen) {
        vec3 ro_plane = eye + t * rd;
        return getWinding2D(spinProject(eye, center, n), spinProject(ro_plane, center, n), projected_center1, projected_center2) + 
            getWinding2D(spinProject(ro_plane, center, n), spinProject(ro, center, n), projected_center1, projected_center2);
    } else {
        return getWinding2D(spinProject(eye, center, n), spinProject(ro, center, n), projected_center1, projected_center2);
    }
}

float getSceneWinding(in vec3 eye, in vec3 ro) {
    vec3 center = vec3(0.0, 0.0, 0.2);
    float radius = 0.7;
    vec3 n = vec3(0.0, 1.0, 0.0);
    float wn = getWinding(eye, ro, center, n, radius);
    wn -= getWinding(eye, ro, center, n, radius - 0.3);
    return wn;
}

float compute_step_offset(float t) {
    float s = t / (PI) - 0.5;
    return (mod(-s, 1.0) + s) * 2.0 * PI;
}

float stripes(float t) {
    float stripesi = mod(t * 2.4848, 2.0);
    float stripes = smoothstep(0.5 - smoothness, 0.5 + smoothness, abs(stripesi - 1.0));
    return stripes;
}

vec3 rainbow(float t) {
    t *= 0.25;
    float s = sin(t);
    return vec3(s, cos(t), -s) * 0.5 + 0.5;
}

vec3 tex(float t) {
    return (stripes(t) * 0.1 + 0.9) * rainbow(t);
}

float intersectFloor(in vec3 eye, in vec3 rd) {
    float t = -eye.z / rd.z;
    if (t < 0.0) {
        t = (1.0-eye.z)/rd.z;
    }
    return t;
}

// Helper function to calculate the color for a single ray (pixel/sub-pixel)
// This function must be defined BEFORE mainImage, and after all functions it calls.
vec4 calculateRaymarchColor(vec2 fragCoord_pixel_space) {
    float globalTime = iTime * 0.1 * 0.6;
    // camera setup
    vec2 uv = (fragCoord_pixel_space - iResolution.xy * 0.5) / iResolution.x;
    vec3 eye = vec3(cos(-globalTime) * 0.6, sin(-globalTime * 2.0) * 0.6, 0.2);
    float vertLook = iMouse.z > 0.0 ? (iMouse.y / iResolution.y - 0.5) * 8.0 : 0.1;
    vec3 w = normalize(vec3(normalize(vec2(0.2, 0.0) - eye.xy), vertLook));
    vec3 up = vec3(0.0, 0.0, 1.0);
    vec3 u = normalize(cross(w, up));
    vec3 v = cross(u, w);
    vec3 rd = normalize(FDIST * w + uv.x * u + uv.y * v);
    
    // trace the scene geometry
    float t = intersectFloor(eye, rd);
    vec3 col;
    vec3 ro = eye + t * rd;
    
    // winding number of view to scene
    float wn = getSceneWinding(eye, ro);
    // winding number of the camera relative to a fixed point
    float base_wn = getSceneWinding(vec3(-10.0, 0.0, 0.0), eye);
    // winding number jumps timed with entering of portal / a new branch cut
    float step_wn_offset = compute_step_offset(globalTime + PI * 0.5);
    // total winding number to provide a consistent coordinate system in the presence of the portal
    float final_wn = wn + base_wn - step_wn_offset;

    col = tex(final_wn);
    col = mix(rainbow(final_wn + PI * 2.0) * 0.2, col, pow(0.8, t));
    col = pow(col, vec3(0.7));

    return vec4(col,1.0); // Return the fully rendered scene color for this pixel
}


void mainImage( out vec4 O, in vec2 fragCoord )
{
    vec4 fragColor; // This will hold the final color to output to O

    // 1. Get the base rendered scene color
    fragColor = calculateRaymarchColor(fragCoord);

    // 2. Apply BCS (Brightness, Contrast, Saturation) - Always applied
    fragColor.rgb += BRIGHTNESS;
    fragColor.rgb = (fragColor.rgb - 0.5) * CONTRAST + 0.5;
    float luma = dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    fragColor.rgb = mix(vec3(luma), fragColor.rgb, SATURATION);

    // Common variables for Vignette and CRT (if enabled)
    vec2 U = fragCoord;
    vec2 V = 1.0 - 2.0 * U / MACRO_RES;

    // 3. Apply Vignette Effect - Always applied
    fragColor.rgb *= 1.25 * (1.0 - MACRO_SMOOTH(0.1, 1.8, length(V * V))); // Dim overall brightness towards edges
    // Add reddish tint to the vignette (applied to RGB)
    fragColor.rgb += 0.14 * pow(1.0 - length(V * vec2(0.5, 0.35)), 3.0); 
    
    // 4. Apply CRT-specific effects (Background Noise, Scanlines) - Only if CRT_EFFECT_ENABLED
    #ifdef CRT_EFFECT_ENABLED
        // Apply dark background with subtle noise effect.
        // This effectively tints the image's darker areas towards the noisy background color.
        vec3 noisy_base = BACKGROUND_COLOR.rgb + 0.06 * hash2(MACRO_TIME + V * vec2(1462.439, 297.185));
        fragColor.rgb = mix(noisy_base, fragColor.rgb, min(1.0, length(fragColor.rgb)));

        // Apply Horizontal Scanline Effect
        float scanLine = 0.75 + 0.35 * sin(fragCoord.y * 1.9);
        fragColor.rgb *= scanLine;
    #endif

    // Final clamping to ensure color values are between 0 and 1
    fragColor = clamp(fragColor, 0.0, 1.0);
    O = fragColor; // Assign the final processed color to the output
}