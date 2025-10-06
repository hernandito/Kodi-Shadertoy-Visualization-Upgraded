// --- CONFIGURABLE PARAMETERS ---
// Adjust these #defines to control the look and feel
#define ANIMATION_SPEED 0.5 // Multiplier for iTime (T). Default 0.6
#define BRIGHTNESS 1.20      // Overall color multiplier (1.0 is default)
#define CONTRAST 1.40        // Contrast adjustment around 0.5 (1.0 is default)
#define SATURATION 1.0      // Color intensity (1.0 is default)
#define MID_GRAY 0.6        // Anchor point for contrast adjustment
// -------------------------------

// Robust Tanh Conversion Method: Utility function for GLES 1.0 compatibility.
vec4 tanh_approx(vec4 x) { 
    const float EPSILON = 1e-6; 
    return x / (1.0 + max(abs(x), EPSILON)); 
}

#define T iTime * ANIMATION_SPEED
// c is the radius (size) of the orb.
#define O(Z,c) ( length(              /* orb */  \
             p - vec3( sin( T*c*6. ) * 16. ,     \
                       sin( T*c*4. ) * 4. + 1.5,  \
                       Z +12.  +cos(T*.5) *16. )  ) - c )


void mainImage(out vec4 o, vec2 u) {
    // Explicit Variable Initialization (required for robustness)
    float d = 0.0;
    float a = 0.0;
    float e = 0.0;
    float i = 0.0;
    float s = 0.0;
    vec3 ep = vec3(0.0);
    
    // p initialized to iResolution.xyz
    vec3 p = iResolution.xyz; 
    o = vec4(0.0); // Initialize output accumulator
    
    // scale coords
    u = (u+u-p.xy)/p.y;
    
    u += vec2(cos(T*.4)*.3, cos(T*.8)*.1);
    
    // Loop header
    for(i=0.0; i++<100.0; // 1e2 is 100.0

        // accumulate distance
        d += s = 0.01 + 0.35 * abs(s),
        
        // color accumulation (Robust Division applied to prevent division by zero)
        // Moon halo multiplier is 0.02
        o += vec4(1.0) / (s + max(0.5*e, 0.01)) + 0.02 * vec4(1.0, 2.0, 5.0, 0.0) / max(length(u - 0.65), 1e-6))
        
        // noise loop start, march
        for (p = vec3(u*d,d), // p = ro + rd *d
            // Orb radii parameters (0.2, 0.3, 0.4)
            e = max( 0.8 * min( O( 12.0, 0.2), 
                              min( O( 16.0, 0.3), 
                                   O( 14.0, 0.4) )), 0.001 ), 
                            
            // plane, mix with entity/orb (no division, safe)
            s = mix(e*0.02, 4.0 + p.y, smoothstep(0.0, 12.0, e)),
            
            // noise params loop
            a = 0.05; a < 3.0; a += a)
            
            // apply noise (no division, safe)
            s -= abs(dot(cos(T+0.2*p.z+p / a ), 0.3+p-p)) * a;
    
    // 1. Tanh Conversion Application (Divisor set to 40.0, restoring original dimness)
    vec4 temp_o = o / 40.0; 
    o = tanh_approx(temp_o);

    // 2. Brightness adjustment
    o.rgb *= BRIGHTNESS;

    // 3. Contrast adjustment: (color - mid_gray) * contrast + mid_gray
    o.rgb = (o.rgb - vec3(MID_GRAY)) * CONTRAST + vec3(MID_GRAY);

    // 4. Saturation adjustment: mix(grayscale, original_color, saturation)
    float luma = dot(o.rgb, vec3(0.299, 0.587, 0.114));
    o.rgb = mix(vec3(luma), o.rgb, SATURATION);
}
