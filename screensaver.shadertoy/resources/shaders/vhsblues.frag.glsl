// VHS Effect Shader for Static Image (Adapted from https://www.shadertoy.com/view/ldjGzV)

// Noise function for VHS static
float noise(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Layered noise for more even distribution
float layeredNoise(vec2 st, float t) {
    float n1 = noise(st + t);
    vec2 st2 = st * 2.0;
    float n2 = noise(st2 + t);
    vec2 st3 = st * 4.0;
    float n3 = noise(st3 + t);
    return 0.5 * n1 + 0.3 * n2 + 0.2 * n3;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Fix for upside-down image
    uv.y = 1.0 - uv.y; // Flip vertically (fix upside-down)

    // Tunable parameters with detailed explanations
    float noiseScale = 100.0; // Controls the size of the noise pattern (flickering static effect)
                              // - Higher values (e.g., 200.0) make the noise finer (smaller grains)
                              // - Lower values (e.g., 50.0) make the noise coarser (larger grains)
    float noiseSpeed = 5.0;   // Controls how fast the noise flickers over time
                              // - Higher values (e.g., 10.0) make the noise flicker faster
                              // - Lower values (e.g., 2.0) make the noise flicker slower
    float noiseStrength = 0.15; // Controls how intense the noise overlay is
                                // - Higher values (e.g., 0.3) make the noise more visible (more static)
                                // - Lower values (e.g., 0.05) make the noise subtler
                                // - Set to 0.0 to disable the noise effect entirely
    float distortionAmount = 0.02; // Controls the maximum amount of horizontal shifting for distortion
                                   // - Higher values (e.g., 0.05) make the horizontal shifts larger (more wobbly)
                                   // - Lower values (e.g., 0.01) make the shifts smaller (less wobbly)
    float distortionSpeed = 0.5;   // Controls how fast the distortion changes over time
                                   // - Higher values (e.g., 1.0 or 2.0) make the distortion cycle faster
                                   // - Lower values (e.g., 0.2) make the distortion cycle slower
    float distortionBandSize = 0.05; // Controls the size of the horizontal bands for distortion
                                     // - Higher values (e.g., 0.1) create fewer, larger bands (less frequent shifts)
                                     // - Lower values (e.g., 0.03) create more, smaller bands (more frequent shifts)
    float distortionStrength = 0.2; // Controls how much the distortion affects the image
                                    // - Higher values (e.g., 1.0) make the distortion fully visible
                                    // - Lower values (e.g., 0.3) make the distortion less noticeable
                                    // - Set to 0.0 to disable distortion entirely
    float chromaticAberration = 0.005; // Controls the amount of color channel separation (RGB split effect)
                                       // - Higher values (e.g., 0.01) create a larger split between red, green, and blue
                                       // - Lower values (e.g., 0.002) make the split smaller
    float chromaticStrength = 0.5; // Controls how much the chromatic aberration affects the image
                                   // - Higher values (e.g., 1.0) make the RGB split fully visible
                                   // - Lower values (e.g., 0.2) make the RGB split less noticeable
                                   // - Set to 0.0 to disable chromatic aberration entirely
    float scanlineStrength = 0.2; // Controls the intensity of the scanlines (horizontal lines like on a CRT TV)
                                  // - Higher values (e.g., 0.3) make the scanlines darker and more visible
                                  // - Lower values (e.g., 0.05) make the scanlines lighter and subtler
                                  // - Set to 0.0 to disable scanlines entirely
    float effectTransparency = 0.6; // Controls how much the effects (distortion, chromatic aberration, scanlines, noise) blend with the original image
                                    // - Higher values (e.g., 1.0) make the effects fully visible (no blending with the original image)
                                    // - Lower values (e.g., 0.3) make the effects more transparent, showing more of the original image

    // Horizontal distortion
    float band = floor(uv.y / distortionBandSize);
    float distortionOffset = fract(sin(dot(vec2(band, iTime * distortionSpeed), vec2(12.9898, 78.233))) * 43758.5453123) * 2.0 - 1.0;
    vec2 uvDistorted = uv;
    uvDistorted.x += distortionOffset * distortionAmount * distortionStrength;

    // Chromatic aberration (sample the texture with slight offsets for RGB channels)
    vec2 uvR = uvDistorted + vec2(chromaticAberration, 0.0) * chromaticStrength;
    vec2 uvG = uvDistorted;
    vec2 uvB = uvDistorted - vec2(chromaticAberration, 0.0) * chromaticStrength;
    float r = texture2D(iChannel0, uvR).r;
    float g = texture2D(iChannel0, uvG).g;
    float b = texture2D(iChannel0, uvB).b;
    vec3 col = vec3(r, g, b);

    // Original color without chromatic aberration (for blending)
    vec3 colBase = texture2D(iChannel0, uv).rgb;
    col = mix(colBase, col, chromaticStrength);

    // Noise overlay
    vec2 st = uv * noiseScale;
    float t1 = iTime * noiseSpeed;
    float t2 = (iTime + 0.016) * noiseSpeed;
    float n1 = layeredNoise(st, t1);
    float n2 = layeredNoise(st, t2);
    float blend = 0.5 * (sin(iTime * noiseSpeed) + 1.0);
    float noiseValue = mix(n1, n2, blend);
    col += vec3(noiseValue * noiseStrength);

    // Scanlines
    float scanline = sin(uv.y * iResolution.y * 2.0) * scanlineStrength;
    col -= vec3(scanline);

    // Blend the effects with the original image based on transparency
    vec3 finalCol = mix(colBase, col, effectTransparency);

    fragColor = vec4(finalCol, 1.0);
}

/** SHADERDATA
{
    "title": "VHS Effect on Static Blue Screen",
    "description": "Applies VHS effects to a static VHS blue screen image",
    "model": "person"
}
*/