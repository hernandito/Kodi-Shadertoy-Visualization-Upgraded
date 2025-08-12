// Add precision qualifiers for floats and samplers
precision highp float;
precision highp int;
precision highp sampler2D;

/*
    Mandelbrot Pattern Decoration
    -----------------------------


    After looking at Fabrice's Mandelbrot derivative example, it occurred
    to me that I have a heap of simple Mandelbrot and Julia related 
    demonstrations that I've never gotten around to posting, so here's one 
    of them. I put it together a long time ago using the standard base code, 
    which you'll find in countless examples on the internet. I'm pretty sure 
    I started with IQ's "Orbit Traps" shader, which is a favorite amongst 
    many on here, then added a few extra lines to produce the effect you 
    see. There's not a lot to this at all, so hopefully, it'll be easy to 
    consume.

    Producing Mandelbrot and Julia patterns is pretty straight forward. At 
    it's core, you're simply transforming each point on the screen in a 
    certain way many times over, then representing the transformed point 
    in the form of shades and colors.

    In particular, you treat each point as if it were on a 2D complex plane, 
    then perform an iterative complex operation -- which, ironically, is not 
    complex at all. :) In this particular example, the iterative complex 
    derivative is recorded also, which is used for a bit of shading.

    In regard to the shading process itself, most people tend to set a 
    bailout, then provide a color based on the transformed point distance,
    and leave it at that. However, with barely any extra code, it's 
    possible to makes things look more interesting.   

    The patterns look pretty fancy, but they're nothing more than repeat 
    circles and grid boundaries applied after transforming the coordinates. 
    The shading and highlights were made up on the spot, but none of it was
    complex, nor was it based on reality (no pun intended).

    

    Related examples:

    Based on one of IQ's really nice Mandelbrot example. I love the
    subtle feathering.
     Mandelbrot - orbit traps -- IQ
     https://www.shadertoy.com/view/ldf3DN

    // Beautiful example.
    Heading To The Sun -- NivBehar
    https://www.shadertoy.com/view/wtdSzS

*/

// BCS Post-processing parameters
#define BRIGHTNESS 0.01    // Adjust brightness (-1.0 to 1.0, 0.0 is original)
#define CONTRAST 1.02      // Adjust contrast (0.0 to inf, 1.0 is original)
#define SATURATION 1.40   // Adjust saturation (0.0 to inf, 1.0 is original)

// Overall animation speed control
#define ANIMATION_SPEED .20 // Adjust animation speed (e.g., 0.5 for half, 2.0 for double)

// Field of View adjustment
#define FOV_ADJUSTMENT 2.0 // Adjust FOV (e.g., 0.5 for narrower, 2.0 for wider)


void mainImage(out vec4 fragColor, in vec2 fragCoord ){

    
    // Base color.
    vec3 col = vec3(0.0);
    
    // Anitaliasing: Just a 2 by 2 sample. You could almost get away with not using
    // it at all, but it is necessary.
    #define AA 2
    for(int j=0; j<AA; j++){
        for(int i=0; i<AA; i++){

            // Offset centered coordinate -- Standard AA stuff.
            vec2 p = (fragCoord + vec2(float(i), float(j))/float(AA) - iResolution.xy*.5)/iResolution.y;
            
            // Time, rotating back and forth.
            // iTime multiplied by ANIMATION_SPEED
            float ttm = cos(sin(iTime * ANIMATION_SPEED / 8.0)) * 6.2831;
            
            // Rotating and translating the canvas... More effort needs to be put in here,
            // but it does the job.
            p *= mat2(cos(ttm), sin(ttm), -sin(ttm), cos(ttm));
            // iTime multiplied by ANIMATION_SPEED
            p -= vec2(cos(iTime * ANIMATION_SPEED / 2.0) / 2.0, sin(iTime * ANIMATION_SPEED / 3.0) / 5.0);
            
            
            // Jump off point and zoom... Where and how much you zoom in greatly effects what
            // you see, so I probably should have put more effort in here as well, but this
            // shows you enough.
            // iTime multiplied by ANIMATION_SPEED
            float zm = (200.0 + sin(iTime * ANIMATION_SPEED / 7.0) * 50.0);
            vec2 cc = vec2(-.57735 + .004, .57735) + p/zm;
 

            // Position and derivative. Initialized to zero.
            vec2 z = vec2(0.0), dz = vec2(0.0);

            // Iterations: Not too many. You could get away with fewer, if need be.
            const int iter = 128;
            int ik = 128; // Bail out value. Set to the largest to begin with.
            vec3 fog = vec3(0.0); //vec3(.01, .02, .04);
            
            for(int k=0; k<iter; k++){


                // Derivative: z' = z*z'*2. + 1.
                // Imaginary partial derivatives are similar to real ones.
                dz = mat2(z, -z.y, z.x)*dz*2.0 + vec2(1.0, 0.0); // A better way. Thanks, Fabrice. :)
                //dz = vec2(z.x*dz.x - z.y*dz.y, z.x*dz.y + z.y*dz.x)*2. + vec2(1, 0);
            
                
                // Position: z = z*z + c.
                // Squaring an imaginary point is slightly different to squaring a real
                // one, but at the end of the day, it's just a transformation.
                z =  mat2(z, -z.y, z.x)*z + cc;
                //z = (vec2(z.x*z.x - z.y*z.y, 2.*z.x*z.y)) + cc;
                
                
                // Experimental transformation with twisting... It's OK, but I wasn't
                // feeling it.
                //float l = (float(k)/500.);
                //z = mat2(cos(l), sin(l), -sin(l), cos(l))*mat2(z, -z.y, z.x)*z + cc;
 
                
                // If the length (squared to save cycles) of the transformed point goes 
                // out of bounds, break. In layperson's terms, points that stay within 
                // the set boundaries longer appear brighter... or darker, depending what
                // you're trying to achieve.
                if(dot(z, z) > 1.0/.005){
                    ik = k; // Record the break number, or however you say it.
                    break;
                }
                
            }
            
            
            
            
            // Lines and shading. There'd be a few ways to represent a boundary line, and
            // I'd imagine there'd be better ways than this, but it works, so it'll do.
            float ln = step(0.0, length(z)/15.5  - 1.0);
            
            
            // Distance... shade... It's made up, but there's a bit of logic there. Smooth 
            // coloring involves the log function. I remember reading through a proof a few 
            // years back, when I used to like that kind of thing. It made sense at the time. :)
            float d = sqrt(1.0/max(length(dz), .0001))*log(dot(z, z));
            // Mapping the distance from zero to one.
            d = clamp(d*50.0, 0.0, 1.0); 
            
            // Flagging successive layers. You can use this to reverse directions, alternate
            // colors, etc.
            float dir = mod(float(ik), 2.0)<.5? -1.0 : 1.0;
            
            // Layer coloring and shading. Also made up.
            float sh = (float(iter - ik))/float(iter); // Shade.
            vec2 tuv = z/320.0; // Transformed UV coordinate.
            
            // Rotating the coordinates, based on the global canvas roations and distance
            // for that parallax effect to aid the depth illusion.
            // iTime multiplied by ANIMATION_SPEED
            float tm = (-ttm*sh*sh*16.0);
            // Rotated, repeat coordinates.
            tuv *= mat2(cos(tm), sin(tm), -sin(tm), cos(tm));
            tuv = abs(mod(tuv, 1.0/8.0) - 1.0/16.0); 
            
            // Rendering a grid of circles, and showing the grid boundaries. Anything is 
            // possible here: Truchets, Voronoi, etc.
            float pat = smoothstep(0.0, 1.0/length(dz), length(tuv) - 1.0/32.0);
            pat = min(pat, smoothstep(0.0, 1.0/length(dz), abs(max(tuv.x, tuv.y) - 1.0/16.0) - .04/16.0));
            
            // Coloring the layer. These are based on the shaded distance value, but you can
            // choose anything you want.
            //vec3 lCol = (.55 + .45*cos(6.2831*(d*d)/3. + vec3(0, 1, 2) - 4.))*1.25;
            vec3 lCol = pow(min(vec3(1.5, 1.0, 1.0)*min(d*.85, .96), 1.0), vec3(1.0, 3.0, 16.0))*1.15;
            
            // Appolying the circular grid pattern to the color, based on successive layer count.
            // We're also applying a boundary line.
            // Modified this line to make the "white background" layer use the same orange-to-yellow gradient
            lCol = dir<0.0? lCol*min(pat, ln) : lCol*max(1.0 - pat, 1.0 - ln);
            
            
            
            // A fake unit direction vector to provide a fake reflection vector in order
            // to produce a fake glossy diffuse value for fake highlights. The knowledge
            // behind all this is also fake. :D
            vec3 rd = normalize(vec3(p, 1.0));
            rd = reflect(rd, vec3(0.0, 0.0, -1.0));
            // Synchronizing the gloss movement... It wasn't for me.
            // rd.xy = mat2(cos(tm), sin(tm), -sin(tm), cos(tm))*rd.xy; 
            float diff = clamp(dot(z*.5 + .5, rd.xy), 0.0, 1.0)*d;
            
            
            // Fake reflective pattern, which has been offset slightly, and moved in a 
            // reflective manner.
            tuv = z/200.0;
            tm = -tm/1.5 + .5;
            tuv *= mat2(cos(tm), sin(tm), -sin(tm), cos(tm));
            tuv = abs(mod(tuv, 1.0/8.0) - 1.0/16.0); 
            pat = smoothstep(0.0, 1.0/length(dz), length(tuv) - 1.0/32.0);
            pat = min(pat, smoothstep(0.0, 1.0/length(dz), abs(max(tuv.x, tuv.y) - 1.0/16.0) - .04/16.0));

            
            // Adding the fake gloss. The "ln" variable is there to stop the gloss from 
            // reaching the outer fringe, since I thought that looked a little better.
            lCol += mix(lCol, vec3(1.0)*ln, .5)*diff*diff*.5*(pat*.6 + .6);
            
            // Swizzling the color on every sixth layer -- I thought it might break up the
            // orange and red a little.
            if (mod(float(ik), 6.0)<.5) lCol = lCol.yxz;
            lCol = mix(lCol.xzy, lCol, d/1.2); // Shade based coloring, for something to do.
            
            // This was a last minute addition. I put some deep black lined fringes on the layers
            // to add more illusion of depth. Comment it out to see what it does.
            lCol = mix(lCol, vec3(0.0), (1.0 - step(0.0, -(length(z)*.05*float(ik)/float(iter)  - 1.0)))*.95);
            
            // Applying the fog.
            lCol = mix(fog, lCol, sh*d);
            
            
            // Used for colored fog.
            //lCol *= step(0., d - .25/(1. + float(ik)*.5));
            
            // Applying the color sample.
            col += min(lCol, 1.0);
        }
    }
    
    // Divide by the sample number.
    col /= float(AA*AA);
    
    
    // Toning down the highlights... but I'm going to live on the edge and leave it as is. :D
    //col = (1. - exp(-col))*1.25;
    
    // Apply BCS post-processing
    // Brightness
    col += BRIGHTNESS;

    // Contrast
    col = (col - 0.5) * CONTRAST + 0.5;

    // Saturation
    vec3 luminance = vec3(dot(col, vec3(0.2126, 0.7152, 0.0722)));
    col = mix(luminance, col, SATURATION);

    // Subtle vignette.
    vec2 uv = fragCoord/iResolution.xy;
    col *= pow(16.0*(1.0 - uv.x)*(1.0 - uv.y)*uv.x*uv.y, 1.0/8.0)*1.15;
    
    fragColor = vec4(sqrt(max(col, 0.0)), 1.0 );
}
