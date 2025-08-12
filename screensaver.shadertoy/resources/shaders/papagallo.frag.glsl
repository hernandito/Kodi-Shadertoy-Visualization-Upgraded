// --- Robust Tanh Conversion Method Start ---
// Robust approximation for tanh(x) suitable for GLSL ES 1.0
// Prevents issues with division by zero or very small numbers.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6; // Small epsilon to prevent division by zero.
    // The approximation used is x / (1.0 + |x|)
    // Using max(abs(x), EPSILON) in the denominator ensures it's never zero,
    // which is crucial for stability in lower-end GLSL versions.
    return x / (1.0 + max(abs(x), EPSILON));
}
// --- Robust Tanh Conversion Method End ---

// --- GLSL ES 1.0 Compatibility Functions Start ---
// Custom round function for GLSL ES 1.0, as 'round()' is not supported.
float custom_round(float x) {
    return floor(x + 0.5);
}
// --- GLSL ES 1.0 Compatibility Functions End ---

// CC0: Colorful failure
// Saw some art on mastodon. Thought I should try to recreate it.
// Failed and ended up with this instead

// Twigl link: https://twigl.app?ol=true&ss=-OTYXalxlI_QjCEpIDfF

// This shader has been modified for full compatibility with the Kodi Shadertoy addon,
// adhering to OpenGL ES 1.0 specifications and specific addon requirements.
//
// Key modifications include:
// - Implementation of 'tanh_approx' function to replace unsupported 'tanh'.
// - Explicit initialization of all declared variables.
// - Robust division by adding a small epsilon to denominators.
// - Manual implementation of complex matrix transformation to ensure GLSL ES 1.0 compatibility.
// - Replaced 'round()' function with 'custom_round()' for GLSL ES 1.0 compliance.
// - Added parameters for Brightness, Contrast, Saturation, Global Animation Speed,
//   Screen Zoom, Global Rotation Speed, and **Screen Center Offset (X and Y)**.
// - Assumes 'iResolution' and 'iTime' are implicitly available from the Kodi addon environment,
//   as 'uniform' declarations and 'iChannelTime' are stated as unsupported.
// - 'mainImage' signature and 'O' as output variable are preserved, consistent with
//   Kodi addon's behavior for Shadertoy shaders.

// --- PARAMETERS ---
// Adjust these #define values to control the shader's appearance and speed.

// Post-processing parameters for Brightness, Contrast, and Saturation (BCS)
#define POST_BRIGHTNESS 0.0      // Range: -1.0 (darker) to 1.0 (brighter). Default: 0.0
#define POST_CONTRAST   1.0      // Range: 0.0 (no contrast) to 2.0+ (high contrast). Default: 1.0
#define POST_SATURATION 1.0      // Range: 0.0 (grayscale) to 2.0+ (high saturation). Default: 1.0

// Global animation speed control
#define ANIMATION_SPEED 0.20     // Range: 0.0 (static) to 2.0+ (faster). Default: 1.0

// Screen zoom control
#define SCREEN_ZOOM     1.250     // Range: 0.1 (very zoomed out) to 5.0+ (very zoomed in). Default: 1.0

// Global rotation speed control (counter-clockwise relative to default direction)
// Angle is in radians per second. 0.0 disables rotation.
#define ROTATION_SPEED  0.05     // Example: 0.05 radians/second. Adjust for desired speed.

// Screen center offset
// Values are relative to screen height. E.g., 0.1 means 10% of screen height offset.
#define OFFSET_X        -0.50      // X-axis offset. Range: typically -0.5 to 0.5. Default: 0.0
#define OFFSET_Y        0.20      // Y-axis offset. Range: typically -0.5 to 0.5. Default: 0.0


void mainImage(out vec4 O, vec2 C) {
    // Explicitly initialize all variables to prevent undefined behavior.
    // This is a common source of artifacts and unpredictable behavior in GLSL ES 1.0.
    float s = 0.0; // Ray steps counter, initialized to zero
    float l = 0.0; // Layer counter for inner loop, initialized to zero
    float d = 0.0; // Distance to surface, initialized to zero
    float q = 0.0; // Quantized Z coordinate, initialized to zero
    float r = 0.0; // Ray distance (accumulated), initialized to zero
    float h = 0.1; // Slice thickness, explicitly initialized
    float t = iTime * ANIMATION_SPEED; // Time variable, scaled by ANIMATION_SPEED.

    // Initialize vec4 variables to zero.
    vec4 c = vec4(0.0); // Accumulated color
    vec4 p = vec4(0.0); // Current ray position
    vec4 x = vec4(0.0); // Transformed position for distance calculation

    // Calculate normalized screen coordinates (UVs)
    // C - 0.5 * R: Centers coordinates around (0,0)
    // / R.y: Normalizes to a square aspect ratio based on height (so Y goes from -0.5 to 0.5)
    vec2 uv = (C - iResolution.xy * 0.5) / iResolution.y;

    // --- APPLY GLOBAL OFFSET ---
    // Shift the effective center of the effect and the axis of rotation.
    // Subtracting the offset moves the content in the opposite direction of the offset.
    uv -= vec2(OFFSET_X, OFFSET_Y);

    // --- APPLY GLOBAL ROTATION ---
    // Calculate the current rotation angle based on time and speed.
    // We use -ROTATION_SPEED to achieve the requested opposite rotation direction.
    float angle = iTime * (-ROTATION_SPEED);
    float cos_angle = cos(angle);
    float sin_angle = sin(angle);

    // Apply the 2D rotation matrix to the UV coordinates (which are now offset).
    float rotated_uv_x = uv.x * cos_angle - uv.y * sin_angle;
    float rotated_uv_y = uv.x * sin_angle + uv.y * cos_angle;
    uv = vec2(rotated_uv_x, rotated_uv_y);
    // --- END GLOBAL ROTATION ---

    // --- APPLY SCREEN ZOOM ---
    // Apply zoom to the rotated and offset UVs.
    uv /= SCREEN_ZOOM;


    // Main raymarching loop - casts a ray from the camera and steps along it
    for (
        vec2 R = iResolution.xy; // R = screen resolution (assumed implicitly available from Kodi)
        ++s < 77.0; // Increment ray steps, loop for up to 77 steps to find surface
        r += 0.5 * d // Advance the ray by half the calculated distance to the surface
    ) {
        // Calculate the ray's 4D position from camera through this pixel
        // The 'uv' variable already incorporates the screen zoom, offset, and global rotation.
        p = r * normalize(vec3(uv, 1.0)).xyzx; // Use 'uv' directly for ray direction based on new scaling

        // Animate the scene by continuously moving along the Z axis over time
        p.z += t; // Use scaled time 't'

        // Quantize the Z coordinate to create distinct, repeating slices or layers.
        // This forms the core "layered" 3D structure of the scene.
        // Robust division: max(h, 1e-6) prevents division by zero if 'h' somehow becomes zero.
        // Using custom_round() instead of round()
        q = custom_round(p.z / max(h, 1e-6)) * h;

        // Inner loop: Samples multiple layers around the current quantized slice.
        // This technique helps reduce artifacts, especially when the space is twisted.
        // The original `d=l=3.` is expanded for explicit GLSL ES 1.0 compatibility.
        for (
            d = 3.0, l = 3.0; // Initialize both 'd' (for min operation) and 'l' (loop counter)
            l >= -2.0; // Loop iterates from l=3.0 down to l=-2.0 (5 layers)
            l-- // Decrement layer counter
        ) {
            // Start with the current ray position for this layer's transformation
            x = p;
            x.z -= q; // Offset Z to align with the current layer

            // --- GLSL ES 1.0 Compatibility Fix for `mat2(vec4)` constructor ---
            // The original shader uses `mat2(cos(vec4))` which is a compact but non-standard
            // way to construct a matrix, likely not supported or interpreted incorrectly
            // in GLSL ES 1.0. This section explicitly computes each matrix component and
            // applies the transformation manually to ensure compatibility and correctness.
            float current_angle_base = q + h * l;
            // The original `vec4(0,11,33,0)` implies these offsets for the matrix components.
            // Reconstructing the `mat2` elements based on these offsets.
            float m00 = cos(current_angle_base + 0.0);  // Top-left element
            float m10 = cos(current_angle_base + 11.0); // Bottom-left element (corresponds to .y in vec4 construction)
            float m01 = cos(current_angle_base + 33.0); // Top-right element (corresponds to .z in vec4 construction)
            float m11 = cos(current_angle_base + 0.0);  // Bottom-right element (corresponds to .w in vec4 construction)

            // Apply the matrix multiplication to the x.xy components of 'x'.
            float temp_x_val = x.x * m00 + x.y * m01;
            float temp_y_val = x.x * m10 + x.y * m11;
            x.x = temp_x_val;
            x.y = temp_y_val;
            // --- End GLSL ES 1.0 Compatibility Fix ---

            x.x = abs(x.x); // Mirror the X coordinate to create symmetry (e.g., a mirrored spiral)

            // Calculate the minimum distance to the procedural surface.
            // This defines the shape of the 3D objects being rendered (curved tubes).
            // 'max' is used for constructive solid geometry (CSG) operations or to define bounding shapes.
            d = min(d, max(length(x.xz - vec2(1.0 - 0.5 * sin(0.6 * (q + h * l) + x.y), h * l)) - 0.07, abs(x.y) - 4.0));
        }

        // Add a small offset to the distance to make the tubes appear slightly translucent,
        // allowing for more subtle color blending.
        d = abs(d) + 2e-3;

        // Calculate a color based on the current ray position and time.
        // This creates the dynamic, "colorful" and animated effect.
        p = 1.0 + sin(2.0 * length(p.xy) + p.z + vec4(0.0, 1.0, 2.0, 0.0) - t); // Use scaled time 't'

        // Accumulate color: Brighter when closer to the surface (smaller 'd').
        // 'p.w / d' creates an intensity falloff, multiplying by the color 'p'.
        // Robust division: max(d, 1e-6) prevents division by zero if 'd' is extremely small.
        c += p.w / max(d, 1e-6) * p;
    }

    // Apply tone mapping to prevent overexposure and compress the color range.
    // The accumulated color 'c' is scaled down by 1E4 and then passed through
    // the robust tanh approximation for a smooth, artistic compression.
    vec3 final_color = tanh_approx(c / 1e4).rgb; // Extract RGB for post-processing

    // --- APPLY BCS PARAMETERS ---
    // Adjust Brightness
    final_color += POST_BRIGHTNESS;

    // Adjust Contrast
    // Convert to luma (grayscale), then mix between luma and original color based on contrast.
    // This provides a more visually correct contrast adjustment than simple scaling.
    vec3 luma = vec3(dot(final_color, vec3(0.299, 0.587, 0.114))); // Standard BT.709 luma coefficients
    final_color = mix(luma, final_color, POST_CONTRAST);

    // Adjust Saturation
    // Convert to average grayscale, then mix between grayscale and original color based on saturation.
    vec3 avg_color = vec3(dot(final_color, vec3(0.333))); // Simple average for desaturation
    final_color = mix(avg_color, final_color, POST_SATURATION);

    // --- FINAL OUTPUT ---
    // Output color assigned to 'O', as expected by the Kodi addon.
    O = vec4(clamp(final_color, 0.0, 1.0), 1.0);
}