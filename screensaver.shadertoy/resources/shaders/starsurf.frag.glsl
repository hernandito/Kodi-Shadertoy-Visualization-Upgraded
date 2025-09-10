// I love that we can make stuff we could never see in real-life :)

// The Robust Tanh Conversion Method
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters iTime
#define BRIGHTNESS 1.1
#define CONTRAST   1.80
#define SATURATION 1.0

// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

    float f = max(0.0, 1.0 - abs(b - a)/k);
    return min(a, b) - k*0.25*f*f;
}

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
    // Explicit variable initialization
    float d = 0.0;
    float a = 0.0;
    float e = 0.0;
    float i = 0.0;
    float s = 0.0;
    float t = iTime*.4;
    
    vec3 p = iResolution; 
    
    // scale coords. Division is made robust.
    u = (u+u-p.xy)/max(p.y, 1e-6);

    // cinema bars
    if (abs(u.y) > 0.8) { o = vec4(0.0); return; }

    // sun. Division is made robust.
    float sun = max(length(u-vec2(1.3, 0.65)), 1e-6);
    
    // clear o, march 140 steps
    for(o = vec4(0.0); i++<140.0;
        
        // accumulate distance. Division is made robust.
        d += s = min(0.005+abs(s), e=max(0.2*e, 0.001)),
        
        // brightness, orb light. Division is made robust.
        o += 2.0*vec4(1,2,4,0)*1.0/max(s+e*1e2, 1e-6),
        o += vec4(5,2,1,0)*0.001/max(sun, 1e-6))
        
        
        // noise loop start, march
        for (p = vec3(u*d,d), // p = ro + rd *d;
            // entity (orb)
            e = length(p - vec3(
                sin(sin(t * 0.3)+t*0.4) * 16.0,
                2.0+sin(sin(t*0.5)+t*0.2) *6.0 + 6.0,
                64.0+cos(t*0.7)*24.0))-0.1,
            
            // angled plane and horizontal plane
            s = smin(4.0+p.y, 7.0+p.y + (p.x)*0.6, 15.0),
            
            // move the blue stuff
            p.x += t* 7.0,
            
            // noise starts at .5 up to 16., grow by a+=a
            a = 0.5; a < 16.0; a += a)
                
                // apply noise. Division is made robust.
                s += abs(dot(sin(p.z+t+p * a), 0.1+p-p)) / max(a, 1e-6);
    
    // tanh tonemap, brightness. Replaced `tanh` with `tanh_approx` and made division robust.
    vec4 tanhValue = o / max(2.0, 1e-6);
    o = tanh_approx(tanhValue);
    
    // Apply BCS post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}