// Palette Options
#define PALETTE_ORIGINAL 1
#define PALETTE_METAL 0

// User-selectable palette (default: original)
uniform int uPalette; // Can be set to PALETTE_ORIGINAL or PALETTE_METAL

vec3 originalPalette(float t) {
    return 0.5 + 0.5 * cos(t + vec3(0.0, 2.0, 4.0));
}

vec3 metalPalette(float t) {
    // Define key metallic colors
    vec3 gold = vec3(0.851, 0.761, 0.435);   // #FFD700
    vec3 copper = vec3(0.800, 0.502, 0.000); // #C08000
    vec3 silver = vec3(0.753, 0.753, 0.753); // #BFBFBF
    vec3 nickel = vec3(0.694, 0.694, 0.647); // #B1B1A5
    vec3 iron   = vec3(0.502, 0.502, 0.502); // #909090

    // Create a repeating sequence
    float phase = mod(t * 0.2, 1.0); // Adjust multiplier for speed
    
    if (phase < 0.2) {
        return mix(gold, copper, phase / 0.2);
    } else if (phase < 0.4) {
        return mix(copper, silver, (phase - 0.2) / 0.2);
    } else if (phase < 0.6) {
        return mix(silver, nickel, (phase - 0.4) / 0.2);
    } else if (phase < 0.8) {
        return mix(nickel, iron, (phase - 0.6) / 0.2);
    } else {
        return mix(iron, gold, (phase - 0.8) / 0.2);
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    // Control the speed of the animation here:
    float time = iTime * 0.1; // Adjust this value to change speed
                            //  Smaller values make it slower, larger values faster.

    // Simulate a beat frequency
    float beat = sin(time * 1.0) * 0.15 + 0.15;

    // Radial pattern
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    
    // Spiral + pulse
    float spiral = sin(10.0 * radius - time * .3 + angle * 5.0);
    float pulse = sin(30.0 * radius - time * 10.0) * 0.5 + 0.5;
    float ring = smoothstep(0.01, 0.02, abs(spiral) * pulse);

    // Color cycle
    vec3 color;
    if (uPalette == PALETTE_METAL) {
        color = metalPalette(time);
    } else {
        color = originalPalette(time);
    }
    
    // Glow
    color *= 1.0 / (radius * 5.0 + 0.1);

    // Custom Vignette effect
//    color *= 1.4 - dot(uv, uv) * 0.5; // Apply vignette (darken corners)
//    float t = mod(iTime, 230.0);
//    color *= smoothstep(0.0, 5.0, t) * smoothstep(229.5, 229.0, t); // Faster initial ramp (5s), faster fade (1s cycle)

    // Add darkening falloff to the lines
    float lineFactor = abs(spiral) * pulse; // Get the line intensity
    float falloff = smoothstep(0.0, 0.12 * ring, lineFactor); // Adjust 0.5 to control falloff distance, scaling it by ring
    color = mix(color, vec3(0.0), (1.0 - falloff) * 0.4); // 0.8 controls the darkness of the lines
   
    color *= ring; // Apply color after the falloff

    fragColor = vec4(color, 1.0);
}
