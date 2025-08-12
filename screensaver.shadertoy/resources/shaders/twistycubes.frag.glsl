// wireframe code modified from FabriceNeyert2: https://www.shadertoy.com/view/XfS3DK

precision mediump float; // Required for GLSL ES 1.00 compatibility

// --- Tanh Approximation Function ---
vec3 tanh_approx(vec3 x) {
    const float EPSILON = 1e-6; // Small epsilon to prevent division by zero for x=0
    return x / (1.0 + max(abs(x), EPSILON)); // Applies component-wise to vec3
}

// --- Tonemap Strength Factor ---
// This factor scales the color value before the tanh_approx function.
// The original shader implicitly used 3.0 (from `c*c*3.`).
// Adjust this to fine-tune the overall brightness and saturation after tonemapping.
// Increase for brighter/more saturated, decrease for darker/less saturated.
#define TONEMAP_STRENGTH_FACTOR 3.0 

// --- Post-Processing BCS Parameters ---
// Adjust these values to control the final look of the output.
// Brightness: Additive adjustment. Range typically -1.0 to 1.0. 0.0 for no change.
#define POST_BRIGHTNESS 0.10 
// Contrast: Multiplicative adjustment. Range typically 0.0 to 2.0+. 1.0 for no change.
#define POST_CONTRAST   1.40 
// Saturation: Blends between grayscale (0.0) and original color (1.0). >1.0 for oversaturated.
#define POST_SATURATION 1.0 

// --- Screen Scaling Zoom Effect ---
// Adjust this to zoom the overall effect in or out on the screen.
// 1.0 = original size.
// > 1.0 = zoom out (makes effect appear smaller, e.g., 1.5 for 50% smaller).
// < 1.0 = zoom in (makes effect appear larger).
#define SCREEN_ZOOM_FACTOR 1.5 // Set to 1.5 for a slightly smaller effect

// --- Macro Definitions ---
// H: Hue palette - ensure all literals are floats (e.g., 90.0 instead of 90)
#define H(a) (cos(radians(vec3(-30.0, 60.0, 150.0)) + (a)*6.2832) * 0.5 + 0.5)

// A: Rotation matrix - ensure all literals are floats
#define A(v) mat2(cos((v)*3.1416 + vec4(0.0, -1.5708, 1.5708, 0.0)))

// s: Segment rendering macro - ensure all literals are floats
// This macro updates the accumulating color 'c' by taking the maximum with a new segment's brightness.
#define s(a, b) c = max(c, 0.01 / abs(L( u, K(a, v, h), K(b, v, h) ) + 0.02) * k_color * 10.0 * o); 


// --- Helper Functions ---

// L: Line distance function
float L(vec2 p, vec3 A, vec3 B)
{
    vec2 a = A.xy;
    vec2 b = B.xy - a;
    p -= a;
    // clamp ensures 'h' is within 0-1 range for valid line segment projection.
    // max(dot(b,b), 1e-6) prevents division by zero if b is a zero vector.
    float h = clamp(dot(p, b) / max(dot(b, b), 1e-6), 0.0, 1.0);
    // 0.01*mix(A.z, B.z, h) adds depth-based fading to the line.
    return length(p - b * h) + 0.01 * mix(A.z, B.z, h);
}

// K: Camera transformation function
vec3 K(vec3 p, mat2 v, mat2 h)
{
    p.zy *= v; // Apply pitch rotation
    p.zx *= h; // Apply yaw rotation
    // Always apply perspective projection (keyboard check removed as per previous request)
    p *= 4.0 / (p.z + 4.0); 
    return p;
}

// --- Main Shader Function ---
void mainImage( out vec4 C, in vec2 U )
{
    // --- Shadertoy Uniforms ---
    // iResolution: Screen resolution (vec2)
    // iMouse: Mouse coordinates (xy) and button state (z, w)
    // iTime: Shader playback time (float)

    vec2 R = iResolution.xy;
    // Normalize UV coordinates and apply SCREEN_ZOOM_FACTOR to make effect smaller
    vec2 u = (U + U - R) / R.y * 1.2 * SCREEN_ZOOM_FACTOR; 
    // Mouse coordinates normalized to -2 to 2 range based on screen height
    vec2 m = (iMouse.xy * 2.0 - R) / R.y; 
    
    float t = iTime*0.2 / 60.0; // Time scaled for animation speed
    float l = 15.0;         // Loop size (number of cubes)
    float j = 1.0 / l;      // Increment size for the loop
    float r = 0.8;          // Scale factor for each successive cube
    float o = 0.1;          // Base brightness for segments
    float i = 0.0;          // Loop counter (starting increment)

    // Default mouse movement if not clicking (circular motion)
    if (iMouse.z < 1.0) // Check if mouse button is NOT pressed
    {
        m = sin(t * 6.2832 + vec2(0.0, 1.5708)); // Circular movement pattern
        m.x *= 2.0; // Stretch the X component to create an elliptical path
    }
    
    mat2 v = A(m.y); // Pitch rotation matrix based on mouse Y
    mat2 h;          // Yaw rotation matrix (will be set in the loop)
    
    vec3 p = vec3(0.0, 1.0, -1.0); // Initial cube coordinates (relative to origin)
    
    // --- Background (now black) ---
    // Temporarily disabled the color shifting background effect as requested.
    vec3 c = vec3(0.0); // Set background to black
    
    vec3 k_color; // Color for the current cube

    // --- Cube Drawing Loop ---
    // Iterates 'l' times to draw nested cubes
    for (; i < 1.0; i += j)
    {
        k_color = H(i + iTime / 3.0) + 0.2; // Generate unique color for each cube
        h = A(m.x + i); // Calculate yaw rotation for current cube, offset by loop iteration
        p *= r; // Scale the cube coordinates inward for nesting effect

        // Draw cube segments using the 's' macro
        s( p.yyz, p.yzz ) 
        s( p.zyz, p.zzz )
        s( p.zyy, p.zzy )
        s( p.yyy, p.yzy )
        s( p.yyy, p.zyy )
        s( p.yzy, p.zzy )
        s( p.yyz, p.zyz )
        s( p.yzz, p.zzz )
        s( p.zzz, p.zzy )
        s( p.zyz, p.zyy )
        s( p.yzz, p.yzy )
        s( p.yyz, p.yyy )
    }
    
    // --- Final Tonemapping ---
    // Apply contrast by squaring 'c', then scale by TONEMAP_STRENGTH_FACTOR,
    // and finally pass through tanh_approx to limit brightness (prevent blowout)
    vec3 final_color = tanh_approx(c * c * TONEMAP_STRENGTH_FACTOR);

    // --- Apply Post-Processing BCS (Brightness, Contrast, Saturation) ---
    // Brightness adjustment
    final_color += POST_BRIGHTNESS;

    // Contrast adjustment
    final_color = (final_color - 0.5) * POST_CONTRAST + 0.5;

    // Saturation adjustment
    // Calculate luminance (grayscale equivalent) using standard ITU-R BT.709 weights
    vec3 grayscale = vec3(dot(final_color, vec3(0.2126, 0.7152, 0.0722))); 
    final_color = mix(grayscale, final_color, POST_SATURATION);

    // Output final color with full opacity
    C = vec4(final_color, 1.0); 
}