vec4 tanh_approx(vec4 x) { float EPSILON = 1e-6; return x / (1.0 + max(abs(x), EPSILON)); }

float PI = 3.14159265359;
float TWOPI = 6.28318530718;

vec3 cos_reduced(vec3 x) {
    vec3 n = floor(x / TWOPI + 0.5);
    return cos(x - n * TWOPI);
}

float sin_reduced(float x) {
    float n = floor(x / TWOPI + 0.5);
    return sin(x - n * TWOPI);
}

// Define BCS (Brightness, Contrast, Saturation) parameters
#define BRIGHTNESS .90
#define CONTRAST 1.20
#define SATURATION 1.0

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
    vec2 I = fragCoord;
    vec4 O = vec4(0.0);
    vec3 r = iResolution;
    vec3 c = vec3(0.0);
    vec3 p = vec3(0.0);
    float z = 0.0;
    float f = 0.0;
    float ii = 0.0;  // renamed from i to avoid keyword conflict if any
    
    while( ii < 50.0 ) {
        // Turbulence distortion loop
        p = z * (vec3(I, 0.0) / 0.4 - r.xyy) / r.y;
        p.y = abs(p.y + 2.0);
        c = p;
        p.x *= 0.2;
        float freq = 1.2;
        for( int k = 0; k < 8; k++ ) {
            p += cos_reduced(p.yzx * freq - iTime / 4.0) / freq;
            freq += 1.0;
        }
        // Add original coordinates for smoothness
        p += c;
        // Clamp p.y to positive for robustness in reflection
        float py = max(p.y, 1e-6);
        // Step forward with waves for clouds/water
        vec3 cos_term = cos_reduced(p / py) / 8.0;
        float sin_term = sin_reduced(py / 7.0) * 0.4;
        f = length(cos_term + sin_term);
        z += f;
        // Horizon coloring and shade clouds and add sun
        vec4 horizon = cos(c.y / 14.0 - vec4(7.0, 2.0, 3.0, 0.0)) + 1.0;
        float sun_term = length(c.xy / max(z, 1e-6) - 0.6) - 0.1;
        float denom_sun = max(sun_term, 0.1);
        float denom_cloud = max(0.9 + py * f, 1e-6);
        O += horizon * z * z / denom_cloud / denom_sun;
        // Increment iterator
        ii += 1.0;
    }
    
    // Tanh tonemapping
    O = tanh_approx(O / 1e4);
    
    // Apply BCS adjustments
    vec3 color = O.rgb;
    vec3 luminance = vec3(0.299, 0.587, 0.114); // Standard luminance coefficients
    float luma = dot(color, luminance);
    vec3 bright = vec3(BRIGHTNESS) * (color - luma) + luma;
    vec3 contrast = (bright - 0.5) * CONTRAST + 0.5;
    vec3 saturation = mix(vec3(luma), contrast, SATURATION);
    
    fragColor = vec4(saturation, O.a);
}