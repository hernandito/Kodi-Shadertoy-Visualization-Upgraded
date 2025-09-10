// The Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS .90
#define CONTRAST   1.30
#define SATURATION 1.0

// Animation speed
#define ANIM_SPEED .60

vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    // Brightness
    color += brightness - 1.0;
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    // Saturation
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

void mainImage(out vec4 o, vec2 u) {

    // Variable declarations and explicit initialization
    float i = 0.0;
    float d = 0.0;
    float s = 0.0;
    float e = 0.0;
    float t = iTime * ANIM_SPEED;
    float zt = t * 12.0;
    float xt = t * 13.0;
          
    vec3 p = iResolution;
    
    // Scale coords and move the camera around a bit
    u = (u + u - p.xy) / max(p.y, 1e-6) + cos(t * 0.3) * vec2(0.4, 0.2);
    
    // Clear `o`, march up to 128 steps
    for (o = vec4(0.0); i++ < 128.0;
        
        // Accumulate distance of orb, plane or clouds
        d += s = min(e, min(1.0 + p.y * 0.6, 5.0 - p.y * 0.05)),
        
        // Accumulate brightness. Division is made robust.
        o += s + 3.0 / max(e, 1e-6))
        
        // Noise start
        for (
            p = vec3(u * d, d + zt),
            
            // Entity (orb), a sphere
            e = length(p - vec3(
                sin(sin(t * 0.2) + t * 0.4) * 4.0,
                sin(sin(t * 1.3) + t * 0.2) * 2.0,
                14.0 + zt + cos(t * 0.5) * 8.0)) - 0.1,

            // Move to the side
            p.x -= xt,

            // Start noise at 0.02, until 2, grow by s += s
            s = 0.02;
            s < 2.0;
            s += s)
                // Apply noise. Division is made robust.
                p += abs(dot(sin(p * s), p - p + 0.12)) / max(s, 1e-6);
    
    // Make our angled sun beam light thing
    u += (u.yx * 0.7 + 0.2 - vec2(-1.0, 0.1));
    
    // Tanh tonemap, color, brightness, light
    // All divisions are made robust before applying tanh_approx
    vec4 tanhValue = vec4(5, 2, 1, 0) * o * o / max(d, 1e-6) / 1e3 / max(length(u), 1e-6);
    o = tanh_approx(tanhValue);

    // Apply post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}