// CC0: Glowing mountain lines
// Playing around with @XorDev's dot noise function
// Not what I intended, but it works

// Twigl: https://twigl.app?ol=true&ss=-OZ0M95iFPCSAPdqq9Lt

// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 1.0
#define CONTRAST   1.6
#define SATURATION 1.0

vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    // Brightness
    color += brightness - 1.0;
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    // Saturation
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

// Shader entry point: O = output color, C = pixel coordinates
void mainImage(out vec4 O, vec2 C) {
    float
        a = 0.0,      // Amplitude for noise octaves
        d = 0.0,      // Distance field value
        i = 0.0;      // Ray marching step counter
    
    vec3
        p = vec3(0.0),      // Current 3D position being sampled
        Z = iResolution,    // Screen resolution
        I = normalize(vec3(C, Z.y) - 0.5 * Z);  // Ray direction from camera
    
    vec4 o = vec4(0.0); // Accumulated color output
    
    // Main raymarching loop - march ray through 3D space
    for(
        Z = vec3(0.0, 0.0, fract(-iTime) / max(I.z, 1e-6));  // Ray position (raymarching state)
        ++i < 60.0;
        Z += 1.0 / max(abs(I), vec3(1e-6)) // Step along ray direction
    )
        // Sample at two different Z depths (j=0 and j=2, skipping j=1)
        for(
            int j = 0;
            j < 3;
            j += 2
        ) {
            // Calculate 3D world position
            p = Z[j] * I;
            p.z += iTime;    // Move forward with time

            p *= 0.125;        // Scale down the sampling space
            d = p.y;         // Start with Y coordinate as base
            O = 1.0 + sin(0.5 * p.x + p.z + vec4(2.0, 1.0, 0.0, 2.0));  // Color based on position

            // Generate fractal noise with 3 octaves
            for(
                a = 0.6;      // Initial amplitude
                a > 0.1;      // Gives 3 amplitudes
                p = p.yzx     // Rotate coordinates (x->y, y->z, z->x)
            )
                // Dot noise by XorDev found here: https://www.shadertoy.com/view/wfsyRX
                d += a + a * dot(sin(p), cos(p * 1.618).yzx),  // Add noise octave
                a *= 0.5,                                      // Halve amplitude each octave
                p.yz *= 0.2 * mat2(6.0, 8.0, -8.0, 6.0);       // Scale & rotate Y,Z coordinates

            // Convert to distance field and add fog effect
            d = abs(d) + 5e-4 / max(I[j] * I[j], 1e-6) + 0.01 * smoothstep(10.0, 60.0, Z[j]);
            // Accumulate color contribution (volumetric rendering)
            o += O.w / max(d, 1e-6) * O * smoothstep(60.0, 40.0, Z[j]);
        }
    
    // Apply tone mapping to prevent color overflow
    O = tanh_approx(o / 500.0);

    // Apply BCS post-processing
    O.rgb = bcs(O.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}