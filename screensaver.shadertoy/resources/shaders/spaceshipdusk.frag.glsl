
/*
    "Starship" by @XorDev

    Inspired by the debris from SpaceX's 7th Starship test:
    https://x.com/elonmusk/status/1880040599761596689
    
    My original twigl version:
    https://x.com/XorDev/status/1880344887033569682
    
    <512 Chars playlist: shadertoy.com/playlist/N3SyzR
*/

// Simple dithering function to reduce banding
float dither(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453) * 0.02;
}

void mainImage(out vec4 O, vec2 I)
{
    // Resolution for scaling
    vec2 r = iResolution.xy;
    
    // Tunable parameters
    float zoomFactor = 60.; // Controls the zoom level of the effect
                            // - Higher values (e.g., 100.) zoom in closer (particles appear larger)
                            // - Lower values (e.g., 20.) zoom out more (particles appear smaller)
    float trailLengthScale = 0.35; // Controls the length of the particle trails (glow stretch in x-direction)
                                   // - Smaller values (e.g., 0.1) make trails longer but may cause glow cutoff
                                   // - Larger values (e.g., 1.0) make trails shorter
    float particleSpeed = 0.005; // Controls the speed of the particles (affects trail length)
                                 // - Smaller values (e.g., 0.005) make particles move slower, creating longer trails
                                 // - Larger values (e.g., 0.02) make particles move faster, creating shorter trails
    float turbulenceSpeed = 60.; // Controls the speed of the smoke turbulence in the trails
                                 // - Higher values (e.g., 64.) make the turbulence flow slower
                                 // - Lower values (e.g., 16.) make the turbulence flow faster
    float turbulenceMapScale = 2.0; // Controls the scale of the sky turbulence (cloud noise size)
                                    // - Higher values (e.g., 5.) make the noise smaller/more detailed
                                    // - Lower values (e.g., 1.) make the noise larger/less detailed
    float trailFlareScale = 1.9; // Controls how much the trail flares out (widens) along its length
                                 // - Higher values (e.g., 2.5) make the trail flare out more
                                 // - Lower values (e.g., 0.5) make the trail flare out less
    float rotationAngle = -2.02143; // Controls the angle of comet movement (in radians)
                                    // - -2.2143 (approx. -127 degrees) sets movement from top-left to bottom-right
                                    // - -1.5708 (approx. -90 degrees) makes movement vertical (top to bottom)
                                    // - 0.0 (0 degrees) makes movement horizontal (left to right)
    
    // Sky gradient parameters
    vec3 skyTopColor = vec3(0.03, 0.06, 0.18); // Lighter blue (now at the "bottom" of the gradient, e.g., bottom-right)  0.05, 0.1, 0.3
    vec3 skyBottomColor = vec3(0.0, 0.0, 0.0); // Darker blue/black (now at the "top" of the gradient, e.g., top-left)
    float skyGradientAngle = -0.3142; // Angle of the sky gradient (in radians, approx. -18 degrees)
                                      // - 0.0 is vertical (bottom to top)
                                      // - -0.2618 (approx. -15 degrees) tilts the gradient slightly
                                      // - -0.3491 (approx. -20 degrees) tilts the gradient more
    
    // Compute rotated coordinates for the gradient
    vec2 uv = I / r.xy; // Normalized screen coordinates (0 to 1)
    uv = uv - 0.5; // Center the coordinates
    float c = cos(skyGradientAngle), s = sin(skyGradientAngle);
    vec2 rotatedUV = mat2(c, -s, s, c) * uv; // Rotate the coordinates
    rotatedUV = rotatedUV + 0.5; // Shift back to normalized space
    
    // Compute normalized coordinate along the rotated y-axis for the gradient
    // Invert the gradient so lighter color is at the "bottom" (bottom-right) and darker at the "top" (top-left)
    float yNorm = clamp(1. - rotatedUV.y, 0., 1.);
    
    // Interpolate between the bottom and top sky colors
    vec3 skyColor = mix(skyBottomColor, skyTopColor, yNorm);
    
    // Center, rotate, and scale for comet movement
    c = cos(rotationAngle), s = sin(rotationAngle);
    vec2 p = (I + I - r) / r.y * mat2(c, s, -s, c) * 5. / zoomFactor;
    
    // Sum of colors, RGB color shift, and wave
    vec4 S = vec4(0.), C = vec4(1, 2, 3, 0), W;
    
    // Time, trailing time, and iterator variables
    for(float t = iTime, T = .1 * t + p.y, i = 0.; i++ < 30.;
    
        S += (cos(W = sin(i) * C) + 1.)
        * exp(sin(i + i * T))
        / length(max(p,
            p / vec2(trailLengthScale,
                     (1. + trailFlareScale * abs(p.x)) * texture(iChannel0, turbulenceMapScale * (p / exp(W.x) + vec2(i, t) / turbulenceSpeed)) * 40.))
        ) / 1e4)
        p += particleSpeed * cos(i * (C.xz + 8. + i) + T + T);
    
    // Compute the comet trails
    vec4 cometColor = clamp(S * S, 0., 1.);
    
    // Combine the sky gradient with the comet trails (additive blending)
    O = vec4(skyColor + cometColor.rgb, 1.);
    
    // Add dithering to reduce banding on TV
    O += dither(I / r.xy);
}
/** SHADERDATA
{
    "title": "Starship Particle Trails",
    "description": "Simulates glowing particle trails inspired by SpaceX Starship debris with a twilight sky",
    "model": "person"
}
*/