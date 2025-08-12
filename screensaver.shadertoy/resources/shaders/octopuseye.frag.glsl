// Mirror-like "Happy Accident" Shader (CC0)
// A shiny reflective variation of a raymarched fractal accident
// ATTRIBUTION: Shader techniques inspired by (alphabetical):
//   @byt3_m3chanic
//   @FabriceNeyrat2
//   @iq
//   @shane
//   @XorDev
//   + many more

precision mediump float; // Ensure medium precision for GLSL ES 1.00

// New Post-Processing Parameters for BCS
#define BRIGHTNESS_POST .90     // Adjusts overall brightness (1.0 for neutral)
#define SATURATION_POST 1.0     // Adjusts color intensity (1.0 for neutral, 0.0 for grayscale)
#define POST_CONTRAST 1.4       // Adjusts contrast (1.0 for neutral, >1.0 for more contrast)

// General purpose small epsilon for numerical stability
const float TINY_EPSILON = 1e-6; 


// The Robust Tanh Conversion Method: tanh_approx functions
// This provides a numerical approximation for tanh suitable for GLSL ES 1.00.
// It also includes a small EPSILON to prevent division by zero, making it robust.

// Overload for vec4 input
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), TINY_EPSILON));
}

// Overload for vec3 input
vec3 tanh_approx(vec3 x) {
    return x / (1.0 + max(abs(x), TINY_EPSILON));
}


float map(vec3 p) {
    // Domain repetition
    p = abs(fract(p) - 0.5);
    // Cylinder + planes SDF
    // Reverted to original 1e-3 for the fractal formula's intended behavior
    return abs(min(length(p.xy) - 0.175, min(p.x, p.y) + 1e-3)) + 1e-3;
}

vec3 estimateNormal(vec3 p) {
    float eps = 0.001; // Explicitly initialized
    return normalize(vec3(
        map(p + vec3(eps, 0.0, 0.0)) - map(p - vec3(eps, 0.0, 0.0)),
        map(p + vec3(0.0, eps, 0.0)) - map(p - vec3(0.0, eps, 0.0)),
        map(p + vec3(0.0, 0.0, eps)) - map(p - vec3(0.0, 0.0, eps))
    ));
}

void mainImage(out vec4 O, in vec2 C) {
    vec2 r = iResolution.xy; // Initialized
    vec2 uv = (C - 0.5 * r) / max(r.y, TINY_EPSILON); // Initialized, added robustness for division by r.y

    float t = iTime*.1; // Initialized
    float z = fract(dot(C, sin(C))) - 0.5; // Initialized
    vec4 col = vec4(0.0); // Explicitly initialized
    vec4 p = vec4(0.0); // Explicitly initialized
    vec4 q = vec4(0.0); // Explicitly initialized

    for (float i = 0.0; i < 77.0; i++) {
        // Ray direction
        p = vec4(z * normalize(vec3(C - 0.7 * r, r.y)), 0.1 * t);
        p.z += t;

        q = p; // Initialized

        // Apply "bugged" rotation matrices for glitchy fractal distortion
        // Re-interpreted for GLSL ES 1.00 by applying cos to each component individually
        // and passing as four separate floats to mat2 constructor.
        p.xy *= mat2(
            cos(2.0 + q.z + 0.0), // cos(V.x)
            cos(2.0 + q.z + 11.0), // cos(V.y)
            cos(2.0 + q.z + 33.0), // cos(V.z)
            cos(2.0 + q.z + 0.0)  // cos(V.w)
        ); 
        p.xy *= mat2(
            cos(q.x + 0.0),   // cos(V.x)
            cos(q.y + 11.0),  // cos(V.y)
            cos(q.z + 33.0),  // cos(V.z)
            cos(q.w + 0.0)    // cos(V.w)
        );

        // Distance estimation
        float d = map(p.xyz); // Explicitly initialized for safety later, though assigned here

        // Estimate lighting
        vec3 pos = p.xyz; // Explicitly initialized
        vec3 lightDir = normalize(vec3(0.3, 0.5, 1.0)); // Initialized
        vec3 viewDir = normalize(vec3(uv, 1.0)); // Initialized
        vec3 n = estimateNormal(pos); // Explicitly initialized
        vec3 reflectDir = reflect(viewDir, n); // Explicitly initialized

        // Fake environment reflection (sky blue + fade to white)
        vec3 envColor = mix(vec3(0.8, 0.4, 0.8), vec3(1.0), 0.5 + 0.5 * reflectDir.y); // Initialized

        // Specular highlight
        float spec = pow(max(dot(reflectDir, lightDir), 0.0), 32.0); // Explicitly initialized

        // Funky palette color using original method
        // Reverted denominator to original, as it's inherently robust (always >= 0.5)
        vec4 baseColor = (1.0 + sin(0.5 * q.z + length(p.xyz - q.xyz) + vec4(0,4,3,6)))
                         / (0.5 + 2.0 * dot(q.xy, q.xy)); // Reverted denominator
        
        // Combine base color + environment reflection + specular highlight
        vec3 finalColor = baseColor.rgb * 0.1 + envColor * 0.9 + vec3(spec) * 1.2; // Explicitly initialized

        // Brightness weighted accumulation
        // This division remains robust, as 'd' (distance) can genuinely approach zero.
        col.rgb += finalColor / max(d, TINY_EPSILON);

        z += 0.6 * d;
    }

    // Apply BCS post-processing
    // Brightness
    col.rgb *= BRIGHTNESS_POST;
    // Saturation (mix between grayscale and original color)
    col.rgb = mix(vec3(dot(col.rgb, vec3(0.2126, 0.7152, 0.0722))), col.rgb, SATURATION_POST);
    // Contrast (adjust around 0.5 gray level)
    col.rgb = (col.rgb - 0.5) * POST_CONTRAST + 0.5;

    // Compress brightness range
    // Replaced tanh() with tanh_approx() and added robustness for division
    // Now calls the vec3 overload of tanh_approx
    O = vec4(tanh_approx(col.rgb / max(2e4, TINY_EPSILON)), 1.0);
}
