/*
    "Phosphor 3" by @XorDev

    https://x.com/XorDev/status/1949897576435581439
    
    <512 playlist:
    https://www.shadertoy.com/playlist/N3SyzR
*/

// --- PARAMETERS FOR ADJUSTMENT ---
// Adjust the Brightness, Contrast, and Saturation of the final image.
// Default values of 1.0 will maintain the original look.
#define BRIGHTNESS 1.2
#define CONTRAST 1.4
#define SATURATION 1.0

// --- ROBUST TANH CONVERSION METHOD ---
// The following function approximates the tanh() function.
// It is used to ensure compatibility with platforms that do not support it.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

void mainImage(out vec4 O, vec2 I)
{
    //Animation time
    float t = iTime*.2;
    
    // Explicitly initialize all variables to prevent undefined behavior.
    float z = 0.0;
    float d = 0.0;
    float s = 0.0;
    float i = 0.0;
    
    // Raymarch depth
    // Step distance
    // Signed distance
    // Raymarch iterator
    
    // Initialize output color
    O = vec4(0.0);
    
    // Raymarch 80 steps
    for(; i++<8e1;
        // Color and brightness. Added a robustness check for the division by d.
        O+=(cos(s+vec4(0,1,8,0))+1.)/max(d, 1E-6))
    {
        //Sample point (from ray direction)
        vec3 p = z*normalize(vec3(I+I,0)-iResolution.xyy);
        //Rotation axis
        vec3 a = normalize(cos(vec3(5,0,1)+t-d*4.));
        //Move camera back 5 units
        p.z+=5.;
        //Rotated coordinates
        a = a*dot(a,p)-cross(a,p);
        
        //Turbulence loop
        for(d=1.;d++<9.;)
            a-=sin(a*d+t).zxy/d;
        
        //Distance to ring
        z+=d=.1*abs(length(p)-3.)+.07*abs(cos(s=a.y));
    }
    
    // Tanh approximation for tonemapping
    O = tanh_approx(O/5e3);

    // Apply BCS adjustments to the tonemapped color
    // Brightness
    O = pow(O, vec4(1.0 / BRIGHTNESS));
    // Contrast
    O = 0.5 + (O - 0.5) * CONTRAST;
    // Saturation
    O = mix(vec4(dot(O.xyz, vec3(0.333))), O, SATURATION);
}
