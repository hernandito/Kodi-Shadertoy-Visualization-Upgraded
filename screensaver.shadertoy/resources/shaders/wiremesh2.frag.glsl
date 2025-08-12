// Abstract painting of a pond within a rocky shell surrounded by small dunes.
//
// I wanted to know how this visualization would look when using:
//    - Wireframe display.
//    - Marching based fog.
//    - Single-tap lighting.
//    - Minimal code.
//
// Well ... it looks a little rad ._.
//
// Try toggling the comments below for an even more fancy effect.
//

// Define a small epsilon for robustness in divisions
const float EPSILON = 1e-6;

// Robust round function for Kodi compatibility (GLSL ES 1.0 might not support round())
float round_approx(float x) {
    return floor(x + 0.5);
}

// --- Metallic Gold Material Parameters ---
// GOLD_SPECULAR_TINT_FACTOR: Controls how much the specular highlight is tinted by the gold color.
// A value of 0.0 means a white highlight, 1.0 means the highlight is fully tinted by the gold color.
#define GOLD_SPECULAR_TINT_FACTOR 0.7
// GOLD_SPECULAR_STRENGTH: Multiplier for the intensity of the specular highlight on the gold material.
// Higher values make the highlight brighter and more prominent.
#define GOLD_SPECULAR_STRENGTH 2.0
// -----------------------------------------

mat2 rot(float a) { return mat2(cos(radians(a + vec4(0, -90, 90, 0)))); }

float dumbbell(vec2 p) // https://www.shadertoy.com/view/WXV3Dw dumbbell
{
    // close shape by symmetry
    p.y -= 2.0;
    p.y = -abs(p.y);
    p.y += 2.0;
    // half dumbbell
    p.x = abs(p.x);
    p -= 1.0;
    float s = p.x < p.y ? -1.0 : +1.0; // Could use sign() here but that's broken on some systems!
    return (length(p+s)-sqrt(2.0))*s;
}

float molecule(vec3 p) // https://www.shadertoy.com/view/lXXyDN sphere torus grid exact distance (jt)
{
    p = abs(p); // coordinate symmetry
    vec3 o = vec3(0,-1,+1);
    vec3 s = p * mat3(o.xyz,o.yxz,o.yzx); // transposed matrix multiplication for smaller code

    // diagonal permutation
    if(s.x < 0.0 && s.z > 0.0) p.yzx = p.xyz;
    if(s.y < 0.0 && s.z < 0.0) p.zxy = p.xyz;

    return dumbbell(vec2(length(p.xy),p.z));
}

float scene(vec3 p)
{
    float zoom = 4.;
    p.y -= 4. * cos(iTime);
    return molecule(p / zoom) * zoom;
}

float map(vec3 p)
{
    float r = 10., h = max(0., p.y);
    p.y -= h;
    int i = 0;
    for ( ; i<3 ; i++) // comment and change i to display single slice
    {
        vec3 q = p;
        // Replaced round() with round_approx() for Kodi compatibility
        q[i] = round_approx(p[i]); // comment to display as solid
        float s = scene(q);
        // Replaced round() with round_approx() for Kodi compatibility
        s -= round_approx(s);
        // Enhanced division robustness for length and subtraction
        r = min(r, length(vec3(s, p[i] - q[i], h)) - .1);
    }
    return r;
}

float dmap(vec3 p, vec3 l)
{
    // Enhanced division robustness: 1e-3 is already small, but max ensures it's never zero
    return (map(p + normalize(l) * 1e-3) - map(p)) / max(1e-3, EPSILON);
}

vec3 col(float d)
{
    // iq - Disk - https://www.shadertoy.com/view/3ltSW2
    vec3 base_col = (d>0.0) ? vec3(0.9,0.6,0.3) : vec3(0.65,0.85,1.0);
    
    // Apply initial density falloff
    base_col *= 1.0 - exp(-6.0*abs(d));

    // Calculate the highlight component (the original white core)
    vec3 highlight_component = vec3(1.0);
    float highlight_mix_factor = 1.0 - smoothstep(0.0, 0.01, abs(d));

    // If it's the gold material (d > 0.0), tint the highlight and increase its strength
    if (d > 0.0) {
        highlight_component = mix(vec3(1.0), base_col, GOLD_SPECULAR_TINT_FACTOR);
        highlight_mix_factor *= GOLD_SPECULAR_STRENGTH;
    }

    // Mix the base color with the (potentially tinted and strengthened) highlight
    vec3 final_col = mix(base_col, highlight_component, highlight_mix_factor);
    
    return final_col;
}

vec4 M; // Declared globally

vec3 view(vec3 v)
{
    v.zy *= rot(30. + M.y * 100.);
    v.zx *= rot(20. + M.x * 100.);
    return v;
}

void mainImage(out vec4 Q, vec2 U)
{
    vec3 r = iResolution;
    // Explicitly initialize M to prevent "uninitialized" warning
    M = vec4(0.0); 
    M = (abs(iMouse) - r.xyxy / 2.) / r.y;
    if (length(iMouse.zw) < 10.) M = vec4(0);
    
    vec3 p = view(vec3(0, 0, -32));
    vec3 v = view(normalize(vec3(U - r.xy * vec2(.5, .772 - .5 * abs(M.y)), r.y)));
    
    int i=0; 
    float d = 0.0; // Explicitly initialize d
    
    for ( ; (d = map(p)) > 1e-3 && i<100 ; i++)
        p += v * d;
    
    Q = vec4(map(p) > 1. ? 0. : max(.1, dmap(p, vec3(1, 3, -2))));
    // Replaced round() with round_approx() for Kodi compatibility
    // Enhanced division robustness for float(i)
    Q.xyz *= col(round_approx(scene(p)) / 10.);
    Q /= max(float(i) / 10., EPSILON); // Ensure division by zero is avoided if i is 0
}
