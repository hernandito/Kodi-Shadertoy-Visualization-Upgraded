// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters for color adjustment
#define BRIGHTNESS 1.20
#define CONTRAST   2.30
#define SATURATION 1.50

// Toggle the squiggly element on or off (1.0 = on, 0.0 = off)
#define SQUIGGLY_ON 1.0

// The color for the squiggly elements
#define SQUIGGLY_COLOR vec3(4.0, 4.0, 3.0)


// Function for Brightness, Contrast, and Saturation adjustments
vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

// This function now returns a vec2: x=distance, y=shape_ID
vec2 dist(vec3 p) {
    vec2 twist = cos(p.z*0.05 - iTime*.2 + vec2(0.0, 11.0));
    
    // The squiggly element's shape
//  float fd = length(vec2(p.x + sin(p.z*2.0) * 0.55, p.y + 2.0) * 0.7) + sin(p.z * 0.5 - iTime*.2 * 2.0) * 0.35;
    float fd = length(vec2(p.x + sin(p.z*1.50) * 0.55, p.y + 3.0) * 0.7) + sin(p.z * 0.15 - iTime*.2 * 2.0) * 0.25;
    
    // The spiral background shape
    float tp = (smoothstep(-1.0, 1.0, sin(iTime*.2)) * 5.0 + 50.0 - abs(dot(p.xy, twist))) * 0.3;
    
    // Check if we are toggling the squiggly element off
    if (SQUIGGLY_ON == 0.0) {
        fd = 1e10; // This makes the spiral background the only visible shape
    }
    
    // Determine which shape is closer
    if (fd < tp) {
        return vec2(fd, 1.0); // 1.0 means we hit the squiggly element
    } else {
        return vec2(tp, 0.0); // 0.0 means we hit the background
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 d = normalize(vec3(2.0 * fragCoord, 0.0) - iResolution.xyy);
    vec3 p = vec3(0.0, 0.0, -5.0 * iTime*.2);
    vec3 l = vec3(0.0);

    float s = 0.0;
    float shape_id = 0.0;

    for(float i = 0.0; i < 120.0; i++) {
        vec2 dist_result = dist(p);
        s = dist_result.x;
        shape_id = dist_result.y;
        
        p += d * s;
        l += exp(cos(p.z * 0.05 + vec3(0.1, 7.2, 2.0)) * 0.7 + 0.1) * 6e-6 / (8e-4 + s*s);
    }

    vec3 final_color;

    // Use a single variable for the depth-based shading
    vec3 ld = normalize(vec3(0.0, 1.0, 1.0));
    float n = 0.5 + smoothstep(0.0, 0.6, dist(p).x + dist(p).x * 0.1 - dist(p).x);
    
    // Use the shape_id to choose the color
    if (shape_id == 1.0) {
        // If the squiggly element is closest, calculate its brightness and apply the desired color
        float brightness = dot(n * l * l, vec3(1.0/3.0));
        final_color = brightness * SQUIGGLY_COLOR;
    } else {
        // Otherwise, use the original color
        final_color = n * l * l;
    }

    // Apply BCS post-processing adjustments
    final_color = bcs(final_color, BRIGHTNESS, CONTRAST, SATURATION);
    
    // Apply the tanh_approx function for compatibility
    fragColor = tanh_approx(vec4(final_color, 1.0));
}