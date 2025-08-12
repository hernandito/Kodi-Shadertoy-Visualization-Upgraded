Copy the entire contents of the <xaiArtifact> above (including comments and code).
    Save it as PaperNoiseTextureInstructions.glsl or PaperNoiseTextureInstructions.txt in a directory for shader utilities (e.g., /path/to/shader_utils/).
    Ensure the file is preserved for future reference.

Submit to Me:

    When you want to apply the paper noise texture to a new shader, provide me with:
        The full text of PaperNoiseTextureInstructions.glsl (or just reference it, and I’ll recall it).
        The target shader code you want to modify.
        Optional: The desired base color (if different from the original blue) and any preferences for intensity or scale.
    Example submission:
    text

Please apply the paper noise texture as per PaperNoiseTextureInstructions.glsl.
Target shader:
[Insert your shader code here]
Desired color: vec3(1.0, 0.0, 0.0) (red)
Preferences: intensity = 1.0, scale = 1.5


===================================================

```
// Directive: Apply Paper Noise Texture to a Shader
// Purpose: Add a paper-like noise texture to a shader, as seen in the blue mountain shader (June 2, 2025).
// Method: Use a 2D random function to generate subtle noise, additively blended with the shader's base color.
// Instructions: Provide these directions and the target shader code to apply the paper noise texture.
// Last Updated: June 2, 2025

// Steps to Apply Paper Noise Texture:
// 1. Include the Paper Noise Functions
//    - Add the `rand2` and `applyPaperNoise` functions to the shader, typically before `mainImage` or in a common tab.
//    - Code:
//      ```glsl
//      float rand2(vec2 p) {
//          return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
//      }
//
//      vec3 applyPaperNoise(vec3 color, vec2 uv, float intensity, float scale) {
//          float noise = (rand2(uv * scale) - 0.5) * 0.07;
//          return color + intensity * noise;
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
//      - `uv`: Controls noise strength (default: 1.125; use 0.5` for subtler noise, `2.0` for stronger).
//      - `scale`: Adjusts noise frequency (default: `1.0`; use `2.0` for finer grains, `0.5` for coarser).

// 4. Adjust for the Shader's Design
//    - Color: The noise is additive, blending with the base color. For example, applying to a red design (`vec3(1.0, 0, 0.0)`), the noise creates brightness variations.
//    - To match the original blue shader's feel, use `intensity = 1.0` and `scale` based on resolution (e.g., `1.5` for high-res).
//    - If the noise is too strong, reduce `intensity` (e.g., `0.8`). If too subtle, increase it (e.g., `1.5`).
//    - For different grain sizes, adjust `scale` (e.g., `2.0` for finer, `0.5` for larger grains).

// 5. Test and Validate
//    - In Shadertoy: Verify the noise texture resembles the grainy paper effect from the blue mountain shader.
//    - In Kodi: Save as `[shadername].frag.glsl` in `/storage/.kodi/addons/screensaver.shadertoy/resources/shaders/`. Restart Kodi and check the texture appears.
//    - Debug: If no noise appears, output `vec3(rand2(uv))` as `fragColor` to confirm `rand2` works.

// Example Integration
// Target Shader (simplified example):
// ```glsl
// precision highp float;
// uniform vec2 iResolution;
// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     vec2 uv = fragCoord.xy / iResolution.xy;
//     vec3 color = vec3(1.0, 0.0, 0.0); // Red design
//     fragColor = vec4(color, 1.0);
// }
// ```
// Modified with Paper Noise:
// ```glsl
// precision highp float;
// uniform vec2 iResolution;

// // Paper noise functions
// float rand2(vec2 p) {
//     return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
// }
//
// vec3 applyPaperNoise(vec3 color, vec2 uv, float intensity, float scale) {
//     float noise = (rand2(uv * scale) - 0.5) * 0.07;
//     return color + intensity * noise;
// }

// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     vec2 uv = fragCoord.xy / iResolution.xy;
//     vec3 color = vec3(1.0, 0.0, 0.0); // Red design
//     color = applyPaperNoise(color, uv, 1.125, 1.0); // Add paper noise
//     fragColor = vec4(color, 1.0);
// }
// ```

// Troubleshooting
// - No Noise: Ensure `rand2` and `applyPaperNoise` are included and `uv` is computed correctly.
// - Incorrect Grain: Adjust `scale` (e.g., `2.0` for finer, `0.5` for coarser).
// - Noise Too Strong/Weak: Modify `intensity` (e.g., `0.5` to `2.0`).
// - Kodi Issues: Verify `iResolution` and test with `fragColor = vec4(vec3(rand2(uv)), 1.0);` to debug.

// Notes
// - The noise is additive, so it may brighten dark colors. For dark designs, reduce `intensity`.
// - If the target shader uses a different noise function (e.g., Simplex noise), specify if you prefer that instead.
// - For Kodi, ensure `iGlobalTime` is used if the shader involves time-based effects.

// Future Submission
// To apply this texture to a new shader:
// 1. Provide these instructions.
// 2. Share the target shader code.
// 3. Specify the desired base color (if different from the original blue) and any preferences for intensity or scale.
// I will integrate the paper noise texture as described, ensuring compatibility with Shadertoy and Kodi.

// Save this file as `PaperNoiseTextureInstructions.glsl` alongside your shader utilities for easy reference.
```