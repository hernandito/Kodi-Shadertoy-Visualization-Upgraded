#ifdef GL_ES
// Set default precision for floats to mediump for better compatibility with older OpenGL ES 1.0 devices.
precision mediump float;
#endif

// Robust Tanh Conversion Method:
// This function approximates the hyperbolic tangent (tanh) function.
// It includes an EPSILON to prevent division by zero, making it robust.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6; // A small constant to prevent division by zero.
    return x / (1.0 + max(abs(x), EPSILON)); // x / (1 + |x|) approximation.
}

// ==== BCS Adjustment Parameters ====
// Adjust these values to control the final look of the shader.
#define BRIGHTNESS_ADJ 1.4   // Overall brightness (1.0 is neutral; >1.0 brighter, <1.0 darker)
#define CONTRAST_ADJ   1.2   // Contrast (1.0 is neutral; >1.0 more contrast, <1.0 less)
#define SATURATION_ADJ 1.0   // Color saturation (1.0 is neutral; >1.0 more vibrant, <1.0 desaturated)

void mainImage(out vec4 O, vec2 I)
{
    // Explicitly initialize all variables to prevent undefined behavior.
    float z = 0.0; // Raymarch depth
    float d = 0.0; // Step distance
    float f = 0.0; // Fire distance (also used as turbulence loop iterator)
    float i = 0.0; // Raymarch iterator
    
    // Explicitly initialize O (output color)
    O = vec4(0.0);

    // Clear fragColor and raymarch 80 steps
    // The original compact for loop syntax has been expanded for GLSL ES 1.0 compatibility.
    for(i = 0.0; i < 100.0; i += 1.0) // Original was i++<1e2, changed to 100.0 for clarity
    {
        // Coordinates for turbulent clouds
        vec3 c = vec3(0.0); // Explicitly initialize c
        // Raymarch sample point
        // Ensure iResolution.xyy is treated as a vec3.
        vec3 p = z * normalize(vec3(I.xy, 0.0) * 1.9 - iResolution.xyy); // Changed I+I to vec3(I.xy, 0.0)*2.0 for clarity
        
        // Shift camera back 7 units
        p.z += 6.0;
        
        // Use these coordinates in turbulence
        c = p;
        
        // Turbulence loop
        // Explicitly initialize f for this inner loop.
        for(f = 1.0; f < 9.0; f += 1.0) // Original was f++<9., changed to 9.0 for clarity
        {
            c += sin(c.zxy * f + f + iTime) / max(f, 1E-6); // Robust division for f
        }
        
        // Fire cloud distance
        // Robust division for 6.0.
        // Replaced tanh with tanh_approx.
        // Ensure all literals are floats (e.g., 0.6, 2.0, 1.2, 8.0, 6.0).
        z += d = min(f = 0.1 + length(c) + c.y,
                     min(length(p.xz) + tanh_approx(vec4(0.6 * p.y - 2.0)).x, // Apply tanh_approx to a vec4, then take .x
                         length(max(c = sin(p * 5.0), c.yzx) - 1.2 + p.x / 8.0))) / 6.0; // Robust division for 8.0
        
        // Coloring and brightness (post-iteration from original for loop)
        // Robust division for z and f.
        O += (3.0 + vec4(9.0, 4.0, f, 0.0)) * d / max(z, 1E-6) / max(f, 1E-6);
    }
    
    // Tanh tonemap
    // Replaced tanh with tanh_approx.
    // Robust division for 200.0.
    O = tanh_approx(O * O / max(200.0, 1E-6));

    // --- Apply BCS adjustments in post-processing ---
    vec3 final_color = O.rgb;

    // 1. Brightness: Directly multiplies the color.
    final_color *= BRIGHTNESS_ADJ;

    // 2. Contrast: Adjusts contrast around a midpoint (0.5).
    final_color = (final_color - 0.5) * CONTRAST_ADJ + 0.5;

    // 3. Saturation:
    // Calculate luminance (grayscale equivalent) of the color.
    // Standard NTSC luminance coefficients are used (0.299, 0.587, 0.114).
    float luminance = dot(final_color, vec3(0.299, 0.587, 0.114));
    // Linearly interpolate between the grayscale color and the original color based on SATURATION_ADJ.
    final_color = mix(vec3(luminance), final_color, SATURATION_ADJ);
    // --- End BCS adjustments ---

    O = vec4(final_color, O.a); // Assign the adjusted color back to O
}
