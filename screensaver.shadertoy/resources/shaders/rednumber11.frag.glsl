/*
    GLSL Shader: Volumetric Lava Orb with Lightning and Sparks
    (Adapted for Kodi / OpenGL ES 1.0 compatibility)
    
    Fixes applied:
    - Robust Tanh Conversion.
    - Audio input replaced with float audio = 0.0; to match disabled state.
    - Global ANIMATION_SPEED parameter added.
*/

// =========================================================
// --- GLOBAL ANIMATION CONTROL ---
// Use 1.0 for original speed, < 1.0 for slower (e.g., 0.5), 
// > 1.0 for faster (e.g., 2.0).
#define ANIMATION_SPEED .4
#define T (iTime * ANIMATION_SPEED)
// =========================================================

// --- USER PARAMETERS: Color Adjustment ---
#define BRIGHTNESS .90
#define CONTRAST   1.60
#define SATURATION .9
// -----------------------------------------

// The required epsilon constant for numerical stability and division protection
const float EPSILON = 1e-6;

// --- ROBUST TANH CONVERSION METHOD (ES 1.0 compatible 'tanh') ---

// Helper for vec3 color (used specifically for color tonemapping)
vec3 tanh_approx3(vec3 x) { 
    return x / (1.0 + max(abs(x), vec3(EPSILON))); 
}

// Function to apply Brightness, Contrast, and Saturation (BCS)
vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    // Adjust Brightness
    color += brightness - 1.0;
    
    // Adjust Contrast (pivot point is 0.5)
    color = (color - 0.5) * contrast + 0.5;
    
    // Adjust Saturation
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color = mix(grayscale, color, saturation);
    
    return color;
}

// --- CORE FUNCTIONS ---

// orb central (SDF or pseudo-distance field)
float orb(vec3 p) {
    // T is already scaled by ANIMATION_SPEED
    float t = T * 0.5; 
    return length(p - vec3(
        sin(sin(t*0.2)+t*0.4) * 6.0,
        1.0+sin(sin(t*0.5)+t*0.2) *4.0,
        12.0+T+cos(t*0.3)*8.0));
}

// paleta rojo-naranja (Red-Orange Palette)
vec3 lavaPalette(float x) {
    vec3 deepRed   = vec3(0.7, 0.05, 0.02);
    vec3 hotOrange = vec3(1.0, 0.25, 0.05);
    vec3 brightRed = vec3(1.0, 0.15, 0.1);
    return (x < 0.5) ? mix(deepRed, hotOrange, smoothstep(0.0,0.5,x))
                     : mix(hotOrange, brightRed, smoothstep(0.5,1.0,x));
}

// relámpagos eléctricos (Electric Lightning)
float lightning(vec2 uv, float intensity) {
    float l = 0.0; 
    
    float n = fract(sin(dot(uv, vec2(12.9898,78.233)) + T*5.0) * 43758.5453);
    float x = sin(T*3.0 + n*10.0)*0.5;
    float dist = abs(uv.x - x);
    l = smoothstep(0.05, 0.0, dist) * intensity;
    return l;
}

// destellos con movimiento de chispa (Spark with movement)
float spark(vec2 uv, float seed, float beat) {
    float n = fract(sin(seed*12.9898+T*1.7) * 43758.5453);
    
    vec2 pos = vec2(sin(seed*13.1)*0.8, cos(seed*9.7)*0.6);
    
    // movimiento vertical descendente
    pos.y -= mod(T*0.5 + seed*3.0, 2.0) - 1.0;
    
    float d = length(uv - pos);
    
    // glow con pulso de beat
    return exp(-20.0*d) * beat * (0.5+0.5*n);
}

void mainImage(out vec4 o, vec2 u) {
    float t = T;
    
    // Explicit Initialization of all raymarching variables
    float d = 0.0;     // Ray distance accumulator
    float s = 0.0;     // Step size / noise distance
    float e = 1000.0;  // Distance to the orb/SDF
    float i = 0.0;     // Outer loop counter
    float a = 0.0;     // Inner loop counter
    
    vec3 p = iResolution.xyz; // Resolution vector (used as vec3 for raymarch position)
    vec3 col = vec3(0.0);     // Color accumulator
    
    // Initialize output accumulator explicitly
    o = vec4(0.0); 
    
    // coords normalizadas
    u = (u+u-p.xy)/p.y;
    u += vec2(cos(t*0.1)*0.3, cos(t*0.3)*0.1);
    
    // Raymarch loop (128 steps)
    for(i=0.0; i<128.0; i+=1.0) {
        
        // 1. Calculate current 3D position
        vec3 currentPos = vec3(u*d, d+t); 
        
        // 2. Distance to orb (e)
        e = orb(currentPos) - 0.1;

        // 3. Noise/Tunnel distance calculation (s)
        vec3 pNoise = currentPos;
        
        // Apply rotation to noise plane
        pNoise.xy *= mat2(cos(0.1*t + pNoise.z/8.0 + vec4(0.0, 33.0, 11.0, 0.0)));
        s = 4.0 - abs(pNoise.y);
        
        // Fractal loop to generate noise (a)
        for (a = 0.8; a < 32.0; a += a){
            pNoise += cos(0.7*t + pNoise.yzx)*0.2;
            s -= abs(dot(sin(0.1*t + pNoise * a ), 0.6 + pNoise - pNoise)) / a;
        }

        // 4. Determine new step size (s) and update orb distance estimate (e)
        e = max(0.5 * e, 0.01); 
        s = min(0.03 + 0.2 * abs(s), e); 
        
        // 5. Accumulate Color (Robust division applied)
        col += lavaPalette(s+e) / max(s + e * 3.0, EPSILON);
        
        // 6. Advance ray
        d += s;
    }
    
    // Audio input FIX: Retaining the static look by setting audio to 0.0
    float audio = 0.0; 
    
    // relámpagos (lightning) - Disabled by audio=0.0
    float bolt = lightning(u, audio);
    vec3 boltColor = mix(vec3(1.0,0.9,0.8), vec3(0.3,0.6,1.0), fract(T*0.5));
    col += bolt * boltColor * 2.5;
    
    // chispas en movimiento (sparks) - Disabled by audio=0.0
    float sparks = 0.0;
    for (int j=0; j<6; j++) {
        sparks += spark(u, float(j)*1.37, audio); 
    }
    col += sparks * vec3(1.0, 0.7, 0.2); 
    
    // tono final (Robust Tanh Conversion applied)
    col = tanh_approx3(col/5.0);
    
    // Apply Brightness, Contrast, Saturation
    col = applyBCS(col, BRIGHTNESS, CONTRAST, SATURATION);
    
    col = pow(col, vec3(0.85));
    
    o = vec4(col,1.0);
}
