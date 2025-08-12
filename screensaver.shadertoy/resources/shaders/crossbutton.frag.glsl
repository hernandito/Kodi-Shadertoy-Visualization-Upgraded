#define T iTime*.3
#define PI 3.141596
#define S smoothstep

mat2 rotate(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

// https://www.shadertoy.com/view/XtGfzw
float sdCross(in vec2 p, in vec2 b, float r)
{
    p = abs(p); p = (p.y>p.x) ? p.yx : p.xy;
    vec2  q = p - b;
    float k = max(q.y,q.x);
    vec2  w = (k>0.0) ? q : vec2(b.y-p.x,-k);
    return sign(k)*length(max(w,0.0)) + r;
}

vec4 tanh_approx(vec4 x) { const float EPSILON = 1e-6; return x / (1.0 + max(abs(x), EPSILON)); }

void mainImage(out vec4 O, in vec2 I){
    vec2 R = iResolution.xy;
    vec2 uv = (I*2.-R)/R.y;

    O = vec4(0.0, 0.0, 0.0, 1.0); // Initialize output with alpha 1.0

    vec3 ro = vec3(0.,0.,-20.);
    vec3 rd = normalize(vec3(uv, 1.));
    float z = 0.0; // Initialize depth
    float d = 1e10; // Initialize distance
    vec3 p = vec3(0.0); // Initialize current ray position

    #define BRIGHTNESS 1.10   // Brightness adjustment (1.0 = neutral)
    #define CONTRAST 1.70     // Contrast adjustment (1.0 = neutral)
    #define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)

    // --- PALETTE DEFINITIONS ---
    #define NUM_COLORS 5
    #define COLOR_HOLD_TIME 6.5        // Seconds to hold a color combination
    #define COLOR_TRANSITION_TIME 1.5  // Seconds for smooth transition between colors

    // Toggle for selecting between original shader coloring and the new palette
    // Set to 1 to use the new palette, 0 to use the original shader's coloring.
    #define USE_NEW_PALETTE 0

    // Define the color palette (order chosen to separate similar colors for better visual distinction)
    vec3 paletteColors[NUM_COLORS];
    paletteColors[0] = vec3(0.9215, 0.9215, 0.8274); // #ebebd3 (light beige)
    paletteColors[1] = vec3(0.0, 0.612, 1.588);      // Updated as requested: no blue
    paletteColors[2] = vec3(0.9765, 0.3412, 0.2196); // #f95738 (red-orange)
    paletteColors[3] = vec3(0.9569, 0.8275, 0.3686); // #f4d35e (yellow)
    paletteColors[4] = vec3(0.9333, 0.5882, 0.2941); // #ee964b (orange)



    // Calculate palette blending based on time for smooth transitions and holds
    float segmentDuration = COLOR_HOLD_TIME + COLOR_TRANSITION_TIME;
    float currentGlobalTime = T*6.0;

    // GLSL ES 1.00 compatible modulo for floats: x - y * floor(x / y)
    float totalCycleDuration = segmentDuration * float(NUM_COLORS);
    float normalizedGlobalTime = currentGlobalTime - totalCycleDuration * floor(currentGlobalTime / totalCycleDuration);

    // Determine the current and next color segments in the cycle
    int currentSegment = int(floor(normalizedGlobalTime / segmentDuration));

    // GLSL ES 1.00 compatible integer modulo: x - (x / y) * y
    int idx1 = currentSegment - (currentSegment / NUM_COLORS) * NUM_COLORS;
    int idx2 = (currentSegment + 1) - ((currentSegment + 1) / NUM_COLORS) * NUM_COLORS;

    float segmentProgress = normalizedGlobalTime - float(currentSegment) * segmentDuration;

    // These are the two primary colors currently active in the time cycle
    vec3 colorA = paletteColors[idx1];
    vec3 colorB = paletteColors[idx2];

    // Calculate the time-based blend factor, with a hold period at the start of each segment
    float timeBlendFactor = S(COLOR_HOLD_TIME, segmentDuration, segmentProgress); // Smooth transition after hold

    for(float i = 0.; i < 100.; i++){
        p = ro + rd * z;

        p.xz *= rotate(T*.5);
        p.xy *= rotate(T*.5);

        d = sdCross(p.xz, vec2(4,1), 0.);
        d = length(vec2(d,p.y))-2.;
        d = sdCross(vec2(d,p.y), vec2(4,1), 0.); // Corrected 'avec2' to 'vec2'

        d = abs(d)+0.01;

        // The base intensity/pattern from the original shader.
        // This is now a constant value to disable the animating diagonal "shadow".
        float originalPatternIntensity = 1.1;

        // The original color calculation base, which includes the rainbow spectrum.
        vec3 originalRainbowEffectBase = (1.1 + sin(vec3(3,2,1) + (p.x+p.z)*0.2 - T*2.0));

        vec3 finalRayColor;

        #if USE_NEW_PALETTE
            // To ensure two colors are visible on the geometry at the same time,
            // we create a spatial blend between colorA and colorB based on p.y.
            float spatialMixFactor = S(-5.0, 5.0, p.y);
            vec3 spatiallyBlendedColor = mix(colorA, colorB, spatialMixFactor);

            // Now, we need to smoothly transition the *pair* of colors over time.
            // We blend the current spatial blend with the spatial blend of the *next* pair in the cycle.
            int nextIdx1 = idx2; // The second color of the current pair becomes the first of the next
            int nextIdx2 = (idx2 + 1) - ((idx2 + 1) / NUM_COLORS) * NUM_COLORS; // The next color in sequence

            vec3 nextPairColor1 = paletteColors[nextIdx1];
            vec3 nextPairColor2 = paletteColors[nextIdx2];

            vec3 nextSpatialBlend = mix(nextPairColor1, nextPairColor2, spatialMixFactor);

            // Blend between the current and next spatial blends using the time-based blend factor.
            vec3 timeAndSpatiallyBlendedColor = mix(spatiallyBlendedColor, nextSpatialBlend, timeBlendFactor);

            // Modulate the final color by the original pattern's intensity.
            finalRayColor = timeAndSpatiallyBlendedColor * originalPatternIntensity;
        #else
            // If new palette is disabled, use the original shader's rainbow coloring.
            finalRayColor = originalRainbowEffectBase;
        #endif

        // Apply the chosen color influence to the output
        O.rgb += finalRayColor / max(d, 1e-6); // This line is different from the SSS version
        z += d*.5;

        if(z>100. || d<1e-3) break;
    }

    // TONE MAPPING and BCS ADJUSTMENT (from original shader)
    vec3 color = tanh_approx(vec4(O.rgb, 0.0) / max(3e3, 1e-6)).rgb; // Compress bright values with robust division
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), color, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    O.rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0); // Final RGB with clamping
    O.a = 1.0; // Preserve alpha
}
