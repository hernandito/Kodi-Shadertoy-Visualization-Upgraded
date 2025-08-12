precision mediump float; // Set default precision for floats

// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

#define T (iTime * .1)
// Replaced tanh() with tanh_approx() and ensured scalar output by taking .x
#define P(z) (vec3(tanh_approx(vec4(cos((z) * .4) * .5)).x * 8., \
                    tanh_approx(vec4(cos((z) * .5) * .5)).x * 4., (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
// #define N normalize // Not explicitly defined in original, but normalize is a built-in function

// --- GLOBAL PARAMETERS (for BCS) ---
#define BRIGHTNESS .50    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.70      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)

// --- COLOR PALETTE PARAMETERS ---
// Selects the active color palette:
// 0: Original shader's coloring
// 1: New Warm Palette
#define COLOR_PALETTE_MODE 1 // Set to 1 to enable the warm palette

#define NUM_WARM_PALETTE_COLORS 6 // Number of colors in the warm palette

// Controls the overall brightness of the colors sampled from the warm palette.
// Increased for brighter colors, decreased for darker.
// Adjusted from 1.0 to 0.05 to prevent immediate white-out.
#define WARM_PALETTE_BRIGHTNESS_SCALE 0.025
// Controls how rapidly the colors cycle through space (i.e., how many color bands are visible).
// Higher values create more frequent color changes.
// Example: 0.1 for a slower cycle, 0.5 for a faster, more banded cycle.
// Adjusted from 1.0 to 0.1 to show more colors.
#define WARM_PALETTE_DENSITY_SCALE 0.8


void mainImage(out vec4 o, in vec2 u) {
    // Explicit Variable Initialization
    float s = 0.006; // Explicitly initialized
    float l = 0.0;   // Explicitly initialized
    float w = 1.0;   // Explicitly initialized
    float d = 0.0;   // Explicitly initialized
    float i = 0.0;   // Loop counter, explicitly initialized

    vec3 r_res = iResolution.xyz; // Explicitly initialized
    vec3 q_local = vec3(0.0);    // Explicitly initialized (renamed from 'q')
    vec3 e_val = vec3(0.005,0.0,0.0); // Explicitly initialized (renamed from 'e')
    
    vec3 p_pos = P(T); // Explicitly initialized (renamed from 'p')
    vec3 ro = p_pos; // Explicitly initialized
    
    vec3 Z = normalize( P(T+1.0) - p_pos); // Explicitly 1.0
    vec3 X = normalize(vec3(Z.z,0.0,-Z.x)); // Explicitly 0.0 (Corrected -Z to -Z.x)
    
    // Normalize uv only once, outside the D calculation for clarity and robustness
    vec2 normalized_uv = (u - r_res.xy / 2.0) / max(r_res.y, 1e-6); // Robust division
    
    // Replaced tanh() with tanh_approx() and ensured scalar output by taking .x
    vec3 D = vec3(rot(sin(p_pos.z*0.15)*0.3)*normalized_uv, 1.0) // Explicitly 0.15, 0.3, 1.0
             * mat3(-X, cross(X, Z), Z); // Explicitly initialized

    if (iMouse.z > 40.0) { // Explicitly 40.0
        float a = atan(0.0, -1.0); // Explicitly 0.0, -1.0
        D.yz *= rot(-a * 0.5 + iMouse.y/max(r_res.y, 1e-6) * a); // Explicitly 0.5, Robust division
        D.zx *= rot(a - iMouse.x/max(r_res.x, 1e-6) * a * 2.0); // Explicitly 2.0, Robust division
    }
    
    o = vec4(0.0); // Explicitly initialize o

    // Define the new warm color palette
    vec3 warmPaletteColors[NUM_WARM_PALETTE_COLORS];
    warmPaletteColors[0] = vec3(1.0, 0.843, 0.0);   // #FFD700 (Gold)
    warmPaletteColors[1] = vec3(1.0, 0.647, 0.0);   // #FFA500 (Orange)
    warmPaletteColors[2] = vec3(1.0, 0.271, 0.0);   // #FF4500 (OrangeRed)
    warmPaletteColors[3] = vec3(0.863, 0.078, 0.235); // #DC143C (Crimson)
    warmPaletteColors[4] = vec3(0.698, 0.133, 0.133); // #B22222 (FireBrick)
    warmPaletteColors[5] = vec3(0.545, 0.0, 0.0);   // #8B0000 (DarkRed)


    for(int steps = 0; s > 0.005 && steps++ < 100; ) { // Explicitly 0.005, 100
        p_pos = ro + D * d;
        q_local = p_pos; // Use q_local
        q_local.xy -= P(q_local.z).xy;
        s = 2.75 - length(q_local.xy); // Explicitly 2.75
        q_local.x -= 3.0; // Explicitly 3.0
        q_local.xy *= 0.5; // Explicitly 0.5

        w = 0.5; // Explicitly 0.5
        for (int j = 0; j++ < 8; q_local *= l, w *= l ) { // Explicitly 8
            q_local = abs(sin(q_local)) - 1.0; // Explicitly 1.0
            l = 1.6 / max(dot(q_local,q_local), 1e-6); // Explicitly 1.6, Robust division
        }
        s = length(q_local)/max(w, 1e-6); // Robust division

        vec3 current_color_contribution;
        #if COLOR_PALETTE_MODE == 1
            // Logic to pick color from warmPaletteColors based on p_pos.z
            float color_index_float = mod(p_pos.z * WARM_PALETTE_DENSITY_SCALE, float(NUM_WARM_PALETTE_COLORS));
            int idx1 = int(floor(color_index_float));
            int idx2 = int(ceil(color_index_float));
            // GLSL ES 1.0 compatible integer modulo
            idx1 = idx1 - (idx1 / NUM_WARM_PALETTE_COLORS) * NUM_WARM_PALETTE_COLORS; 
            idx2 = idx2 - (idx2 / NUM_WARM_PALETTE_COLORS) * NUM_WARM_PALETTE_COLORS; 
            current_color_contribution = mix(warmPaletteColors[idx1], warmPaletteColors[idx2], fract(color_index_float));
            current_color_contribution *= WARM_PALETTE_BRIGHTNESS_SCALE;
        #else
            current_color_contribution = abs(sin(p_pos))*0.05; // Original color generation
        #endif
        o.rgb += current_color_contribution;


        for(float a_inner = 0.2; a_inner < 12.0; ) { // Explicitly 0.2, 12.0 (renamed 'a' to 'a_inner')
            s -= abs(dot(sin(p_pos*a_inner*(20.0+(sin(T)*0.6+0.5))), // Explicitly 20.0, 0.6, 0.5
                         vec3(0.75)))/max(a_inner, 1e-6)*0.01; // Explicitly 0.75, 0.01, Robust division
            a_inner += a_inner; // Original was a+=a, this is equivalent to a_inner *= 2.0
        }
        d += s;
    }
    o.rgb *= exp(-d/max(abs(4.0+sin(p_pos.z)), 1e-6)); // Explicitly 4.0, Robust division
    o = vec4(pow(o.rgb,vec3(0.45)), 1.0); // Explicitly 0.45, 1.0

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = o.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    o.rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);
}
