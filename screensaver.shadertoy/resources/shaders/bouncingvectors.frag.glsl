// Kodi GLSL ES 1.0 Compatible Audio Visualizer (with BCS Controls)
// Vectors by Xor, reactive by PAEz, adapted for GLSL ES 1.0 (Kodi)

#define EPSILON 1e-6

// --- Robust Tanh Conversion Method ---
// Approximates tanh(x) as x / (1.0 + |x|) for GLSL ES 1.0 compatibility.
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// FFT bands
#define LOW_START      0
#define LOW_END        20
#define LOW_COUNT (LOW_END-LOW_START)

#define MID_START      150
#define MID_END        350
#define MID_COUNT (MID_END-MID_START)

#define HIGH_START     490
#define HIGH_END       502
#define HIGH_COUNT (HIGH_END-HIGH_START)

// Main loop parameters
#define MAX_ITERATIONS 80.0
#define COLOR_MULTIPLIER 9.0
#define FINAL_DIVISOR 60000.0

// Ray and space parameters
#define RAY_SCALE 2.0
#define DEPTH_OFFSET_MIN 8.0  // bass = 0
#define DEPTH_OFFSET_MAX 5.0   // bass = 1
#define STEP_SIZE 0.10

// Time-based animation
#define TIME_DIVISOR 20.0
#define PHASE_OFFSET_Y 2.0
#define PHASE_OFFSET_Z 4.0

// Inner loop parameters
#define INNER_LOOP_START 2.0
#define INNER_LOOP_END 9.0

// Mathematical operations
#define CROSS_PRODUCT_WEIGHT 1.0
#define DOT_PRODUCT_WEIGHT 1.0

// Interpolation range for audio parameters
#define FREQUENCY_SCALAR_MIN 1.0
#define FREQUENCY_SCALAR_MAX 1.50

#define GRID_SPACING_SCALAR_MIN 1.0
#define GRID_SPACING_SCALAR_MAX 2.0

#define GLOW_MIN 1.0
#define GLOW_MAX 0.8

#define GRID_DENSITY_MIN 1.0
#define GRID_DENSITY_MAX 3.0

#define DEPTH_MIN 4.0
#define DEPTH_MAX 0.0

#define BRIGHT_MIN 1.0
#define BRIGHT_MAX 0.8

// Color channel weights
#define RED_WEIGHT 1.0
#define GREEN_WEIGHT 1.0
#define BLUE_WEIGHT 1.0
#define ALPHA_WEIGHT 1.0

// --- Post-processing BCS Defines ---
// Adjustments applied after ray-marching is complete.
// BRIGHTNESS_OFFSET: 0.0 is neutral (range: e.g., -0.5 to 0.5)
#define BRIGHTNESS_ADJUST 0.02 
// CONTRAST_SCALE: 0.05 is neutral (range: e.g., -1.0 to 1.0)
#define CONTRAST_ADJUST 0.450 
// SATURATION_SCALE: 1.0 is neutral (range: e.g., 0.0 for grayscale to 2.0 for high saturation)
#define SATURATION_SCALE 1.0

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Explicit variable initializations
    float low = 0.0;
    float mid = 0.0;
    float high = 0.0;
    float time = iTime;
    vec2 resolution = iResolution.xy;
    vec3 pixelCoord = vec3(fragCoord, 0.0);
    vec4 outputColor = vec4(0.0);
    float depth = 0.0;
    float stepDistance = 0.0;
    
    // Band averages calculation (using texture() for general compatibility)
    for (int i = LOW_START; i < LOW_END; ++i) {
        // Sample in the middle of the texel for better averaging
        low += texture(iChannel0, vec2((float(i) + 0.5) / 512.0, 0.5)).r;
    }
    for (int i = MID_START; i < MID_END; ++i) {
        mid += texture(iChannel0, vec2((float(i) + 0.5) / 512.0, 0.5)).r;
    }
    for (int i = HIGH_START; i < HIGH_END; ++i) {
        high += texture(iChannel0, vec2((float(i) + 0.5) / 512.0, 0.5)).r;
    }

    // Avoid dividing by zero and apply scaling
    low  = (LOW_COUNT  > 0) ? (low  / float(LOW_COUNT)) * 1.6 : 0.0;
    mid  = (MID_COUNT  > 0) ? (mid  / float(MID_COUNT)) : 0.0;
    high = (HIGH_COUNT > 0) ? (high / float(HIGH_COUNT)) * 1.7 : 0.0;


    // Interpolate parameters based on audio
    float DEPTH_OFFSET = mix(DEPTH_OFFSET_MIN, DEPTH_OFFSET_MAX, low);
    float FREQUENCY_SCALAR = mix(FREQUENCY_SCALAR_MIN, FREQUENCY_SCALAR_MAX, high);
    float GRID_SPACING_SCALAR = mix(GRID_SPACING_SCALAR_MIN, GRID_SPACING_SCALAR_MAX, high);
    float GLOW = mix(GLOW_MIN, GLOW_MAX, high);
    float GRID_DENSITY = mix(GRID_DENSITY_MIN, GRID_DENSITY_MAX, high);
    depth = mix(DEPTH_MIN, DEPTH_MAX, high); // Initialize depth here
    float BRIGHT = mix(BRIGHT_MIN, BRIGHT_MAX, high);
    
    // Raymarch loop
    for(float iteration = 0.0; iteration < MAX_ITERATIONS; iteration++) {
        // Ray direction normalization
        vec3 rayDir = normalize(pixelCoord.rgb * RAY_SCALE - resolution.xyy);
        
        vec3 position = depth * rayDir;
        vec3 animationVector = normalize(sin(time / TIME_DIVISOR + vec3(0.0, PHASE_OFFSET_Y, PHASE_OFFSET_Z)));
        vec3 tempVector = vec3(0.0); 
        
        position.z += DEPTH_OFFSET;
        
        // Complex vector operation
        tempVector = animationVector = DOT_PRODUCT_WEIGHT * dot(animationVector, position) * animationVector + CROSS_PRODUCT_WEIGHT * cross(animationVector, position);
        
        // Inner loop
        for(stepDistance = INNER_LOOP_START; stepDistance < INNER_LOOP_END; stepDistance++) {
            animationVector += sin(ceil(animationVector * stepDistance * GRID_SPACING_SCALAR) * GLOW - time).yzx / max(stepDistance, EPSILON); // Robust division
        }
        
        // Calculate the step distance
        float current_step_dist = STEP_SIZE * length(sin(animationVector * animationVector * FREQUENCY_SCALAR)) * GLOW * sqrt(length(tempVector * sin(tempVector.yzx*GRID_DENSITY)));
        depth += current_step_dist;
        
        // Robust accumulation
        outputColor += vec4(COLOR_MULTIPLIER * RED_WEIGHT, iteration * GREEN_WEIGHT, depth * BLUE_WEIGHT, ALPHA_WEIGHT) / max(current_step_dist, EPSILON) * BRIGHT;
    }
    
    // Final robust Tanh Conversion
    vec4 tempOutput = outputColor / max(FINAL_DIVISOR, EPSILON);
    outputColor = tanh_approx(tempOutput);

    // --- Apply Brightness, Contrast, Saturation (BCS) ---
    
    // 1. Contrast
    // Adjusts contrast around the mid-gray point (0.5)
    float contrast_scale = 1.0 + CONTRAST_ADJUST;
    outputColor.rgb = (outputColor.rgb - 0.5) * contrast_scale + 0.5;

    // 2. Saturation
    // Calculate luminance (grayscale) and mix the original color with the grayscale based on SATURATION_SCALE
    float luminance = dot(outputColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 gray_color = vec3(luminance);
    outputColor.rgb = mix(gray_color, outputColor.rgb, SATURATION_SCALE);

    // 3. Brightness
    // Simply adds an offset to the color channels
    outputColor.rgb += BRIGHTNESS_ADJUST;

    fragColor = outputColor;
}
