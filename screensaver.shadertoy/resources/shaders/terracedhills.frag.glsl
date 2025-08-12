// Add precision qualifiers for floats and samplers for Kodi compatibility
precision highp float;
precision highp int;
precision highp sampler2D;

/*

    Terraced Hills
    --------------

    This is an abstract representation of the terraced hills you see throughout various parts 
    of the world. In essence, it's just a very basic terrain layout with some edging.

    I wanted to make something nice and simple. The code is reasonably compact, but without 
    sacrificing too much in the way of efficiency or readability.

*/

// BCS Post-processing parameters
#define BRIGHTNESS -0.10    // Adjust brightness (-1.0 to 1.0, 0.0 is original)
#define CONTRAST 1.10      // Adjust contrast (0.0 to inf, 1.0 is original)
#define SATURATION 1.4    // Adjust saturation (0.0 to inf, 1.0 is original)

// Field of View parameter
#define FOV_ADJUSTMENT 1.0 // Adjust FOV (e.g., 0.5 for narrower, 2.0 for wider). Default is 1.0 for original FOV.

// Fog strength parameter
#define FOG_STRENGTH_PARAM 0.25 // Adjust the rate at which fog increases with distance (e.g., 0.1 for less dense, 0.5 for more dense)

// Noise map scale parameter
#define NOISE_MAP_SCALE 1024.0 // Adjust the scale of the blocky noise texture (e.g., 256.0 for larger blocks, 1024.0 for smaller blocks)


// 2x2 matrix rotation. Angle vector, courtesy of Fabrice.
mat2 rot2( float th ){ vec2 a = sin(vec2(1.5707963, 0.0) + th); return mat2(a, -a.y, a.x); }

// The triangle function that Shadertoy user Nimitz has used in various triangle noise demonstrations.
// See Xyptonjtroz - Very cool.
float tri(in float x){return abs(x-floor(x)-.5);} // Triangle function.
vec2 tri(in vec2 x){return abs(x-floor(x)-.5);} // Triangle function.
//vec2 tri(in vec2 x){return cos(x*6.2831853)*0.25+0.25;} // Smooth version. Not used here.

// PF - phase variance. Varies between zero and 1. Zero is redundant, as it returns the triangle function.
//vec2 trap(in vec2 x, float pf){ return (tri(x - pf*.125) + tri(x + pf*.125))*.5; } // Trapezoid function.

// A simple noisey layer made up of a sawtooth combination.
float hLyr(vec2 p) { return dot(tri(p/1.5 + tri(p.yx/3.0 + .25)), vec2(1.0)); } // Added .0 to 3.

// I've mentioned this before, but you can make some pretty interesting surfaces simply by 
// combining mutations of a rudimentary functional layer. Take the base layer, then rotate, skew,
// change frequency, amplitude, etc, and combine it with the previous layer. Continue ad infinitum...
// or until your GPU makes you stop. :)
float hMap(vec2 p) {
    
    float ret = 0.0, a = 1.0; // Explicitly use 0.0 and 1.0 for float literals

    // Combining three layers of the function above.
    for(int i=0; i<3; i++) {
        ret += abs(a)*hLyr(p/a); // Add a portion of the layer to the final result.
        //p = rot2(1.5707963/3.)*p;
        //p = mat2(.866025, .5, -.5, .866025)*p; // Rotate the layer only.
        p = mat2(0.866025, 0.57735, -0.57735, 0.866025)*p; // Rotate and skew the layer. // Added .0 to numbers
        a *= -0.3; // Multiplying the amplitude by a negative for an interesting variation.     
    }

    // Squaring and smoothing the result for some peakier peaks. Not mandatory.
    ret = smoothstep(-0.2, 1.0, ret*ret/1.39/1.39); // Added .0 to -0.2
    
    
    // The last term adds some ridges. Basically, you take the result then blend in a 
    // small periodic portion of it... The code explains it better.   
    return ret*0.975 + tri(ret*12.0)*0.05; // Range: [0, 1].. but I'd double check. :) // Added .0 to numbers
    //return ret*.99 + clamp(cos((ret)*6.283*24.)*.5+.5, 0., 1.)*.01; // Another way.


}

// Distance function. A flat plane perturbed by a height function of some kind.
float map(vec3 p) { return (p.y - hMap(p.xz)*.35)*.75; }


// Tetrahedral normal - courtesy of IQ. I'm in saving mode, so am saving a few map calls.
// I've added to the function to include a rough tetrahedral edge calculation.
vec3 normal(in vec3 p, inout float edge){
  
    // Edging thickness. I wanted the edges to be resolution independent... or to put it
    // another way, I wanted the lines to be a certain pixel width regardless of the 
    // canvas size. If you don't, then the lines can look too fat in fullscreen.
    vec2 e = vec2(-1.0, 1.0)*.5/iResolution.y; // Explicitly use 1.0 and 0.5 
    
    // The hit point value, and four nearby samples, spaced out in a tetrahedral fashion.
    float d1 = map(p + e.yxx), d2 = map(p + e.xxy);
    float d3 = map(p + e.xyx), d4 = map(p + e.yyy); 
    float d = map(p);
    
    // Edge calculation. Taking for samples around the hit point and determining how
    // much they vary. Large variances tend to indicate an edge.
    edge = abs(d1 + d2 + d3 + d4 - d*4.0); // Explicitly use 4.0
    edge = smoothstep(0.0, 1.0, sqrt(edge/e.y*2.0)); // Explicitly use 0.0, 1.0, 2.0
    
    // Recalculating for the normal. I didn't want the sample spacing to change from
    // one resolution to the next. Hence, the fixed number. Just for the record, I tend
    // to work within the 800 by 450 window. 
    e = vec2(-1.0, 1.0)*.001; // Explicitly use 1.0
    d1 = map(p + e.yxx), d2 = map(p + e.xxy);
    d3 = map(p + e.xyx), d4 = map(p + e.yyy); 
    
    // Normalizing.
    return normalize(e.yxx*d1 + e.xxy*d2 + e.xyx*d3 + e.yyy*d4 );    
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )    {
    

    // Unit direction ray.
    vec3 rd = normalize(vec3(fragCoord.xy - iResolution.y*0.5, iResolution.y / FOV_ADJUSTMENT)); // Apply FOV_ADJUSTMENT
    
    // Orienting to face a particular direction.
    rd.yz = rot2(0.35)*rd.yz; // Explicitly use 0.35
    
    // Camera point - Placed above the plane and moving in the general XZ direction. 
    vec3 ro = vec3(iTime*0.04, 0.5, iTime*0.02); // Explicitly use 0.04, 0.5, 0.02
    
    // Basic raymarching.    
    float t=0.0, d; // Explicitly use 0.0
    for(int i=0; i<96; i++) {
        
        d = map(ro + rd*t); // Closest distance to current ray point.
        
        // Break condition - Surface hit, or too far.
        if(abs(d)<0.001*(t*0.125 + 1.0) || t>20.0) break; // Explicitly use 0.001, 0.125, 1.0, 20.0

        // Advancing the ray - Using a bit more accuracy nearer the camera.
        t += (step(1.0, t)*0.3 + 0.7)*d; // Explicitly use 1.0, 0.3, 0.7
    }
    
    // Hit point. Note that about a quarter of the screen hits the curved far plane (sky),
    // so a few cycles are wasted, but there's no nested code block, which looks a bit
    // neater... I wouldn't do this for more sophisticated examples, but it's OK here.
    vec3 sp = ro + rd*t;
    
    // Applying direct lighting. It's simpler, but it's more of an aesthetic choice for this
    // particular example.
    vec3 ld = vec3(-0.676, 0.408, 0.613); // Normalized, or pretty close.
    

    // Normal and edge value.
    float edge;
    vec3 n = normal(sp, edge);
    
    float dif = max(dot(ld, n), 0.0); // Diffuse. // Explicitly use 0.0
    float spe = pow(max(dot(reflect(rd, n), ld), 0.0), 16.0); // Specular. // Explicitly use 0.0, 16.0

    float sh = hMap(sp.xz); // Using the height map to enhance the peaks and troughs.
    
    // A bit of random, blocky sprinkling for the hills. Cheap, but it'll do.
    float rnd = fract(sin(dot(floor(sp.xz*NOISE_MAP_SCALE), vec2(41.73, 289.67)))*43758.5453)*0.5 + 0.5; // Apply NOISE_MAP_SCALE
    
    // The fog. Since the foreground color is pretty bland, I've made it really colorful. I've gone
    // for the sunset cliche... or misty morning sunrise, if you prefer. :)
    vec3 fog = mix(vec3(0.75,0.77, 0.78), vec3(1.04, 0.95, 0.87), (pow(1.0 + dot(rd, ld), 3.0))*0.35); // Explicitly use 0.75, 0.77, 0.78, 1.04, 0.95, 0.87, 1.0, 3.0, 0.35
    
    // Using the values above to produce the final color, then mixing in some fog according to distance.
    vec3 c = mix((vec3(1.1, 1.05, 1.0)*rnd*(dif + 0.1)*sh + fog*spe)*(1.0 - edge*0.7), fog*fog, min(1.0, t*FOG_STRENGTH_PARAM)); // Explicitly use 1.0, 0.1, 0.7

    // Apply BCS post-processing
    // Brightness
    c += BRIGHTNESS;

    // Contrast
    c = (c - 0.5) * CONTRAST + 0.5;

    // Saturation
    vec3 luminance = vec3(dot(c, vec3(0.2126, 0.7152, 0.0722)));
    c = mix(luminance, c, SATURATION);

    // No gamma correction. If you wanted, you could think of it as postprocessing the final
    // color and gamma correction rolled into one. :)
    fragColor = vec4(c, 1.0); // Explicitly use 1.0
}
