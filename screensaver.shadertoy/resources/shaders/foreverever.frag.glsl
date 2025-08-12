// New tanh_approx functions for both float and vec4
float tanh_approx(float x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// #define parameters for Brightness, Contrast, and Saturation
// Adjust these values to change the look of the shader
// The default values result in no change.
#define bcs vec3(-0.20, 1.50, 0.90) // (Brightness, Contrast, Saturation)

// #define parameters for screen rotation
#define rotationSpeed 0.025 // A value like 0.1 for slow, 1.0 for fast.
#define rotationDirection 1.0 // 1.0 for clockwise, -1.0 for counter-clockwise.

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Explicitly initialize all variables as per the Robust Tanh Conversion Method
    float i = 0.0;
    float d = 0.0;
    float s = 0.0;
    float n = 0.0;
    float t = iTime * 0.1;
    vec3 p = iResolution;
    
    // The output color 'o' and input coordinates 'u' are now 'fragColor' and 'fragCoord'
    // for standard GLSL syntax, and fragColor is initialized to 0.0.
    fragColor = vec4(0.0);
    vec2 u = (fragCoord - p.xy / 2.0) / p.y;

    // Apply rotation to the screen coordinates before the main loop
    float angle = iTime * rotationSpeed * rotationDirection;
    float c = cos(angle);
    float s_rot = sin(angle);
    mat2 rotMatrix = mat2(c, -s_rot, s_rot, c);
    u *= rotMatrix;

    u += vec2(cos(t * 0.3) * 0.2, sin(t * 0.2) * 0.15);

    // The main loop with converted logic
    for (i = 0.0; i++ < 1e2; d += s = 0.001 + abs(s) * 0.8, fragColor += 1.0 / max(s, 1E-6)) {
        for (
            p = vec3(u * d, d + t * 4.0),
            p.xy *= mat2(cos(0.02 * t - p.z * 0.1 + vec4(0, 33, 11, 0))),
            // Converted tanh() call using tanh_approx()
            s = tanh_approx(1.0 + p.y),
            n = 2.0;
            n < 8.0;
            n *= 1.37
        ) {
            s += abs(dot(step(1.0 / max(d, 1E-6), cos(t + p.z + p * n)), vec3(0.4))) / n;
        }
    }
    
    // Converted the final tanh() call and made the division robust.
    // The blue component has been increased to make it more visible.
     fragColor = tanh_approx(vec4(d / 15.0, d / 125.0, 1.50 / max(d, 1E-6), 0.0) * fragColor / 1e4 / max(length(u), 0.01));

    // Apply Brightness, Contrast, and Saturation
    // Brightness (bcs.x)
    vec3 outputColor = fragColor.rgb + bcs.x;
    
    // Contrast (bcs.y)
    outputColor = (outputColor - 0.5) * bcs.y + 0.5;

    // Saturation (bcs.z)
    float luma = dot(vec3(0.2126, 0.7152, 0.0722), outputColor);
    outputColor = luma + bcs.z * (outputColor - luma);

    // Final output to fragColor with applied BCS
    fragColor.rgb = outputColor;
}
