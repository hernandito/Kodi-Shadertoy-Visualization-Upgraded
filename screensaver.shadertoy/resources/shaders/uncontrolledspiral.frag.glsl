// CC0: Spiralling out of control (Kodi-compatible version)
// I wanted to try something else than a spiral but ended up with one anyway

// Define BCS parameters
#define BRIGHTNESS .80    // Adjust brightness (1.0 is neutral)
#define CONTRAST 1.4      // Adjust contrast (1.0 is neutral)
#define SATURATION 1.20    // Adjust saturation (1.0 is neutral)


// Define X and Y offset parameters
#define X_OFFSET -0.2       // X offset for the effect center (e.g., -0.2 to 0.2)
#define Y_OFFSET 0.1       // Y offset for the effect center (e.g., -0.2 to 0.2)

// Robust tanh approximation function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Gyroid distance field function
float g(vec4 p, float s) {
    return abs(dot(sin(p * s), cos(p.zxwy)) - 1.0) / s;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Explicitly initialize all variables
    float i = 0.0;     // Loop counter (iteration count)
    float z = 0.0;     // Distance traveled along the ray
    float Y = 0.0;     // Temporary variable for calculations
    float D = 0.0;     // Distance to the nearest surface
    vec4 O = vec4(0.0); // Accumulated color (starts at 0,0,0,0)
    vec4 p = vec4(0.0); // Current 3D position we're checking

    // Define the maximum number of iterations
    const int MAX_ITERATIONS = 80;

    // Main rendering loop - this is "raymarching"
    // We shoot a ray from the camera and step along it
    for (int j = 0; j < MAX_ITERATIONS; j++) {
        i = float(j);  // Convert loop counter to float for calculations
        vec2 r = iResolution.xy;    // Screen resolution (width, height)

        // Apply X and Y offsets to the fragment coordinates
        vec2 offsetCoord = fragCoord + vec2(X_OFFSET * r.x, Y_OFFSET * r.y);

        // Convert screen coordinates to 3D ray direction with offsets
        p = z * normalize(vec3(offsetCoord - 0.5 * r, r.y)).xyzy;
        p.z += iTime * 0.7;  // Add time to z-coordinate to create forward motion

        // Create watery like distortion
        D = g(p, 23.0) + g(p, 11.0) + g(p, 7.0);

        // Rotate the xy coordinates over time - this creates the spiral twist
        p.xy *= mat2(cos(0.3 * iTime * 0.2 + 0.4 * p.z + vec4(0, 11, 33, 0)));

        // The width of the spiral varies with depth
        Y = 0.9 + 0.5 * sin(0.5 * p.z);
        // Create the spiral walls and distort them with robust division
        z += Y = 1e-3 + 0.6 * abs(Y * abs(p.x / max(Y, 1e-6) - floor(max(p.x / max(Y, 1e-6), 1.0) + 0.5)) + D / 9.0 - 0.1);

        // Points closer to the center axis are brighter
        Y *= 0.9 + dot(p.xy, p.xy) / 4.0;

        // Generate the final color using sine waves
        p = 1.0 + sin(4.0 * p.x + p.y + vec4(7, 3, 23, 7) / 4.0);

        // Add color to our accumulated result with robust division
        O += (p.w / max(Y, 1e-6)) * p;
    }

    // Apply BCS adjustments
    vec4 color = tanh_approx((O + z * z * z * vec4(6, 4, 2, 0)) / 9e3);

    // Brightness adjustment
    color.rgb *= BRIGHTNESS;

    // Contrast adjustment
    color.rgb = (color.rgb - 0.5) * CONTRAST + 0.5;

    // Saturation adjustment
    vec3 luminance = vec3(0.299, 0.587, 0.114);
    vec3 gray = vec3(dot(color.rgb, luminance));
    color.rgb = mix(gray, color.rgb, SATURATION);

    // Final color output
    fragColor = color;
}