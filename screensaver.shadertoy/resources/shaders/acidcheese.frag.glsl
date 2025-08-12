// --- GLSL Version and Precision Directives for Kodi Compatibility (GLSL ES 1.0) ---
precision highp float;
precision highp int;
precision lowp sampler2D;

// Define a small epsilon for numerical stability in divisions.
const float EPSILON = 1e-6; // 0.000001

// The Robust Tanh Conversion Method: tanh_approx function
// Ensures numerical stability for tanh, especially near zero.
// Expects a vec4 input for consistency with common use cases.
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// Global time variable, changed to iTime as requested.
#define T iTime

// --- Custom Parameters ---
#define SCREEN_ZOOM     .50 // Adjusts zoom level: >1.0 zooms in, <1.0 zooms out (to see more)

// --- Post-processing Parameters (Brightness, Contrast, Saturation) ---
#define BRIGHTNESS 0.10    // Adjust brightness: 0.0 for no change, positive for brighter, negative for darker
#define CONTRAST   1.60    // Adjust contrast: 1.0 for no change, >1.0 for more contrast, <1.0 for less
#define SATURATION 1.0    // Adjust saturation: 1.0 for no change, >1.0 for more saturated, <1.0 for desaturated


// Standard 2D rotation matrix function.
// This replaces the problematic `#define r(a) mat2(cos(a+vec4(0,11,33,0)))`
mat2 rotate(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

void mainImage(out vec4 o, vec2 fragCoord) { // Using fragCoord as input name for consistency
    // Explicitly initialize all variables.
    float i_loop = 0.0; // Loop counter, renamed to avoid conflict with `i` in outer scopes
    float r_val = 0.0;  // Renamed to avoid confusion with `iResolution`
    float s_val = 0.0;  // Step distance, renamed to avoid confusion with `s` in loop
    float t_val = T * 0.2; // Time variable, now using `T`

    // `d` initial value: .5 * texelFetch(iChannel0, ivec2(u)%1024, 0).a
    // `texelFetch` is GLSL ES 3.0+, replaced with `texture2D`.
    // `ivec2(u)%1024` implies reading from a repeating texture based on raw pixel coords.
    // FIXED: Removed texture2D call, initializing d_current to a constant value.
    float d_current = 0.25; // Initialized to a constant value as iChannel0/texture2D caused errors.

    vec3  p_res = iResolution.xyz; // Renamed iResolution to p_res.
    
    // Normalized UV coordinates, `u` in original code.
    // MODIFIED: Apply SCREEN_ZOOM to uv_norm calculation.
    vec2 uv_norm = (fragCoord - p_res.xy / 2.0) / p_res.y / SCREEN_ZOOM;

    // Output color, explicitly initialized to black.
    o = vec4(0.0);

    // Main loop: Broken down from golfed form for clarity and GLSL ES 1.0 compatibility.
    for (i_loop = 0.0; i_loop < 70.0; ++i_loop) { // `7e1` changed to `70.0`
        vec3 p_current_ray_pos = vec3(0.0); // Renamed p to avoid confusion with p_res
        vec3 q_current = vec3(0.0);       // Renamed q to avoid conflict

        // 1. Calculate current ray position `p` in 3D space.
        // Original: `p = vec3(u * d, d + t+t) + cos(t+.3*p.zzx)*.5`
        // `p.zzx` refers to previous `p`, here it's `p_res.zzx` if it was global.
        // Assuming `p.zzx` was meant to use the *newly calculated* `p_current_ray_pos` after `uv_norm * d_current`.
        p_current_ray_pos = vec3(uv_norm * d_current, d_current + t_val + t_val) + cos(t_val + 0.3 * p_res.zzx) * 0.5;

        // 2. Apply rotation to `p.xy`.
        // Original: `p.xy *= mat2(cos(.3*t+vec4(0,33,11,0)))`
        // Replaced with fixed `rotate` function, assuming the `vec4` was just 0.0 offset.
        p_current_ray_pos.xy *= rotate(0.3 * t_val);

        // 3. Calculate `b` and `e` (distance field components).
        q_current = p_current_ray_pos * 0.275; // Original: `q=p*.275`
        // Original: `b=abs(dot(sin(q*1.57-1.5),cos(q.zyx))-.25)-.1;`
        // `tanh` not present in original `b` calc, but in `d` calc.
        float b_val = abs(dot(sin(q_current * 1.57 - 1.5), cos(q_current.zyx)) - 0.25) - 0.1; // Float literals

        q_current = p_current_ray_pos * 0.095; // Original: `q=p*.095`
        // Original: `e=abs(dot(sin(q*1.57),cos(q.zxy))-.25)/.25-.25;`
        // Added robustness to division.
        float e_val = abs(dot(sin(q_current * 1.57), cos(q_current.zxy)) - 0.25) / max(0.25, EPSILON) - 0.25; // Float literals

        // Original: `e=max(abs(max(b,e)),1e-4);`
        e_val = max(abs(max(b_val, e_val)), 1e-4); // Float literal

        // 4. Update `d` and `s`.
        // Original: `d += s = .006+.6*abs(dot(tanh(cos(.1*t+p*.5)*2.), cos(p+sin(t+p.zxy*4.)/8.))),`
        // `tanh` is present here. Replaced with `tanh_approx`.
        // FIXED: Corrected `vec4` constructor. `cos(...) * 2.0` results in a `vec3`, so only one `0.0` is needed.
        s_val = 0.006 + 0.6 * abs(dot(tanh_approx(vec4(cos(0.1 * t_val + p_current_ray_pos * 0.5) * 2.0, 0.0)).xyz, cos(p_current_ray_pos + sin(t_val + p_current_ray_pos.zxy * 4.0) / 8.0))); // Float literals
        d_current += s_val;

        // 5. Accumulate color `o`.
        // Original: `o += (1.+cos(.3*p.z+vec4(3,1,0,0))) / s);`
        // `cos(float + vec4)` is non-standard. Assume `cos` acts element-wise after scalar addition.
        // Added robustness to division.
        o += (vec4(1.0) + cos(0.3 * p_current_ray_pos.z + vec4(3.0, 1.0, 0.0, 0.0))) / max(s_val, EPSILON); // Float literals
    }
    
    // Final output calculation.
    // Original: `o = tanh(o / 5e3 * exp(d/24.));`
    // Replaced `tanh` with `tanh_approx`. Added robustness to division.
    // `exp(d/24.)` is fine.
    o = tanh_approx(o / max(5000.0, EPSILON) * exp(d_current / 24.0));

    // --- Post-processing: Apply BCS (Brightness, Contrast, Saturation) Adjustments ---
    vec3 final_rgb = o.rgb; // Get the tone-mapped color

    // 1. Brightness Adjustment
    final_rgb += BRIGHTNESS;

    // 2. Contrast Adjustment
    final_rgb = (final_rgb - 0.5) * CONTRAST + 0.5;

    // 3. Saturation Adjustment
    float luminance = dot(final_rgb, vec3(0.299, 0.587, 0.114));
    final_rgb = mix(vec3(luminance), final_rgb, SATURATION);

    // Apply final color to output, clamped to 0-1 range to prevent over-exposure artifacts
    o.rgb = clamp(final_rgb, 0.0, 1.0);
}
