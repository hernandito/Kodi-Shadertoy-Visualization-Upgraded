/*
    "Starship" by @XorDev - Adapted for Kodi with Adjusted Trail Length, Spacing, Glow, and Turbulence
*/

#ifdef GL_ES
precision mediump float;
#endif

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 r = iResolution.xy;
    
    // Coordinate for sparkles with rotation and scaling
    vec2 p = (fragCoord + fragCoord - r) / r.y;
    
    // Adjustable angle for sparkle motion direction (in degrees)
    const float theta = 25.0; // Angle in degrees; 0 = horizontal (left to right), 90 = vertical (bottom to top),
                              // 45 = bottom-left to top-right, -45 = top-left to bottom-right
    const float PI = 3.14159265359;
    float thetaRad = theta * PI / 180.0; // Convert to radians
    float c = cos(thetaRad); // cos(theta)
    float s = sin(thetaRad); // sin(theta)
    p = vec2(p.x * c - p.y * s, p.x * s + p.y * c);
    
    // Zoom (confirmed: larger value = larger effect)
    p /= 0.085; // Fine-tune: increase (e.g., 0.12) to zoom out more, decrease (e.g., 0.08) to zoom in
    
    vec4 O = vec4(0.0);
    
    float t = iTime;
    float i = 0.0;
    
    // Debug mode: set to 1 to visualize turbulence values directly
    const int debugTurbulence = 0; // Change to 1 to debug turbulence
    
    for (; i < 15.0; i++)
    {
        // Pulsing brightness with per-sparkle speed variation
        float glowIntensity = 0.5 * exp(sin(i * 1.37 + i * t * (0.05 + 0.01 * sin(i * 1.37)))); // Range: [0.19, 1.36]
        // Fine-tune: adjust 0.5 for brightness (0.4 dimmer, 0.6 brighter),
        // 0.05 for base speed (0.03 slower, 0.07 faster), 0.01 for speed variation (0.02 more, 0.005 less)
        
        // Sample turbulence from iChannel0 (v6 version, confirmed working)
        float turbulence = 1.0; // Fallback
        vec2 uv = p / (exp(sin(i) + 2.0) * 2.0) + vec2(t * 0.05, i * 0.1);
        turbulence = texture(iChannel0, uv).r;
        turbulence = mix(0.5, 1.5, turbulence); // Map [0,1] to [0.5,1.5] for variation
        
        if (debugTurbulence == 1) {
            // Debug mode: output turbulence value as grayscale
            fragColor = vec4(vec3(turbulence), 1.0);
            return;
        }
        
        // Colorful fronts with turbulent falloff, orange sparkles with slight red tint
        vec4 color = cos(sin(i) * vec4(1, 2, 3, 0)) + 1.;
        // Shift white sparkles to light orange with slight red tint
        if (color.r > 1.5 && color.g > 1.5 && color.b > 1.5) {
            color.b *= 0.7; // Reduce blue for orange
            color.r *= 1.3; // Slightly stronger red boost for red tint
        }
        O += color * glowIntensity / length(max(p, p / vec2(turbulence * 70.0, 2)));
		
		// ORIGINAL CODE BEFORE ADJUSTMENTS BELOW
		//O += color * glowIntensity / length(max(p, p / vec2(turbulence * 40.0, 2)));
		
        // Fine-tune trail length: increase 40.0 (e.g., 60.0) for longer trails (glow stretches further in x-direction),
        //   decrease (e.g., 20.0) for shorter trails (glow more compact)
		
        // Fine-tune trail width: increase 2 (e.g., 4) for wider trails (thicker in y-direction),
        //   decrease (e.g., 1) for thinner trails
		
        // Fine-tune color: adjust 0.7 blue (0.6 warmer, 0.8 cooler), 1.3 red (1.4 more red, 1.2 less)
        
        // Shift position for spacing and front variation, added t * 0.05 for continuous motion
        p -= 1.0 * sin(i * vec2(12, 1.5) - i * i - t * 0.1 + p.x * 0.000005 + sin(i * 1.37 + t * 0.02) * 0.8 + t * 0.01);
       
		// ORIGINAL CODE BEFORE ADJUSTMENTS BELOW
        // p -= 1.0 * sin(i * vec2(10, 1.3) - i * i - t * 0.1 + p.x * 0.000005 + sin(i * 1.37 + t * 0.02) * 0.2 + t * 0.05);

	   // Fine-tune spacing: vec2(10, 1.3); decrease (e.g., vec2(8, 1.1)) for more spacing, increase (e.g., vec2(12, 1.5)) for less
	   
        // Fine-tune position: p.x * 0.000005 adds a small position-dependent offset; adjust if needed (e.g., 0.00001)
		
        // Fine-tune front variation: sin(i * 1.37 + t * 0.02) * 0.2; adjust 0.2 (0.3 more, 0.1 less), 0.02 (0.03 faster, 0.01 slower)
		
        // Added t * 0.05 for continuous motion; adjust 0.05 (0.1 faster, 0.03 slower)
    }
    
    // Sparkles with brightness adjusted for trail visibility
    float brightnessFactor = 0.5e4; // Fine-tune: increase (e.g., 0.7e4) for dimmer, decrease (e.g., 0.3e4) for brighter
    vec4 sparkles = O * O / brightnessFactor;
    sparkles = sparkles / (1.0 + abs(sparkles));
    
    // Output sparkles against black sky
    fragColor = sparkles;
}