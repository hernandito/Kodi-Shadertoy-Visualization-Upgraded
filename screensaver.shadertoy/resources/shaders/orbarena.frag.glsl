// Combined Animated Scene: Orb/Floor (Foreground) and Fractal Structure (Background)
// Refactored for GLSL 1.0 compatibility (Kodi/GLES)
// Includes X-axis shift parameter and STRONGER Dithering to eliminate banding.

// --- UTILITIES & CONSTANTS ---
#define EPSILON 0.000001
#define ONE_OVER_1E7 0.0000001 
#define MAX_RAY_DIST 100.0 // Max ray distance

// Animation and Tiling Parameters
#define Z_SPEED 0.40            // Speed of backward movement (background structure)
#define Z_REPEAT 11.0           // Distance until the scene tiles/repeats
#define X_SHIFT 0.150           // Horizontal post-processing offset (User requested)

// --- NEW PARAMETERS ---
#define ORB_ANIM_SPEED 0.50     // Multiplier for the speed of the three flying orbs (User requested)
#define FOV_SCALE 0.9          // Field of View (FOV) adjustment


// Dithering Noise Function (2D to 1D hash)
// Creates a simple, tileable noise pattern based on screen coordinates.
float hash21(vec2 p) {
    p = fract(p * vec2(12.9898, 78.233));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

// Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    // This function approximates tanh(x) as x / (1.0 + |x|) for robust scaling.
    return x / (1.0 + max(abs(x), EPSILON));
}

// D_Orb: Orb Distance Function 
float D_Orb(float Z_val, float c_val, vec3 p_raw, float T) {
    // Apply ORB_ANIM_SPEED multiplier to time (T)
    float t_scaled = T * ORB_ANIM_SPEED;
    
    vec3 center = vec3(
        sin(t_scaled * c_val * 6.0) * 3.0,
        sin(t_scaled * c_val * 4.0) * 2.0 + 1.5,
        Z_val + 5.0 + cos(t_scaled * 0.5) * 16.0
    );
    return length(p_raw - center) - c_val;
}


// D_Structure: Calculates the distance to the Fractal Structure for a given position 'p'
float D_Structure(vec3 p) {
    float w = 0.35;
    float l = 0.0;
    vec3 p_fractal = p * 0.1; 
    p_fractal.xy += 1.5; 
    
    // Fractal iterations (7 iterations)
    for (int j = 0; j < 7; j++) {
        p_fractal = sin(p_fractal);
        l = 3.0 / dot(p_fractal, p_fractal);
        p_fractal *= l;
        w *= l;
    }
    
    return length(p_fractal)/w; 
}


void mainImage(out vec4 o, vec2 u) {
    // Store the original screen coordinate for the dither hash
    vec2 fragCoord = u;

    // Explicit variable declarations and initialization
    o = vec4(0.0);
    float d = 0.0;
    float i = 0.0;
    float e_orbs = 0.0;
    float s_floor = 0.0;
    float s_structure = 0.0;
    float s_closest = 0.0;
    float T = iTime;
    vec3 p_res = iResolution;
    
    // Normalize coordinates and setup camera ray
    u = ( u - p_res.xy/2.0 ) / p_res.y;
    
    // Apply FOV_SCALE
    u *= FOV_SCALE;

    // Apply X-AXIS SHIFT
    u.x += X_SHIFT; 

    u.y += 0.3; // Initial camera height offset
    
    // Calculate the continuous Z-shift for the backward movement
    float walk_z = T * Z_SPEED;
    
    // Raymarch loop: Clean initialization and structure
    for(i = 0.0; i < 164.0; i += 1.0) {
        
        // 1. Calculate current ray position (p_raw: true Z-distance, used for non-tiled objects like Orbs)
        vec3 p_raw = vec3( u*d, d );
        
        // 2. Tiled/Moving Position (p_tiled: Z-motion applied, used for Floor and Structure)
        vec3 p_tiled = p_raw;
        p_tiled.z -= walk_z; 
        p_tiled.z = mod(p_tiled.z, Z_REPEAT) - Z_REPEAT * 0.5; 
        
        
        // --- A. Orb Distance (e_orbs) ---
        e_orbs = max( 0.8 * min( D_Orb( 17.0, 0.1, p_raw, T),
                                 min( D_Orb( 16.0, 0.2, p_raw, T),
                                      D_Orb( 14.0, 0.3, p_raw, T) )), 0.001 );

        // --- B. Floor Distance (s_floor) ---
        // Floor is at y = -1.0
        s_floor = max(1.0 + p_tiled.y, 0.001); 

        // --- C. Direct Fractal Structure Distance (s_structure) ---
        s_structure = D_Structure(p_tiled); 

        // --- Combined Step ---
        s_closest = min( min(e_orbs, s_floor), s_structure );
        
        
        // --- Color Accumulation ---
        
        if (s_closest == e_orbs || s_closest == s_floor) {
            // Base Floor/Orb Color: Dark ambient + Orb Glare
            float base_color_contrib = (d / s_closest) * 0.4 + 100000.0 / e_orbs; 
            
            // Accumulate base color
            o.x += base_color_contrib;
        } 
        // If the closest hit is the White Structure (Background Layer)
        else {
            // White light for the structure
            o.x += d / s_closest; 
        }
        
        d += s_closest;
        
        if (d > MAX_RAY_DIST) break;
        
        // If the step size is too small, we have hit something and can break early
        if (s_closest < EPSILON) break;
    } 
    
    // --- Dithering Application ---
    // Increased scale from 1.0e-7 to 2.0e-6 to aggressively break up visible banding.
    float dither_noise = (hash21(fragCoord) - 0.5) * 2.0e-6; // <<< Increased Dither Strength
    o.x += dither_noise;

    // Apply final color scaling (subtle blue/purple tint) and robust tanh conversion
    o = tanh_approx(vec4(1.0, 2.0, 3.0, 0.0) * o.x * ONE_OVER_1E7);
}
