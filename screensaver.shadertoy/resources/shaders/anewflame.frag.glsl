precision mediump float; // Required for ES 2.0 (ES 1.0 compatible subset)

#define BRIGHTNESS 1.10  // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.2    // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0  // Saturation adjustment (1.0 = neutral)

vec4 tanh_approx(vec4 x) { const float EPSILON = 1e-6; return x / (1.0 + max(abs(x), EPSILON)); }

void mainImage(out vec4 O, vec2 C) {
    vec3 r = vec3(0.0); // Initialize screen resolution
    vec3 o = vec3(0.0); // Initialize output color accumulator
    vec3 p = vec3(0.0); // Initialize current ray position
    vec3 P = vec3(0.0); // Initialize stored/reference position
    float i = 0.0; // Initialize ray step counter
    float j = 0.0; // Initialize temporary variable
    float d = 0.0; // Initialize distance to nearest surface
    float z = 0.0; // Initialize current depth along the ray
    float t = 0.0; // Initialize current time
    O = vec4(0.0); // Initialize output

    r = iResolution; // Assign resolution
    t = iTime*.4; // Assign time

    // RAYMARCHING LOOP: Cast a ray from camera through each pixel
    for (; i < 88.0; i += 1.0) { // Use float increment for ES 1.0 compatibility
        p = z * normalize(vec3(C - 0.5 * r.xy, r.y)); // Convert screen coords to 3D ray direction
        p.z -= 4.0; // Move camera back 4 units
        P = p; // Store original ray position

        // SPACE TRANSFORMATION
        p.xz *= mat2(cos(P.y * P.y / 4.0 + 2.0 * P.y - t + vec4(0, 11, 33, 0))); // Rotate XZ plane
        p.x += sin(0.2 * t - P.x); // Add sinusoidal wave distortion

        // TURBULENCE
        d = j = 9.0; // Initialize d and j
        for (; j > 5.0; j -= 1.0) {
            d /= 0.8; // Increase frequency
            p += 0.4 * (p.y + 2.0) * cos(p.zxy * d - 3.0 * t) / d; // Add scaled noise
        }

        // DISTANCE FIELD
        j = length(p - P); // Distance for coloring
        p = abs(p); // Mirror space

        d = abs(min(max(p.z - 0.1, p.x - 1.0 - 0.3 * P.y), max(p.x - 0.2, p.z - 1.0 - 0.3 * P.y))) + 9e-3; // Box intersection
        z += max(d, 1e-6) / 8.0; // Step forward with robust division

        // COLOR CALCULATION
        P = 1.0 + sin(0.5 + j - P.y + P.z + vec3(2, 3, 4)); // RGB variations

        // VOLUMETRIC RENDERING
        o += P.x / max(d, 1e-6) * P; // Accumulate color with robust division
    }

    // TONE MAPPING and BCS ADJUSTMENT
    vec4 color = tanh_approx(o.xyzx / 2e3); // Compress bright values, output RGBA
    // Luminance calculation
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    // Apply saturation
    vec3 saturated = mix(vec3(luminance), color.rgb, SATURATION);
    // Apply contrast
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    // Apply brightness
    O = vec4(clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0), color.a); // Final output with clamping
}