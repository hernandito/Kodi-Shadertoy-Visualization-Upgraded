precision mediump float; // Set default precision for floats

// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

#define T (iTime * .2)
#define P(z) (vec3((cos((z) * .4) * .3) * 6., \
                    (cos((z) * .3) * .3) * 6., (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize
#define inf 9e9

// --- GLOBAL PARAMETERS (for BCS) ---
#define BRIGHTNESS 1.30    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.40      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)

// --- FIELD OF VIEW PARAMETER ---
// Adjusts how much of the scene is visible.
// Values > 1.0 will zoom out (show more), values < 1.0 will zoom in (show less).
#define FIELD_OF_VIEW_MULTIPLIER 1.7 // Default to 1.5 to show more of the effect

// --- TEXTURE MAPPING SCALE PARAMETER ---
// Controls the scale of the texture applied to the geometry.
// Higher values will make the texture appear smaller (more repetitions).
// Lower values will make the texture appear larger (fewer repetitions).
#define TEXTURE_SCALE 1.1 // Default to 0.5 for current visual

vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001);
    n /= max((n.x + n.y + n.z ), 1e-6); // Added robustness for division by sum of components
    
    return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}


float tunnel (vec3 p, float r) {
    p.xy -= P(p.z).xy;
    return r - abs(p.y);
}

float gyroid(vec3 p) {
    // Replaced tanh(p) with tanh_approx(vec4(p, 0.0)).xyz
    return dot(tanh_approx(vec4(p, 0.0)).xyz, sin(p+cos(p.yzx)));
}

float map(vec3 p) {
 
    return min(tunnel(p, 6.0), // Explicitly 6.0
               max(tunnel(p, 0.3), gyroid(p))); // Explicitly 0.3
}

float AO(in vec3 pos, in vec3 nor) {
    float sca = 2.0; // Explicitly initialized
    float occ = 0.0; // Explicitly initialized
    for( int i=0; i<5; i++ ){ // Explicitly 5
        
        float hr = 0.01 + float(i)*0.5/4.0; // Explicitly 0.01, 0.5, 4.0
        float dd = map(nor * hr + pos); // Explicitly initialized
        occ += (hr - dd)*sca;
        sca *= 0.7; // Explicitly 0.7
    }
    return clamp( 1.0 - occ, 0.0, 1.0 ); // Explicitly 1.0, 0.0, 1.0
}

// Corrected normal calculation function
vec3 calculateNormal(in vec3 p_in, in vec3 e_val) {
    return N(map(p_in) - vec3(
        map(p_in - e_val.xyy),
        map(p_in - e_val.yxy),
        map(p_in - e_val.yyx)
    ));
}

void mainImage(out vec4 o, in vec2 u) {
    // Explicit Variable Initialization
    float s = 0.02; // Explicitly initialized
    float d = 0.0;   // Explicitly initialized
    float i = 0.0;   // Explicitly initialized
    float a = 0.0;   // Explicitly initialized (not used in original, but declared)

    vec3 r_res = iResolution.xyz; // Explicitly initialized (renamed from 'r')
    u = (u - r_res.xy / 2.0) / max(r_res.y, 1e-6); // Robust division, Explicitly 2.0
    
    // Apply FIELD_OF_VIEW_MULTIPLIER to the normalized UV coordinates
    u *= FIELD_OF_VIEW_MULTIPLIER;

    vec3 e_val = vec3(0.001,0.0,0.0); // Explicitly initialized (renamed from 'e')
    vec3 p_pos = P(T); // Explicitly initialized (renamed from 'p')
    vec3 ro = p_pos; // Explicitly initialized
    
    vec3 Z = N( P(T+1.0) - p_pos); // Explicitly 1.0
    vec3 X = N(vec3(Z.z,0.0,-Z.x)); // Explicitly 0.0 (Corrected -Z to -Z.x)
    
    vec3 D = vec3(rot(sin(T*0.2)*0.4)*u, 1.0) // Explicitly 0.2, 0.4, 1.0
             * mat3(-X, cross(X, Z), Z); // Explicitly initialized
             
    o = vec4(0.0); // Explicitly initialize o

    while(i++ < 135.0 && s > 0.01) { // Explicitly 135.0, 0.01
        p_pos = ro + D * d * 0.5; // Explicitly 0.5
        d += map(p_pos);
    }
        
    vec3 r_normal = calculateNormal(p_pos, e_val); // Use the corrected normal calculation function
    
    o.rgb = pow(tex3D(iChannel0, p_pos * TEXTURE_SCALE, r_normal), vec3(2.2)); // Changed iChannel1 to iChannel0, Explicitly 0.5, 2.2
    for (i = 0.2; i < 0.8; ) { // Explicitly 0.2, 0.8
        o += abs(dot(sin(o.rgb * i * 4.0), vec3(0.5))) / max(i, 1e-6); // Explicitly 4.0, 0.5, Robust division
        i *= 1.4142; // Explicitly 1.4142
    }
    
    o *= max(dot(r_normal, normalize(ro-p_pos)), 0.05); // Explicitly 0.05
    o *= AO(p_pos, r_normal);
    // Replaced tanh() with tanh_approx() and ensured robust division
    o = tanh_approx(o/max(d,10.0)*exp(-d/max(32.0, 1e-6))/2.0); // Explicitly 10.0, 32.0, 2.0

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = o.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    o.rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);
}
