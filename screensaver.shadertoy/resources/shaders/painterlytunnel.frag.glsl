
   // Saturation adjustment (1.0 = neutral)
precision mediump float; // Set default precision for floats

// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Replaced tanh() with tanh_approx() and ensured scalar output by taking .x
#define P(z) vec3(tanh_approx(vec4(cos((z) * .31) * .6)).x * 6., \
                  tanh_approx(vec4(cos((z) * .33) * .5)).x * 6., (z))
// Incorporated ANIMATION_SPEED into the T macro
#define T ((sin(iTime*.05*ANIMATION_SPEED)+iTime*.02*ANIMATION_SPEED)) * 6.
// Corrected rot macro for standard mat2 construction
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
// #define N normalize // normalize is a built-in function

// --- GLOBAL PARAMETERS (for BCS) ---
#define BRIGHTNESS .001    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.900      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0 
#define ANIMATION_SPEED .20 // Controls the overall animation speed (1.0 = normal speed)


void mainImage( out vec4 o, in vec2 u )
{
    // Explicit Variable Initialization
    float s = 0.002; // Explicitly initialized
    float d = 0.0;   // Explicitly initialized
    float i = 0.0;   // Explicitly initialized
    float l = 0.0;   // Explicitly initialized
    float w = 0.0;   // Explicitly initialized
    float ws = 0.0;  // Explicitly initialized

    vec3 r_res = iResolution.xyz; // Explicitly initialized (renamed from 'r')
    
    vec3 p_pos = P(T); // Explicitly initialized (renamed from 'p')
    vec3 ro = p_pos; // Explicitly initialized
    
    vec3 Z = normalize( P(T+3.0) - p_pos); // Explicitly 3.0
    vec3 X = normalize(vec3(Z.z,0.0,-Z.x)); // Explicitly 0.0 (Corrected -Z to -Z.x)
    
    // Normalize uv only once, outside the D calculation for clarity and robustness
    vec2 normalized_uv = (u - r_res.xy / 2.0) / max(r_res.y, 1e-6); // Robust division
    
    vec3 D = vec3(rot(sin(p_pos.z*0.3)*0.3)*normalized_uv, 1.0) // Explicitly 0.3, 0.3, 1.0
             * mat3(-X, cross(X, Z), Z); // Explicitly initialized
    
    o = vec4(0.0); // Explicitly initialize o

    for(int steps = 0; s > 0.001 && steps++ < 100; ) { // Explicitly 0.001, 100
        p_pos = ro + D * d;
        p_pos.xy -= P(p_pos.z).xy;
        p_pos.y -= 1.5; // Explicitly 1.5
        p_pos.x *= 0.5; // Explicitly 0.5
        
        w = 0.6; // Explicitly initialized
        ws = 0.4; // Explicitly initialized
        
        for (int j = 0; j++ < 6; p_pos *= l, w *= l ) { // Explicitly 6
            p_pos = abs(sin(p_pos)) - 1.0; // Explicitly 1.0
            l = (1.0 + ws) / max(dot(p_pos + 0.05, p_pos), 1e-6); // Explicitly 1.0, 0.05, Robust division
            ws += ws * 0.2; // Explicitly 0.2
        }
        s = length(p_pos) / max(w, 1e-6); // Robust division
        d += s;
    }
    
    float exp_arg = (i > 65.0) ? d : (-d / 2.0); // Explicitly 65.0, 2.0
    // Ensure the base of pow is non-negative and boost intensity for higher contrast
    o.rgb += pow(max(0.0, 1.0 - exp(exp_arg)), 0.45) * 1.0; 

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = o.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    o.rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);
}
