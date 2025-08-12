// Add precision qualifiers for floats and samplers for Kodi compatibility
precision highp float;
precision highp int;
precision highp sampler2D;

/*
    Apollonian Structure
    --------------------

    Overall, there's nothing particularly exciting about this shader, but I've 
    always liked this structure, and thought it'd lend itself well to the two 
    tweet environment.

    I couldn't afford shadows, AO, etc, so applied a bit of fakery to at least
    convey that feel.


*/

// BCS Post-processing parameters
#define BRIGHTNESS -0.10    // Adjust brightness (-1.0 to 1.0, 0.0 is original)
#define CONTRAST 1.3      // Adjust contrast (0.0 to inf, 1.0 is original)
#define SATURATION 1.0    // Adjust saturation (0.0 to inf, 1.0 is original)

// Fog parameters
#define FOG_START 5.0     // Distance where fog begins to appear
#define FOG_END 15.0      // Distance where fog is at full strength
#define FOG_STRENGTH 0.0  // Overall opacity/strength of the fog (0.0 to 1.0)
#define FOG_COLOR vec3(1.0, 0.95, 0.9) // Color of the fog (e.g., vec3(0.0, 0.0, 0.0) for black, vec3(0.5, 0.6, 0.7) for a light blue haze)


// Apollonian based fractal: I couldn't find the original source, but it's
// been around for a while. IQ has a really cool variation here: 
// Apollonian: https://www.shadertoy.com/view/4ds3zn
//
// I'm guessing the original was posted by someone on a fractal forum somewhere 
// at some stage.
//
float m(vec3 p){
    
    // Moving the scene itself forward, as opposed to the camera.
    // IQ does it in one of his small examples.
    p.z += iTime*.1;
    
    // Loop counter and variables.
    float i = 0.0, s = 1.0, k; // Explicitly use 0.0 and 1.0 for float literals

    // Repeat Apollonian distance field. It's just a few fractal related 
    // operations. Break up space, distort it, repeat, etc. More iterations
    // would be nicer, but this function is called a hundred times, so I've
    // used the minimum to give just enough intricate detail.
    while(i++ < 6.0) p *= k = 1.5/dot(p = mod(p - 1.0, 2.0) - 1.0, p), s *= k; // Explicitly use 1.0 and 2.0
        
    // Render numerous little spheres, spread out to fill in the 
    // repeat Apollonian lattice-like structure you see.
    //
    // Note the ".01" at the end. Most people make do without it, but
    // I like the tiny spheres to have a touch more volume, especially
    // when using low iterations.
    return length(p)/s - .015; 
    
}


void mainImage( out vec4 c, vec2 u)
{
    // Direction ray and origin. By the way, you could use "o = d/d" (Thanks, Fabrice),
    // then do some shuffling around in the lighting calculation, but I didn't quite 
    // like the end result, so I'll leave it alone, for now anyway.
    vec3 d = vec3(u/iResolution.y - .5, 1.0)/4.0, o = vec3(1.0, 1.0, 0.0); // Explicitly use 1.0 and 0.0

    // Initialize to zero.
    c -= c;
    
    // Raymarching loop -- sans break, which always makes me cringe. :)
    // Loop counter c.w is initialized to 0.0 before the loop, so it starts from 0.
    // The condition c.w++ < 1e2 means it runs for 100 iterations (0 to 99).
    for (float iter_count = 0.0; iter_count < 100.0; iter_count++) { // Changed while to for loop for compatibility
        o += m(o)*d;
    }
    
    // Lame lighting - loosely based on directial derivative lighting and the 
    // way occlusion is performed, but mostly made up. It'd be nice to get rid 
    // of that "1.1," but it's kind of necessary.  Note that "o.z" serves as  
    // a rough distance estimate, and to give a slight volumetric light feel. 
    //c += (m(o - .01)*m(o - d)*4e1 + o.z*1.1 - 2.)/o.z;
    // I stared at the line above for ages and got nothing. Fabrice looked at it
    // instantly, and saw the obvious. :)
    // Changed the additive constant from 1.1 (scalar) to vec3(1.0, 0.95, 0.9) for a warm white/cream tint.
    c.rgb += (m(o - .012)*m(o - d)*30.0 - 1.9)/o.z + vec3(.9, 0.85, 0.75); // Use 40.0 for 4e1

    // Apply fog effect
    float fogFactor = smoothstep(FOG_START, FOG_END, o.z);
    c.rgb = mix(c.rgb, FOG_COLOR, fogFactor * FOG_STRENGTH);

    // Apply BCS post-processing
    // Brightness
    c.rgb += BRIGHTNESS;

    // Contrast
    c.rgb = (c.rgb - 0.5) * CONTRAST + 0.5;

    // Saturation
    vec3 luminance = vec3(dot(c.rgb, vec3(0.2126, 0.7152, 0.0722)));
    c.rgb = mix(luminance, c.rgb, SATURATION);
    
}
