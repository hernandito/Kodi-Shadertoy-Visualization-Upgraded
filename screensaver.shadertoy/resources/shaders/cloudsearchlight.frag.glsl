// A robust approximation of the tanh function for older GLSL versions
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters for Brightness, Contrast, and Saturation
// Adjust these values to change the look of the final output.
#define BRIGHTNESS 0.0      // Range: -1.0 to 1.0 (0.0 is default)
#define CONTRAST   1.05      // Range: 0.0 to 2.0 (1.0 is default)
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

void mainImage(out vec4 o, vec2 u) {
    // Explicitly initializing all variables to prevent undefined behavior
    float i = 0.0, a = 0.0, d = 0.0, s = 0.0, t = iTime * 0.2;
    vec3 p = iResolution;
    o = vec4(0.0);

    u = (u - p.xy / 2.0) / p.y;
    if (abs(u.y) > 0.4) {
        o = vec4(0.0);
        return;
    }
    u += vec2(cos(t * 0.4) * 0.3, cos(t * 0.8) * 0.1);

    for(i = 0.0; i++ < 1e2;
        d += s = 0.03 + abs(s) * 0.2,
        o += 1.0 / max(s, 1e-6)) {
        
        p = vec3(u * d, d + t);
        p.x *= 0.8;
        p.x += t * 4.0;
        s = 4.0 + p.y;
        
        for (a = 0.05; a < 2.0; a += a) {
            s -= abs(dot(sin(t + p * a * 8.0), 0.04 + p - p)) / a;
        }
    }
    
    u -= (u.yx * 0.7 + 0.2 - vec2(-0.2, 0.1));

    // Replaced tanh() with the tanh_approx() function
    float dot_u_u = dot(u, u);
    o = tanh_approx(vec4(5.0, 2.0, 1.0, 0.0) * o / (3e4 * max(pow(dot_u_u, 1.9), 1e-6)));

    // Apply the BCS adjustments to the final color
    o.rgb = applyBCS(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}