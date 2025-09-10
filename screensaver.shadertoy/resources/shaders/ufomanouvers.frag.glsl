// moon color improvement from @JennySchub
// thanks :D !

// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 1.10
#define CONTRAST   1.50
#define SATURATION 1.0

vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    // Brightness
    color += brightness - 1.0;
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    // Saturation
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

void mainImage(out vec4 o, vec2 u) {
    // Explicitly initialize variables to prevent undefined behavior.
    float d = 0.0;
    float a = 0.0;
    float e = 0.0;
    float i = 0.0;
    float s = 0.0;
    float t = iTime;
    
    vec3 p = iResolution;
    
    // scale coords
    u = (u+u-p.xy)/p.y;
    
    // sun
    float sun = max(length(u-vec2(1.2, .6)), .001);
    
    // clear o, march 140 steps
    for(o*=i; i++<140.;
        
        // accumulate distance
        d += s = min(.005+.7*abs(s), e=max(.2*e, .001)),
        
        // little light + big light
        o += .1/(max(mix(s,e,.1), 1e-6)) + .005/sun)
        
        // noise loop start, march
        for (p = vec3(u*d,d), // p = ro + rd *d;
            
            // entity (orb), len(p - vec3(wigglez)) - radius
            // p.y is mirrored
            e = length(vec3(p.x, abs(p.y), p.z)
                    - vec3(tanh_approx(cos(t*.5)*3. * vec4(1.0)).x * 128. - 128.,
                        tanh_approx(sin(sin(t)+t) * vec4(1.0)).x * 32. + 64.,
                        256.+cos(t*.7)*24.))-.01,
            
            // plane
            s = 16. + p.y,
            
            // move the gray stuff
            p.x += t * 3.,
            
            // noise starts at .2 up to 4., grow by a+=a
            a = .1; a < 4.; a += a)
            
            // apply turbulence
            p += cos(a+p.yzx*.4)*.3,
            
            // apply noise
            s += abs(dot(sin(p * a), vec3(.1))) / max(a, 1e-6);

    // gradient sun color to green-blue
    o *= mix(vec4(4,2,1,0),
                vec4(vec4(.1,.8,1.,1.)),
                smoothstep(.3, -.1, p.y*.001));

    // tanh tonemap, brightness
    o = tanh_approx(o/10.0);
    
    // Apply BCS post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}