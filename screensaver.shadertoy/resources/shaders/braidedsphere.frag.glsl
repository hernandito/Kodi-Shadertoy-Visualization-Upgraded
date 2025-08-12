precision mediump float; // Required for ES 2.0

#define m0 0.01 // 质量 .0001 .001 .0001
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

// --- Animation Speed Control ---
#define ANIMATION_SPEED_FACTOR 0.07 // Adjust to control overall animation speed (e.g., 1.0 for slower, 5.0 for faster)
#define time (iTime * ANIMATION_SPEED_FACTOR) // Applied animation speed factor here

// Define EPSILON for robustness in divisions
const float EPSILON = 1e-6;

// Struct to hold distance and object ID
struct SDFResult {
    float dist;
    int obj_id; // 0 for main object, 1 for floor, 2 for braid, 3 for sd12
};

// --- Default mri values (replaces iMouse functionality) ---
// Adjust these values to control the shader's default behavior
// and toggle between different effects.
// Experiment with combinations of MRI_X, MRI_Y, and MRI_Z.
// Example values from original logic:
// MRI_X: 0, 1, 2, 3 (influences braid, sd12 structure)
// MRI_Y: 0, 1, 2, 3 (influences braid, sd12 variations)
// MRI_Z: 0-15 (influences post-processing in mainImage, affecting overall look)
#define MRI_X 0
#define MRI_Y 3
#define MRI_Z 0 

// --- Customizable Background Color ---
#define BACKGROUND_COLOR vec3(0.35, 0.35, 0.35) // Medium grey (RGB values from 0.0 to 1.0)

// --- Post-Processing (Brightness, Contrast, Saturation) ---
#define POST_BRIGHTNESS -0.650   // Additive brightness (-1.0 to 1.0, 0.0 is no change)
#define POST_CONTRAST 0.70     // Multiplicative contrast (0.0 for no contrast, 1.0 for original, >1.0 for more)
#define POST_SATURATION 0.0   // Saturation (0.0 for grayscale, 1.0 for original, >1.0 for more)

// --- Screen Scaling Parameter ---
#define SCREEN_SCALE 1.3 // Adjust to zoom in/out (1.0 for original size, >1.0 to shrink effect, <1.0 to enlarge effect)

// --- Screen Rotation Parameter (Counter-clockwise) ---
#define SCREEN_ROTATION_SPEED 0.15 // Adjust to control screen rotation speed (e.g., 0.0 for no rotation, 0.1 for faster)


// smin and smax functions (defined before use)
float smin(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / max(k, EPSILON), 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float smax(float d1, float d2, float k) {
    return smin(d1, d2, -k); // Smooth maximum via negated smin
}

// Helper for round() equivalent in GLSL ES 1.0
float round_es1(float x) {
    return floor(x + 0.5);
}

// Helper for float modulo in GLSL ES 1.0
float mod_es1(float x, float y) {
    return x - y * floor(x / y);
}

// Function for 'dlian' (chain)
float dlian(vec3 p) {
    p.x = p.x / 3.1415926;
    p.yz *= rot(3.14159265 / 4.0);
    float r = 0.05, R = 0.15, sz = 3.0;
    p.yz /= sz;
    if (r > 0.25) r = 0.25;
    if (R > 0.25 - r) R = 0.25 - r;
    
    vec4 o_temp = vec4(0.0); o_temp.y = 0.5; // Explicitly initialize o_temp
    vec4 x_temp = vec4(p.x + o_temp.x, p.x + o_temp.y, p.x + o_temp.z, p.x + o_temp.w) - round_es1(p.x + o_temp.y); // Apply round_es1
    
    x_temp = max(abs(x_temp) - (0.25 - R + r), 0.0);
    x_temp.zw = p.yz;
    float a = length(vec2(length(x_temp.xz) - R, x_temp.w)) - r;
    float b = length(vec2(length(x_temp.yw) - R, x_temp.z)) - r;
    return min(a, b) * sz;
}

// Function for 'braid3'
vec3 braid3(vec3 p) {
    vec3 y = p.y - 0.6 * cos(p.x + vec3(0, 2, 4));
    vec3 z = p.z - 0.1 * cos(p.x + p.x + vec3(1, 5, 3));
    vec3 r_sq = y * y + z * z; // Renamed to r_sq to avoid conflict with 'r' in sd12
    vec3 e_vec = vec3(1); // Renamed to e_vec to avoid conflict with 'e' in mainImage
    vec3 a_vec = vec3(0.0); // Explicitly initialize a_vec
    
    r_sq = step(r_sq, r_sq.yzx) * step(r_sq, r_sq.zxy);
    
    a_vec = vec3(dot(e_vec, y * r_sq),
                 dot(e_vec, z * r_sq),
                 p.x);
    return p.yzx - a_vec;
}

// Function for 'braidx'
float braidx(vec3 p) {
    vec3 v_temp = vec3(0.0); // Explicitly initialize v_temp
    vec3 q_temp = p; // Explicitly initialize q_temp
    float i_loop = 0.0; // Explicitly initialize i_loop
    float n_val = 2.0;
    float a_val = 2.0;
    
    // Use MRI_X directly
    if (MRI_X == 2) n_val = 3.0;
    
    for (; i_loop++ < n_val;) {
        v_temp = braid3(q_temp);
        q_temp.yz -= v_temp.xy;
        q_temp *= a_val;
    }
    return (length(q_temp.yz) - 0.5) / (a_val * (n_val + 1.0)); // n_val + 1.0 for ++n
}

// Function for 'txb'
float txb(vec3 a, vec3 b, vec3 r_vec, float x_val) {
    vec2 u_vec = vec2(a.x, b.x);
    float m_val = r_vec.x;
    float y_val = 0.0; // Explicitly initialize y_val
    
    if (r_vec.y < m_val) { m_val = r_vec.y; u_vec = vec2(a.y, b.y); }
    if (r_vec.z < m_val) { m_val = r_vec.z; u_vec = vec2(a.z, b.z); }
    
    y_val = atan(u_vec.y, u_vec.x) / 6.28 + 0.5;
    y_val = y_val * 20.0;
    x_val = x_val * 20.0;
    return 1.0 - ((cos(x_val) * cos(y_val)) / 2.0 + 0.5);
}

// Function for 'braid'
float braid(vec3 p) {
    // Use MRI_Y and MRI_X directly
    if (MRI_Y > 1) return braidx(p);
    if (MRI_X == 1) return dlian(p);
    
    vec3 y = p.y - 0.6 * cos(p.x + vec3(0, 2, 4));
    vec3 z = p.z - 0.1 * cos(p.x + p.x + vec3(1, 5, 3));
    vec3 r_vec = sqrt(y * y + z * z) - 0.2; // Renamed r_vec to avoid conflict
    
    float min_r = min(r_vec.x, min(r_vec.y, r_vec.z));
    
    // Use MRI_X directly
    return min_r * (MRI_X > 0 && MRI_X < 3 ? txb(y, z, r_vec, p.x) : 1.0);
}

// sd12 now returns an SDFResult struct
SDFResult sd12(vec3 p) {
    SDFResult res;
    res.obj_id = -1; // Default obj_id
    res.dist = 0.0; // Initialize dist
    
    float rx = length(p) - 1.25;
    if (rx > 0.1) {
        res.dist = rx;
        return res;
    }
    
    vec3 a = normalize(sqrt(vec3(0.5 - 0.1 * sqrt(5.0), 0.0, 0.5 + 0.1 * sqrt(5.0))));
    vec3 b = a.yzx;
    vec3 c = a.zxy;
    vec3 e_vec = normalize(vec3(1)); // Renamed to e_vec
    vec3 ac = normalize(a - c);
    vec3 ba = normalize(b - a);
    vec3 n_vec = normalize(cross(c - b, b + c)); // Renamed to n_vec
    
    float sg = 1.0;
    float x_val = 0.0, y_val = 0.0, ang = 0.0; // Explicitly initialize
    float r_val = 0.1; // Renamed to r_val
    float d_val = 0.0, d1_val = 0.0, d2_val = 0.0, d3_val = 0.0; // Explicitly initialize
    
    // 正二十面体の旋转折叠
    for (int i = 0; i < 9; i++) { // Explicitly initialize i
        if (dot(p, n_vec) < 0.0) p = reflect(p, n_vec), sg = -sg;
        n_vec = n_vec.yzx; // Rotate n_vec for next iteration
    }
    n_vec = ba;
    if (dot(p, n_vec) < 0.0) p = reflect(p, n_vec), sg = -sg;
    n_vec = ac;
    if (dot(p, n_vec) < 0.0) p = reflect(p, n_vec), sg = -sg;
    n_vec = ba;
    if (dot(p, n_vec) < 0.0) p = reflect(p, n_vec), sg = -sg;
    
    float aa = 2.0, bb = 1.08, md;
    // Use MRI_Y directly
    if (mod_es1(float(MRI_Y), 2.0) < 1.0) { aa = 0.97; bb = 3.0; } // Use mod_es1
    
    md = max(dot(p - e_vec * aa, e_vec), length(p) - bb * length(a));
    res.obj_id = 3;
    
    // Fix: Apply round_es1 to each component of the vec3 individually
    md += length(p * 15.0 * sg - vec3(round_es1((p * 15.0 * sg).x), round_es1((p * 15.0 * sg).y), round_es1((p * 15.0 * sg).z))) * (0.02 - 0.0); 
    if (md < m0) {
        res.dist = md;
        return res;
    }
    
    for (int i = 0; i < 2; i++) { // Explicitly initialize i
        vec3 az = c;
        vec3 ay = ba;
        vec3 ax = normalize(cross(az, ay));
        vec3 w_vec = vec3(dot(p, ax), dot(p, ay), dot(p, az)); // Renamed w_vec
        
        ang = atan(w_vec.y, w_vec.x);
        y_val = w_vec.z - 0.8;
        x_val = length(w_vec.xy);
        
        x_val = x_val - 0.7 - pow(2.0, 0.5 + 0.5 * sin(sg * ang * 5.0 + 0.4)) * r_val;
        
        d_val = sqrt(max(0.0, x_val * x_val + y_val * y_val)) - r_val * 1.3; // Ensure non-negative sqrt arg
        
        // Use MRI_X directly
        if (MRI_X > 2) { // Changed from mri.x > 2 to MRI_X > 2
            if (abs(d_val) < md) md = abs(d_val), res.obj_id = 1;
        }
        if (d_val < 0.1) {
            vec3 c3 = (a + b + c) / 3.0;
            vec2 n_temp = normalize(abs(vec2(length(c - c3), length(c3)))); // Renamed n_temp
            vec2 ct = vec2(x_val, y_val) * mat2(n_temp.x, -n_temp.y, n_temp.y, n_temp.x);
            
            d1_val = braid(vec3(ang * sg * 10.0 + time * 7.2368, ct / r_val)) * r_val; // Use 'time' here
            if (d1_val < md) md = d1_val, res.obj_id = 2;
        } else {
            md = min(md, d_val + 0.1);
        }
        p = p.zxy; // Rotate p for next iteration
    }
    res.dist = md;
    return res;
}

// map now returns an SDFResult struct
SDFResult map(vec3 p) {
    float t = (time + 6.0) * 0.15; // Use 'time' here
    p.xy *= rot(t);
    p.yz *= rot(t * 0.7);
    p.zx *= rot(t * 0.3);
    return sd12(p);
}

// Soft shadow calculation
float softshadow(vec3 ro, vec3 rd, int obj_id_hit) { // Pass obj_id_hit
    float res = 1.0;
    float t = 0.05; // Original initial t
    float k_val = 1.5;
    for (int i = 0; i < 256 && t < 20.0; i++) { 
        SDFResult sdf_res_h = map(ro + rd * t);
        float h = sdf_res_h.dist;
        int current_obj_id = sdf_res_h.obj_id;
        
        // If the shadow ray hits the object it originated from (self-shadowing)
        // then treat it as transparent. Otherwise, it's an opaque shadow caster.
        if (current_obj_id == obj_id_hit) {
            h = 999.0; // Prevent self-shadowing
        }

        if (h < 0.003) { // Original hit threshold
            return 0.0; // It's in shadow
        }

        res = min(res, k_val * h / t);
        t += h; // Original step advancement
    }
    return (res + 0.3) / 1.3;
}

// Main image function
void mainImage(out vec4 O, vec2 U) {
    // Default values for mri components (replaces iMouse functionality)
    // These are now constants defined at the top.
    int mri_x = MRI_X;
    int mri_y = MRI_Y;
    int mri_z = MRI_Z; 
    
    O = vec4(BACKGROUND_COLOR, 1.0); // Initialize to custom BACKGROUND_COLOR

    vec2 R = iResolution.xy;
    vec2 u_uv = (U + U - R) / max(R.y, EPSILON); // Renamed to avoid conflict
    
    // Apply screen scaling
    u_uv *= SCREEN_SCALE;

    // Apply screen rotation
    float angle = iTime * SCREEN_ROTATION_SPEED;
    mat2 rotation_matrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    u_uv = rotation_matrix * u_uv;

    vec3 eye = vec3(0, 0, -3);
    vec3 dir = normalize(vec3(u_uv, 2));
    vec3 sun = 5.0 * (0.12 * cos((time * 0.0 + 11.0) * 1.0 + 0.0 + vec3(7, 11, 13)) + vec3(-1, 2, -3) / 3.0); // Use 'time' here
    vec3 eps = vec3(0, 0.0001, 0);
    vec3 nor = vec3(0.0); // Explicitly initialize nor
    vec3 p_pos = vec3(0.0); // Explicitly initialize p_pos
    vec3 sp = vec3(0.0); // Explicitly initialize sp
    vec3 ep = vec3(0.0); // Explicitly initialize ep

    float d_dist = 0.0, t_ray = 0.0; // Explicitly initialize t_ray
    float ccc = 0.0; // Explicitly initialize ccc
    float ln_val = 0.0, er_val = 0.0; // Explicitly initialize
    float sha = 1.0, sha2 = 1.0; // Explicitly initialize
    float lnu = length(u_uv);
    bool ht = false; // Explicitly initialize ht

    // Main raymarching loop
    for (int i = 0; i < 256 && t_ray < 8000.0; i++) { // Increased limits for robust hits
        p_pos = eye + dir * t_ray;
        SDFResult current_sdf_result = map(p_pos); // map returns SDFResult
        d_dist = current_sdf_result.dist;
        int current_obj_id = current_sdf_result.obj_id; // Get obj_id

        if (d_dist < m0) { // HIT ANY OBJECT (main object or floor)
            // Calculate normal
            nor = normalize(vec3(map(p_pos + eps.yxx).dist, map(p_pos + eps).dist, map(p_pos + eps.xxy).dist) - d_dist);
            
            // Calculate lighting vectors
            sp = normalize(sun - p_pos); // Light direction from point to sun
            ep = normalize(eye - p_pos); // View direction from point to eye

            // Calculate lighting components (ln_val, er_val)
            ln_val = max(0.0, dot(nor, sp)); // Diffuse light
            er_val = max(0.0, dot(ep, reflect(-sp, nor))); // Specular light (reflection of light ray off surface towards eye)

            vec3 final_color_rgb;

            if (current_obj_id == 1) { // Hit the floor (obj_id 1 from gyr)
                final_color_rgb = BACKGROUND_COLOR; // Base color for floor
            } else { // Hit the main object (obj_id 0, 2, 3 from sd12)
                // Reconstruct original object coloring logic
                float ambt = 0.3, difu = 0.6, spec_power = 80.0;
                vec4 lightClr_base = vec4(er_val * er_val, ln_val * 0.9, 0.55, 1.0); // Base color from original
                
                if (current_obj_id == 3) { // Specific coloring for obj_id 3
                    lightClr_base = vec4(1.5, ln_val * 0.75, er_val * 0.75, 1.0) * 1.0 + 0.3;
                }
                
                final_color_rgb = lightClr_base.rgb * (ambt + (difu * ln_val + pow(er_val, spec_power)));
                final_color_rgb *= vec3(1.0); // Equivalent to original 'O *= clr' when clr is vec4(1)
            }
            
            // Apply shadow (always active)
            vec3 rf = normalize(sun * 100.0 - p_pos); // Light ray for shadow
            float shd = softshadow(p_pos - dir * 0.001, rf, current_obj_id); // Pass obj_id_hit
            final_color_rgb *= (shd + 0.2); // Apply shadow with ambient component
            
            // Apply distance fade and gamma correction
            final_color_rgb *= smoothstep(600.0, 0.0, length(p_pos));
            final_color_rgb = pow(final_color_rgb, vec3(0.8));
            
            O = vec4(final_color_rgb, 1.0);
            ht = true; // Mark as hit
            break; // Exit loop after hit
        }
        t_ray += max(d_dist * 0.8, m0); // Advance ray
    }

    // Post-loop modifications to O from original shader
    O.yz += ccc * 0.2 * sha2;

    if (mri_z == 9 && ht == true) O *= ln_val * 0.0 + sha + 0.0 * er_val + 0.1, O = pow(O, O) * 0.99;
    if (mri_z == 14) O = sqrt(O);
    if (mri_z == 13 && ht == true) O = pow(vec4(sha), 1.0 - O);
    if (mri_z == 0) O = pow(max(O, 0.0), vec4(0.71));
    
    // Post-processing (Brightness, Contrast, Saturation) - always applied to final O
    // Brightness
    O.rgb += POST_BRIGHTNESS;

    // Contrast
    O.rgb = (O.rgb - 0.5) * POST_CONTRAST + 0.5;

    // Saturation
    float luminance = dot(O.rgb, vec3(0.2126, 0.7152, 0.0722));
    O.rgb = mix(vec3(luminance), O.rgb, POST_SATURATION);

    // Final clamping to ensure colors are within [0, 1]
    O = clamp(O, 0.0, 1.0);

    // If the loop finishes without a hit, O is already vec4(BACKGROUND_COLOR, 1.0)
}
