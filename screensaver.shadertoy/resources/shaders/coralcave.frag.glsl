precision mediump float; // Set default precision for floats

// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

#define T (iTime * 1.0)
#define path1(z) (vec3(tanh_approx(vec4(cos((z) * .11) * .25)).x * 15.0, \
                    tanh_approx(vec4(cos((z) * .09) * .24)).x * 16.0, (z))) // Explicitly 15.0, 16.0

#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

// --- GLOBAL PARAMETERS (for BCS) ---
#define BRIGHTNESS 1.05    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.10      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)

// --- FIELD OF VIEW PARAMETER ---
// Adjusts how much of the scene is visible.
// Values > 1.0 will zoom out (show more), values < 1.0 will zoom in (show less).
#define FIELD_OF_VIEW_MULTIPLIER 1.0 // Default to 1.0 for no scaling

// --- COLOR ADJUSTMENT PARAMETERS ---
// Adjusts the amplitude of the sine wave affecting the red channel.
// Higher values make the red component more pronounced.
#define COLOR_RED_AMPLITUDE 0.60 // Default 1.0 (original strength)

// Adjusts the amplitude of the cosine wave affecting the green channel.
// Higher values make the green component more pronounced.
#define COLOR_GREEN_AMPLITUDE 0.70 // Default 1.0 (original strength)

// Adjusts the frequency of the sine wave for the red channel along the Z-axis.
// Higher values create more rapid color changes.
#define COLOR_Z_FREQ_RED 0.3 // Default 0.2 (original frequency)

// Adjusts the frequency of the cosine wave for the green channel along the Z-axis.
// Higher values create more rapid color changes.
#define COLOR_Z_FREQ_GREEN 0.05 // Default 0.1 (original frequency)

// --- NEW BASE COLOR ADJUSTMENT PARAMETERS ---
// Multiplier for the base 's' value in the green channel.
// Increase to add more green to the base color.
#define COLOR_BASE_GREEN_FACTOR 0.15 // Initial value for amber/rust

// Multiplier for the base 's' value in the blue channel.
// Decrease to reduce blue and shift towards orange/red.
#define COLOR_BASE_BLUE_FACTOR 0.0 // Initial value for amber/rust


void mainImage(out vec4 o, in vec2 u) {
    // Explicit Variable Initialization
    vec2 r_res = iResolution.xy; // Renamed r to r_res
    vec3 p = vec3(0.0); // Explicitly initialized
    float d = 0.0; // Explicitly initialized
    float s = 0.0; // Explicitly initialized
    float od = 0.0; // Explicitly initialized
    float a = 0.0; // Explicitly initialized for the loop

    u = (u - r_res.xy / 2.0) / max(r_res.y, 1e-6); // Robust division, Explicitly 2.0
    
    // Apply FIELD_OF_VIEW_MULTIPLIER to the normalized UV coordinates
    u *= FIELD_OF_VIEW_MULTIPLIER;

    vec3 ro = path1(T); // Explicitly initialized
    vec3 la = path1(T+5.0); // Explicitly 5.0

    vec3 laz = normalize(la - ro) * 0.6; // Explicitly 0.6
    vec3 lax = normalize(cross(laz, vec3(0.0,-1.0, 0.0))); // Explicitly 0.0, -1.0, 0.0
    vec3 lay = cross(lax, laz); // Explicitly initialized

    vec3 rd = vec3(rot(sin(T*0.03))*u, 1.0) * mat3(-lax, lay, laz); // Explicitly 0.03, 1.0

    o = vec4(0.0); // Explicitly initialize output

    do {
        p = ro + rd * d;
        vec3 p1 = path1(p.z); // Explicitly initialized

        s = min(length(p.xy - p1.xy),
                length(p.y - p1.y));
        s = min(s, length(p.x - p1.y + 8.0)); // Explicitly 8.0
        s = min(s, length(p.x - p1.x));
        s = 2.0 - min(s, length(p.x - p1.x)); // Explicitly 2.0

        for (a = 0.2; a < 8.0; ) { // Explicitly 0.2, 8.0
            s -= abs(dot(sin(p * a * 8.0), vec3(0.045))) / max(a, 1e-6); // Robust division, Explicitly 8.0, 0.045
            a += a; // Equivalent to a *= 2.0
        }
        d += s;
    } while(d < 100.0 && s > 0.01); // Explicitly 100.0, 0.01

    p = ro + rd * d;

    // Replaced tan() with tanh_approx() and ensured scalar output by taking .x
    od = length(p - vec3(path1(p.z).xy,
                20.0 + T + tanh_approx(vec4(cos(T*0.13)*1.0)).x * 10.0)) - 0.5; // Explicitly 20.0, 0.13, 1.0, 10.0, 0.5

    s = abs(sin(p.x)+sin(p.y)+sin(p.z*0.5)); // Explicitly 0.5
    // Adjusted color calculation using new parameters for base green and blue
    o.rgb = vec3(s + sin(p.z * COLOR_Z_FREQ_RED) * COLOR_RED_AMPLITUDE, // Red channel
                 s * COLOR_BASE_GREEN_FACTOR + s * cos(p.z * COLOR_Z_FREQ_GREEN) * COLOR_GREEN_AMPLITUDE, // Green channel
                 s * COLOR_BASE_BLUE_FACTOR) // Blue channel
            * 1.0 / pow(max(od, 1e-6), 0.75); // Robust division, Explicitly 0.2, 0.1, 1.0, 0.75

    o *= texture(iChannel0, p.xz); // Changed texture2D to texture

    // Applying tanh_approx to the final color and robust division
    // Explicitly providing the 1.0 for the w component of the vec4 constructor
    o = vec4(pow(tanh_approx(vec4(o.rgb/max(od, 1e-6)*5.0, 1.0)).rgb, vec3(0.45)), 1.0) - dot(u,u)*0.2; // Robust division, Explicitly 5.0, 0.45, 1.0, 0.2

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = o.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    o.rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);
}
