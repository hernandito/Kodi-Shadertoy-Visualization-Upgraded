// --- Universal BCS Post-processing Snippet ---
// This snippet applies Brightness, Contrast, and Saturation (BCS) adjustments to the final color
// of a shader. It can be dropped at the end of the shader code, right before the final output
// line (e.g., fragColor = ..., O = ...). It works with both vec3 and vec4 color outputs.

// === How to Use This Snippet ===
// 1. **Paste the Snippet**: Copy this entire block and paste it right before the final output line
//    in your shader. The final output line is typically where the shader sets fragColor or O.
// 2. **Identify the Output Variable**: Look at the last line of your shader to see what variable
//    is being set (e.g., fragColor, O, col). Also note its type (vec3 or vec4).
// 3. **Choose the Correct Application Line**: Uncomment the appropriate line below based on your
//    shader's output variable and type. Adjust the variable name to match your shader's output.
// 4. **Tweak BCS Parameters**: Adjust post_brightness, post_contrast, and post_saturation to
//    fine-tune the image appearance. See suggestions below.
// 5. **Optional Clamp**: If your shader doesn't already clamp the output, add a clamp after the
//    BCS application (e.g., fragColor = clamp(fragColor, 0.0, 1.0);).

// === BCS Parameters ===
// Brightness: -1.0 to 1.0 (0.0 = no change, positive brightens, negative darkens)
// Contrast: 0.0 to 2.0 (1.0 = no change, higher increases contrast, lower reduces)
// Saturation: 0.0 to 2.0 (1.0 = no change, 0.0 = grayscale, higher increases saturation)
const float post_brightness = -0.10; // Default: no change
const float post_contrast = 1.20;   // Default: no change
const float post_saturation = 1.0; // Default: no change

// === Suggested Adjustments ===
// - If the image looks washed out on your TV:
//   - post_brightness = 0.2 (slight brightening)
//   - post_contrast = 1.2 (increase contrast)
//   - post_saturation = 1.3 (boost colors)
// - If the image is too dark:
//   - post_brightness = 0.3 to 0.5 (brighten more)
// - If colors are too muted:
//   - post_saturation = 1.5 (more vibrant colors)

// === Apply BCS Adjustments to a vec3 Color ===
vec3 applyBCS(vec3 col) {
    // Apply brightness
    col = clamp(col + post_brightness, 0.0, 1.0);

    // Apply contrast
    col = clamp((col - 0.5) * post_contrast + 0.5, 0.0, 1.0);

    // Apply saturation
    vec3 grayscale = vec3(dot(col, vec3(0.299, 0.587, 0.114))); // Luminance
    col = mix(grayscale, col, post_saturation);

    return col;
}

// === Apply BCS to the Final Color ===
// Uncomment the line that matches your shader's output variable and type.
// Adjust the variable name (e.g., fragColor, O, col) to match your shader.

// Example 1: For vec4 output named 'fragColor' (common in Shadertoy shaders)
// fragColor.rgb = applyBCS(fragColor.rgb);

// Example 2: For vec3 output named 'O' (some shaders use O as a vec3)
// O = applyBCS(O);

// Example 3: For vec4 output named 'O' (some shaders use O as a vec4)
// O.rgb = applyBCS(O.rgb);

// Example 4: For vec3 output named 'col' (if the shader uses a custom variable)
// col = applyBCS(col);

// Example 5: For vec4 output named 'finalColor' (another possible variable name)
// finalColor.rgb = applyBCS(finalColor.rgb);

// === Full Example with fragColor (vec4) ===
// If your shader's last lines look like this:
//     fragColor = vec4(color, 1.0);
//     fragColor *= smoothstep(2.1, .7, dist);
// You would add the snippet here and use:
//     fragColor.rgb = applyBCS(fragColor.rgb);
// Final code would look like:
//     fragColor = vec4(color, 1.0);
//     fragColor *= smoothstep(2.1, .7, dist);
//     // --- Universal BCS Post-processing Snippet ---
//     [... snippet code ...]
//     fragColor.rgb = applyBCS(fragColor.rgb);
//     // ---------------------------------------------

// === Full Example with O (vec3) ===
// If your shader's last lines look like this:
//     O = pow(color, vec3(0.75));
// You would add the snippet here and use:
//     O = applyBCS(O);
// Final code would look like:
//     O = pow(color, vec3(0.75));
//     // --- Universal BCS Post-processing Snippet ---
//     [... snippet code ...]
//     O = applyBCS(O);
//     // ---------------------------------------------

// === Full Example with O (vec4) ===
// If your shader's last lines look like this:
//     O = vec4(color, 1.0);
//     O *= 0.9;
// You would add the snippet here and use:
//     O.rgb = applyBCS(O.rgb);
// Final code would look like:
//     O = vec4(color, 1.0);
//     O *= 0.9;
//     // --- Universal BCS Post-processing Snippet ---
//     [... snippet code ...]
//     O.rgb = applyBCS(O.rgb);
//     // ---------------------------------------------

// === Optional Final Clamp ===
// If your shader doesn't already clamp the output, you can add this after the BCS application:
// fragColor = clamp(fragColor, 0.0, 1.0);
// or
// O = clamp(O, 0.0, 1.0);

// ---------------------------------------------