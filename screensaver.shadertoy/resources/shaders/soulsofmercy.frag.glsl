// --- Robust Tanh Conversion Method (for OpenGL ES 1.0) ---

// Adds robustness to division operations to prevent NaN/Inf when approaching zero.
const float EPSILON = 1e-6;

// Robust Tanh Approximation (Tanh(x) ≈ x / (1.0 + |x|))
vec4 tanh_approx(vec4 x) { 
    return x / (1.0 + max(abs(x), EPSILON)); 
}

// ---------------------------------------------------------

// ---------------- USER PARAMETERS ----------------
#define ANIMATION_SPEED .2 // Multiplier for iTime
#define FOV .90 // Field of View (adjusts zoom)
#define BRIGHTNESS 1.00
#define CONTRAST   1.30
#define SATURATION 1.2
// -------------------------------------------------

#define T (iTime * ANIMATION_SPEED) // T is now scaled by speed

// A robust BCS function
vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    
    // Using a luminance formula that is more robust for saturation
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color = mix(grayscale, color, saturation);
    
    return color;
}


float fractal(vec3 p) {
    // Explicitly initializing variables for robustness (s and w start the loop)
    float s = 0.0, w = 1.0, l = 0.0;
    
    p.xy *= mat2(cos(.3*T*.5+p.z-vec4(0,33,11,0)));
    p += cos(T*.5+p.yzx*12.)*.07;
    p.y -= 1.6;
    
    // Loop structure retained for minified style
    for (s=0.,w=1.; s++ < 7.; p *= l, w *= l ) {
        p  = abs(sin(p))-1.0;
        
        // Division Robustness Check: Protect against dot(p,p) being zero
        l = 1.3 / max(dot(p,p), EPSILON);
    } 
    
    // Division Robustness Check: Protect against 'w' being zero (although w increases in the loop)
    return length(p) / max(w, EPSILON);
}

vec4 fire(vec2 u) {
    // Explicitly initializing variables, especially 'd' which was uninitialized in the original
    float i = 0., d = 0., s = 0., n = 0.;
    vec3 p = vec3(0.0);
    vec4 o = vec4(0.0);
    
    for(; i++ < 1e2; ) {
        p = vec3(u * d, d + T*4.);
        p += cos(p.z+T*5.+p.yzx*.5)*.6;
        s = 2. + sin(T*5.*.5)*2. - length(p.xy);
        p.xy *= mat2(cos(.3*T*5.+vec4(0,33,11,0)));
        
        for (n = 1.6; n < 32.; n += n ) {
            s -= abs(dot(sin( p.z + T*5. + p*n ), vec3(1.12))) / n;
        }
        
        d += s = .01 + abs(s)*.1;
        // The division here is safe since s >= 0.01
        o += 1.0 / s;
    }
    
    // Division Robustness Check: Protect against 'd' being zero in the final calculation
    return (vec4(5,2,1,1) * o * o / max(d, EPSILON));
}

void mainImage(out vec4 o, in vec2 u) {
    // Explicitly initializing variables
    float s = 0.1, d = 0., i = 0.;
    vec3 p = iResolution.xyz; // Using iResolution.xyz for vec3 initialization
    
    // Coordinate transformation
    // Applied FOV scaling here:
    u = (u - p.xy/2.0) / p.y / FOV;

    o = vec4(0.0);
    
    for(;i++ < 64.0;) {
        p = vec3(u * d, d);
        d += s = fractal(p);
        
        // Division Robustness already present: max(s, .001) is used
        o += 0.7 / max(s, 0.001);
        o.b += 0.2 / max(s, 0.001);
    }
    
    // Mix with the fire function result
    o = mix(o, fire(u)/50.0, 0.4);
    
    // Tanh Replacement Step:
    // 1. Compute the input value to tanh
    vec4 tanh_input = o / 1e5 / max(length(u), EPSILON);
    
    // 2. Apply the tanh_approx function
    o = tanh_approx(tanh_input);
    
    // 3. Apply Brightness, Contrast, Saturation (BCS) adjustment
    o.rgb = applyBCS(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}
