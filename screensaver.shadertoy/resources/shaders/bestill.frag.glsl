// A robust approximation of the tanh function for older GLSL versions
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters for Brightness, Contrast, and Saturation
// Adjust these values to change the look of the final output.
#define BRIGHTNESS 0.10      // Range: -1.0 to 1.0 (0.0 is default)
#define CONTRAST   1.40      // Range: 0.0 to 2.0 (1.0 is default)
#define SATURATION 1.0      // Range: 0.0 to 2.0 (1.0 is default)

// Color adjustment parameters
// You can change these to control the overall color scheme of the effect.
#define COLOR_EFFECT vec4(3.0, 2.50, 1.0, 0.0)     // The color of the main effect.
#define COLOR_BARS vec4(0.0)                     // The color of the top and bottom cinematic bars.
#define COLOR_BACKGROUND vec3(0.0)               // The background color behind the effect.

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
    float d = 0.0, a = 0.0, e = 0.0, i = 0.0, s = 0.0, t = iTime * 0.5;
    vec3 p = iResolution;
    o = vec4(0.0);
    
    // scale coords
    u = (u + u - p.xy) / p.y;
    
    // cinema bars
    if (abs(u.y) > 0.8) {
        o = COLOR_BARS;
        return;
    }
    
    // camera movement
    u += vec2(cos(t * 0.4) * 0.3, cos(t * 0.8) * 0.1);
    
    // Replaced o*=i with o=vec4(0.0) as 'i' starts at 0.0
    for(i = 0.0; i++ < 1e2;
        // entity (orb)
        e = length(p - vec3(
            sin(sin(t * 0.2) + t * 0.4) * 2.0,
            1.0 + sin(sin(t * 1.3) + t * 0.2) * 1.23,
            12.0 + t + cos(t * 0.5) * 8.0)) - 0.1,
            
        // accumulate distance
        d += s = min(0.01 + 0.4 * abs(s), e = max(0.8 * e, 0.01)),
            
        // grayscale color
        o += 1.0 / max((s + e * 4.0), 1e-6))
            
        // noise loop start, march
        for (p = vec3(u * d, d + t), // p = ro + rd *d, p.z + t;
            // diagonal plane
            s = 4.0 + p.y + p.x * 0.3,
            
            // noise starts at .42 up to 16.,
            // grow by a+=a
            a = 0.42; a < 16.0; a += a)
            
            // apply noise
            s -= abs(dot(sin(0.6 * t + p * a), 0.18 + p - p)) / a;
            
    // tanh tonemap, brightness, light off-screen
    u += (u.yx * 0.7 + 0.2 - vec2(-1.0, 0.1));
    o = tanh_approx(COLOR_EFFECT * o / max(1e1, 1e-6) / max(dot(u, u), 1e-6));

    // Apply the BCS adjustments to the final color
    o.rgb = applyBCS(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);

}