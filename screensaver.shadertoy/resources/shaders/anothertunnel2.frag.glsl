
//https://www.shadertoy.com/view/tf2fDd


// === Animation Speed Control ===
// Control the overall animation speed. Default = 1.0 (original speed).
#define CAMERA_SPEED 0.1

// === Center Position Control ===
// Offset the center of the tunnel. 0.0 is centered. 
// E.g., 0.5 will move the center halfway to the right edge.
#define CENTER_OFFSET_X 0.0
#define CENTER_OFFSET_Y 0.250

// === Tunnel Diameter Scale (New) ===
// Controls the overall radius of the tunnel opening. 
// Lower values (e.g., 5.0) shrink the central black hole diameter, making the walls closer to the center.
#define TUNNEL_DIAMETER_SCALE 12.0

// === Wall Repetition Control ===
// Controls the frequency/scale of the wall pattern. 
// Higher values (e.g., 2.0) create more, smaller repetitions, making the tunnel look deeper.
#define WALL_FREQUENCY 2.40


// =============================================================
// ROBUST TANH CONVERSION METHOD IMPLEMENTATION
// Robust approximation of tanh(x) for GLSL ES 1.0
// =============================================================
vec4 tanh_approx(vec4 x) { 
    const float EPSILON = 1e-6; 
    // This stable approximation avoids the native tanh function.
    return x / (1.0 + max(abs(x), EPSILON)); 
}

// ------------------------------------------------------------
// GLSL ES 1.0 Safe 3D Hash Function (replaces bitwise hash)
// ------------------------------------------------------------
float hash(vec3 p) {
    // p must be integer grid coordinates (already ensured in the noise function)
    
    // Use the fractional part of sin(dot(p, large_vector)) * large_magic_number
    float n = dot(p, vec3(1.0, 57.0, 113.0));
    n = sin(n);
    
    // 43758.5453123 is a commonly used large fractional number for noise.
    return fract(n * 43758.5453123);
}

// ------------------------------------------------------------
// Value noise
// ------------------------------------------------------------
float noise(vec3 x) {
    // Explicitly initialize variables
    ivec3 i = ivec3(0);
    vec3 f = vec3(0.0);
    vec3 i_f = vec3(0.0); // Float version of i
    
    i = ivec3(floor(x));
    i_f = vec3(i); // Convert integer coordinates to float coordinates for hash input
    f = fract(x);
    f = f * f * (3.0 - 2.0 * f); // smoothstep

    // The hash function now takes vec3 arguments
    return mix(
        mix(
            mix(hash(i_f + vec3(0.0, 0.0, 0.0)),
                hash(i_f + vec3(1.0, 0.0, 0.0)), f.x),
            mix(hash(i_f + vec3(0.0, 1.0, 0.0)),
                hash(i_f + vec3(1.0, 1.0, 0.0)), f.x), f.y),
        mix(
            mix(hash(i_f + vec3(0.0, 0.0, 1.0)),
                hash(i_f + vec3(1.0, 0.0, 1.0)), f.x),
            mix(hash(i_f + vec3(0.0, 1.0, 1.0)),
                hash(i_f + vec3(1.0, 1.0, 1.0)), f.x), f.y),
        f.z
    );
}

// ------------------------------------------------------------
// Main raymarch entry
// ------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Calculate normalized, aspect-ratio corrected UV coordinates (0,0 is center)
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Apply the offset shift here
    uv.x += CENTER_OFFSET_X;
    uv.y += CENTER_OFFSET_Y;

    // Use a scaled time variable to simplify downstream calculations
    float time = iTime * CAMERA_SPEED;

    // Explicit variable initialization for ES 1.0 compatibility
    vec4 col = vec4(0.0);
    float d = 0.0; // depth accumulator
    float s = 0.0; // step size
    vec3 p = vec3(0.0); // current ray position 
    vec3 b = vec3(0.0); // turbulence base 
    float density = 0.0; // density sample 
    float clear = 0.0; // tunnel shaping 


    // Volumetric raymarch loop
    for (float i = 0.0; i < 150.0; i++) {
        // Nonlinear stepping (feedback-based)
        s = 0.0005 + abs(s) * 0.12;
        d += s;

        // Current ray position: Z-movement scaled by CAMERA_SPEED
        p = vec3(uv * d * 2.0, d + time * 5.0);
        
        // Turbulence base
        b = p;
        // Turbulence swirl speed scaled by CAMERA_SPEED
        b += sin(b + time * 5.9).yzx*smoothstep(-1.,1.,sin(time*.25)); 

        // Apply turbulence influence
        p.xy += sin(b.xy * 0.91 + p.z);
        
        // --- Apply WALL_FREQUENCY to the texture coordinates ---
        vec3 p_tex = p * WALL_FREQUENCY;

        // Base sinusoidal accumulation: now uses p_tex
        col += sin(p_tex.y * 0.1 + p_tex.z * 0.2 + vec4(.91, 0.5, 0.1, 1.0)) / (s * s + 1e-9);

        // Sample density: Noise movement scaled by CAMERA_SPEED
        density = noise(p_tex + time) - noise(p_tex);

        // --- New Tunnel Geometry Calculation ---
        // total_radius scales the entire opening. 0.3 is the base radius, 0.7 is the oscillation amplitude.
        float total_radius = TUNNEL_DIAMETER_SCALE * (0.3 + 0.7 * smoothstep(-1.0, 1.0, sin(time * 0.25)));
        
        // Tunnel shaping (clear space near camera)
        clear = length(p.xy) - total_radius;
        s = max(s, -clear);
        s +=density;
    }

    // --------------------------------------------------------
    // Tone mapping: tanh_approx + gamma
    // --------------------------------------------------------
    // Step 1: Calculate the argument for tanh and store in temp variable
    vec4 tanh_arg = col * col * col * col / 1e31;
    
    // Step 2: Apply the robust tanh_approx function
    fragColor = pow(tanh_approx(tanh_arg), vec4(0.4545));
}
