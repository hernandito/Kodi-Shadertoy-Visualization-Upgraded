precision mediump float; // Set default precision for floats

// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

#define PI 3.14159265359 // Define PI for spherical mapping

#define T (iTime * .04)
// Replaced tanh() with tanh_approx() and ensured scalar output by taking .x
#define P(z) (vec3(tanh_approx(vec4(cos((z) * .7) * .15)).x * 8., \
                    tanh_approx(vec4(cos((z) * .6) * .2)).x * 12., (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
// #define N normalize // normalize is a built-in function

bool orbHit = false; // Explicitly initialized

// --- GLOBAL PARAMETERS (for BCS) ---
#define BRIGHTNESS 1.0    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.20      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)

// --- ORB COLOR PARAMETER ---
// Define the base color for the metallic orb. This color will tint the reflections.
#define ORB_METALLIC_BASE_COLOR vec3(2.90, 0.3, 0.0) // A red-gold base color
#define ORB_SHININESS 64.0 // Higher value for sharper specular highlight
#define ORB_SPECULAR_STRENGTH 0.75 // How strong the specular highlight is

// --- SCREEN SCALE PARAMETER ---
// Adjusts the zoom level of the scene.
// Values > 1.0 zoom in (magnify), values < 1.0 zoom out (minify).
#define SCREEN_SCALE 0.90 // Default to 1.0 for no scaling


vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001);
    n /= max((n.x + n.y + n.z ), 1e-6); // Added robustness for division by sum of components
    
    return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

float orb(vec3 p) {
    float t = T*0.3; // Explicitly 0.3
    // Replaced tanh() with tanh_approx() and ensured scalar output by taking .x
    // Corrected tan() to tanh_approx() assuming intent was tanh
    return length(p - vec3(
                P(p.z).x+tanh_approx(vec4(sin(p.z+t) * 0.2)).x, // Explicitly 0.2
                P(p.z).y+sin(sin(p.z*1.5)+t*1.75) * 0.2, // Explicitly 1.5, 1.75, 0.2
                0.7+T+tanh_approx(vec4(cos(t*0.5)*0.9)).x*0.2)); // Explicitly 0.7, 0.5, 0.9, 0.2
}

vec4 fog(vec4 rgb, float d) {
    float fogDistance = 2.35 + sin(iTime * 0.2) * 0.5; // Explicitly 2.35, 0.2, 0.5
    float fogAmount = 0.6 + sin(iTime * 0.1) * 0.1; // Explicitly 0.6, 0.1, 0.1
    float fogColor = 0.84 + sin(iTime * 0.3) * 0.7; // Explicitly 0.84, 0.3, 0.7

    if(fogDistance != 0.0) {
        float f = d - fogDistance; // Explicitly initialized
        if(f > 0.0) { // Explicitly 0.0
            f = min(1.0,f * fogAmount); // Explicitly 1.0
            rgb.rgb = mix(rgb.rgb, vec3(0.2 + f * fogColor),f); // Explicitly 0.2
        }
    }
    return rgb;
}

float fractal(vec3 p) {
    float i = 0.0; // Explicitly initialized
    float s = 0.0; // Explicitly initialized
    float w = 3.5; // Explicitly initialized
    float l = 0.0; // Explicitly initialized
    
    p *= 4.0; // Explicitly 4.0
    
    p.xy -= 1.5; // Explicitly 1.5
    
    for (; i++ < 8.0; ) { // Explicitly 8.0
        p = (sin(p)); // abs(sin(p)) was in original, but sin(p) is common for fractals
        l = 2.75 / max(dot(p,p), 1e-6); // Explicitly 2.75, Robust division
        p *= l;
        w *= l;
    }
    return length(p)/max(w, 1e-6); // Robust division
}

float map(vec3 p) {
    float n = 0.0; // Explicitly initialized
    float s_val = 0.0; // Explicitly initialized (renamed from 's')
    float f_val = 0.0; // Explicitly initialized (renamed from 'f')
    vec3 q = p; // Explicitly initialized
    p.xy -= P(p.z).xy;
    
    vec3 fractalPos = p; // Explicitly initialized
    p.z += length(q.xy - p.xy);
    s_val = fractal(p);
    for (n = 0.3; n < 4.0; ) { // Explicitly 0.3, 4.0
        p += abs(dot(sin(p * n * 32.0), vec3(0.008))) / max(n, 1e-6); // Explicitly 32.0, 0.008, Robust division
        n *= 2.0; // Equivalent to n+=n
    }
    f_val = 1.0 - p.y; // Explicitly 1.0
    s_val = min(s_val,max(0.5 - abs(p.x), 0.3 - abs(p.y))); // Explicitly 0.5, 0.3
    
    float orb_dist = orb(q) - 0.05; // Explicitly 0.05
    s_val = min(s_val, orb_dist);
    s_val = min(s_val, f_val);
    orbHit = s_val == orb_dist; // Check if the orb was the closest object

    return s_val;
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
vec3 calculateNormal(in vec3 p_in) {
    vec3 e_normal_eps = vec3(0.01, 0.0, 0.0); // Explicitly initialized
    return normalize(vec3(
        map(p_in + e_normal_eps.xyy) - map(p_in - e_normal_eps.xyy),
        map(p_in + e_normal_eps.yxy) - map(p_in - e_normal_eps.yxy),
        map(p_in + e_normal_eps.yyx) - map(p_in - e_normal_eps.yyx)
    ));
}

void mainImage(out vec4 o, in vec2 u) {
    // Explicit Variable Initialization
    float s = 0.002; // Explicitly initialized
    float d = 0.0;   // Explicitly initialized
    float i = 0.0;   // Explicitly initialized
    float a = 0.0;   // Explicitly initialized (not used in original, but declared)

    vec3 r_res = iResolution.xyz; // Explicitly initialized (renamed from 'r')
    
    vec3 e_val = vec3(0.01,0.0,0.0); // Explicitly initialized (renamed from 'e')
    vec3 p_pos = P(T); // Explicitly initialized (renamed from 'p')
    vec3 ro = p_pos; // Explicitly initialized
    
    vec3 Z = normalize( P(T+1.0) - p_pos); // Explicitly 1.0
    vec3 X = normalize(vec3(Z.z,0.0,-Z.x)); // Explicitly 0.0 (Corrected -Z to -Z.x)
    
    // Normalize uv only once, outside the D calculation for clarity and robustness
    vec2 normalized_uv = (u - r_res.xy / 2.0) / max(r_res.y, 1e-6); // Robust division
    
    // Apply SCREEN_SCALE to the normalized UV coordinates
    normalized_uv /= SCREEN_SCALE;

    vec3 D = vec3(rot(sin(T*0.4)*0.6)*normalized_uv, 1.0) // Explicitly 0.4, 0.6, 1.0
             * mat3(-X, cross(X, Z), Z); // Explicitly initialized
    
    o = vec4(0.0); // Explicitly initialize o

    while(i++ < 200.0 && s > (0.001 * i * 0.02)) { // Explicitly 200.0, 0.001, 0.02
        p_pos = ro + D * d;
        d += (s = map(p_pos)*0.6); // Explicitly 0.6
    }
        
    vec3 r_normal = calculateNormal(p_pos); // Use the corrected normal calculation function
    
    if (orbHit) {
        // Metallic, shiny, reflective red-gold material
        vec3 metallic_base_color = ORB_METALLIC_BASE_COLOR;

        // Calculate reflection vector
        vec3 reflect_dir = reflect(D, r_normal); // D is ray direction from camera, r_normal is surface normal

        // Spherical mapping for environment texture lookup
        vec2 env_uv = vec2(atan(reflect_dir.x, reflect_dir.z) / (2.0 * PI) + 0.5, asin(reflect_dir.y) / PI + 0.5);

        // Sample environment map (iChannel0)
        vec3 reflected_color = texture(iChannel0, env_uv).rgb;

        // Simple light for specular highlight
        vec3 orb_light_pos = ro + vec3(0.0, 5.0, 0.0); // Light above the camera
        vec3 orb_light_dir = normalize(orb_light_pos - p_pos);
        float specular_intensity = pow(max(dot(reflect(-D, r_normal), orb_light_dir), 0.0), ORB_SHININESS);

        // Combine base color, reflection, and specular
        // The base color tints the reflection for metallic look
        o.rgb = reflected_color * metallic_base_color + vec3(specular_intensity * ORB_SPECULAR_STRENGTH);
        o.rgb *= 2.0; // Keep the brightness multiplier
    } else {
        o.rgb = pow(tex3D(iChannel0, p_pos*3.5, r_normal), vec3(2.2)); // Changed iChannel1 to iChannel0
        o.rgb /= max(pow(orb(p_pos), 2.5), 1e-6); // Robust division, Explicitly 2.5
    }
    
    o.rgb *= max(dot(r_normal, normalize(ro-p_pos)), 0.05); // Explicitly 0.05
    o.rgb *= AO(p_pos, r_normal)*4.0; // Explicitly 4.0
    // Apply tanh_approx to the final color, which is already vec4(rgb, alpha)
    o = tanh_approx(pow(fog(o,d)*exp(-d/max(4.0, 1e-6)), vec4(0.45))); // Explicitly 4.0, 0.45, Robust division

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = o.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    o.rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);
}
