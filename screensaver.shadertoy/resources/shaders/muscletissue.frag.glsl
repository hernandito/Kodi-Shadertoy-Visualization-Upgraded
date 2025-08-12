#define PULSE_AMPLITUDE 0.05  // Reduced amplitude of the distortion pulse (range: 0.0 to 0.1 for subtlety)
#define PULSE_FREQUENCY 0.650    // Frequency of the distortion pulse (range: 0.5 to 2.0 for speed)
#define TEXTURE_SCALE 2.50      // Scale factor for texture size (range: 0.1 to 2.0, <1.0 makes texture smaller)

// BCS parameters for post-processing
#define BRIGHTNESS 0.80         // Range: 0.0 to 2.0 (1.0 = no change)
#define CONTRAST 1.30           // Range: 0.0 to 2.0 (1.0 = no change)
#define SATURATION 0.80         // Range: 0.0 to 2.0 (1.0 = no change)

vec4 fBm(vec2 p) {
    return texture(iChannel0, p * TEXTURE_SCALE) * 0.5 + 
           texture(iChannel0, p * vec2(2.0) * TEXTURE_SCALE) * 0.25 + 
           texture(iChannel0, p * vec2(4.0) * TEXTURE_SCALE) * 0.125 + 
           texture(iChannel0, p * vec2(8.0) * TEXTURE_SCALE) * 0.0625;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    // Calculate a smooth gradient from left (0) to right (1) to control distortion intensity
    float distortionFactor = smoothstep(0.0, 1.0, uv.x);
    // Apply pulsing distortion with intensity increasing toward the right
    float pulse = sin(iTime * PULSE_FREQUENCY) * PULSE_AMPLITUDE * distortionFactor;
    uv.x += pulse; // Horizontal distortion scaled by the gradient
    uv.y += pulse * 0.5 * sin(iTime * PULSE_FREQUENCY * 1.5); // Vertical distortion also scaled
    // Existing drift and distortion logic with texture scale
    vec2 distortedUV = (uv.xy * vec2(0.5) * uv.x) + vec2(iTime * 0.01, 0.0);
    fragColor = fBm(distortedUV) + vec4(0.53, 0.02, 0.02, 0.0);

    // Post-processing: BCS adjustments
    // 1. Brightness: Multiply the color by the brightness factor
    fragColor.rgb *= BRIGHTNESS;

    // 2. Contrast: Adjust contrast around the midpoint (0.5)
    fragColor.rgb = (fragColor.rgb - 0.5) * CONTRAST + 0.5;

    // 3. Saturation: Convert to grayscale and mix with original color
    float gray = dot(fragColor.rgb, vec3(0.299, 0.587, 0.114)); // Luminance
    fragColor.rgb = mix(vec3(gray), fragColor.rgb, SATURATION);

    // 4. Ensure colors stay in valid range after adjustments
    fragColor.rgb = clamp(fragColor.rgb, 0.0, 1.0);
}