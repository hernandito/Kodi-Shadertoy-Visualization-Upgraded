// Dust Effect: Small, random, moving dot-like particles (e.g., floating particles or dust)
// Usage: Add to a shader to create the illusion of dust or particles in a fluid

// Random noise function for dust effect
vec3 dustRandom(vec2 co) {
    vec3 a = fract(cos(co.x * 8.3e-3 + co.y) * vec3(1.3e5, 4.7e5, 2.9e5));
    vec3 b = fract(sin(co.x * 0.3e-3 + co.y) * vec3(8.1e5, 1.0e5, 0.1e5));
    return mix(a, b, 0.5);
}

// Parameters for the dust effect
const float dustSpeed = 0.1;    // Speed of particle motion (lower = slower, e.g., 0.05 for very slow)
const float dustScale = 2.0;    // Spatial scale of particles (higher = more/smaller particles, e.g., 4.0 for denser)
const float dustExponent = 70.0; // Sparsity of particles (higher = sparser, e.g., 50.0 for more, 100.0 for fewer)
const float dustAmplitude = 0.4; // Amplitude of motion (higher = larger motion, e.g., 0.2 for subtle)
const vec3 dustColor = vec3(1.0); // Color of particles (default white, e.g., vec3(0.8, 0.8, 1.0) for light blue)

// Dust effect function
// Inputs: fragCoord (screen coords), iResolution (screen resolution), iTime (time)
// Returns: vec4 to add to the final color
vec4 dustEffect(vec2 fragCoord, vec3 iResolution, float iTime) {
    // Base position
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 pos = vec3(uv * 2.0 - 1.0, 0.0);
    
    // Animate position
    float animTime = iTime * dustSpeed;
    pos += dustAmplitude * vec3(sin(animTime / 16.), sin(animTime / 12.), sin(animTime / 128.));
    
    // Generate seed for random points
    vec2 seed = pos.xy * dustScale;
    seed = floor(seed * iResolution.x);
    
    // Compute random value and brightness
    vec3 rnd = dustRandom(seed);
    return vec4(dustColor * pow(rnd.y, dustExponent), 1.0);
}

// Example usage in mainImage
// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     vec3 color = vec3(0.0); // Your shader's color computation
//     vec4 dust = dustEffect(fragCoord, iResolution, iTime);
//     color += dust.rgb;
//     fragColor = vec4(color, 1.0);
// }

// Notes:
// - Add dustRandom and dustEffect to your shader.
// - Call dustEffect in mainImage and add to final color.
// - Adjust parameters (dustSpeed, dustScale, dustExponent, dustAmplitude, dustColor) as needed.
// - To tie motion to an existing animated position, modify pos in dustEffect:
//   pos = yourAnimatedPosition + dustAmplitude * vec3(sin(animTime / 16.), sin(animTime / 12.), sin(animTime / 128.));