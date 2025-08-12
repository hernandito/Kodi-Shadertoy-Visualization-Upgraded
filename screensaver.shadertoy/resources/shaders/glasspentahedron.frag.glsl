/*
    "Crystal" by @XorDev

    Testing a new rotation technique, iridescence and a dodecahedron formula
*/

// --- Robust Tanh Conversion Method Directives ---

// 1. Include the tanh_approx function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- Post-Processing BCS Parameters ---
// Adjusts the overall brightness of the final image.
// Positive values increase brightness, negative values decrease it.
#define POST_BRIGHTNESS 0.0   // Default: 0.0 (no change)

// Adjusts the contrast of the final image.
// 1.0 is no change. Values > 1.0 increase contrast, values < 1.0 decrease it.
#define POST_CONTRAST   1.30   // Default: 1.0 (no change)

// Adjusts the saturation of the final image.
// 1.0 is no change. 0.0 results in a grayscale image. Values > 1.0 oversaturate.
#define POST_SATURATION 1.0   // Default: 1.0 (no change)


void mainImage(out vec4 O, vec2 I)
{
    // 3. Ensure Explicit Variable Initialization:
    // Initialize output color (fragColor) to black iTime
    O = vec4(0.0);

    // Raymarch depth
    float z = 0.0;
    // Step distance
    float d = 0.0;
    // Raymarch iterator
    float i = 0.0;
    
    // Raymarch 100 steps
    // Original loop: for(O*=i;i++<1e2; O+=(cos(i*.2+vec4(0,1,2,0))+1.)/d)
    // Rewritten for clarity and robustness:
    for(i = 0.0; i < 100.0; i++)
    {
        //Sample point (from ray direction)
        vec3 p = z * normalize(vec3(I + I, 0.0) - iResolution.xyy); 
        //Rotation axis
        vec3 a = normalize(cos(vec3(0.0, 2.0, 4.0) + iTime*.2)); 
        //Move camera back 4 units
        p.z += 4.0; 
        //Rotated absolute coordinates
        a = abs(a * dot(a, p) - cross(a, p));
        
        //Distance to hollow dodecahedron
        // Calculate 'd' (step distance)
        d = 0.01 + 0.2 * abs(max(max(a += 0.6 * a.yzx, a.y).x, a.z) - 2.0); 
        // Accumulate raymarch depth
        z += d;

        // Coloring and brightness
        // 4. Enhance General Division Robustness: Replace X / Y with X / max(Y, 1E-6)
        O += (cos(i * 0.2 + vec4(0.0, 1.0, 2.0, 0.0)) + 1.0) / max(d, 1e-6); 
    }
    
    // 2. Replace tanh() calls: Change tanh(value) to tanh_approx(value).
    // 4. Enhance General Division Robustness: Replace X / Y with X / max(Y, 1E-6)
    O = tanh_approx(O * O / max(3e7, 1e-6));

    // --- Apply Post-Processing BCS Adjustments ---
    // Brightness
    O.rgb += POST_BRIGHTNESS;

    // Contrast
    // Adjusts around a 0.5 gray pivot
    O.rgb = (O.rgb - 0.5) * POST_CONTRAST + 0.5;

    // Saturation
    // Calculate luminance (grayscale equivalent)
    float luma = dot(O.rgb, vec3(0.2126, 0.7152, 0.0722)); 
    vec3 gray = vec3(luma);
    // Mix between grayscale and original color based on POST_SATURATION
    O.rgb = mix(gray, O.rgb, POST_SATURATION);

    // Ensure alpha is 1.0 for proper display
    O.a = 1.0; 
}