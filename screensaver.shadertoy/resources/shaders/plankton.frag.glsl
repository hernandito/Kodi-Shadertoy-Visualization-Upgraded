const float EPSILON = 1e-6; // Epsilon for robust division and tanh_approx

// Robust tanh approximation function
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- Global Animation Speed Control ---
// Adjust this value to change the overall speed of the animation.
// A value of 1.0 is normal speed. Higher values make it faster, lower values make it slower.
#define ANIMATION_SPEED 0.1
// --------------------------------------

// --- Background Color Control ---
// Define the RGB color for the plain background. Default is black.
#define BACKGROUND_COLOR vec3(0.0, 0.0, 0.0)
// --------------------------------

// --- Animated Elements Green Channel Gain ---
// Controls the intensity of the green channel's contribution to the animated elements' color.
// A value of 1.5 is the original default. Increase for more green intensity, decrease for less.
#define GREEN_CHANNEL_GAIN .65
// --------------------------------------------

#define PI 3.1415
#define SIZE 0.3

mat2 scale(vec2 _scale){
    return mat2(_scale.x,0.0,
                0.0,_scale.y);
}

void mainImage(out vec4 o, vec2 fragCoord) {
    float t = iTime * ANIMATION_SPEED; // Apply animation speed control here
    vec2 u = (fragCoord - iResolution.xy * 0.5) / max(iResolution.y, EPSILON); // Robust division
    u += vec2(sin(t) / 2.0, cos (t * 2.0) / 4.0); // Explicit float literals
    u = scale(vec2(sin(t * 0.5) + 1.3)) * u;

    vec4 accumulated_o = vec4(0.0); // Initialize to black for accumulation
    float d = 0.0;    

    // Raymarch!
    for (int i = 0; i <70; i++) {
        vec3 p = vec3(u * vec2(1.2, 1.2) * d,  pow(d, 0.78) + 2.0 * t); // Explicit float literals

        float angle = p.z * 0.1 + t; // Explicit float literal
        float ca = cos(angle);
        float sa = sin(angle);

        mat2 rot = mat2(ca, -sa, sa, ca);

        p.xy += vec2(0.7 + sin(t)*2.0, 0.3 + cos(t) * 4.0); // Explicit float literals
        p.xy = rot * p.xy;
        p.xy += vec2(0.6 + sin(t)*2.0, 0.3  + cos(t) * 2.0); // Explicit float literals
        // starting 'signed distance'
        float s = 1.16; // Explicit float literal

        // Add distraction
        float n = 1.0; // Explicit float literal
        while (n < 8.0) { // Explicit float literal
            vec3 noiseInput = vec3(1.7, 1.7, 1.1 * pow(n, 1.6)) * p; // Explicit float literals
            float noise = abs(dot(cos(noiseInput), vec3(0.3, 0.3, 0.3))) / max(n, EPSILON); // Robust division, Explicit float literals
            s -= 0.9 * noise; // Explicit float literal
            n += 0.9 * n; // Explicit float literal
        }

        // Distance and color accumulation over Z axis (ray marching loop)
        float eps = 0.01 + abs(s) * 0.6; // Explicit float literals
        d += eps;
        accumulated_o += vec4(1.4 / max(eps, EPSILON)); // Robust division, Explicit float literal
    }

    // Apply tanh_approx and other color manipulations
    o = tanh_approx(accumulated_o / max((10000.0 * length(u)), EPSILON)); // Replaced tanh with tanh_approx, Robust division, Explicit float literal
    o.z =  d / 100.0; // Explicit float literal
    o.y = GREEN_CHANNEL_GAIN * (o.x * 0.3 + o.y * 0.9); // Apply green channel gain

    // --- Apply Background Color (new logic) ---
    // Calculate a 'presence' factor for the animated elements.
    // If o.rgb is very dark (close to black), it means the elements are not prominent here.
    float element_presence = length(o.rgb);
    // Use smoothstep to create a clean transition between background and elements.
    // Adjust the 0.01 and 0.1 thresholds as needed to fine-tune when the background appears.
    element_presence = smoothstep(0.01, 0.1, element_presence);
    
    // Mix the BACKGROUND_COLOR with the calculated element color based on presence.
    o.rgb = mix(BACKGROUND_COLOR, o.rgb, element_presence);
    // -------------------------------------------
}
