precision mediump float; // Required for ES 2.0

// Define EPSILON for robustness in divisions
const float EPSILON = 1e-6;

// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

// --- Effect Color Parameter ---
// Adjusts the main color of the effect.
// Default is white (vec3(1.0, 1.0, 1.0)).
#define MAIN_EFFECT_COLOR vec3(1, 0.89, 0.678)

// --- Effect Offset Parameters ---
// Adjusts the position of the effect on the screen.
// Positive values move the effect right (X) or down (Y).
#define OFFSET_X 0.0 // Default X offset
#define OFFSET_Y 100.0 // Default Y offset

void mainImage(out vec4 o, vec2 u) {
    // Explicitly initialize all variables
    float i = 0.0;
    float d = 0.0;
    float s = 0.0;
    float t = 30.0 + iTime * 0.05; // Using iTime as per Kodi preference

    vec3 p_res = iResolution.xyz; // Explicitly initialize p_res with iResolution components
    
    // Explicitly initialize output color vector 'o'
    o = vec4(0.0);

    // Normalize UV coordinates relative to resolution, with division robustness
    // Added OFFSET_X and OFFSET_Y to shift the effect
    u = (u - p_res.xy / 2.0 + vec2(OFFSET_X, OFFSET_Y)) / max(p_res.y, EPSILON);
    
    // Main loop
    for(i = 0.0; i < 64.0; i++) { // Explicitly initialized i
        // Division by s enhanced for robustness
        o += 1.0 / max(s, 0.01); 
        
        d += s = 0.6 * abs(s) + 0.03;
        
        // p_current_ray_pos represents the current ray position in 3D space
        vec3 p_current_ray_pos = vec3(u * d, d + t);

        p_current_ray_pos.xy *= rot(p_current_ray_pos.z * 0.1);
        p_current_ray_pos.xy *= rot(t);
        p_current_ray_pos += cos(t + p_current_ray_pos.yzx * (0.7 + sin(t) * 0.7));
        
        s = cos(cos(p_current_ray_pos.x) - cos(p_current_ray_pos.y));
        s += abs(dot(sin(p_current_ray_pos * 8.0), 0.1 + p_current_ray_pos - p_current_ray_pos));
    }
    // Replace tanh() with tanh_approx() and enhance division robustness
    o = tanh_approx(o * o / max(1e7, EPSILON));

    // Apply the MAIN_EFFECT_COLOR to the final output
    o.rgb *= MAIN_EFFECT_COLOR;
}
