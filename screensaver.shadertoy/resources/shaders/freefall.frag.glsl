// ------------------------------------------------------------
// Dot Noise (by Xor, https://www.shadertoy.com/view/wfsyRX)
// Produces smooth chaotic noise using golden ratio rotations.
// ------------------------------------------------------------
//
// ---------------- USER PARAMETERS ----------------
#define BRIGHTNESS 1.0
#define CONTRAST 1.2
#define SATURATION 1.0
#define GLOBAL_ANIMATION_SPEED .25
// -------------------------------------------------

// Robust Tanh Conversion Method
// Approximates the tanh function to be compatible with older GLSL versions.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

float dot_noise(vec3 p) {
    const float PHI = 1.618033988; // golden ratio
    const mat3 GOLD = mat3(
        -0.571464913, +0.814921382, +0.096597072,
        -0.278044873, -0.303026659, +0.911518454,
        +0.772087367, +0.494042493, +0.399753815
    );
    return dot(cos(GOLD * p), sin(PHI * p * GOLD));
}

// A robust BCS function
vec4 bcs_final(vec4 color, float brightness, float contrast, float saturation) {
    color.rgb += brightness - 1.0;
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    
    // Using a luminance formula that is more robust for saturation
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color.rgb = mix(grayscale, color.rgb, saturation);
    
    return color;
}

// ------------------------------------------------------------
// Main raymarch entry
// ------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    vec4 col = vec4(0.0);
    float d = 0.0; // depth accumulator
    float s = 0.0; // step size
    vec3 p = vec3(0.0); // current ray position
    float iTime_scaled = iTime * GLOBAL_ANIMATION_SPEED;
    
    // Volumetric raymarch loop
    for (float i = 0.0; i < 400.0; i++) {
        // Nonlinear stepping (feedback-based)
        s = 0.007 + abs(s) * 0.04;
        d += s;
        
        // Base sinusoidal accumulation
        col += abs(vec4(2.1,.25,.1,1.)+sin(d*.5 + vec4(1.65, 0.15,  .5+p.z*9.+iTime_scaled, 0.)) +2.*smoothstep(-1.,1.,sin(p.z*1.))) / (s * s + 1e-9);

        // Compute current ray position
        p = vec3(uv * d * 2.0, d + iTime_scaled * 1.0);
        // Compute rotation angle based on position and time
        float a = abs(cos(iTime_scaled * 0.05) * 2.) +iTime_scaled*.2;

        // Create 2D rotation matrix
        mat2 rot = mat2(cos(a), sin(a), -sin(a), cos(a));

        // Apply rotation to XY-plane
        p.xy *= rot;
        // Sample density via dot noise
        float density = dot_noise(p+iTime_scaled)*(1.+5.*smoothstep(-1.,1.,sin(iTime_scaled*.25)));
        // Clear space around camera
        float clear = length(p - vec3(0, 0, iTime_scaled)) - 2.0;
        s = max(s, -clear);
        s += abs(density);
    }

    // --------------------------------------------------------
    // Tone mapping
    //  tanh + gamma approach 
    // --------------------------------------------------------
    vec4 tanh_arg = col * col * col * col / 9e27;
    fragColor = 2.0 * pow(tanh_approx(tanh_arg), vec4(0.4545));
    
    // Apply BCS
    fragColor = bcs_final(fragColor, BRIGHTNESS, CONTRAST, SATURATION);
}
