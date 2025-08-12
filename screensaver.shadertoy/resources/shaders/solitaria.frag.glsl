// Paper Lantern created by SeongWan Kim (kaswan / twitter @idgmatrix)
// Thanks to iq and @kevinroast 
// shadow and glow effect codes from http://www.kevs3d.co.uk/dev/shaders/distancefield6.html

#define EPSILON 0.005
#define MAX_ITERATION 256
#define AO_SAMPLES 4
#define SSS_SAMPLES 5
#define SHADOW_RAY_DEPTH 16

// Post-processing parameters
#define BRIGHTNESS -0.160    // Adjust brightness: 0.0 for no change, positive for brighter, negative for darker
#define CONTRAST 1.8      // Adjust contrast: 1.0 for no change, >1.0 for more contrast, <1.0 for less
#define SATURATION 1.0    // Adjust saturation: 1.0 for no change, >1.0 for more saturated, <1.0 for desaturated
#define MAX_BRIGHTNESS 0.80 // Maximum RGB value to prevent pure whites

// Zoom parameter
#define ZOOM_SCALE 0.80    // Adjust zoom: 1.0 for no zoom, >1.0 to zoom in, <1.0 to zoom out

// Robust Tanh Conversion Method: tanh_approx function
vec4 tanh_approx(vec4 x) {
    const float EPSILON_TANH = 1e-6; // Using a distinct epsilon for tanh_approx
    return x / (1.0 + max(abs(x), EPSILON_TANH));
}

#define rot(a) mat2(cos(a + vec4(0, 11, 33, 0)))
#define r iResolution
#define pi acos(-1.)
#define tau 2. * pi
// Reverted: Using iTime directly as requested
#define t iTime * .2 

float map(vec3 p){
    // Robust Tanh Conversion Method: Explicit Variable Initialization
    float e = 1e5, d = 1e5; // e1, e2 were unused, removed them for cleaner code
    
    // Robust Tanh Conversion Method: Replace tanh() calls
    p.xy *= rot(tanh_approx(vec4(sin(t * .2) * 8. + 5.)) * pi/2.);
    p.zx *= rot(tanh_approx(vec4(sin(t * .1) * 8. - 5.)) * pi/2. - .8);
    
    // Robust Tanh Conversion Method: Explicit Variable Initialization
    for(float i = 0.0; i < 32.0; i++){ // Initialize i to 0.0
        float a = i * tau / 42. + t * .3;
        vec2 g1 = vec2(
                    (2. + cos(3. * a)) * sin(2. * a),
                    (2. + cos(3. * a)) * cos(2. * a)
                );
        vec2 g2 = vec2(
                    cos(a) + 2. * cos(2. * a),
                    sin(a) - 2. * sin(2. * a)
                );

        vec3 k = vec3(g1, sin(3. * a)) * .5;
                    
        e = length(p - k) - .45;
        d = min(d, e);
    }
    
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Robust Tanh Conversion Method: Explicit Variable Initialization
    fragColor = vec4(0.0); // Explicitly initialize to vec4(0.0)
    
    // Robust Tanh Conversion Method: Enhance General Division Robustness
    vec2 u = (fragCoord - r.xy / 2.0) / max(r.y, 1E-6) / ZOOM_SCALE; // Apply zoom scale to UV
    
    // Robust Tanh Conversion Method: Explicit Variable Initialization
    vec3 p = vec3(0.0, 0.0, -5.0); // Explicitly initialize to vec3(0.0, 0.0, -5.0)
    vec3 D = normalize(vec3(u, 2.0) / ZOOM_SCALE); // Adjust ray direction with zoom scale
    
    // Robust Tanh Conversion Method: Explicit Variable Initialization for accumulators
    float s = 0.0; // Initialize s
    float i = 0.0; // Initialize i
    float d = 0.0; // Initialize d, as it accumulates
    float e = 0.0; // Initialize e, as it accumulates
    
    while(i++ < 20.0){
        s = map(p);
        p += s * D;
        d += s;

        // Robust Tanh Conversion Method: Enhance General Division Robustness
        e += max(.03 / max(d, 1E-6), 0.0); // Added max(..., 1E-6) for robustness
    }
    
    fragColor = vec4(e * 5.0, e * e * 25.1, e, 1.0); 
    fragColor.z = (p.z < -.85 ? 3.0 : 2.5) - d / 1.5;
    
    // Apply BCS post-processing
    // Brightness
    fragColor.rgb += BRIGHTNESS;
    // Contrast
    fragColor.rgb = ((fragColor.rgb - 0.5) * CONTRAST) + 0.5;
    // Saturation
    float luma = dot(fragColor.rgb, vec3(0.299, 0.587, 0.114)); // Standard NTSC luma weights
    vec3 grayscale = vec3(luma);
    fragColor.rgb = mix(grayscale, fragColor.rgb, SATURATION);
    
    // Clamp to prevent pure whites
    fragColor.rgb = min(fragColor.rgb, vec3(MAX_BRIGHTNESS));
}