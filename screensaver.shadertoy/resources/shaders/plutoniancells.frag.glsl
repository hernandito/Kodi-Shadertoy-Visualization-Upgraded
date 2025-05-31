//
//
//
//
//
//


// The MIT License
// Copyright © 2013 Inigo Quilez

#define ANIMATE

// Toggle for the vignette effect (comment out to disable)
#define VIGNETTE_ENABLED

// --- Parameters (Grouped for Easy Adjustment) ---

// Voronoi Settings
const float voronoiScale = 46.0;    // Scale factor for the Voronoi pattern (controls the number of cells)
                                    //   - Increase for more cells (e.g., 48.0), decrease for fewer cells (e.g., 20.0)
const float mdInitial = 48.0;       // Initial distance for Voronoi calculations (ensures algorithm stability)
                                    //   - Should be large enough to cover the expected maximum distance between points
                                    //   - Typically set to match or exceed voronoiScale for robustness

// Feature Points Settings
const vec3  featureColor = vec3(1.0, 0.6, 0.1); // Color of the feature points (yellow-orange)
const float featureGlowRadius = 0.12;           // Radius of the soft glow around feature points
const float featureCoreRadius = 0.04;           // Radius of the bright core of feature points
const float featureBrightness = 1.0;            // Brightness scaling for feature points (0.0 to 1.5)

// Border Settings
const vec3  borderColor = vec3(0.30, 0.1, 0.10); // Color of the Voronoi borders (dark red)
const float borderFadeStart = 0.04;              // Start of the border fade
const float borderFadeEnd = 0.07;                // End of the border fade

// Isoline Settings
const float isolineFrequency = 64.0; // Frequency of the isolines
const float isolineAmplitude = 0.5;  // Amplitude of the isolines (0.0 to 1.0)

// Gradient Overlay Settings
const vec3  gradientStart = vec3(200.0 / 255.0); // Center color of the gradient (#C8C8C8)
const vec3  gradientEnd = vec3(0.0);             // Edge color of the gradient (#000000)
const float gradientScale = 1.06;                // Scale of the gradient
const float gradientOpacity = 0.85;              // Opacity of the gradient (0.0 to 1.0)
const float gradientNormalize = 0.707;           // Normalization factor for the gradient

// Vignette Settings (used when VIGNETTE_ENABLED is defined)
const float vignetteDarkness = 0.1;     // Maximum darkness at the edges (0.0 to 1.0)
const float vignetteBlur = 0.25;        // Transition width of the vignette
const float vignetteRectSize = 0.40;    // Half-size of the inner bright rectangle
const float vignetteCornerRadius = 0.2; // Corner radius of the vignette

// Final Adjustments
const float brightness = 0.0;  // Overall brightness adjustment (-1.0 to 1.0)
const float contrast = 1.025;  // Contrast adjustment (0.0 to 2.0)
const float saturation = 1.4;  // Saturation adjustment (0.0 to 2.0)

// --- End of Parameters ---

vec2 hash2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

// Reverted voronoi function to return a single vec3
vec3 voronoi(in vec2 x) {
    vec2 ip = floor(x);
    vec2 fp = fract(x);

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
    vec2 mg, mr;

    float md = mdInitial;
    for (int j = -1; j <= 1; j++)
    for (int i = -1; i <= 1; i++) {
        vec2 g = vec2(float(i), float(j));
        vec2 o = hash2(ip + g);
        #ifdef ANIMATE
        o = 0.5 + 0.5 * sin(iTime + 6.2831 * o);
        #endif
        vec2 r = g + o - fp;
        float d = dot(r, r);

        if (d < md) {
            md = d;
            mr = r;
            mg = g;
        }
    }

    //----------------------------------
    // second pass: distance to borders
    //----------------------------------
    md = mdInitial;
    for (int j = -2; j <= 2; j++)
    for (int i = -2; i <= 2; i++) {
        vec2 g = mg + vec2(float(i), float(j));
        vec2 o = hash2(ip + g);
        #ifdef ANIMATE
        o = 0.5 + 0.5 * sin(iTime + 6.2831 * o);
        #endif
        vec2 r = g + o - fp;

        if (dot(mr - r, mr - r) > 0.00001)
            md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
    }

    return vec3(md, mr);
}

// Rounded Rectangle Distance Function for Vignette
float roundedRect(vec2 p, vec2 center, vec2 halfSize, float r) {
    vec2 d = abs(p - center) - halfSize + vec2(r);
    return length(max(d, vec2(0.0))) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = fragCoord / iResolution.xx;

    vec3 c = voronoi(voronoiScale * p);

    // isolines
    vec3 col = c.x * (isolineAmplitude + isolineAmplitude * sin(isolineFrequency * c.x)) * vec3(1.0);
    // borders
    col = mix(borderColor, col, smoothstep(borderFadeStart, borderFadeEnd, c.x));

    // feature points (static brightness)
    float dd = length(c.yz);
    vec3 adjustedFeatureColor = featureColor * featureBrightness;
    col = mix(adjustedFeatureColor, col, smoothstep(0.0, featureGlowRadius, dd));
    col += adjustedFeatureColor * (1.0 - smoothstep(0.0, featureCoreRadius, dd));

    // Gradient Overlay (Radial, Multiply)
    vec2 uv = fragCoord / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;
    float dist = length(uv - vec2(0.5 * iResolution.x / iResolution.y, 0.5)) / gradientScale;
    dist = dist / gradientNormalize;
    dist = clamp(dist, 0.0, 1.0);
    float gradientFactor = mix(gradientStart.r, gradientEnd.r, dist);
    col *= mix(1.0, gradientFactor, gradientOpacity);

    // Dark Rounded Vignette Effect (darkens edges, center untouched)
    #ifdef VIGNETTE_ENABLED
        // Compute normalized screen coordinates (0 to 1)
        vec2 uv_norm = fragCoord.xy / iResolution.xy;
        // Adjust for aspect ratio to make the vignette proportional
        uv_norm.x *= iResolution.x / iResolution.y;
        // Scale the half-size to account for aspect ratio
        vec2 scaledRectSize = vec2(vignetteRectSize * iResolution.x / iResolution.y, vignetteRectSize);
        // Center the rectangle in normalized coordinates
        vec2 center = vec2(0.5 * iResolution.x / iResolution.y, 0.5);
        // Compute distance to the rounded rectangle
        float dRect = roundedRect(uv_norm, center, scaledRectSize, vignetteCornerRadius);
        // Create a mask: 1.0 in the center, 0.0 at the edges
        float vignetteMask = 1.0 - smoothstep(0.0, vignetteBlur, dRect);
        // Apply a non-linear falloff for a more gradual transition
        vignetteMask = pow(vignetteMask, 1.5);
        // Apply vignette: darken the edges, leave the center untouched
        col *= mix(1.0 - vignetteDarkness, 1.0, vignetteMask);
    #endif

    // Final Adjustments: Brightness, Contrast, and Saturation
    col += brightness;
    col = clamp(col, 0.0, 1.0);

    col = (col - 0.5) * contrast + 0.5;
    col = clamp(col, 0.0, 1.0);

    float luminance = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luminance), col, saturation);
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}









/*    IMAGE BASED
#define ANIMATE

vec2 hash2(vec2 p) {
    return textureLod(iChannel0, (p + 0.5) / 256.0, 0.0).xy;
}

vec3 voronoi(in vec2 x) {
    vec2 ip = floor(x);
    vec2 fp = fract(x);

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
    vec2 mg, mr;

    float md = 48.0;
    for (int j = -1; j <= 1; j++)
    for (int i = -1; i <= 1; i++) {
        vec2 g = vec2(float(i), float(j));
        vec2 o = hash2(ip + g);
        #ifdef ANIMATE
        o = 0.5 + 0.5 * sin(iTime + 6.2831 * o);
        #endif
        vec2 r = g + o - fp;
        float d = dot(r, r);

        if (d < md) {
            md = d;
            mr = r;
            mg = g;
        }
    }

    //----------------------------------
    // second pass: distance to borders
    //----------------------------------
    md = 33.0;
    for (int j = -2; j <= 2; j++)
    for (int i = -2; i <= 2; i++) {
        vec2 g = mg + vec2(float(i), float(j));
        vec2 o = hash2(ip + g);
        #ifdef ANIMATE
        o = 0.5 + 0.5 * sin(iTime + 6.2831 * o);
        #endif
        vec2 r = g + o - fp;

        if (dot(mr - r, mr - r) > 0.00001)
            md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
    }

    return vec3(md, mr);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = fragCoord / iResolution.xx;

    vec3 c = voronoi(48.0 * p);

    // isolines
    vec3 col = c.x * (0.5 + 0.5 * sin(64.0 * c.x)) * vec3(1.0);
    // borders
    col = mix(vec3(.30, 0.1, 0.10), col, smoothstep(0.04, 0.07, c.x));
    // feature points
    float dd = length(c.yz);
    col = mix(vec3(1.0, 0.6, 0.1), col, smoothstep(0.0, 0.12, dd));
    col += vec3(1.0, 0.6, 0.1) * (1.0 - smoothstep(0.0, 0.04, dd));

    fragColor = vec4(col, 1.0);
}



   THIS IS ALL PROCEDURAL VORONIE CALCULATIOINS 


// The MIT License
// Copyright © 2013 Inigo Quilez

#define ANIMATE

vec2 hash2(vec2 p) {
    // Use procedural white noise instead of texture
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

vec3 voronoi(in vec2 x) {
    vec2 ip = floor(x);
    vec2 fp = fract(x);

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
    vec2 mg, mr;

    float md = 48.0;
    for (int j = -1; j <= 1; j++)
    for (int i = -1; i <= 1; i++) {
        vec2 g = vec2(float(i), float(j));
        vec2 o = hash2(ip + g);
        #ifdef ANIMATE
        o = 0.5 + 0.5 * sin(iTime + 6.2831 * o);
        #endif
        vec2 r = g + o - fp;
        float d = dot(r, r);

        if (d < md) {
            md = d;
            mr = r;
            mg = g;
        }
    }

    //----------------------------------
    // second pass: distance to borders
    //----------------------------------
    md = 33.0;
    for (int j = -2; j <= 2; j++)
    for (int i = -2; i <= 2; i++) {
        vec2 g = mg + vec2(float(i), float(j));
        vec2 o = hash2(ip + g);
        #ifdef ANIMATE
        o = 0.5 + 0.5 * sin(iTime + 6.2831 * o);
        #endif
        vec2 r = g + o - fp;

        if (dot(mr - r, mr - r) > 0.00001)
            md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
    }

    return vec3(md, mr);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = fragCoord / iResolution.xx;

    vec3 c = voronoi(48.0 * p);

    // isolines
    vec3 col = c.x * (0.5 + 0.5 * sin(64.0 * c.x)) * vec3(1.0);
    // borders
    col = mix(vec3(.30, 0.1, 0.10), col, smoothstep(0.04, 0.07, c.x));
    // feature points
    float dd = length(c.yz);
    col = mix(vec3(1.0, 0.6, 0.1), col, smoothstep(0.0, 0.12, dd));
    col += vec3(1.0, 0.6, 0.1) * (1.0 - smoothstep(0.0, 0.04, dd));

    fragColor = vec4(col, 1.0);
}

*/
