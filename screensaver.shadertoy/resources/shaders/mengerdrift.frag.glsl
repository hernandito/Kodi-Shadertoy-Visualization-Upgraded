#ifdef GL_ES
precision mediump float;
#endif

const float EPSILON = 1e-6; // Epsilon for robust division and tanh_approx

// Robust tanh approximation function
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- Animation Speed Control ---
// ANIMATION_SPEED: Multiplier for the overall animation speed.
// A value of 1.0 is normal speed. Higher values make it faster, lower values make it slower.
#define ANIMATION_SPEED 0.4
// -------------------------------

// --- Tanh Amplitude Scale ---
// TANH_AMPLITUDE_SCALE: Adjusts the amplitude of the camera's "look around" motion.
// Increase this value to make the camera's target move more dramatically,
// compensating for the compression introduced by tanh_approx.
// A value around 1.45 helps to match the original tanh's amplitude.
#define TANH_AMPLITUDE_SCALE 1.45
// ----------------------------

// --- Ambient Occlusion Parameters ---
// AO_STRENGTH: Overall intensity of the ambient occlusion effect. (e.g., 0.5 to 2.0)
#define AO_STRENGTH 1.0
// AO_SAMPLE_COUNT: Number of samples taken to calculate AO. (e.g., 3 to 8)
#define AO_SAMPLE_COUNT 5
// AO_SAMPLE_STEP_SCALE: Controls the distance between AO samples. (e.g., 0.5 to 1.5)
#define AO_SAMPLE_STEP_SCALE 1.0
// AO_FALLOFF_FACTOR: Controls how quickly the AO effect diminishes. (e.g., 0.5 to 0.9)
#define AO_FALLOFF_FACTOR 0.7
// ------------------------------------

// --- Post-Processing Parameters (Brightness, Contrast, Saturation) ---
// BRIGHTNESS: Adjusts overall brightness (-1.0 to 1.0)
#define BRIGHTNESS -0.10
// CONTRAST: Adjusts contrast (0.0 for no contrast, >1.0 for more)
#define CONTRAST .90
// SATURATION: Adjusts color saturation (0.0 for grayscale, >1.0 for more vivid)
#define SATURATION 1.0
// -------------------------------------------------------------------

// --- Light Brightness Parameter ---
// LIGHT_BRIGHTNESS_SCALE: Multiplier for the overall brightness of the light sources.
// A value of 1.0 is default. Increase for brighter lights, decrease for dimmer.
#define LIGHT_BRIGHTNESS_SCALE 0.85
// ----------------------------------

// look around speed
#define LOOK_SPEED 2.0 // Explicit float literal

// max iterations (steps)
#define MARCH_ITERS 160.0 // Explicit float literal

// delete if you don't want
//#define LIGHT_GLIMMER // User requested this to be commented out

// speed
#define T (iTime * 0.2 * ANIMATION_SPEED) // Apply animation speed control

#define LOOK_FREQ (tanh_approx(vec4(cos((T*0.3)*0.125)*9.0)).x) // Use tanh_approx, convert to vec4, take .x
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize

bool fractalHit = false; // Explicitly initialized

// @Shane
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
    n = max((abs(n) - 0.2)*7.0, 0.001); // Explicit float literals
    n /= max((n.x + n.y + n.z), EPSILON); // Robust division
    
    // Changed texture2D to texture to match original golfed version's likely intent for Kodi compatibility
    return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

// @Shane's Menger function hacked up
// MENGERLAYER macro expanded directly into fractal function to avoid compile errors
float fractal(in vec3 q){
    float d_val = 0.0; // Explicitly initialized
    float s_val = 16.0; // Explicitly initialized
    vec3 p = q;
    d_val = 1.0; // Explicitly initialized

    // MENGERLAYER(5.0, min, 4.0); expanded
    s_val /= (5.0);
    p = abs(fract(q/s_val)*s_val - s_val*0.5);
    d_val = min(d_val, min(max(p.x, p.y),
                  min(max(p.y, p.z),
                  max(p.x, p.z))) - s_val/(4.0));

    // MENGERLAYER(6.0, max, 5.5); expanded
    s_val /= (6.0);
    p = abs(fract(q/s_val)*s_val - s_val*0.5);
    d_val = max(d_val, min(max(p.x, p.y),
                  min(max(p.y, p.z),
                  max(p.x, p.z))) - s_val/(5.5));

    // MENGERLAYER(4.0, max, 3.5); expanded
    s_val /= (4.0);
    p = abs(fract(q/s_val)*s_val - s_val*0.5);
    d_val = max(d_val, min(max(p.x, p.y),
                  min(max(p.y, p.z),
                  max(p.x, p.z))) - s_val/(3.5));

    return d_val;
}

float map(vec3 p){
    p.y -= 1.0; // Explicit float literal
    return fractal(p);
}

vec3 look(vec3 p) {
    float t_local_oscillations = T * LOOK_SPEED; // Use local time for look function
    return (p - vec3(
                tanh_approx(vec4(cos(t_local_oscillations * 0.5)*2.0)).x * 6.5 * TANH_AMPLITUDE_SCALE, // Apply TANH_AMPLITUDE_SCALE
                tanh_approx(vec4(cos(t_local_oscillations * 0.7)*3.0)).x * 2.5 * TANH_AMPLITUDE_SCALE, // Apply TANH_AMPLITUDE_SCALE
                5.0 + T)); // Use global T for this part, as in original.
}

// @Shane - Ambient Occlusion function with adjustable parameters
float AO(in vec3 pos, in vec3 nor) {
    float sca = AO_STRENGTH; // Use AO_STRENGTH parameter
    float occ = 0.0; // Explicitly initialized
    for( int i=0; i<AO_SAMPLE_COUNT; i++ ){ // Use AO_SAMPLE_COUNT parameter
        float hr = 0.01 + float(i)*AO_SAMPLE_STEP_SCALE/4.0; // Use AO_SAMPLE_STEP_SCALE
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= AO_FALLOFF_FACTOR; // Use AO_FALLOFF_FACTOR
    }
    return clamp( 1.0 - occ, 0.0, 1.0 ); // Explicit float literals
}

// Function to apply Brightness, Contrast, and Saturation adjustments
vec4 adjustBCS(vec4 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color.rgb += brightness;
    // Apply contrast (pivot around 0.5)
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    // Apply saturation (mix with grayscale)
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // Calculate luminance
    color.rgb = mix(vec3(luma), color.rgb, saturation); // Mix between grayscale and original color
    // Clamp to ensure values stay within [0, 1] range
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    return color;
}

void mainImage(out vec4 o, in vec2 u) {
    float s = 0.002; // Explicitly initialized
    float d = 0.0; // Explicitly initialized
    float i = 0.0; // Explicitly initialized
    float a = 0.0; // Explicitly initialized
    vec3 r = iResolution.xyz; // Explicitly initialized
    
    u = rot(sin(T*0.16)*3.3)*(u-r.xy/2.0)/max(r.y, EPSILON); // Explicit float literals, robust division
    
    vec3 e = vec3(0.01,0.0,0.0); // Explicitly initialized
    vec3 p = vec3(0.0,0.0,T); // Explicitly initialized
    vec3 ro = p; // Explicitly initialized
    
    vec3 Z = N( vec3(0.0,0.0,T+3.0) - look(p) - p); // Explicit float literals
    vec3 X = N(vec3(Z.z,0.0,-Z.x)); // Explicit float literals. Assuming -Z.x for the golfed -Z
    vec3 D = vec3(u, 1.0)* mat3(-X, cross(X, Z), Z); // Explicit float literal

    o = vec4(0.0); // Explicitly clear output color
    while(i++ < MARCH_ITERS && s > 0.001) // Explicit float literal
        p = ro + D * d,
        d += (s = map(p)*0.65); // Explicit float literal
        
    r = N(map(p) - vec3(map(p-e.xyy), // Use r as a temporary for normal calculation
                        map(p-e.yxy),
                        map(p-e.yyx)));
    
    vec4 lights = vec4(1.0); // Explicitly initialized
    o.rgb  = pow(tex3D(iChannel0, p*5.0, r), vec3(2.2)); // Explicit float literals

    #ifdef LIGHT_GLIMMER
    lights = abs(o /
        max(dot(cos(0.3*iTime+p),vec3(0.01)), EPSILON)); // Robust division, explicit float literal
    #else
    lights = vec4(16.0); // Explicit float literal
    #endif
    o *= 2.0 * AO(p, r) * lights * LIGHT_BRIGHTNESS_SCALE; // Apply AO_STRENGTH through the AO function, and LIGHT_BRIGHTNESS_SCALE
    o = tanh_approx(o / max(5.0, EPSILON) * d); // Use tanh_approx, robust division

    // Apply BCS adjustments in post-processing
    o = adjustBCS(o, BRIGHTNESS, CONTRAST, SATURATION);
}
