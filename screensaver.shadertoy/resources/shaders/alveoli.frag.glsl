// CC0: Trailing the Twinkling Tunnelwisp
//  A bit of Saturday coding (also Norway’s Constitution Day).
//  Some artifacts remain, but it’s good enough for my standards.

//  Music by Pestis created for Cassini's Cosmic Conclusion
//   https://demozoo.org/productions/367582/

// For those that like it as a twigl: https://twigl.app?ol=true&ss=-OQcCGG943U4cNdWOlAG

// --- OpenGL ES 1.0 Compatible tanh approximation ---
vec4 tanh_approx(vec4 x) {
    // Approximation of tanh(x) = x / (1.0 + abs(x))
    return x / (1.0 + abs(x)); // Use 1.0 for clarity
}

// --- Post-processing functions for better output control ---
vec4 saturate(vec4 color, float sat) {
    // Adjusts color saturation
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    // Applies brightness, contrast, and saturation adjustments
    color.rgb = (color.rgb - 0.5) * contrast + 0.5; // Use 0.5 for clarity
    color.rgb *= brightness;
    return saturate(color, saturation);
}

// Distance field for gyroid, adapted from Paul Karlik's "Gyroid Travel" in KodeLife
//  Tweaked slightly for this effect
float g(vec4 p,float s) {
    // Makes it nicer (IMO) but costs bytes!
    // p.x=-abs(p.x);
    return abs(dot(sin(p*s),cos(p.zxwy))-1.0)/s; // Use 1.0 for clarity
}

// --- Glow Denominator Epsilon Parameter ---
// Adjust this value to control the smoothing of sharp details.
// Increase the value to smooth out intricate areas and reduce pixelation.
// Decrease the value to reveal more fine details (may increase pixelation).
float glow_denominator_epsilon = 0.003; // Increased default epsilon from 0.0001
// ------------------------------------------

// --- Post-processing Parameters (BCS) ---
// Adjust these values to fine-tune the final image appearance AFTER tone mapping
float post_brightness = 2.0;     // Increase for brighter image, decrease for darker
float post_contrast = 1.10;      // Increase for more contrast, decrease for less
float post_saturation = 1.0;     // Increase for more saturated colors, decrease for less
// ----------------------------------------

// --- Glow Pulse Minimum Brightness ---
// Adjust this value to control how dark the pulsing glow becomes.
// Higher values will prevent it from going fully dark.
float glow_pulse_min = 0.6; // Adjust this value (original was effectively lower)
// -------------------------------------

// --- Horizon Offset Parameter ---
// Adjust this value to lower or raise the horizon line.
// Increase the value to lower the horizon (see more of the top/sky).
// Decrease the value to raise the horizon (see more of the floor).
float horizon_offset = -0.50; // Adjust this value to shift the horizon
// ---------------------------------


void mainImage(out vec4 O,vec2 C){
    // Raymarch iterator, step distance, depth, sign of q.y + 0.1, and Time
    float i;
    float d = 0.0; // Initialize step distance
    // --- Initial raymarch depth ---
    // Starting depth (reverted to original starting point)
    float z = 0.750; // Adjusted initial z
    // ---------------------------------------
    float s;
    float T = iTime;

    // Declare variables used in the loop before the loop
    vec4 o = vec4(0.0); // Initialize accumulated color
    vec4 q = vec4(0.0); // Initialize q here to be accessible after the loop
    vec4 p; // Use a single variable 'p' as in the original, but be mindful of its state
    vec4 U = vec4(2.0, 1.0, 0.0, 3.0); // Use explicit floats

    // Store resolution
    vec2 r = iResolution.xy;

    // Raymarch loop (standardized structure)
    // Step through the scene, up to 78 steps
    for (i = 0.0; i < 78.0; i += 1.0) // Converted to standard for loop
    {
        // The order of operations matters here, replicating the original loop header
        // Advance along the ray by current distance estimate (+ epsilon)
        // The epsilon makes the cave walls somewhat translucent
        z += d + 0.0005; // Use explicit float

        // Compute ray direction, scaled by distance
        // --- Adjust Camera Field of View (FOV) and Apply Horizon Offset ---
        // Adjust the '2.0' value here for FOV:
        // Increase the value to narrow the FOV (zoom in).
        // Decrease the value to widen the FOV (zoom out).
        // Subtract horizon_offset from the y-component to lower the horizon.
        vec3 ray_dir_base = vec3((C+C-r)/r.y, 2.0); // FOV factor
        ray_dir_base.y -= horizon_offset; // Apply horizon offset
        q = vec4(normalize(ray_dir_base) * z, 0.2);
        // -------------------------------------------------------------------

        // Traverse through the cave
        q.z += T/30.0; // Use explicit float

        // Save sign before mirroring
        s = q.y + 0.1; // Use explicit float

        // Creates the water reflection effect
        q.y = abs(s);

        // --- Position transformations for distance calculation ---
        // Reusing 'p' as in the original, applying transformations sequentially
        p = q; // Start with q
        p.y -= 0.11; // Apply first y offset

        // Twist cave walls based on depth
        // Using the full mat2 definition for clarity and compatibility
        float angle = -2.0 * p.z + 11.0 * U.z; // Use explicit floats
        mat2 twist_mat = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
        p.xy = twist_mat * p.xy; // Apply rotation

        p.y -= 0.2; // Apply second y offset

        // Combine gyroid fields at multiple scales for more detail
        // --- Adjust Curtain Size and Frequency ---
        // Adjust the scaling factors (8.0, 24.0, and the new 48.0) and the final divisor (4.0):
        // Decrease the scaling factors to make the curtains larger and fewer.
        // Increase the scaling factors to make the curtains smaller and more numerous.
        // Decrease the final divisor to make the curtains larger.
        // Increase the final divisor to make the curtains smaller.
        // --- Explicitly cast p to vec4 for the g function calls ---
        vec4 g_pos = p; // Create a temporary vec4 from the current state of p
        // Added a third term for more detail at a higher frequency
        d = abs(g(vec4(p),8.0) - g(vec4(p),24.0)) / 4.0 + abs(g(vec4(p),48.0)) / 12.0; // Added third gyroid scale
        // -----------------------------------------

        // --- Base glow color calculation ---
        // Replicate original's reuse of 'p' for glow color calculation based on q.z
        vec4 glow_color_pos = vec4(0.0, 0.0, q.z, 0.0); // Use q.z for glow color position
        vec4 glow_color = 1.0 + cos(0.7 * U + 5.0 * glow_color_pos.z); // Calculate glow based on q.z

        // Accumulate glow — brighter and sharper if not mirrored (above axis)
        float glow_factor = (s > 0.0) ? 1.0 : 0.1; // Use explicit floats
        float denominator = (s > 0.0) ? d : d*d*d;
        // --- Applied glow_denominator_epsilon for smoothing ---
        // Added the epsilon parameter to the max function
        o += glow_factor * glow_color.w * glow_color / max(denominator, glow_denominator_epsilon); // Used glow_denominator_epsilon
        // ----------------------------------------------------
    }

    // Add pulsing glow for the “tunnelwisp”
    // Use explicit float and handle potential division by zero.
    // q is available here because it was declared before the loop.
    // --- Modified pulsing glow to use glow_pulse_min ---
    float pulse = glow_pulse_min + 0.5 * (1.0 + sin(T) * sin(1.7 * T) * sin(1.3 * T));
    o += pulse * 1000.0 * U / max(length(q.xy), 0.0001); // Modified pulsing glow
    // ---------------------------------------------------------------------

    // Apply tanh for soft tone mapping
    // Replaced tanh with tanh_approx and adjusted the divisor
    O = tanh_approx(o / 100000.0); // Use explicit float and adjusted divisor

    // --- Apply Post-processing (BCS) ---
    O = applyPostProcessing(O, post_brightness, post_contrast, post_saturation);
    // -----------------------------------

    // Final clamp to ensure valid output range
    O = clamp(O, 0.0, 1.0); // Use 0.0, 1.0 for clarity
}
