// Directive: Apply Paper Noise Texture to a Shader
// Purpose: Add a paper-like noise texture to a shader, as seen in the blue mountain shader (June 2, 2025).
// Method: Use a hash-based 2D noise function to generate subtle noise, additively blended with the shader's base color.
// Instructions: Provide these directions and the target shader code to apply the paper noise texture.
// Last Updated: June 2, 2025

// Steps to Apply Paper Noise Texture:
// 1. Include the Paper Noise Functions
//    - Add the `hash2` and `applyPaperNoise` functions to the shader, typically before `mainImage` or in a common tab.
//    - Code:
//      ```glsl
//      vec2 hash2(vec2 p) {
//          return fract(sin(vec2(
//              dot(p, vec2(127.1, 311.7)),
//              dot(p, vec2(269.5, 183.3))
//          )) * 43758.5453);
//      }
//
//      vec3 applyPaperNoise(vec3 color, vec2 uv, float intensity, float scale) {
//          vec2 noise = (hash2(uv * scale) - 0.5) * 0.15;
//          float noiseVal = (noise.x + noise.y) * 0.5;
//          return color + intensity * noiseVal;
//      }
//      ```

// 2. Compute UV Coordinates
//    - Ensure the shader calculates UV coordinates (e.g., `vec2 uv = fragCoord.xy / iResolution.xy`).
//    - If the shader uses a different coordinate system (e.g., centered or scaled), adjust UVs to map to [0,1] or as needed.

// 3. Apply the Noise to the Base Color
//    - In `mainImage`, after computing the shader's base color (e.g., `vec3 color`), call `applyPaperNoise` to add the texture.
//    - Example:
//      ```glsl
//      vec3 color = vec3(0.0, 0.2, 0.45); // Base color (e.g., blue)
//      color = applyPaperNoise(color, uv, 1.125, 1.0); // Add paper noise
//      fragColor = vec4(color, 1.0);
//      ```
//    - Parameters:
//      - `color`: The shader's base color (any RGB color for the design).
//      - `uv`: UV coordinates (typically [0,1]).
//      - `intensity`: Controls noise strength (default: 1.125; use 0.5 for subtler noise, 2.0 for stronger).
//      - `scale`: Adjusts noise frequency (default: 1.0; use 0.5 for larger grains, 2.0 for finer).

// 4. Adjust for the Shader's Design
//    - Color: The noise is additive, blending with the base color. For example, applying to a red design (`vec3(1.0, 0.0, 0.0)`), the noise creates brightness variations.
//    - To match the original blue shader's feel, use `intensity = 1.125` and `scale = 1.0`.
//    - If the noise is too strong, reduce `intensity` (e.g., 0.8). If too subtle, increase it (e.g., 1.5).
//    - For different grain sizes, adjust `scale` (e.g., 0.5 for larger, 2.0 for finer grains).

// 5. Test and Validate
//    - In Shadertoy: Verify the noise texture resembles the grainy paper effect from the blue mountain shader.
//    - In Kodi: Save as `[shadername].frag.glsl` in `/storage/.kodi/addons/screensaver.shadertoy/resources/shaders/`. Restart Kodi and check the texture appears.
//    - Debug: If no noise appears, output `hash2(uv)` as `fragColor.rgb` to confirm `hash2` works.

// Example Integration
// Target Shader (simplified example):
// ```glsl
// precision highp float;
// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     vec2 uv = fragCoord.xy / iResolution.xy;
//     vec3 color = vec3(1.0, 0.0, 0.0); // Red design
//     fragColor = vec4(color, 1.0);
// }
// ```
// Modified with Paper Noise:
// ```glsl
// precision highp float;

// // Paper noise functions
// vec2 hash2(vec2 p) {
//     return fract(sin(vec2(
//         dot(p, vec2(127.1, 311.7)),
//         dot(p, vec2(269.5, 183.3))
//     )) * 43758.5453);
// }
//
// vec3 applyPaperNoise(vec3 color, vec2 uv, float intensity, float scale) {
//     vec2 noise = (hash2(uv * scale) - 0.5) * 0.15;
//     float noiseVal = (noise.x + noise.y) * 0.5;
//     return color + intensity * noiseVal;
// }

// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     vec2 uv = fragCoord.xy / iResolution.xy;
//     vec3 color = vec3(1.0, 0.0, 0.0); // Red design
//     color = applyPaperNoise(color, uv, 1.125, 1.0); // Add paper noise
//     fragColor = vec4(color, 1.0);
// }
// ```

// Troubleshooting
// - No Noise: Ensure `hash2` and `applyPaperNoise` are included and `uv` is computed correctly.
// - Incorrect Grain: Adjust `scale` (e.g., 0.5 for larger, 2.0 for finer).
// - Noise Too Strong/Weak: Modify `intensity` (e.g., 0.5 to 2.0).
// - Kodi Issues: Verify `iResolution` and test with `fragColor = vec4(hash2(uv), 0.0, 1.0);` to debug.

// Notes
// - The noise is additive, so it may brighten dark colors. For dark designs, reduce `intensity`.
// - If the target shader uses a different noise function (e.g., Simplex noise), specify if you prefer that instead.
// - For Kodi, ensure `iGlobalTime` is used if the shader involves time-based effects.

// Texture Scale Option
// - The `scale` parameter in `applyPaperNoise` controls the grain size of the paper noise texture.
// - Default: `scale = 1.0` (matches the grain size of the original blue mountain shader).
// - Lower values (e.g., 0.5 or 0.25): Larger grains, as if viewing the paper closer up.
// - Higher values (e.g., 2.0 or 3.0): Finer grains, as if viewing the paper from farther away.
// - To prevent artifacts (e.g., lines) at very low scales, scales below 0.2 may need adjustment based on testing.
// - To specify a larger texture (closer-up effect), provide a lower `scale` value when submitting the shader.
//   Example Submission:
//     ```
//     Apply paper noise texture per PaperNoiseTextureInstructions.glsl.
//     Target shader: [shader code]
//     Color: vec3(0.5, 0.55, 0.6)
//     Intensity: 1.125
//     Scale: 0.5 // Larger grains
//     ```
// - If no `scale` is specified, the default `1.0` will be used.

// Future Submission
// To apply this texture to a new shader:
// 1. Provide these instructions.
// 2. Share the target shader code.
// 3. Specify the desired base color (if different from the original blue) and any preferences for intensity or scale.
// I will integrate the paper noise texture as described, ensuring compatibility with Shadertoy and Kodi.

// Save this file as `PaperNoiseTextureInstructions.glsl` alongside your shader utilities for easy reference.