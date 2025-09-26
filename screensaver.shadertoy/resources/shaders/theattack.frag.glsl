// --- Robust Tanh Conversion Method (for OpenGL ES 1.0) ---

// Adds robustness to division operations to prevent NaN/Inf when approaching zero. 
const float EPSILON = 1e-6;

// Robust Tanh Approximation (Tanh(x) ≈ x / (1.0 + |x|))
vec4 tanh_approx(vec4 x) { 
    return x / (1.0 + max(abs(x), EPSILON)); 
}

// ---------------------------------------------------------

// ---------------- USER PARAMETERS ----------------
#define ANIMATION_SPEED 0.2 // New global control for animation speed (1.0 is default)
#define BRIGHTNESS 1.00
#define CONTRAST   1.10
#define SATURATION 1.00
// -------------------------------------------------

// A robust BCS function
vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    
    // Using a standard luminance formula for saturation
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color = mix(grayscale, color, saturation);
    
    return color;
}

// P(z) is the camera path function (used for initial ray origin 'ro')
#define P(z) vec3(cos(.2*z), sin(z*.05)*.25, z)
#define t iTime

void mainImage(out vec4 O, vec2 C) {
    // Explicitly initialize variables
    O = vec4(0.0); 

    vec3 p = vec3(0.0);
    vec3 X = vec3(0.0); 
    vec3 ro = vec3(0.0);
    vec3 r = iResolution.xyx; 

    float z = 0.0;
    float i = 0.0;
    float d = 0.0; 
    
    // Scaled time using the new speed control
    float t_scaled = iTime * ANIMATION_SPEED;

    for (; ++i < 150.;) {
        z += 0.1 * d;
        
        // Apply speed control to camera movement
        ro = P(t_scaled); 
        
        // Generate ray direction and position (p = ro + z * direction)
        p = ro + z * normalize(vec3(C - 0.1 * r.xy, r.y));
        
        // Apply speed control to forward tunnel movement
        p.z += t_scaled; 
        
        X = p; // Snapshot raymarch position for detail calculation

        // Apply speed control to global translation and rotation
        p = 1.0 - p - (cos(t_scaled * 0.2 + 2.0) + sin(t_scaled * 0.05) * 1.5);
        
        // Apply speed control to 2D rotation in XY plane (swirl tunnel)
        p.xy *= mat2(cos(sin(p.z * 0.9 + t_scaled * 0.5) * 0.2 + vec4(0.0, 11.0, 33.0, 0.0)));
        
        // Repeat space (fractal tiling)
        p = fract(p) - 0.25;
        
        // Distance function (d)
        // Robustness: max(..., 1e-3) and final +.001 ensure d > 0.002
        d = abs(sin(p.z) + max((abs(p.x) + abs(p.y) + abs(p.z)) - abs(.09 * sin(X.z * 0.9)) , 1e-3)) + 0.001;

        // Accumulate glow (O)
        O += sin( (sin(length(p.xy) * 1.0 - 5.0 * p.y + vec4(1.0, 0.1, 0.0, 0.0) * 2.0))) / d;
        
        // Optional: surface perturbation for more detail
        d += 0.09 * (sin(p.x * 1.5) + 0.50) * (sin(10.0 * p.y) ) * (sin(90.0 * p.z) - 1.0);
    }
    
    // --- Tanh Conversion and Post-Processing ---
    
    // 1. Compute the input value for the robust tanh approximation
    vec4 tanh_input = O / 10000.0;
    
    // 2. Apply the tanh_approx function and pow for gamma correction
    O = pow(tanh_approx(tanh_input), vec4(1.0 / 2.2));
    
    // 3. Simple tone mapping adjustment
    O *= O;
    
    // 4. Apply Brightness, Contrast, Saturation (BCS) adjustment
    O.rgb = applyBCS(O.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}
