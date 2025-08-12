// CC0: Another twister'
// The twister with a twist to the colors
// I like both version so publishes both

#ifdef GL_ES
precision mediump float;
#endif

// --- Robust Tanh Conversion Method Directives ---

// 1. Include the tanh_approx function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6; 
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- Post-Processing BCS Parameters (for final output) ---
// Adjusts the overall brightness of the final image.
// Positive values increase brightness, negative values decrease it.
#define POST_BRIGHTNESS -0.10   // Default: 0.0 (no change)

// Adjusts the contrast of the final image.
// 1.0 is no change. Values > 1.0 increase contrast, values < 1.0 decrease it.
#define POST_CONTRAST   1.10   // Default: 1.0 (no change)

// Adjusts the saturation of the final image.
// 1.0 is no change. 0.0 results in a grayscale image. Values > 1.0 oversaturate.
#define POST_SATURATION 1.0   // Default: 1.0 (no change)

// --- Screen Scaling and Offset Parameters ---
// Controls the zoom level. 1.0 for no zoom.
// Value > 1.0 zooms IN (objects appear larger).
// Value < 1.0 zooms OUT (objects appear smaller).
#define SCREEN_SCALE 0.40

// Controls the X-offset of the effect's center.
// Positive moves the effect center to the right. Scaled by screen height.
#define OFFSET_X     0.30

// Controls the Y-offset of the effect's center.
// Positive moves the effect center upwards. Scaled by screen height.
#define OFFSET_Y     0.150

// --- NEW: Global Post-Rotation Parameter ---
// Controls the speed of clockwise rotation for the entire effect.
// Positive value for clockwise rotation. Set to 0.0 for no rotation.
// Example: 0.05 for a very slow rotation.
#define POST_ROTATION_SPEED 0.05 // Adjust as needed for desired speed

// Helper function for 2D rotation (standard counter-clockwise)
mat2 rotate2D(float a){ return mat2(cos(a), -sin(a), sin(a), cos(a));}


void mainImage(out vec4 O, vec2 C) {
    // 3. Ensure Explicit Variable Initialization: All floats initialized to 0.0
    float
        i = 0.0,            // ray marching iteration counter (steps along ray)
        j = 0.0,            // fractal iteration counter (detail layers)
        d = 0.0,            // distance to nearest surface (SDF value)
        z = 0.0,            // current depth along ray (world space)
        D = 0.0,            // temporary distance calculation for fractal
        S = 0.0,            // fractal scale factor (shrinks each iteration)
        N = 0.0             // fractal layer ID (determines color/material)
    ;
    // 3. Ensure Explicit Variable Initialization: vec4 'o' initialized to vec4(0.0)
    vec4
        o = vec4(0.0),      // accumulated color/glow
        U = vec4(3.0, 1.0, 2.0, 0.0); // utility vector for swizzling/constants (already initialized)
    
    // Main ray marching loop - cast rays from camera through each pixel
    for(
        vec3
            r = iResolution.xyz, // screen resolution (width, height, width) - initialized here
            p = vec3(0.0),       // current 3D position along ray - initialized for first use
            P = vec3(0.0),       // transformed position for distance field - initialized for first use
            X = vec3(0.0)        // saved position for lighting calculations - initialized for first use
        ; i < 66.0               // Loop condition: iterate 66 times (from ++i to 66)
        ; i += 1.0, z += 0.9 * d // Increment i and advance along ray after each iteration
    ) {
        // CAMERA SETUP: Calculate ray direction from screen coordinate to 3D space
        // Apply screen scaling, offset, and now ROTATION
        
        // 1. Normalize fragment coordinates to -0.5 to 0.5 range (relative to screen center)
        vec2 uv = (C - 0.5 * r.xy);

        // 2. Translate uv by the offset to make the desired center (OFFSET_X, OFFSET_Y) the origin for rotation iTime
        vec2 offset_center = vec2(OFFSET_X * r.y, OFFSET_Y * r.y);
        vec2 pre_rotated_uv = uv - offset_center;

        // 3. Apply the rotation to the translated UVs
        // Pass -angle to rotate2D for clockwise rotation
        float rotation_angle = iTime * POST_ROTATION_SPEED;
        vec2 rotated_uv = rotate2D(-rotation_angle) * pre_rotated_uv;

        // 4. Translate back from the temporary origin
        vec2 post_rotated_uv = rotated_uv + offset_center;

        // 5. Apply scaling
        vec2 final_ray_coords = post_rotated_uv / SCREEN_SCALE;

        p = z * normalize(vec3(final_ray_coords, r.y));
        
        // ANIMATION: Move tunnel along Z axis with time
        p.z += iTime*.5;
        
        // TWIST EFFECT: Apply 2D rotation matrix to XY plane
        // Rotation angle varies with Z depth (.1*p.z) creating spiral twist
        // U.wyxw = (1,3,1,3) provides the cos(θ±π/2) pattern for rotation matrix
        p.xy *= mat2(cos(0.1 * p.z + 11.0 * U.wyxw)); // Ensure 0.1, 11.0 are float literals
        
        // Store original position for lighting calculations later
        X = p;
        
        // TUNNEL WALLS: Create symmetric tunnel by folding Y coordinate
        // Distance 3 from origin, abs() creates mirror symmetry
        p.y = 3.0 - abs(p.y); // Ensure 3.0 is float literal
        
        // INFINITE REPETITION: Tile the space every 4 units in X and Z
        // MODIFIED: Replaced round() with floor(x + 0.5) for broader GLSL compatibility
        p.xz -= floor(p.xz / 4.0 + 0.5) * 4.0; // Ensure 4.0 is float literal
        
        
        // GLOWING LINES: Distance to glowing lines/tubes
        // Creates cylindrical structures at offset (2, -0.6) in XY plane
        P = p; // P is reassigned here, so previous initialization is fine
        P.x = abs(P.x);
        d = length(P.xy - vec2(2.0, -0.6)); // Ensure 2.0, -0.6 are float literals
        
        // GLOW ACCUMULATION: Add volumetric glow effect
        // Inverse distance creates bright glow near surfaces
        // U provides color channels (3,1,2,0) = purple glow
        // 4. Enhance General Division Robustness: 1./sqrt(d) -> 1.0/max(sqrt(d), 1e-6)
        // 4. Enhance General Division Robustness: 2./d -> 2.0/max(d, 1e-6)
        o += 9.0 * (1.0 / max(sqrt(d), 1e-6) + 2.0 / max(d, 1e-6)) * U; // Ensure 9.0 is float literal
        
        // FRACTAL DETAIL LAYER: Adds complex surface details using iterated function
        for(
            S = j = 1.0 // Initialize scale and counter
            ; j < 8.0   // Loop condition: iterate 7 times (from ++j to 8)
            ; j += 1.0, S *= 0.507 // Shrink scale each iteration (magic number for good detail)
        )
            // Quartic power iteration creates box-like shapes
            // 4. Enhance General Division Robustness: pow(dot(P,P),.125) - .125 is exponent, no division.
            D = pow(dot(P = p * p * p * p, P), 0.125) - S, // Ensure 0.125 is float literal
            d = max(d, 0.1 * S - D),                     // Boolean subtraction: carve detail from base - Ensure 0.1 is float literal
            D < d ? d = D, N = j : j,                  // Update closest distance and layer ID
            p.xz = -abs(p.xz),                           // Kaleidoscope folding for fractal symmetry
            p += S * 0.5 * U.zyz                       // Translate for next iteration (2,1,2)*scale - Ensure 0.5 is float literal
        ;
        
        // SURFACE REFINEMENT: Prevent ray from getting too close to surface
        // abs()+1e-3 makes interior surfaces semi-transparent
        d = abs(d) + 1e-3;
        
        // COLOR CALCULATION: Generate surface color from position and fractal layer
        // Sine waves create smooth color transitions
        // abs(X.x)/9 varies color across tunnel width
        // N*0.4 gives different colors per fractal layer
        O = 1.0 - sin(U.zywz - 0.4 * X.x + 0.5 * N); // Ensure 1.0, 0.4, 0.5 are float literals
        
        // FINAL ACCUMULATION: Combine surface lighting with volumetric effects
        // O.w/d*O: surface color weighted by proximity (closer = brighter)
        // z³/4000*(...)*U²: depth-based fog with animated intensity
        // sin(.4*T)*sin(.7*T): creates pulsing effect with beating frequency
        // 4. Enhance General Division Robustness: O.w/d*O -> O.w/max(d, 1e-6)*O
        o += O.w / max(d, 1e-6) * O; // Ensure O.w is float, max(d, 1e-6) handles potential division by zero
    }
    
    // TONE MAPPING: Convert HDR accumulation to displayable LDR color
    // 2. Replace tanh() calls: tanh() -> tanh_approx()
    // 4. Enhance General Division Robustness: o/3e4 -> o/max(3e4, 1e-6)
    O = tanh_approx(o / max(3e4, 1e-6)) / 0.8; // Ensure 0.8 is float literal

    // --- Apply Post-Processing BCS to final output ---
    O.rgb += POST_BRIGHTNESS;
    O.rgb = (O.rgb - 0.5) * POST_CONTRAST + 0.5;
    // Saturation
    float luma = dot(O.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 gray = vec3(luma);
    O.rgb = mix(gray, O.rgb, POST_SATURATION);
}