/*
    GLSL Shader: Abstract Tunnel Raymarcher (Kodi Compatible)
    
    Converted from minified Shadertoy code for OpenGL ES 1.0 compatibility.
    - Explicit variable initialization.
    - Robust Tanh Approximation used.
    - Division robustness applied.
*/

// Define a small constant for numerical stability
const float EPSILON = 1e-6;

// --- ROBUST TANH CONVERSION METHOD (vec4 implementation) ---
// This approximation function replaces the built-in tanh, which is often
// missing or unreliable in OpenGL ES 1.0 environments (like Kodi).
vec4 tanh_approx4(vec4 x) { 
    // Uses the formula: x / (1.0 + |x|)
    return x / (1.0 + max(abs(x), vec4(EPSILON))); 
}

void mainImage(out vec4 o, vec2 u) {
    // --- 1. Explicit Variable Initialization (Crucial for ES 1.0) ---
    // The original shader's minified declaration style is expanded and initialized.
    float i = 0.0;
    float d = 0.0;
    float s = 0.0;
    float c = 0.0;
    float w = 0.0;
    float n = 0.0;
    float t = iTime * 0.3; // Time variable

    vec3 q = vec3(0.0);
    vec3 p = iResolution.xyz; // Use full resolution vector

    // --- 2. Coordinate Setup ---
    // Center, normalize, and add a subtle camera movement
    u = (u - p.xy * 0.5) / p.y;
    u += cos(t * 0.2) * vec2(0.4, 0.1); 

    // Initialize accumulation color
    o = vec4(0.0); 

    // --- 3. Main Raymarch Loop (Outer Loop) ---
    // i++<1e2 is 100 iterations.
    for (; i < 100.0; i++) {
        
        // --- Inner Loop (Per-step density modification) ---
        // Initialize ray position and fractal parameters
        p = vec3(u * d, d + t * 2.0); // Current ray position (XY scaled by depth d)
        q = p; // Copy for separate turbulence
        p.x += t; // Horizontal camera movement

        n = 0.05; // Starting scale for the fractal loop
        while (n < 6.0) {
            // Turbulence/Fractal step 1: Modifies ray position 'p' (color component)
            p += abs(dot(cos(0.2 * t + 0.4 * p / n), vec3(0.8))) * n;
            
            // Turbulence/Fractal step 2: Modifies density position 'q' (density component)
            // Note: The original code only modifies q.yz.
            q.yz += abs(dot(cos(q.z * 0.01 + 0.18 * q / n), vec3(1.3))) * n;
            
            n += n; // n doubles (0.05, 0.1, 0.2, 0.4, 0.8, 1.6, 3.2, 6.4 - stops before 6.0)
        }
        
        // --- Accumulation (Post-Inner Loop) ---
        
        // w: Density-based step adjustment (0.6 * max(q.y, 0.001))
        w = 0.6 * max(q.y, 0.001);
        
        // c: "Clipping" or attenuation factor based on vertical position
        c = 0.1 + 0.2 * abs(p.y - 16.0);
        
        // s: The actual step size taken (min of density-based or clipping factor)
        s = min(c, w);
        
        // d: Advance ray depth
        d += s;
        
        // Accumulate color 'o'. Division protected.
        // The condition w < c determines the color contribution (brighter near 'w' threshold).
        o += w < c ? 
             0.005 / max(s, EPSILON) : // 0.005 / max(s, 1e-6)
             0.6 / max(s, EPSILON);    // 0.6 / max(s, 1e-6)
    }

    // --- 4. Tanh Conversion and Final Output ---

    // Calculate the input value for tanh: o / (2000 * length(u - 0.4))
    // Division protection added for stability, in case length() approaches zero.
    vec4 tanh_input = o / (2000.0 * max(length(u - 0.4), EPSILON));
    
    // Apply the robust approximation
    o = tanh_approx4(tanh_input);
}
