float snap(float a, float b) {
    return floor(a * b) / b;
}

float jumpy(float a) {
    return abs(fract(a) - 0.5) - 0.25;
}

const vec2 spriteSize = vec2(280.0, 385.0) / vec2(1400.0, 770.0); // Frame size relative to sprite sheet
const vec2 atlasSize = vec2(5.0, 2.0); // 2x5 grid
const float spriteScale = 1.0; // 100% scale
const vec2 spritePos = vec2(-0.5, -0.5); // Position offset
const float animSpeed = 24.0; // 24 FPS as set by user
const float spriteHeightPixels = 385.0; // Height of each frame in pixels
const bool enableSmoothing = false; // Toggle motion blur on (true) or off (false)
const int blurSamples = 4; // Number of frames to sample for motion blur
const float blurStrength = 0.5; // Strength of the blur effect

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Calculate scaling factor to map sprite pixels to screen pixels at 100% scale
    float pixelScale = iResolution.y / spriteHeightPixels;
    vec2 ssUv = (fragCoord - iResolution.xy / 2.0) / (iResolution.y / pixelScale);

    // Animation frame selection
    float frameTime = iTime * animSpeed;
    float frame = mod(floor(frameTime), atlasSize.x * atlasSize.y);
    float frameX = mod(frame, atlasSize.x);
    float frameY = floor(frame / atlasSize.x);
    vec2 uvAnim = vec2(spriteSize.x * frameX, spriteSize.y * (atlasSize.y - 1.0 - frameY));

    // Compute UV for the current frame, anchoring to the lower-left corner
    vec2 uv = (ssUv - spritePos) * spriteSize * spriteScale + uvAnim;

    // Mask to ensure only the current frame area is drawn
    vec2 uvInFrame = (uv - uvAnim) / spriteSize;
    vec2 spriteMaskV = step(vec2(0.0), uvInFrame) * step(uvInFrame, vec2(1.0));
    float spriteMaskF = spriteMaskV.x * spriteMaskV.y;

    // Flip y-coordinate just before sampling to correct orientation
    vec2 sampleUV = uv;
    sampleUV.y = 1.0 - sampleUV.y;

    // Sample the current frame
    vec4 spriteColor = texture2D(iChannel0, sampleUV);

    // Apply motion blur if enabled
    if (enableSmoothing) {
        vec4 blurColor = vec4(0.0);
        float totalWeight = 0.0;
        for (int i = -blurSamples / 2; i <= blurSamples / 2; i++) {
            float offset = float(i) * blurStrength;
            float sampleFrame = mod(floor(frameTime + offset), atlasSize.x * atlasSize.y);
            float sampleFrameX = mod(sampleFrame, atlasSize.x);
            float sampleFrameY = floor(sampleFrame / atlasSize.x);
            vec2 sampleUvAnim = vec2(spriteSize.x * sampleFrameX, spriteSize.y * (atlasSize.y - 1.0 - sampleFrameY));
            vec2 sampleUv = (ssUv - spritePos) * spriteSize * spriteScale + sampleUvAnim;
            sampleUv.y = 1.0 - sampleUV.y;
            float weight = exp(-abs(float(i)) / float(blurSamples)); // Gaussian-like weighting
            blurColor += texture2D(iChannel0, sampleUv) * weight;
            totalWeight += weight;
        }
        spriteColor = blurColor / totalWeight;
    }

    // Draw the sprite or background
    if (spriteMaskF > 0.0 && spriteColor.w > 0.1) {
        fragColor = spriteColor;
    } else {
        // Darkened background color (adjust these RGB values to change the background color)
        fragColor = vec4(0.282, 0.435, 0.678, 1.0); // Darker gray background
    }

    // Apply vignette effect
    vec2 vignetteUv = fragCoord.xy / iResolution.xy;
    vignetteUv *= 0.0 - vignetteUv.yx; // Corrected to 1.0 - vignetteUv.yx as per original intent
    float vig = vignetteUv.x * vignetteUv.y * 35.0; // Vignette intensity
    vig = pow(vig, 0.10); // Vignette extent

    // Apply dither to reduce banding
    vec2 ditherUv = fragCoord.xy;
    float dither = mod(ditherUv.x + ditherUv.y, 2.0); // Simple 2x2 Bayer dither
    dither = (dither - 0.5) * 0.05; // Adjust dither strength (0.05 is subtle)

    // Combine vignette and dither
    fragColor.rgb *= vig + dither; // Apply vignette with dither offset
}