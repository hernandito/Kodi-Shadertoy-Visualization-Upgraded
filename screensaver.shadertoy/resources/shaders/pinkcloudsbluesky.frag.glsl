/*
    GLSL Shader: Abstract Tunnel Raymarcher (Kodi Compatible)
    
    This version includes:
    1. User-tuned color parameters for high contrast and deep blue.
    2. Field of View (FOV) control for zooming.
    3. Robust Tanh Approximation (tanh_approx4).
*/

// --- CONFIGURABLE CONSTANTS (User-Defined Parameters) ---

// Field of View (FOV): Controls the zoom. Lower value = more zoom/narrower view (e.g., 0.5).
const float FOV = 1.50; 

// Brightness: 1.0 is normal.
const float BRIGHTNESS = 0.40;
// Contrast: 1.0 is normal.
const float CONTRAST = 2.950;
// Saturation: 1.0 is normal. 0.0 is grayscale.
const float SATURATION = .90;

// Factor to specifically boost the accumulation weight of the blue channel in the 'water' color.
const float BLUE_INTENSITY_FACTOR = 2.5;

// --- UTILITY CONSTANTS ---
const float EPSILON = 1e-6;

// --- ROBUST TANH CONVERSION METHOD (vec4 implementation) ---
// This approximation function replaces the built-in tanh: x / (1.0 + |x|)
vec4 tanh_approx4(vec4 x) { 
    return x / (1.0 + max(abs(x), vec4(EPSILON))); 
}

// --- BRIGHTNESS, CONTRAST, SATURATION (BCS) ADJUSTMENT ---
vec4 applyBCS(vec4 color, float b, float c, float s) {
    // 1. Contrast
    color.rgb = ((color.rgb - 0.5) * c) + 0.5;
    
    // 2. Saturation
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(luma), color.rgb, s);
    
    // 3. Brightness
    color.rgb *= b;
    
    return color; 
}

void mainImage(out vec4 o, vec2 u) {
    // --- 1. Explicit Variable Initialization ---
    float i = 0.0;
    float d = 0.0;
    float s = 0.0;
    float c = 0.0;
    float w = 0.0;
    float n = 0.0;
    float t = iTime * 0.2; 

    vec3 q = vec3(0.0);
    vec3 p = iResolution.xyz; 

    // --- 2. Coordinate and FOV Setup ---
    // Normalize and center coordinates, then apply the FOV scaling.
    u = (u - p.xy * 0.5) / p.y;
    u *= FOV; // Apply FOV scaling
    u += cos(t * 0.2) * vec2(0.4, 0.1); 

    for (o = vec4(0.0); i++ < 100.0; ) {
        
        q = vec3(u * d, d + t * 16.0);
        p = q;
        p.x += t * 4.0; 

        n = 0.05; 
        while (n < 6.0) {
            p += abs(dot(cos(0.6 * t + 0.4 * p / n), vec3(0.8))) * n;
            q.yz += abs(dot(cos(t + q.z * 0.01 + 0.18 * q / n), vec3(0.8))) * n;
            n += n; 
        }
        
        // --- Accumulation Step ---
        w = 0.2 + 0.6 * abs(16.0 + q.y);
        c = 0.3 + 0.2 * abs(p.y - 32.0);
        s = min(c, w);
        d += s;
        
        // Base color accumulation:
        // Apply BLUE_INTENSITY_FACTOR to the blue (Z) component of the water color (w < c)
        vec4 base_color = w < c ? 
                          vec4(2.0, 4.0, 7.0 * BLUE_INTENSITY_FACTOR, 0.0) / max(s, EPSILON) : // Deep Blue/Cyan (Water)
                          vec4(7.0, 5.0, 8.0, 0.0) / max(s, EPSILON);                          // White/Magenta (Sky/Clouds)
                          
        // Secondary color contribution (Orange/Red streak)
        base_color += 0.1 * vec4(12.0, 2.0, 1.0, 0.0) / max(abs(u.y), EPSILON); 
        
        o += base_color;
    }

    // --- 4. Tanh Conversion and Final Output ---

    // Apply robust approximation to the accumulated color (o/1000.0)
    o = tanh_approx4(o / 1000.0);
    
    // Apply Brightness, Contrast, and Saturation adjustments
    o = applyBCS(o, BRIGHTNESS, CONTRAST, SATURATION);
    
    // Final clamp
    o = clamp(o, 0.0, 1.0);
}
