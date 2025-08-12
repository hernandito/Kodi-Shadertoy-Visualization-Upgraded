/*
    "IGNITE" by @XorDev

    https://x.com/XorDev/status/1953128872435745272
    
    <512 playlist:
    https://www.shadertoy.com/playlist/N3SyzR

    Twigl code:
    vec3 p;
    for(float i,z,d,l;i++<6e1;o+=(vec4(5,9,2.+d*5e1,0)/l)/z)
    p=z*normalize(FC.rgb*2.-r.xyy)-cos(.5*t),
    p.z+=5.,p.xz*=mat2(cos(t+p.y*.4-vec4(0,33,11,0))),
    d=length(p),z+=d=min(l=length(cos(p/d/.1)+p.y+d),d-.8-exp(-p*p/.1).y)/9.;
    o=tanh(o*o/7e3);
*/

// The Robust Tanh Conversion Method:
// Added: tanh_approx function for Kodi compatibility
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6; // Define a small epsilon for robustness
    // Ensure the denominator is never zero or too close to zero
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters for Brightness, Contrast, Saturation
// Default values are set to neutral (1.0) to match the original shader's look.
#define BRIGHTNESS .9     // Controls overall lightness/darkness (1.0 for neutral)
#define SATURATION 1.00     // Controls color intensity (1.0 for neutral, 0.0 for grayscale)
#define POST_CONTRAST 1.20  // Controls the difference between light and dark areas (1.0 for neutral)


void mainImage(out vec4 O, vec2 I)
{
    // Added: Explicit variable initialization for robustness
    float z = 0.0;  // Raymarch depth
    float d = 0.0;  // Step distance
    float l = 0.0;  // Light distance
    float i = 0.0;  // Raymarch iterator
    
    vec3 p = vec3(0.0); // Initialize p
    O = vec4(0.0); // Initialize O (fragColor) to clear before accumulating

    // Clear fragColor and raymarch 80 steps (original loop count was 6e1, which is 60)
    for(i = 0.0; i < 70.0; i++) // Initialize 'i' in the for loop for clarity
    {
        // Raymarch sample point
        // Replaced iResolution.xyy with vec3(iResolution.xy, iResolution.y) for clarity and robustness
        p = z * normalize(vec3(I + I, 0.0) - vec3(iResolution.xy, iResolution.y)) + sin(0.5 * iTime*.2);
        
        // Shift camera back 5 units
        p.z += 4.0; // Use 5.0 for float literal
        
        // Rotate and twist
        // Added: Explicit mat2 for clarity, ensured float literals
        p.xz *= mat2(cos(iTime*.40 + p.y * 0.9 - vec4(0.0, 33.0, 11.0, 0.0))); // vec4 for the constant
        
        d = length(p);

        // Robust Division: p/d becomes p / max(d, 1e-6) to avoid division by zero
        // Replaced 0.8 with 0.8 for float literal
        z += d = min(l = length(cos(p / max(d, 1e-6) / 0.1) + p.y + d),
                     d - 0.8 - exp(-p * p / 0.1).y) / 9.0; // Use 9.0 for float literal
        
        // Coloring and brightness
        // Robust Division: /l becomes /max(l, 1e-6)
        // Robust Division: /z becomes /max(z, 1e-6)
        O += (vec4(9.0, 4.80, 0.0 + d * 40.0, 0.0) / max(l, 1e-6)) / max(z, 1e-6);
    }
    
    // Tanh tonemap
    // Replaced tanh with tanh_approx and added robust division for 7e3 (7000.0)
    O = tanh_approx(O * O / max(7000.0, 1e-6));

    // Post-processing adjustments (Brightness, Saturation, Contrast)
    O.rgb *= BRIGHTNESS; // Apply brightness to RGB channels
    O.rgb = mix(vec3(length(O.rgb)), O.rgb, SATURATION); // Apply saturation
    O.rgb = (O.rgb - 0.5) * POST_CONTRAST + 0.5; // Apply contrast

}
