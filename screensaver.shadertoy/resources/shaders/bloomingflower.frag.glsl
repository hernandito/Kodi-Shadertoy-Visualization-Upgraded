precision mediump float; // Required for ES 2.0

// Define EPSILON for robustness in divisions
const float EPSILON = 1e-6;

#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

// --- Core Color Scale Parameter ---
// Controls the internal scaling of the 'e' variable before it's used in the exponential function
// for color calculation. Increasing this value will make the effect darker and increase contrast.
// The original golfed code used 1e5 (100,000.0), which led to very dark output.
#define COLOR_SCALE_FACTOR 800.0 // Adjusted from 100.0 for more contrast and less brightness

void mainImage(out vec4 o, vec2 u)
{
    // Explicitly initialize output color vector 'o' to prevent artifacts
    o = vec4(0.0);

    // UV normalization: This calculation (u / iResolution.xy - 0.5) normalizes
    // X and Y independently to the range [-0.5, 0.5], crucial for the fractal's shape.
    vec2 uv_normalized = (u / iResolution.xy - 0.5);

    // Loop variables declared and explicitly initialized to prevent undefined behavior. iTime
    float g = 0.0;
    float e = 0.0;
    float R = 0.0;
    float S = 0.0;

    // Main loop for fractal iteration.
    for(float i_iter = 0.0; i_iter < 100.0; i_iter++)
    {
        float current_i = i_iter + 1.0; 

        vec3 p_pos = vec3(uv_normalized * g, g - 0.3) - current_i / 2e5;

        p_pos.yz *= mat2(3,2,-1,3)*0.3;

        R = length(p_pos);
        float R_robust = max(R, EPSILON);

        float asin_arg = -p_pos.z / R_robust;
        e = asin(clamp(asin_arg, -1.0, 1.0)) - 0.1 / R_robust;
        
        p_pos = vec3(log(R_robust) - iTime * 0.25, e, atan(p_pos.x, p_pos.y) * 3.0);

        // Inner loop (FBM - Fractal Brownian Motion like calculation)
        for(S = 1.0; S < 1e2; S += S)
        {
            e += pow(abs(dot(sin(p_pos.yxz * S), cos(p_pos * S))), 0.2) / max(S, EPSILON);
        }
        
        g += e * R * 0.1;

        // Color accumulation step.
        // The 'e' is scaled here using COLOR_SCALE_FACTOR before the exponential.
        e = max(e * COLOR_SCALE_FACTOR, 0.7);
        float exp_e_robust = max(exp(e), EPSILON);
        
        float mod_arg = 0.4 - 0.12 / R_robust;
        o += 0.03 / exp_e_robust * (clamp(abs(mod(mod_arg + vec4(8,6,4,0), 6.0) - 3.0) - 1.0, 0.0, 1.0) * e - e + 1.0);
    }
}
