// I originally saw this noise function in Elsio's shaders
// It's explained a bit here
// https://www.shadertoy.com/view/WcXGRM
// And it's really nicely on display here
// https://www.shadertoy.com/view/M3yBWK

// It has a neat effect when used without diffuse lighting
// It looks like a cloud or fluffy smoke thing

// Hold down lmb to make it angrier :D

// --- Animation Speed Control ---
// Adjusts the overall speed of the animation.
// 1.0 is normal speed, values > 1.0 make it faster, < 1.0 make it slower.
#define ANIMATION_SPEED .20

#define T (iTime * 1.8 * ANIMATION_SPEED) // iTime is now scaled by ANIMATION_SPEED
#define m iMouse

// --- Post-Processing BCS Parameters (Adjust these for final image look) ---
#define BRIGHTNESS -0.450         // Adjusts the overall brightness. 0.0 is no change, positive values brighten, negative values darken.
#define CONTRAST 1.7           // Adjusts the overall contrast. 1.0 is no change, values > 1.0 increase contrast, < 1.0 decrease.
#define SATURATION 1.0         // Adjusts the overall saturation. 1.0 is no change, values > 1.0 increase saturation, < 1.0 decrease.
#define MAX_WHITE_VALUE 0.8 // Add this line. Adjust 1.0 to your desired maximum white (e.g., 0.8 for less intense whites).

// --- Robust Tanh Conversion Method ---
// Approximation of tanh(x)
// The denominator 1.0 + abs(x) ensures robustness against division by zero.
float tanh_approx(float x) {
    return x / (1.0 + abs(x));
}

// Helper function to apply scaled tanh_approx.
// The scale_factor is crucial for mimicking the saturation behavior of the original tanh.
float scaled_tanh_approx(float x, float scale_factor) {
    return tanh_approx(x * scale_factor);
}
// --- End Robust Tanh Conversion Method ---

/**
 * @brief Defines the path for the camera/light source.
 * This function now uses the `tanh_approx` function with carefully chosen
 * scaling factors to mimic the original `tanh` behavior for Kodi compatibility.
 *
 * @param zd A depth-related parameter that influences the path.
 * @return A vec3 representing a point in 3D space for the path.
 */
vec3 path(float zd) {
    float t = T * 5.; // T already incorporates ANIMATION_SPEED
    return vec3(
        // Original: tanh(cos(t * .08) * 1.) * 5.3
        // Input to tanh is in [-1, 1]. scaled_tanh_approx with factor ~3.2 matches tanh(1).
        scaled_tanh_approx(cos(t * .08) * 1., 3.2) * 5.3,
        // Original: tanh(cos(t * .05) * 4.) * 1.3
        // Input to tanh is in [-4, 4]. Use a larger scale factor to push towards saturation.
        scaled_tanh_approx(cos(t * .05) * 4., 5.0) * 1.3,
        // Original: zd + T + tanh(cos(T * zd / 20.) * zd / 2.) * zd * .5
        // Input to tanh is around [-3.15, 3.15]. Use a larger scale factor for saturation.
        zd + T + scaled_tanh_approx(cos(T * zd / 20.) * zd / 2., 5.0) * zd * .5);
}

/**
 * @brief Applies Brightness, Contrast, and Saturation adjustments to a color.
 *
 * @param color The input RGB color.
 * @param brightness The brightness adjustment.
 * @param contrast The contrast adjustment.
 * @param saturation The saturation adjustment.
 * @return The adjusted RGB color.
 */
vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color += brightness;

    // Apply contrast
    // Midpoint for contrast adjustment is 0.5 (gray).
    color = ((color - 0.5) * contrast) + 0.5;

    // Apply saturation
    // Convert to grayscale (luminance)
    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    // Interpolate between grayscale and original color based on saturation
    color = mix(vec3(luminance), color, saturation);

    return color;
}
 	
/**
 * @brief The main shader entry point.
 *
 * This function calculates the final color for each pixel on the screen,
 * simulating a raymarching effect through a noise field.
 * Post-processing BCS adjustments are applied as a final step.
 *
 * @param o The output color of the pixel.
 * @param u The screen-space coordinate of the current pixel.
 */
void mainImage(out vec4 o, in vec2 u) {
    vec2 r = iResolution.xy; 
    // Normalize fragment coordinates to [-aspect_ratio/2, aspect_ratio/2] range
    u = (u - r.xy / 2.) / r.y;

    vec3 p,
         ro = vec3(0.,0.,T), // Ray origin, moving along Z-axis with time (scaled by ANIMATION_SPEED)
         la = path(6.3);    // Look-at target, determined by the path function

    // Calculate camera basis vectors
    vec3 laz = normalize(la - ro); // Z-axis (forward)
    vec3 lax = normalize(cross(laz, vec3(0., -1., 0))); // X-axis (right)
    vec3 lay = cross(lax, laz); // Y-axis (up)

    // Ray direction based on normalized fragment coordinates and camera basis
    vec3 rd = vec3(u, 1.) * mat3(-lax, lay, laz) * .1;

    float d = 0., od1; // d: current distance, od1: distance to target sphere

    // Raymarching loop
    for (float i = 0.; i < 100.; i++) {
        p = ro + rd * d; // Current point along the ray

        od1 = length(p - la) - 1.3; // Distance to a sphere centered at 'la' with radius 1.3

        float hit = od1;
        // Limit the raymarch by the vertical distance from the ray origin
        hit = min(hit, 4. - length(p.y - ro.y));
     	
        float n = 0.;
        // Apply a noise function based on 'p'
        // This loop generates a sum of absolute sine waves at different frequencies,
        // creating a cloud-like effect.
        for (float a = .2; a < 8.;
            n -= abs(dot(sin(p * a * 4.), vec3( .08))) / a,
            a += a);
        
        float s = hit + n; // Combined distance field value
     	
        d += s; // Advance the ray by the step 's'
        // Break conditions: if ray goes too far or step size is too small (hit a surface)
        if (d > 100. || s < .01) {
            break;
        }
    }

    // Calculate 'f' based on time and a highly saturated tanh approximation
    // Original: abs(tanh(cos(T*1.)*13.))
    // Input to tanh is in [-13, 13]. This requires a significantly larger scale factor
    // to approximate the strong saturation of tanh for large inputs.
    float f = abs(scaled_tanh_approx(cos(T*1.)*13., 20.0)) +
              sin(T*2.)+cos(T*1.)+sin(T*.5)
              *.04+sin(T); // T already incorporates ANIMATION_SPEED

    // Clamp 'l' (light intensity factor) based on 'f'
    vec3 l = clamp(vec3(1./f),vec3(.5),vec3(5.));

    // Determine base RGB color based on mouse button state
    // If left mouse button is held down (m.z > 40.0), use 'l/od1' for a more "angry" look,
    // otherwise use vec3(1.) (white).
    vec3 rgb = m.z > 40. ?
               vec3(l/od1) : vec3(1.);
    
    // Apply a base color tint
    rgb *= vec3(.4, .3, .2);

    // Final color calculation: power function for gamma correction/contrast,
    // and a vignette effect based on fragment distance from center.
    vec3 finalColor = pow(vec3(rgb * d / (od1 * 30.)), vec3(.45));

    // --- Apply Post-Processing: Brightness, Contrast, Saturation ---
    finalColor = applyBCS(finalColor, BRIGHTNESS, CONTRAST, SATURATION);

    // Apply vignette
    finalColor -= dot(u,u)*.2;

	finalColor = clamp(finalColor, 0.0, MAX_WHITE_VALUE);

    // Output the final color
    o = vec4(finalColor, 1.);
}
