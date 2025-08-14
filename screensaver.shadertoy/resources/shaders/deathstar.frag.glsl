// A robust approximation of the tanh function for older GLSL versions
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters for Brightness, Contrast, and Saturation
// Adjust these values to change the look of the final output.
#define BRIGHTNESS 0.0      // Range: -1.0 to 1.0 (0.0 is default)
#define CONTRAST   1.0      // Range: 0.0 to 2.0 (1.0 is default)
#define SATURATION 1.0      // Range: 0.0 to 2.0 (1.0 is default)

// Function to apply Brightness, Contrast, and Saturation adjustments
vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color += brightness;
    
    // Apply contrast
    color = (color - 0.5) * contrast + 0.5;
    
    // Apply saturation
    vec3 gray = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(gray, color, saturation);
    
    return color;
}

// "Deathstar" by @XorDev
// https://x.com/XorDev/status/1953620412648014334
void mainImage(out vec4 O, vec2 I)
{
    // Explicitly initialize all variables
    float z = 0.0;
    float d = 0.0;
    float f = 0.0;
    float i = 0.0;
    
    O = vec4(0.0);
    vec3 r = iResolution;
    float t = iTime*.5;
    
    // Clear fragcolor and raymarch 100 steps
    for(i = 0.0; i++ < 1e2;)
    {
        // Raymarch sample point
        vec3 p = z * (vec3(I+I, 0.0) - r.xyy) / r.y;
        
        // Cloud coordinates
        vec3 c = p;
        
        // Shift camera back 8 units
        p.z += 8.0;
        
        // Stretch clouds
        c.z *= 3.0;
        
        // Apply cloud turbulence
        for(f = 1.0; f++ < 9.0; c += sin(c.yzx * f + z + t * 0.5) / max(f, 1e-6));
        
        // Step forward (distance to clouds)
        z += min(f = 0.1 + abs(0.2 * c.y + abs(p.y + 0.8)),
                 // Distance to deathstar
                 d = max(length(p) - 3.0, 0.9 - length(p - vec3(-1.0, 1.0, 3.0)))) / 7.0;
                 
        // Accumulate color
        O += vec4(4.0, 6.0, 8.0 + z, 0.0) / max(f, 1e-6) - min(dFdx(z) * r.y + z, 0.0) / max(exp(d * d / 0.1), 1e-6);
    }
    
    // Tanh tonemap using the robust approximation
    O = tanh_approx(O / 2e3);

    // Apply the BCS adjustments to the final color
    O.rgb = applyBCS(O.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}