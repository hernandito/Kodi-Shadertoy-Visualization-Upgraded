// --- Global Parameters (Adjust these values to control the effect) ---
#define X_OFFSET -150.0        // Amount to shift the entire effect on the X-axis (pixels).
                               // Negative values shift left, positive values shift right.
#define Y_OFFSET 50.0          // Amount to shift the entire effect on the Y-axis (pixels).
                               // Negative values shift up, positive values shift down.
#define ROTATION_SPEED 0.05    // Speed of the global rotation. Smaller values are slower.
#define ROTATION_DIRECTION 1.0 // Direction of rotation: 1.0 for clockwise, -1.0 for counter-clockwise.

// --- Post-Processing BCS Parameters (Adjust these for final image look) ---
#define BRIGHTNESS -0.15         // Adjusts the overall brightness. 0.0 is no change, positive values brighten, negative values darken.
#define CONTRAST 1.05           // Adjusts the overall contrast. 1.0 is no change, values > 1.0 increase contrast, < 1.0 decrease.
#define SATURATION 1.0         // Adjusts the overall saturation. 1.0 is no change, values > 1.0 increase saturation, < 1.0 decrease.

// --- Core Shader Constants (from original code) ---
#define STEPS 16
#define LIGHT_SPEED 0.5
#define HARDNESS 2.0
// Note: The original shader implicitly used a scaling factor of 500.0 for UVs based on iResolution.yy.
// We'll keep this consistent.

// Structure to define a ray for raymarching.
struct ray {
    vec2 t; // Target point of the ray (e.g., light source position)
    vec2 p; // Current position of the ray during marching
    vec2 d; // Direction vector of the ray per step
};

/**
 * @brief Defines the 2D signed distance field for the cube-like shape.
 * This function is now exactly as in the original code, without mouse interaction.
 * It expects 'p' to be the pixel coordinate in the effect's local space.
 *
 * @param p The 2D coordinate for which to calculate the scene value.
 * @return A float representing the scene's density at point 'p'.
 */
float scene (in vec2 p) {
    // Offset 'p' relative to the cube's internal origin (400,250).
    p -= vec2 (400,250);

    // Apply internal time-based rotation for the cube's pattern.
    float sn = sin (iTime / 2.0);
    float cs = cos (iTime / 2.0);

    // Define the cube's shape using dot products.
    float f1 = dot (vec2 (sn,-cs), p);
    float f2 = dot (vec2 (cs, sn), p);
    float f = max (f1*f1, f2*f2);

    // Original line for mouse interaction, now commented out as per request.
    // p -= iMouse.xy / iResolution.yy * vec2 (500, 500) - vec2 (400,250);

    // Combine with a circular shape to refine the appearance.
    f = min (f, dot (p, p) * 2.0);

    // Return a value representing the density of the scene at 'p'.
    return 1000.0 / (f + 1000.0);
}

/**
 * @brief Initializes a new ray for raymarching.
 *
 * @param origin The starting point of the ray.
 * @param target The target point the ray is marching towards (e.g., a light source).
 * @return An initialized 'ray' struct.
 */
ray newRay (in vec2 origin, in vec2 target) {
    ray r;
    r.t = target; // Store the target point
    r.p = origin; // Set the ray's current position to its origin
    // Calculate the direction vector for each step.
    r.d = (target - origin) / float (STEPS);
    return r;
}

/**
 * @brief Performs a single step of raymarching.
 * This function is now exactly as in the original code.
 *
 * Moves the ray's current position 'r.p' towards its target based on the
 * scene's density at 'r.p'. This simulates the ray bending around the cube.
 *
 * @param r The ray to march (passed by reference to modify its position).
 */
void rayMarch (inout ray r) {
    // Adjust the ray's position based on the scene's density.
    r.p += r.d * clamp (HARDNESS - scene (r.p) * HARDNESS * 2.0, 0.0, LIGHT_SPEED);
}

/**
 * @brief Calculates the intensity of light at a point.
 *
 * @param r The ray struct, where 'r.p' is the final position after raymarching
 * and 'r.t' is the light source position.
 * @param color The base color and intensity of the light source.
 * @return A vec3 representing the attenuated light color.
 */
vec3 light (in ray r, in vec3 color) {
    // Light intensity decreases with the squared distance from the light source (r.t).
    return color / (dot (r.p, r.p) + color);
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
 * Calculates the final color for each pixel on the screen.
 * Global transformations (shift and rotation) are applied here to `fragCoord`
 * before it's used to calculate the `uv` for the rest of the shader.
 * BCS adjustments are applied as a final post-processing step.
 *
 * @param fragColor The output color of the pixel.
 * @param fragCoord The screen-space coordinate of the current pixel.
 */
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    // --- 1. Apply Global Offset to the raw fragment coordinates ---
    // This shifts the entire rendering grid (and thus the effect) horizontally and vertically.
    vec2 offsetFragCoord = fragCoord.xy + vec2(X_OFFSET, Y_OFFSET);

    // --- 2. Define the rotation pivot (center of the *original* screen) ---
    // We want to rotate the *entire output* as if it's a texture on a screen.
    // The rotation should happen around the center of the screen, not the shifted content's center.
    // So, the pivot is the original screen center in pixel coordinates.
    vec2 rotationPivot = iResolution.xy * 0.5;

    // --- 3. Apply Global Rotation to the *offset* fragment coordinates ---
    // Translate the offsetFragCoord to the origin relative to the rotationPivot,
    // apply the rotation, then translate it back.
    vec2 rotatedOffsetFragCoord = offsetFragCoord - rotationPivot; // Translate to origin
    float angle = iTime * ROTATION_SPEED * ROTATION_DIRECTION;     // Calculate rotation angle
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)); // Create 2D rotation matrix
    rotatedOffsetFragCoord = rotationMatrix * rotatedOffsetFragCoord; // Apply rotation
    rotatedOffsetFragCoord += rotationPivot; // Translate back

    // --- 4. Calculate the UV coordinate using the final transformed fragment coordinate ---
    // This `uv` now represents the pixel's position within the shifted and rotated view.
    vec2 uv = rotatedOffsetFragCoord / iResolution.yy * vec2 (500, 500);

    // --- 5. Initialize rays with the transformed UV and fixed light targets ---
    // The light targets (600, 250) and (200, 250) remain fixed in their original coordinate system.
    // Since `uv` is already transformed, the rays correctly originate from the
    // transformed pixel and march towards these fixed light points.
    ray r0 = newRay (uv, vec2 (600, 250));
    ray r1 = newRay (uv, vec2 (200, 250));

    // --- 6. Perform raymarching for both rays ---
    // The `rayMarch` function calls `scene(r.p)`, where `r.p` is derived from `uv`,
    // which is already globally transformed.
    for (int i = 0; i < STEPS; i++) {
        rayMarch (r0);
        rayMarch (r1);
    }

    // --- 7. Calculate light contributions ---
    r0.p -= r0.t;
    r1.p -= r1.t;

    vec3 light1 = light (r0, vec3 (0.3, 0.2, 0.1) * 20000.0);
    vec3 light2 = light (r1, vec3 (0.1, 0.2, 0.3) * 10000.0);

    // --- 8. Calculate the final scene density using the transformed UV ---
    float f = clamp (scene (uv) * 200.0 - 100.0, 0.0, 3.0);

    // --- 9. Combine light and scene density for the raw pixel color ---
    vec3 finalColor = (light1 + light2) * (1.0 + f);

    // --- 10. Apply Post-Processing: Brightness, Contrast, Saturation ---
    finalColor = applyBCS(finalColor, BRIGHTNESS, CONTRAST, SATURATION);

    // --- 11. Assign the final color to the fragment output ---
    fragColor = vec4 (finalColor, 1.0);
}
