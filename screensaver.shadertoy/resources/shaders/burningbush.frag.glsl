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

// Replaced iTime with T (can be remapped to iTime or iChannelTime[0] as needed)
#define T iTime
#define PI 3.141596
#define S smoothstep

// --- Custom Parameters ---
#define SCREEN_ZOOM     .60 // Adjusts zoom level: >1.0 zooms in, <1.0 zooms out (to see more)
#define ANIMATION_SPEED .40 // Global multiplier for animation speed: >1.0 faster, <1.0 slower

// --- Post-processing Parameters (Brightness, Contrast, Saturation) ---
#define BRIGHTNESS -0.05    // Adjust brightness: 0.0 for no change, positive for brighter, negative for darker
#define CONTRAST   1.40    // Adjust contrast: 1.0 for no change, >1.0 for more contrast, <1.0 for less
#define SATURATION .90    // Adjust saturation: 1.0 for no change, >1.0 for more saturated, <1.0 for desaturated


// 2D rotation matrix function (fixed for standard GLSL ES 1.0 compatibility)
// The original `+ vec4` was non-standard for a rotation matrix construction.
mat2 rotate(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

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

// https://iquilezles.org/articles/distfunctions/
float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    float d = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
    return abs(d) + 0.1;
}

// Main SDF function for the scene.
float map(vec3 p) {
    // Explicitly initialize variables.
    float e = 0.0;
    float s = 1.0;
    float d = 1e9; // Large initial distance.
    
    // Use fixed rotate function.
    // MODIFIED: Apply ANIMATION_SPEED to iTime.
    p.xy *= rotate(cos(T * 0.15 * ANIMATION_SPEED) * 0.25);
    // Replaced tanh() with tanh_approx() and ensured vec4 conversion for float input, then take .x.
    // MODIFIED: Apply ANIMATION_SPEED to iTime.
    p.xz *= rotate(tanh_approx(vec4(cos(T * 0.4 * ANIMATION_SPEED) * 5.0 + 3.0, 0.0, 0.0, 0.0)).x);
    
    // Explicitly initialized loop variable 'i'.
    for(int i = 0; i < 7; i++) {
        p.y = sqrt(max(0.0, p.y)); // Ensure float literal for 0.0.
        
        e = p.y < 0.5 // Ensure float literal for 0.5.
            ? length(p.xz) - 0.005 // Ensure float literal for 0.005.
            : abs(p.y - 0.3); // Ensure float literal for 0.3.
            
        d = min(d, e * s);
        p.y -= 0.5; // Ensure float literal for 0.5.
        
        if(abs(p.z) > abs(p.x))
            p.xz = p.zx;
        
        p.xy *= rotate(sign(p.x)); // Use fixed rotate function.
        
        p *= 2.0; // Ensure float literal for 2.0.
        s /= 2.0; // Ensure float literal for 2.0.
    }
    
    return d;
}

void mainImage(out vec4 O, vec2 I) {
    vec2 R = iResolution.xy;
    // Explicitly initialize uv, ensure float literals.
    // MODIFIED: Apply SCREEN_ZOOM to uv calculation.
    vec2 uv = 2.0 * (I - R / 2.0) / R.y / SCREEN_ZOOM;

    // Explicitly initialize output color.
    O = vec4(0.0);
    
    // Explicitly initialize p and rd, ensure float literals.
    vec3 p = vec3(1.0, 0.82, 0.0);
    vec3 rd = normalize(vec3(-8.0, uv.y - 4.0, uv.x));
    
    // Explicitly initialized loop variable 'i'.
    for(int i = 0; i < 84; i ++) {
        float s = map(p); // 's' is initialized by map(p) return value.
        // Ensure division robustness with max(EPSILON, s), float literals.
        O += 1e-5 * vec4(8.0, 4.0, 1.0, 0.0) / max(EPSILON, s);
        p += rd * s;
    }

    // --- Post-processing: Brightness, Contrast, Saturation (BCS) ---
    vec3 final_rgb = O.rgb; // Get the tone-mapped color

    // 1. Brightness Adjustment
    final_rgb += BRIGHTNESS;

    // 2. Contrast Adjustment
    final_rgb = (final_rgb - 0.5) * CONTRAST + 0.5;

    // 3. Saturation Adjustment
    float luminance = dot(final_rgb, vec3(0.299, 0.587, 0.114)); // Standard NTSC luma weights
    final_rgb = mix(vec3(luminance), final_rgb, SATURATION);

    // Apply final color to output, clamped to 0-1 range to prevent over-exposure artifacts
    O.rgb = clamp(final_rgb, 0.0, 1.0);
}
