// Uniforms/Variables required by the Kodi Shadertoy Addon
// These are implicitly defined as input variables:
// vec3 iResolution (resolution of the viewport)
// float iTime (shader playback time in seconds)

// --- USER CONTROL DEFINES ---
// 1. GLOBAL SPEED: Multiplier applied to iTime for overall animation speed.
#define GLOBAL_SPEED .2

// 2. SCREEN ROTATION: Rotates the entire scene after coordinate normalization.
//    ROTATION_SPEED: Speed of the rotation (e.g., 0.5 is half a radian per second).
#define ROTATION_SPEED 0.2
//    ROTATION_DIRECTION: 1.0 for clockwise, -1.0 for counter-clockwise.
#define ROTATION_DIRECTION -1.0

// 3. FIELD OF VIEW (FOV): Controls the zoom level (perspective).
//    < 1.0 zooms IN (narrower FOV), > 1.0 zooms OUT (wider FOV). 1.0 is default.
#define FIELD_OF_VIEW .850 

// --- Robust Tanh Conversion Method ---
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

/*
 Utilizing this repetitive mirror:
 https://www.shadertoy.com/view/w3VGzc
*/
void mainImage(out vec4 o, vec2 u) {
    // 1. Explicit Variable Initialization and Setup
    
    // Apply Global Speed to time
    float time = iTime * GLOBAL_SPEED; 

    // Resolution vector
    vec3 r = iResolution;
    
    // Legacy 't' variable, now based on adjusted time
    float t = -time * 2.0; 

    // 2. FOV and Normalized Coordinates [-1, 1]
    // The FOV define is used here to scale the viewport size.
    vec2 uv = (u - 0.5 * r.xy) / (r.y * FIELD_OF_VIEW);

    // 3. Post-Rotation (Screen-space rotation of the entire effect)
    float rotation_angle = time * ROTATION_SPEED * ROTATION_DIRECTION;
    mat2 rot_post = mat2(cos(rotation_angle), sin(rotation_angle), -sin(rotation_angle), cos(rotation_angle));
    uv *= rot_post;

    // Accumulated color (Explicitly initialized)
    o = vec4(0.0);

    // Raymarching variables (Explicitly initialized)
    float d = 0.0;    // Distance along ray
    float s = 0.0;    // Step size
    vec3 p = vec3(0.0); // Ray position 
    float a = 0.0;    // Rotation angle variable

    // Raymarch loop
    for (float i = 0.0; i++ < 200.0;) {
        s = 0.001 + abs(s) * 0.1;  // Non-linear step scaling
        d += s; 

        // Ray position in 3D space (using adjusted 'time')
        p = vec3(uv * d, d + time * 5.0);

        // Calculate fog/glow effect using simpler, intermediate steps for GLSL 1.0 compatibility
        vec4 glow_base = vec4(0.9, 0.9 - p.z * 0.1 + p.y * 0.05, 0.1, 0.0);
        vec4 sin_input = d * 0.01 + 9.0 + glow_base;
        float divisor = abs(s * 0.01) + 1e-4;
        
        o += sin(sin_input) / divisor;

        // Rotate xy-plane based on z and time
        a = p.z * (0.1);
        mat2 rot = mat2(cos(a), sin(a), -sin(a), cos(a));
        p.xy *= rot;

        // Initial sin field
        s = cos(p.x + p.y);

        // Fractal-like detail using dot product of sin layers
        for (float n = 1.0; n <= 3.0; n += 1.0) {
            vec3 freq = p * n;
            vec3 timeMod = vec3(
                0.0,
                3.0,
                1.5 
            );
            s += abs(dot(0.5 * sin(freq), timeMod)) / max(n, 1E-6);
        }
    }

    // --- Tanh Conversion and Tone Mapping ---
    
    // 1. Calculate the complex argument for tanh
    vec4 tanh_input = o * o * o * o / 3e23;
    
    // 2. Apply the robust tanh approximation
    vec4 toned_color = tanh_approx(tanh_input); 
    
    // 3. Apply final gamma correction (gamma ≈ 2.2)
    o = pow(toned_color, vec4(0.4545));
}
