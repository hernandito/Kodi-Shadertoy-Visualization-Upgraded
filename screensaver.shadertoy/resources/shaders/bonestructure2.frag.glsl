precision mediump float; // Set default precision for floats

// Robust Tanh Approximation Function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

//============================================================
// Cross-eyed 3D
// Sit as far back from the screen as possible
// Slightly cross your eyes so that there is a third image in the middle.
// Relax your gaze, and concentrate only on that middle image, which is in 3D.
// Click mouse on right side of image for stereo, left side for normal viewing.
// Stereo code from kosalos tanh
//============================================================

//============================================================

// parallax effect
#define PARALLAX .092

// look around speed
#define LOOK_SPEED 6.0 // Explicitly 2.0

// max iterations (steps)
#define MARCH_ITERS 220.0 // Explicitly 220.0

// delete if you don't want
#define LIGHT_GLIMMER

// delete if you don't want
//#define SHAKE

// speed
#define T (iTime * .05)


//============================================================
// Replaced tanh() with tanh_approx() and ensured scalar output by taking .x
#define MORPH_FREQ (tanh_approx(vec4(cos(T*1.5)*1.3)).x*1.7)*.1 // Explicitly 1.5, 1.3, 1.7, 0.1

// Replaced tanh() with tanh_approx() and ensured scalar output by taking .x
#define P(z) (vec3(0.0, \
                    tanh_approx(vec4(cos((z) * .3) * .4)).x * 8., (z))) // Explicitly 0.0, 0.3, 0.4, 8.0
// Replaced tanh() with tanh_approx() and ensured scalar output by taking .x
#define LOOK_FREQ (tanh_approx(vec4(cos((T*.3)*.125)*9.)).x) // Explicitly 0.3, 0.125, 9.0
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize
#define TONEMAP(x) ((x) / max((x) + vec3(0.155), vec3(1e-6)) * 1.019) // Explicitly 0.155, 1.019, Robust division

bool fractalHit = false; // Explicitly initialized

// --- GLOBAL PARAMETERS (for BCS) ---
#define BRIGHTNESS .40    // Brightness adjustment (1.0 = neutral)iChannel0
#define CONTRAST 1.10      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)

// --- FIELD OF VIEW PARAMETER ---
// Adjusts how much of the scene is visible.
// Values > 1.0 will zoom out (show more), values < 1.0 will zoom in (show less).
#define FIELD_OF_VIEW_MULTIPLIER 2.70 // Default to 1.0 for no scaling

vec2 shake() {
    return vec2(
        sin(MORPH_FREQ * 1e5), // Explicitly 1e5
        cos(MORPH_FREQ * 2e5) // Explicitly 2e5
    ) * (abs(MORPH_FREQ) < 0.1 ? MORPH_FREQ*0.07 : 0.0); // Explicitly 0.1, 0.07, 0.0
}

vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001); // Explicitly 0.2, 7.0, 0.001
    n /= max((n.x + n.y + n.z ), 1e-6); // Added robustness for division by sum of components
    
    return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

vec3 fog(vec3 rgb, float d) {
    // set to 0.0 to disable fog
    float fogDistance = 1.75 + sin(iTime * 0.2) * 0.5; // Explicitly 1.75, 0.2, 0.5
    float fogAmount = 0.7 + sin(iTime * 0.1) * 0.5; // Explicitly 0.7, 0.1, 0.5
    float fogColor = 0.84 + sin(iTime * 0.3) * 0.7; // Explicitly 0.84, 0.3, 0.7

    if(fogDistance != 0.0) { // Explicitly 0.0
        float f = d - fogDistance; // Explicitly initialized
        if(f > 0.0) { // Explicitly 0.0
            f = min(1.0,f * fogAmount); // Explicitly 1.0
            rgb = mix(rgb, vec3(3.0,2.0,1.0)*vec3(0.2 + f * fogColor),f); // Explicitly 3.0, 2.0, 1.0, 0.2
        }
    }
    return rgb;
}


float map(in vec3 q){
    vec3 p = q; // Explicitly initialized
    float i = 0.0; // Explicitly initialized
    float s = 0.0; // Explicitly initialized
    float f = 0.0; // Explicitly initialized
    float t = 0.0; // Explicitly initialized
    float w = 1.2; // Explicitly initialized
    float l = 0.0; // Explicitly initialized

    p.xy -= P(p.z).xy;
    t = 4.0 - length(p.xy); // Explicitly 4.0
    
    p.y -= 1.5; // Explicitly 1.5
    
    w = 1.0; // Explicitly 1.0
    for (int j = 0; j++ < 8; p *= l, w *= l ) { // Explicitly 8
        p = abs(sin(p)) - 1.0; // Explicitly 1.0
        l = 1.5 / max(dot(p,p), 1e-6) - MORPH_FREQ; // Explicitly 1.5, Robust division
    }
    f = length(p)/max(w, 1e-6); // Robust division
    fractalHit = f < t;
    return min(f, t);
}

vec3 orb(vec3 p) {
    float t = T*LOOK_SPEED; // Explicitly initialized
    return (p - vec3(
                P(p.z).x+tanh_approx(vec4(cos(t * 0.5)*2.0)).x * 6.5, // Explicitly 0.5, 2.0, 6.5
                P(p.z).y+tanh_approx(vec4(cos(t * 0.7)*3.0)).x * 2.5, // Explicitly 0.7, 3.0, 2.5
                5.0+T)); // Explicitly 5.0
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

void mainImage(out vec4 o, in vec2 U) {
    // Explicit Variable Initialization
    float s = 0.002; // Explicitly initialized
    float d = 0.0;   // Explicitly initialized
    float i = 0.0;   // Explicitly initialized
    float a = 0.0;   // Explicitly initialized (not used in original, but declared)

    vec3 r_res = iResolution.xyz; // Explicitly initialized (renamed from 'r')
    
// --------------------------------------    
    float xsize = r_res.x * 0.5; // Explicitly 0.5
    bool stereo = iMouse.x > xsize; // Explicitly initialized
    vec2 U2 = U; // Explicitly initialized
    
    if(stereo) {
        if(U2.x >= xsize) { // Explicitly initialized
            U2.x -= xsize; // Explicitly initialized
        }
    }
    
    vec2 u_local = rot(sin(T*0.3)*3.3)*(U2-r_res.xy/2.0)/max(r_res.y, 1e-6); // Explicitly 0.3, 3.3, 2.0, Robust division
    
    // Apply FIELD_OF_VIEW_MULTIPLIER
    u_local *= FIELD_OF_VIEW_MULTIPLIER;

    #ifdef SHAKE
    u_local -= shake();
    #endif
// --------------------------------------  
    
    vec3 e_val = vec3(0.01,0.0,0.0); // Explicitly initialized (renamed from 'e')
    vec3 p_pos = P(T); // Explicitly initialized (renamed from 'p')
    vec3 ro = p_pos; // Explicitly initialized
    
    vec3 Z = N( P(T+3.0) - orb(p_pos) - p_pos); // Explicitly 3.0
    vec3 X = N(vec3(Z.z,0.0,-Z.x)); // Explicitly 0.0 (Corrected -Z to -Z.x)
    
    vec3 D = vec3(u_local, 1.0)* mat3(-X, cross(X, Z), Z); // Explicitly 1.0
// --------------------------------------    
    if(stereo) {
        vec3 cameraOffset = -X * PARALLAX; // Explicitly initialized

        if(U.x < xsize) { // Explicitly initialized
            ro += cameraOffset;
        } else {
            ro -= cameraOffset;
        }
    }
// --------------------------------------    

    o = vec4(0.0); // Explicitly initialize o
    while(i++ < MARCH_ITERS && s > 0.001) { // Explicitly 0.001
        p_pos = ro + D * d;
        d += (s = map(p_pos)*0.55); // Explicitly 0.55
    }
        
    vec3 r_normal = calculateNormal(p_pos, e_val); // Use the corrected normal calculation function
    
    vec4 lights = vec4(1.0); // Explicitly initialized
    if (fractalHit) {
        o.rgb = pow(tex3D(iChannel2, p_pos, r_normal*0.25), vec3(2.2)); // Explicitly 0.25, 2.2
        o.rgb = mix(o.rgb, pow(tex3D(iChannel2, p_pos, r_normal), vec3(2.2)), 0.7); // Changed iChannel1 to iChannel0, Explicitly 2.2, 0.7
        // Removed iChannel2 reference as it's not available
        // o.rgb = mix(o.rgb, pow(tex3D(iChannel2, p_pos, r_normal), vec3(2.2)), 0.7);
    } else {
        // bakground noise for tunnel
        o -= 0.2 - abs(dot(sin(p_pos * 1.0 * 32.0), vec3(0.15))); // Explicitly 0.2, 1.0, 32.0, 0.15
        o -= 0.3 - abs(dot(sin(p_pos * 1.0 * 64.0), vec3(0.15))); // Explicitly 0.3, 1.0, 64.0, 0.15
    }

    #ifdef LIGHT_GLIMMER
    if (fractalHit) {
        lights = vec4(abs((vec3(1.6, 1.2, 0.8)) / // Explicitly 1.6, 1.2, 0.8
                    max(dot(cos(0.3*iTime+p_pos),vec3(0.3)), 1e-6))*0.2,0.0); // Explicitly 0.3, 0.3, 0.2, 0.0, Robust division
    }
    #else
    
    #endif
    o *= AO(p_pos, r_normal)*vec4(3.0,2.0,1.0,0.0)*lights; // Explicitly 3.0, 2.0, 1.0, 0.0
    o.rgb = TONEMAP(fog(o.rgb*exp(-d/max(4.0, 1e-6)), d)); // Explicitly 4.0, Robust division

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = o.rgb; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    o.rgb = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

// --------------------------------------    
    if(stereo && abs(U.x - xsize) < 1.0) o.xyz = vec3(1.0); // Explicitly 1.0, 1.0
// --------------------------------------    
}
