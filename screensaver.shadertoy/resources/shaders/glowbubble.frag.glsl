// --- GLSL Version and Precision Directives for Kodi Compatibility (GLSL ES 1.0) ---
precision highp float;
precision highp int;
precision lowp sampler2D;

// Define a small epsilon for numerical stability in divisions.
const float EPSILON = 1e-6; // 0.000001

// The Robust Tanh Conversion Method: tanh_approx function
// Ensures numerical stability for tanh, especially near zero.
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

#define T iTime // Reverted T definition back to iTime for web compatibility
#define PI 3.141596
#define S smoothstep

// --- Post-processing Parameters (Brightness, Contrast, Saturation) ---
#define BRIGHTNESS 0.02    // Adjust brightness: 0.0 for no change, positive for brighter, negative for darker
#define CONTRAST   1.55    // Adjust contrast: 1.0 for no change, >1.0 for more contrast, <1.0 for less
#define SATURATION 1.0    // Adjust saturation: 1.0 for no change, >1.0 for more saturated, <1.0 for desaturated

// --- Animation and Screen Scaling Parameters ---
#define ANIMATION_SPEED 0.50 // Controls the overall speed of the animation. 1.0 is default.
#define SCREEN_ZOOM     0.80 // Controls the zoom level of the scene. 1.0 is default.
#define SCREEN_ROTATION_SPEED 0.205 // Controls the speed of clockwise screen rotation. 0.0 for no rotation.

// 2D rotation matrix function.
mat2 rotate(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

// Signed distance function for a box frame.
// https://iquilezles.org/articles/distfunctions/
float sdBoxFrame( vec3 p, vec3 b, float e )
{
    p = abs(p) - b;
    vec3 q = abs(p + e) - e;
    return min(min(
        length(max(vec3(p.x,q.y,q.z),0.0)) + min(max(p.x,max(q.y,q.z)),0.0),
        length(max(vec3(q.x,p.y,q.z),0.0)) + min(max(q.x,max(p.y,q.z)),0.0)),
        length(max(vec3(q.x,q.y,p.z),0.0)) + min(max(q.x,max(q.y,p.z)),0.0));
}

// Signed distance function for a solid box.
float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    float d = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
    // Added 0.1 and abs for consistency with original.
    // The original sdBox was commented out, but if used, abs(d)+0.1 ensures positive distances for raymarching.
    return abs(d) + 0.1;
}

void mainImage(out vec4 O, in vec2 I){
    // Explicitly initialize all variables.
    vec2 R = iResolution.xy;
    
    // MODIFIED: Apply SCREEN_ZOOM and SCREEN_ROTATION_SPEED to uv calculation
    vec2 uv = ((I * 2.0 - R) / R.y) / SCREEN_ZOOM; // Initial normalization and zoom
    uv *= rotate(T * SCREEN_ROTATION_SPEED); // Apply screen rotation

    O = vec4(0.0); // Explicitly initialize output color.

    vec3 ro = vec3(0.0, 0.0, -10.0); // Ray origin.
    vec3 rd = normalize(vec3(uv, 1.0)); // Ray direction.

    float z = 0.0; // Accumulated distance along the ray, explicitly initialized.
    float d = 1e4; // Minimum distance found, explicitly initialized.
    vec3 col = vec3(0.0); // Accumulated color, explicitly initialized.

    // Raymarching loop.
    for(float i = 0.0; i < 100.0; i++){ // Explicit float literals for loop.
        vec3 p = ro + rd * z; // Current point along the ray.

        vec3 q = p; // Copy of p for transformations.
        // MODIFIED: Apply ANIMATION_SPEED to the rotation calculation
        q.xz *= rotate(T * 0.1 * i * ANIMATION_SPEED + i);
        q.xy *= rotate(T * 0.1 * i * ANIMATION_SPEED + i);

        // Calculate distance to the box frame.
        // If sdBox was intended, ensure its return value is compatible.
        float D = sdBoxFrame(q, vec3(1.1) * i, 0.0);
        //float D = sdBox(q, vec3(1.1)*i); // If sdBox is used, uncomment and ensure it returns positive.

        // Accumulate color.
        // MODIFIED: Ensure division robustness with max(D, EPSILON).
        col += (1.0 + sin(vec3(3.0, 2.0, 1.0) + q.x * 0.5)) / max(D, EPSILON) * 1.5;

        // Update minimum distance.
        d = min(d, D);

        // Advance the ray.
        // MODIFIED: Ensure D is positive before adding to z. Use max(0.0, d) to prevent negative steps.
        z += max(0.0, d) * 0.6;
        
        // Break conditions for raymarching.
        if(z > 1e2 || d < 1e-4) {
            break;
        }
    }

    // Apply the robust tanh conversion to the final color.
    // MODIFIED: Replaced tanh() with tanh_approx().
    vec4 final_color = tanh_approx(vec4(col * 5e-2, 0.0)); // Convert vec3 to vec4 before tanh_approx.
    final_color.a = 1.0; // Ensure alpha is 1.0 for visibility.

    // --- Post-processing: Brightness, Contrast, Saturation (BCS) ---
    // Apply brightness
    final_color.rgb += BRIGHTNESS;

    // Apply contrast
    final_color.rgb = ((final_color.rgb - 0.5) * CONTRAST) + 0.5;

    // Apply saturation
    float luma = dot(final_color.rgb, vec3(0.2126, 0.7152, 0.0722)); // Standard NTSC luma weights
    vec3 grayscale = vec3(luma);
    final_color.rgb = mix(grayscale, final_color.rgb, SATURATION);

    O = final_color;
}
