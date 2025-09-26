// Shadertoy uniforms: iTime, iResolution, iChannel0
// Kodi compatible version with robust raymarch and no uniforms

// ---------------- USER PARAMETERS ----------------
#define MARCH_SPEED 0.2
// Controls the size of the letter blocks. Increase for larger, more distinct "squadrons".
#define GRID_SIZE 1.0 
#define BRIGHTNESS .9
#define CONTRAST 1.0
#define SATURATION 1.60
// -------------------------------------------------

// A robust random function
float random(float v0) { return fract(sin(v0 * 943.712) * 43758.5453); }

float random(float v0, float v1) {
    return random(v1 + random(v0) * 100.0);
}

float random(float v0, float v1, float v2) {
    return random(v2 + random(v0, v1) * 100.0);
}

float random(float v0, float v1, float v2, float v3) {
    return random(v3 + random(v0, v1, v2) * 100.0);
}

#define PI 3.14159265358979

// Creates a random 3x3 rotation matrix
mat3 randrot(vec3 p) {
    vec4 q = vec4(
        random(p.x, p.y, p.z, 1.0),
        random(p.x, p.y, p.z, 2.0),
        random(p.x, p.y, p.z, 3.0),
        random(p.x, p.y, p.z, 4.0)
    );
    q = normalize(q - 0.5);
    return mat3(
        1.0 - 2.0 * (q.y * q.y + q.z * q.z), 2.0 * (q.x * q.y - q.z * q.w), 2.0 * (q.z * q.x + q.y * q.w),
        2.0 * (q.x * q.y + q.z * q.w), 1.0 - 2.0 * (q.z * q.z + q.x * q.x), 2.0 * (q.y * q.z - q.x * q.w),
        2.0 * (q.z * q.x - q.y * q.w), 2.0 * (q.y * q.z + q.x * q.w), 1.0 - 2.0 * (q.x * q.x + q.y * q.y)
    );
}

// Signed distance function for a single letter from a texture atlas
float sdfunit(vec3 p, vec2 n) {
    p *= 1.1;
    p = clamp(p, vec3(-0.5), vec3(0.5));
    // Calculate UV for a 16x16 grid of characters
    vec2 u = (p.xy + 0.5) / 16.0 + n;
    // Get the signed distance value from the texture's alpha channel
    float d = texture(iChannel0, u).w - 0.5;
    
    // Combine distance with the thickness of the letter
    const float EPSILON = 1e-6;
    return (length(vec2(max(d, 0.0), max(abs(p.z) - 0.05, 0.0))) - 0.003) / max(1.1, EPSILON);
}

// Signed distance function for the repeating letter grid
float sdf(vec3 p) {
    // Get the coordinate for the current block
    vec3 f = floor(p / GRID_SIZE);
    vec3 q = fract(p / GRID_SIZE) * GRID_SIZE;
    
    // Use the block coordinate to seed the random values
    vec2 rand = vec2(
        random(f.x, f.y, f.z, 1.0),
        random(f.x, f.y, f.z, 2.0)
    );
    rand = floor(rand * 16.0) / 16.0;

    // Return the SDF for the single letter in the current block
    return sdfunit((q - 0.5 * GRID_SIZE) * randrot(f), rand);
}

// Selenium toning filter for a warmer look
vec3 selenium_toner(vec3 color) {
    // Standard sepia matrix with a slight adjustment for a warmer, reddish tone
    vec3 sepia_color = vec3(
        dot(color, vec3(0.393, 0.769, 0.189)),
        dot(color, vec3(0.349, 0.686, 0.168)),
        dot(color, vec3(0.272, 0.534, 0.131))
    );
    
    // Blend the sepia with the original color based on luminance.
    // This allows darker areas to be more toned, while lighter areas retain more original color.
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return mix(color, sepia_color, 1.0 - luminance);
}

// A robust BCS function
vec4 bcs_final(vec4 color, float brightness, float contrast, float saturation) {
    color.rgb += brightness - 1.0;
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    
    // Using a luminance formula that is more robust for saturation
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color.rgb = mix(grayscale, color.rgb, saturation);
    
    return color;
}

void mainImage(out vec4 fragColor, in vec2 p) {
    vec2 r = iResolution.xy;
    vec3 raypos = vec3(0.1, 0.1, iTime * MARCH_SPEED + 0.5);
    // Normalized ray direction from camera
    vec3 raydir = normalize(vec3((p + p - r) / sqrt(r.x * r.y), 1.0));
    
    // Initialize color to white
    fragColor = vec4(1.0);
    
    // Raymarch loop with maximum distance
    for(int i = 0; i++ < 100; ) {
        float d = sdf(raypos) / 1.8;
        raypos += raydir * d;
        
        // Stop raymarching if we are close to the surface
        if (d < 0.001) {
            break;
        }
        
        // Simple fog effect
        fragColor -= 0.01;
    }
    
    // Apply sepia filter to the resulting grayscale image
    fragColor.rgb = selenium_toner(fragColor.rgb);
    
    // Apply BCS post-processing adjustments
    fragColor = bcs_final(fragColor, BRIGHTNESS, CONTRAST, SATURATION);
}
