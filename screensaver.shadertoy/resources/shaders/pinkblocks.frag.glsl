/*
    Fast, Minimal Animated Blocks
    -----------------------------
    Emulating the Voronoi triangle metric - the one that looks like blocks - with 
    wrappable, rotated tiles. 
    I've slimmed the code down a little bit, but mainly to get the point across that 
    this approach requires far fewer instructions than the regular random-offset-point 
    grid setup. The main purpose of the exercise was efficiency... and to a lesser 
    degree, novelty. :)
    For an instruction count comparison, take a look at a few of the Voronoi block (or 
    standard) Voronoi examples on here.
    Relevant Examples:
    // About as minimal as it gets. Whoever made this had way too much time on his hands. :D
    One Tweet Cellular Pattern - Shane
    https://www.shadertoy.com/view/MdKXDD
    // Awesome. Also good for an instruction count comparison.
    Blocks -IQ
    https://www.shadertoy.com/view/lsSGRc
    // Similar code size, but very different instruction count.
    Triangular Voronoi Lighted - Aiekick
    https://www.shadertoy.com/view/ltK3WD
*/

// Shadertoy-provided uniforms (no need to declare them here, they are implicit):
// uniform vec3 iResolution;
// uniform float iTime;
// uniform float iTimeDelta;
// uniform vec4 iMouse;
// uniform vec4 iDate; // iDate.w is total time, but iTime is more common for animation

// Distance metric. A slightly rounded triangle is being used, but the usual distance iTime
// metrics all work.
float s(vec2 p){
    p = fract(p) - .5;   
    //return max(abs(p.x)*.866 + p.y*.5, -p.y); // Regular triangle.
    //return (length(p)*1.5 + .25)*max(abs(p.x)*.866 + p.y*.5, -p.y);
    return (dot(p, p)*2. + .5)*max(abs(p.x)*.866 + p.y*.5, -p.y);
    //return dot(p, p)*2.;
    //return length(p);
    //return max(abs(p.x), abs(p.y)); // Etc.
    //return max(max(abs(p.x)*.866 + p.y*.5, -p.y), -max(abs(p.x)*.866 - p.y*.5, p.y) + .2);
}
// Very cheap wrappable cellular tiles. This one produces a block pattern on account of the
// metric used, but other metrics will produce the usual patterns.
//
// Construction is pretty simple: Plot two points in a wrappble cell and record their distance. 
// Rotate by a third of a circle then repeat ad infinitum. Unbelievably, just one rotation 
// is needed for a random looking pattern. Amazing... to me anyway. :)
//
// Note that there are no random points at all, no loops, and virtually no setup, yet the 
// pattern appears random anyway.

float m(vec2 p){    
    // Offset - used for animation. Put in as an afterthough, so probably needs more
    // tweaking, but it works well enough for the purpose of this demonstration.
    // Changed iDate.w to iTime for standard Shadertoy compatibility
    vec2 o = sin(vec2(1.93, 0) + iTime)*.166; 
    // The distance to two wrappable, moving points.
    float a = s(p + vec2(o.x, 0)), b = s(p + vec2(0, .5 + o.y));
    // Rotate the layer (coordinates) by 120 degrees. 
    p = -mat2(.5, -.866, .866, .5)*(p + .5);
    // The distance to another two wrappable, moving points.
    float c = s(p + vec2(o.x, 0)), d = s(p + vec2(0, .5 + o.y)); 
    // Return the minimum distance among the four points. If adding the points below,
    // be sure to comment the following line out.
    return min(min(a, b), min(c, d))*2.;
    // One more iteration. Gives an even more random pattern. With this, it's 
    // still a very cheap process. Be sure to comment out the return line above.
    /*
    // Rotate the layer (coordinates) by 120 degrees.
    p = -mat2(.5, -.866, .866, .5)*(p + .5);
    // The distance to yet another two wrappable, moving points.
    float e = s(p + vec2(o.x, 0)), f = s(p + vec2(0, .5 + o.y)); 
    // Return the minimum distance among the six points.
    return min(min(min(a, b), min(c, d)),  min(e, f))*2.;
    */
}
void mainImage(out vec4 o, vec2 p){
    // Screen coordinates.
    p /= iResolution.y/3.;
    // The function value.
    o = vec4(1)*m(p);
    // Cheap highlighting.
    vec4 b = vec4(.8, .5, 1, 0)*max(o - m(p + .01), 0.)/.05;
    // Colorize and add the highlighting.
    o = pow(vec4(1.5, 1, 1, 0)*o, vec4(1, 3.5, 16, 0))  + b*b*(.5 + b*b);
    // Applying a curvature based gradient to the surface to bring 
    // it out a bit more.
    #if 1
    // Height value.
    float h = m(p);
    // Taking four nearby offset samples to use for curvature calculations.
    vec2 e = vec2(.02*450./iResolution.y, 0); // Sample distance.
    vec4 t4 = vec4(m(p - e),  m(p + e), m(p - e.yx), m(p + e.yx));
    // Using the four samples above to calculate the surface curvature.
    float amp = 1.;
    float curv = clamp((h*4. - dot(t4, vec4(1)))/e.x/2.*amp + .5, 0., 1.);
    // Apply the curvature.
    o *= curv*1.5 + .5; // Light lines.
    //o = mix(o, o*o*.5, abs(curv - .5)*2.; // Dark lines.
    #endif
    // Rough gamma correction.
    o = sqrt(max(o, 0.));
}