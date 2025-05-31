// Band-Limited Cosine Pattern with Optional Wave-Warped Effect and Black Hole
// Based on "Band-limiting" by Inigo Quilez (https://www.shadertoy.com/view/WtScDt)
// Modified by Grok to add a wave-warped effect and a black hole

// The MIT License
// Copyright © 2020 Inigo Quilez
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Effect Selection Parameter
// Set to true to enable the wave-warped effect with 4-lobe modulation (new effect)
// Set to false to use the original flowing fabric-like pattern
const bool useWarpedEffect = false;

// Black Hole Parameters
const float blackHoleRadius = 0.2; // Smaller radius for the black hole
const float blackHoleFalloff = 0.35; // Falloff distance for the gradient

// Vignette Parameters
const float vignetteStart = 1.0; // Radius where the vignette starts darkening
const float vignetteEnd = 2.8;   // Radius where the vignette reaches maximum darkness
const float vignetteIntensity = 0.2; // Darkness at the edges (0.0 = black, 1.0 = no darkening)

// Box-filtered cos(x) to prevent aliasing by attenuating high-frequency oscillations
vec3 fcos(in vec3 x)
{
    vec3 w = fwidth(x);
    return cos(x) * sin(0.5 * w) / (0.5 * w); // Exact band-limiting
}

// Color palette made of 8 band-limited cos functions
vec3 getColor(in float t)
{
    vec3 col = vec3(0.6, 0.5, 0.4);
    col += 0.14 * fcos(6.2832 * t *  1.0 + vec3(0.0, 0.5, 0.6));
    col += 0.13 * fcos(6.2832 * t *  3.1 + vec3(0.5, 0.6, 1.0));
    col += 0.12 * fcos(6.2832 * t *  5.1 + vec3(0.1, 0.7, 1.1));
    col += 0.11 * fcos(6.2832 * t *  9.1 + vec3(0.1, 0.5, 1.2));
    col += 0.10 * fcos(6.2832 * t * 17.1 + vec3(0.0, 0.3, 0.9));
    col += 0.09 * fcos(6.2832 * t * 31.1 + vec3(0.1, 0.5, 1.3));
    col += 0.08 * fcos(6.2832 * t * 65.1 + vec3(0.1, 0.5, 1.3));
    col += 0.07 * fcos(6.2832 * t * 131.1 + vec3(0.3, 0.2, 0.8));
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalized coordinates
    vec2 q = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // Deformation for the background pattern
    vec2 p = 2.0 * q / dot(q, q);
    // Apply wave-warped effect with 4-lobe modulation if enabled
    if (useWarpedEffect)
    {
        float angle = atan(p.y, p.x);
        p *= 1.0 + 0.3 * sin(4.0 * angle); // Modulate radius to create 4 lobes
    }

    // Animation
    p.xy += 0.05 * iTime;

    // Background color from band-limited palette
    vec3 col = min(getColor(p.x), getColor(p.y));

    // Enhanced vignette effect
    float distToCenter = length(q);
    float vignetteAlpha = smoothstep(vignetteStart, vignetteEnd, distToCenter);
    float vignetteFactor = mix(1.0, vignetteIntensity, vignetteAlpha);
    col *= vignetteFactor;

    // Black hole effect with improved falloff
    float blackHoleAlpha = smoothstep(blackHoleRadius - blackHoleFalloff, blackHoleRadius + blackHoleFalloff, distToCenter);
    // Apply a non-linear curve to the alpha to reduce grey haze
    blackHoleAlpha = pow(blackHoleAlpha, 2.2); // Gamma-like curve for sharper transition near the center
    // Premultiplied alpha blending: black hole is an overlay with alpha
    vec3 blackHoleColor = vec3(0.0); // Black center
    vec3 blendedCol = blackHoleColor * (1.0 - blackHoleAlpha) + col * blackHoleAlpha;

    fragColor = vec4(blendedCol, 1.0);
}