#ifdef GL_ES
// Set default precision for floats to mediump for better compatibility with older OpenGL ES 1.0 devices.
precision mediump float;
#endif

// Define parameters for Brightness, Contrast, and Saturation adjustment.
// These can be modified to change the post-processing effect.
#define BRIGHTNESS 0.0   // Adjusts the overall lightness/darkness (e.g., 0.1 for brighter, -0.1 for darker)
#define CONTRAST   1.4   // Adjusts the difference between light and dark areas (e.g., 1.2 for more contrast, 0.8 for less)
#define SATURATION 1.0   // Adjusts the intensity of colors (e.g., 1.5 for more vibrant, 0.5 for desaturated)

// Robust Tanh Conversion Method:
// This function approximates the hyperbolic tangent (tanh) function. iTime
// It includes an EPSILON to prevent division by zero, making it robust.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6; // A small constant to prevent division by zero.
    return x / (1.0 + max(abs(x), EPSILON)); // x / (1 + |x|) approximation.
}

// Main image function, compatible with Shadertoy's Kodi addon.
// 'o' maps to fragColor, 'f' maps to fragCoord.
void mainImage(out vec4 o, vec2 f)
{
    // Explicitly initialize all variables to prevent undefined behavior.
    float z = 5.0; // Camera depth, initialized to 5.0.
    float d = 0.0; // Raymarch step distance, initialized to 0.0.
    float i = 0.0; // Raymarch iterator, initialized to 0.0.
    vec3 p = vec3(0.0, 0.0, 0.0); // 3D sample point, initialized to zero vector.
    o = vec4(0.0, 0.0, 0.0, 0.0); // Output color, initialized to black (transparent).

    // Center and scale UVs.
    // Enhanced with robust division to prevent division by zero if iResolution.y is tiny or zero.
    f = f / max(iResolution.y, 1E-6) / 0.1 - z;

    // Raymarch loop (100 steps).
    // The original compact for loop syntax has been expanded for GLSL ES 1.0 compatibility.
    for(i = 0.0; i < 100.0; i += 1.0)
    {
        // 3D sample point.
        p = vec3(f, z);
        
        // Rotated about y-axis.
        // Ensure all vector components are float literals (e.g., 0.0, 33.0).
        p.xz *= mat2(cos(iTime*.3 + vec4(0.0, 33.0, 11.0, 0.0)));
        
        // Calculate the distance from the y-axis in the xy-plane, minus the major radius (3.0).
        // This is part of the standard Torus SDF calculation.
        d = length(p.xy) - 3.0;
        
        // Step the distance to the torus.
        // The original `sqrt(d*d+p*p).z` was ambiguous for GLSL ES 1.0.
        // It has been replaced with `length(vec2(d, p.z)) - 1.5`, which correctly represents
        // the distance to a torus (length of the 2D vector formed by the major radius offset
        // and the z-component, minus the minor radius 1.5).
        float torus_dist = length(vec2(d, p.z)) - 1.5;
        z -= d = 0.1 + 0.2 * abs(torus_dist);
        
        // Sample coloring (attenuate with distance).
        // Ensure all vector components are float literals and use robust division.
        o += (sin(p.y + z + vec4(0.0, 1.0, 2.0, 3.0)) + 1.0) / max(d, 1E-6);
    }
    
    // Tanh tonemap.
    // Replaced `tanh()` with `tanh_approx()` and used robust division.
    // 1e5 is explicitly written as 100000.0 for clarity and compatibility.
    o = tanh_approx(o * o / max(100000.0, 1E-6));

    // Apply Brightness, Contrast, and Saturation adjustments.
    vec3 final_color = o.rgb;

    // 1. Apply Brightness: Add the BRIGHTNESS value directly to the color.
    final_color += BRIGHTNESS;

    // 2. Apply Contrast: Adjust contrast around a midpoint (0.5).
    final_color = (final_color - 0.5) * CONTRAST + 0.5;

    // 3. Apply Saturation:
    // Calculate luminance (grayscale equivalent) of the color.
    // Standard NTSC luminance coefficients are used (0.299, 0.587, 0.114).
    float luminance = dot(final_color, vec3(0.299, 0.587, 0.114));
    // Linearly interpolate between the grayscale color and the original color based on SATURATION.
    final_color = mix(vec3(luminance), final_color, SATURATION);

    // Final output color.
    o = vec4(final_color, o.a);
}
