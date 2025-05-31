/*
    "Grok" - Warm Animated Version with Rotation, Drift & Fire-Like Effect
    + Black Circle Inside Main Effect with Blurry Edge
    + Refined Turbulence with Brightness and Falloff Controls
    + Blue Effect Temporarily Disabled
*/

// 2D noise function to create randomness
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Smooth interpolation between noise samples
float smoothNoise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    float n00 = noise(i);
    float n10 = noise(i + vec2(1.0, 0.0));
    float n01 = noise(i + vec2(0.0, 1.0));
    float n11 = noise(i + vec2(1.0, 1.0));
    
    return mix(mix(n00, n10, u.x), mix(n01, n11, u.x), u.y);
}

// Fractal noise function for more detailed effects
float fractalNoise(vec2 uv, float time) {
    float n = 0.0;
    float amp = 1.0;
    float maxAmp = 0.0;
    for (int i = 0; i < 4; i++) {
        n += smoothNoise(uv * (6.0 + float(i) * 1.5) + time * amp * 1.3) * amp;
        maxAmp += amp;
        amp *= 0.5;
    }
    return n / maxAmp; // Normalize to [0, 1]
}

void mainImage(out vec4 O, in vec2 I)
{
    vec2 r = iResolution.xy;
    vec2 p = (I + I - r) / r.y;

    // Animation time factor for overall motion
    float t = iTime * 0.13;

    // Reintroduce rotation and drift
    // LINE 1: Drift amplitude and speed
    vec2 drift = vec2(0.12 * sin(t * 0.8), 0.12 * cos(t * 0.3));
    // - DRIFT AMPLITUDE (0.12):
    //   Controls how far the effect drifts in the x and y directions.
    //   - Increase to 0.2: Larger drift, more pronounced movement.
    //   - Decrease to 0.05: Smaller drift, subtler movement.
    // - DRIFT SPEED (t * 0.8, t * 0.3):
    //   Controls how quickly the drift oscillates.
    //   - Increase to t * 1.0: Faster drift motion.
    //   - Decrease to t * 0.4: Slower drift motion.
    p += drift;

    // LINE 2: Rotation speed
    float angle = t * 0.4;
    // - ROTATION SPEED (t * 0.4):
    //   Controls how quickly the effect rotates around the center.
    //   - Increase to t * 0.6: Faster rotation.
    //   - Decrease to t * 0.2: Slower rotation.
    mat2 rotation = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    p = rotation * p;

    // Transform p into coordinates aligned with the line (p.x - p.y = 0)
    float s = dot(p, vec2(1.0, 1.0)) / sqrt(2.0); // Along the line (p.x - p.y = 0)
    float t_coord = dot(p, vec2(-1.0, 1.0)) / sqrt(2.0); // Perpendicular to the line

    // Pulsating effect for the main line
    float radius = 0.1 + 0.02 * sin(t * 0.7);

    // Debug mode: set to 1 to visualize turbulence values directly
    const int debugTurbulence = 0; // Change to 1 to debug turbulence

    // Sample turbulence for the main line, adapted from ballofire
    float turbulence = 1.0; // Default value (no turbulence)
    if (t_coord > 0.0) { // Apply turbulence above the line in the aligned coordinates
        // Compute UV coordinates similar to ballofire

        // Adjustments for turbulence (refer to the LINE numbers above):        
        // LINE 1: Directional speed and cloud size
        vec2 uv = vec2(s, t_coord) * 8.0 + vec2(0.0, -t * 0.4); 
        // - DIRECTIONAL SPEED (LINE 1: t * 0.4):
        //   Controls how quickly the turbulence pattern (clouds) moves away from the top of the yellow/orange line (the curved portion).
        //   - Increase to t * 0.6: Clouds move outward faster, creating a more energetic flow.
        //   - Decrease to t * 0.2: Clouds move outward more slowly, creating a calmer flow.
        //
        // - CLOUD SIZE (LINE 1: vec2(s, t_coord) * 8.0):
        //   Controls the size of the individual clouds in the turbulence texture by zooming in or out on the texture map.
        //   - Original setting: * 4.0 (revert to this if tex03a.png doesn't yield desired results)
        //   - Increase to * 10.0: Clouds appear smaller and more detailed, with finer variations (more intricate swirls).
        //   - Decrease to * 6.0: Clouds appear larger and more spread out, with broader variations (softer, less detailed).
                 
        // LINE 2: Cloud distance
        uv /= 1.0; 
        // - CLOUD DISTANCE (LINE 2: uv /= 1.0):
        //   Controls how spread out the clouds appear along the line, acting as an additional zoom factor.
        //   - Increase to /= 2.0: Clouds appear more distant (smaller, more spread out), covering a larger area with finer details.
        //   - Decrease to /= 0.5: Clouds appear closer (larger, more compressed), taking up more space with less coverage.
        
        // Add subtle fractal noise distortion for cloud evolution
        // LINE 3: Cloud evolution speed
        float noiseTime = t * 1.5; 
        // - CLOUD EVOLUTION SPEED (LINE 3: t * 1.5):
        //   Controls how quickly the clouds swirl and evolve over time.
        //   - Increase to t * 2.0: Clouds evolve faster, with more rapid twisting and morphing (more energetic).
        //   - Decrease to t * 1.0: Clouds evolve more slowly, with gradual changes (more relaxed).

        vec2 distortion = vec2(fractalNoise(uv * 0.5, noiseTime), fractalNoise(uv * 0.5 + 10.0, noiseTime));

        // LINE 4: Cloud evolution strength
        uv += distortion * 0.8; 
        // - CLOUD EVOLUTION STRENGTH (LINE 4: distortion * 0.8):
        //   Controls how much the clouds swirl and evolve over time by adding a dynamic offset to the texture.
        //   - Original setting: * 0.5 (revert to this if tex03a.png doesn't yield desired results)
        //   - Increase to * 1.0: More dramatic swirling and morphing, making the clouds feel more alive and dynamic.
        //   - Decrease to * 0.3: Subtler swirling, with less noticeable changes, making the clouds feel more static.
                
        // Sample texture map (using tex03a.png for finer detail)
        turbulence = texture(iChannel0, uv).r;
        turbulence = mix(0.5, 1.5, turbulence); // Map to [0.5, 1.5] for variation

        // LINE 5: Turbulence brightness and falloff
        turbulence = turbulence * 2.0 * exp(-t_coord * 1.0);
        // - BRIGHTNESS (turbulence * 2.0):
        //   Controls the intensity of the turbulence effect on the main line.
        //   - Increase to * 3.0: Turbulence effect is brighter, more pronounced.
        //   - Decrease to * 1.0: Turbulence effect is dimmer, more subtle.
        //
        // - FALLOFF (exp(-t_coord * 1.0)):
        //   Controls how quickly the turbulence fades as it extends outward from the axis.
        //   - Decrease to exp(-t_coord * 0.5): Slower falloff, turbulence extends further with more visibility.
        //   - Increase to exp(-t_coord * 2.0): Faster falloff, turbulence fades more quickly.
    }

    if (debugTurbulence == 1) {
        // Debug mode: output turbulence value as grayscale
        O = vec4(vec3(turbulence), 1.0);
        return;
    }

    // Warm fire-like color palette for the main effect
    vec3 baseColor = vec3(.6, 0.2, 0.07); // Stronger fire tones (reddish-orange), reduced green to remove tint
    // - COLOR ADJUSTMENT:
    //   - If still too greenish, reduce green further to 0.15 or 0.1.
    //   - If too red, increase green slightly to 0.25.

    // Animated brightness pulsing
    float brightness = 0.65 + 0. * sin(t * 0.2 + cos(t * 0.3));
    vec3 color = baseColor * brightness;

    // Compute the main effect line with turbulence
    float thickness = 0.07;
    float dist = abs(length(p) - radius + .02 / (p.x - p.y));
    // Apply turbulence by distorting the distance
    dist /= (t_coord > 0.0) ? turbulence : 1.0; // Apply turbulence above the line
    float intensity = thickness / dist;
    // Adjustment for turbulence impact:
    // - IMPACT (dist /= turbulence):
    //   - Replace with dist /= (turbulence * 0.5 + 0.5) for subtler effect
    //   - Replace with dist /= (turbulence * 1.5) for more pronounced effect

    // Fire-like effect using animated noise (orange irregular animated element)
    float flameScale = 16.0;  
    float flameMovement = t * 1.2;  
    float fireNoise = smoothNoise(p * flameScale + flameMovement) * 0.1;
    float fireEffect = 0.051 / (abs(length(p) - radius - fireNoise) + 0.1);
    // Fine-tune: adjust 0.1 offset (smaller for stronger effect, larger for softer)

    // Main effect with turbulence
    vec3 mainEffectColor = color * intensity;

    // Black circle inside the main effect
    float blackCircleRadius = 0.16; // Diameter 0.15, so radius = 0.075
    float blackCircleDist = length(p);
    // Use smoothstep for a slightly blurry edge (0.005 blur radius)
    float blackCircle = smoothstep(blackCircleRadius - 0.005, blackCircleRadius + 0.005, blackCircleDist); // 0 inside, 1 outside

    // Secondary blue pulsating ring with irregular animated edges (temporarily disabled)
    /*
    float blueRingRadius = 0.03 + 0.005 * sin(t * .3); // Smaller radius
    float blueNoiseScale = 2.0;
    float blueNoiseSpeed = t * 10.0;
    float blueEdgeNoise = fractalNoise(p * blueNoiseScale, blueNoiseSpeed) * 0.03;
    float blueRingEffect = 0.03 / (abs(length(p) - blueRingRadius - blueEdgeNoise) + 0.05);
    vec3 blueColor = vec3(0.1, 0.2, 1.) * (0.4 + 0.1 * sin(t * 2.0)); // Glowing blue
    vec3 blueEffectColor = blueColor * blueRingEffect;
    */

    // Layering (back to front):
    // 1. Black background (implicitly vec3(0.0))
    // 2. Main effect with turbulence
    // 3. Black circle (masks previous layers inside its radius)
    // 4. Orange fire effect (irregular wavy element)
    vec3 finalColor = vec3(0.0); // Start with black background
    finalColor = mainEffectColor; // Add main effect with turbulence
    finalColor *= blackCircle; // Apply black circle (sets inside to black with blurry edge)
    finalColor += color * fireEffect; // Add orange fire effect on top of black circle
    // finalColor += blueEffectColor; // Blue effect disabled

    // Output final composition
    O = vec4(finalColor, 1.0);
}