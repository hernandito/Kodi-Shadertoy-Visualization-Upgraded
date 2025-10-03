// Robust Tanh Conversion for Kodi GLSL ES 1.0 Compatibility

// =========================================================================
// USER-TUNABLE PARAMETERS
// Adjust values below (1.0 is the neutral starting point for all)
// =========================================================================
// Post-Processing Brightness: 1.0 = neutral. Higher = brighter, Lower = darker.
#define BRIGHTNESS .35

// Post-Processing Contrast: 1.0 = neutral.
#define CONTRAST 1.30 

// Post-Processing Saturation: 1.0 = neutral, 0.0 = grayscale.
#define SATURATION 1.0 

// =========================================================================
// ROBUSTNESS & HELPERS
// =========================================================================

// Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) { 
    const float EPSILON = 1e-6; 
    return x / (1.0 + max(abs(x), EPSILON)); 
}

// Helper function to calculate luminance for saturation control (Rec. 709)
float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void mainImage(out vec4 O, vec2 C) {
    // CRITICAL: Explicitly initialize all local variables for GLSL ES 1.0 compatibility
    float i = 0.0;
    float d = 0.0;
    float z = 0.0;
    float t = iTime*.1 * 0.4; // Time calculation

    vec4 o = vec4(0.0); // Color accumulator
    vec4 p = vec4(0.0); // Position vector
    
    vec2 r = iResolution.xy; 
    
    // Raymarching loop
    for(; i < 66.0; i += 1.0) {
        // Increment z based on distance d
        z += d * 0.6; 
        
        // Ray origin and direction setup
        p = vec4(z * normalize(vec3(C - 0.5 * r, r.y)), 0.0);
        p.z += t;
        
        vec3 fl = p.xyz;
        vec3 q = fl;
        q = abs(fract(q * 0.8) - 0.5); // Grid folding/repetition
        
        // Signed Distance Field (SDF) calculations
        float t1 = length(q.xy - vec2(0.15, 0.1)) - 0.08 * (1.0 + 0.3 * sin(fl.z * 12.0 + t * 8.0));
        float t2 = length(q.xz - vec2(0.1, 0.2)) - 0.06 * (1.0 + 0.4 * sin(fl.y * 10.0 + t * 6.0));
        float t3 = length(q.yz - vec2(0.2, 0.05)) - 0.05 * (1.0 + 0.2 * sin(fl.x * 15.0 + t * 10.0));
        
        // Combine minimum distance
        d = min(min(t1, t2), t3);
        
        // Robust SDF: d >= 5e-4
        d = abs(d) + 5e-4; 
        
        // Color accumulation 'h'
        vec4 h = vec4(1.0, 0.3, 0.05, 1.0) * (1.0 + sin(length(fl) * 8.0 + t * 6.0));
        h += vec4(0.2, 0.4, 0.8, 1.0) * (1.0 - smoothstep(0.0, 0.1, d)) * 0.3;
        
        float i_y = 1.0 + 0.1 * sin(fl.z * 1.0 - t * 8.0);
        
        // Accumulate color
        o += h / d * i_y;
    }
    
    // =========================================================================
    // POST-PROCESSING: ROBUST TANH & BCS ADJUSTMENTS
    // =========================================================================
    
    // 1. Apply robust Tanh approximation to the accumulated color (compresses high range to [0, 1])
    vec3 final_color = tanh_approx(o / 9e3).rgb;

    // 2. Contrast (pivots around 0.5)
    final_color = (final_color - 0.5) * CONTRAST + 0.5;

    // 3. Saturation (mixes color with its grayscale luminance)
    float l = luminance(final_color);
    final_color = mix(vec3(l), final_color, SATURATION);

    // 4. Brightness (simple multiplier: 1.0 is neutral)
    final_color *= BRIGHTNESS;

    // 5. Final Output (Clamping and Gamma Correction)
    // Clamp colors to the [0, 1] range for stability on GLSL ES 1.0
    final_color = clamp(final_color, 0.0, 1.0);
    
    // Apply simplified gamma correction (sqrt)
    O = vec4(sqrt(final_color), 1.0);
}
