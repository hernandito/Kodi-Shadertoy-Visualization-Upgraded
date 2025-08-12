precision highp float; // Ensure high precision for calculations

// --- Specular Highlight Controls ---
// Adjusts the strength of the specular highlights. Lower for less white.
#define SPECULAR_INTENSITY 0.2  
// Adjusts the size/sharpness of highlights. Lower for softer, blurrier (e.g., 5.0 to 30.0).
#define SPECULAR_SHININESS 20.0 
// Color of the specular highlights (e.g., vec3(0.8, 0.9, 1.0) for a bluish tint).
#define SPECULAR_COLOR vec3(.80, .60, 0.0) 

// --- Final Output Clamp ---
// Clamps the final output color values. 1.0 is no clamp (standard range).
#define MAX_OUTPUT_VALUE 1.0    

void mainImage( out vec4 O, vec2 u )
{
    // Normalize fragment coordinates to [0,1] range
    u /= iResolution.xy;

    // Calculate depth from iChannel0.
    // Assuming iChannel0 provides some form of depth or grayscale information.
    // The '.rrrr' swizzle ensures all components of the vec4 are taken from the red channel.
    vec4 depth_val = 1.0 - texture(iChannel0, u).rrrr;

    // Calculate fluid volumetric color.
    // The `pow` function creates a volumetric effect, where the base color
    // (vec4(0.8, 0.125, 0.0, 1.0) - an orange/red) is raised to an exponent.
    // The exponent is influenced by the `depth_val` and a sinusoidal wave
    // that moves with time (`iTime`) and varies across the x-axis (`u.x`).
    O = pow( vec4(0.8, 0.125, 0.0, 1.0), 12.0 * depth_val + 3.0 * sin(0.3 * iTime - u.x) ); 

    // Calculate specular highlight.
    // 1. Determine the 'normal' of the surface for lighting calculations.
    //    This is derived from the gradient of the fluid's red channel (O.x)
    //    using `dFdx` and `dFdy` (partial derivatives in x and y).
    vec2 surface_normal = normalize(vec2(dFdx(O.x), dFdy(O.x)));
    
    // 2. Define the light direction.
    //    This is a 2D vector animated over time using `cos(iTime + vec2(0.0, 11.0))`.
    vec2 light_direction_2d = cos(iTime + vec2(0.0, 11.0)); 
    
    // 3. Calculate the diffuse factor.
    //    This is the dot product of the surface normal and light direction,
    //    clamped to a minimum of 0.0 (no light from behind the surface).
    float diffuse_factor = max(0.0, dot(surface_normal, light_direction_2d));
    
    // 4. Compute the specular component.
    //    It's a combination of:
    //    - `SPECULAR_COLOR`: The color tint of the highlight.
    //    - `SPECULAR_INTENSITY`: The overall brightness/strength of the highlight.
    //    - `pow(diffuse_factor, SPECULAR_SHININESS)`: This applies the shininess.
    //      A lower `SPECULAR_SHININESS` value will spread the highlight over a
    //      larger area, making it appear softer and less pixelated.
    vec3 specular_component = SPECULAR_COLOR * SPECULAR_INTENSITY * pow(diffuse_factor, SPECULAR_SHININESS);

    // Add the calculated specular component to the main color of the fluid.
    O.rgb += specular_component;
    
    // Apply a final clamp to the RGB channels of the output color.
    // This ensures that color values do not exceed `MAX_OUTPUT_VALUE`,
    // which can help prevent "blown out" white areas.
    O.rgb = clamp(O.rgb, 0.0, MAX_OUTPUT_VALUE);

    // Ensure the alpha channel is fully opaque.
    O.a = 1.0;
}
