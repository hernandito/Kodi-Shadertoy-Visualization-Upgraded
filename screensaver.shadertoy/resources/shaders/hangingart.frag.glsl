/*

    Geometric Paper Pattern
    -----------------------

    A geometric pattern rendered onto some animated hanging paper, which for some 
    inexplicable and physics defying reason is also animated. :D

    I put this together out of sheer boredom, and I didn't spend a lot of time on 
    it, so I wouldn't look too much into the inner workings, especially not the 
    physics aspects... I honestly couldn't tell you why the paper is waving around 
    like that. :)

    The pattern is about as basic as it gets. I've used some equally basic post
    processing to give it a slightly hand drawn look. The pencil algorithm I've
    used is just a few lines, and is based on one of Flockaroo's more sophisticated
    examples. The link is below, for anyone interested. At some stage, I'd like
    to put a sketch algorithm out that is more hatch-like.

    On a side note, for anyone who likes small functions, feel free to take a look 
    at the "n2D" value noise function. I wrote it ages ago (also when I was bored) 
    and have taken it as far as I can take it. However, I've often wondered whether 
    some clever soul out there could write a more compact one.




    Related examples:

    // A more sophisticated pencil sketch algorithm.
    When Voxels Wed Pixels - Flockaroo 
    // https://www.shadertoy.com/view/MsKfRw

*/

// For those who find the default pattern just a little too abstract and minimal,
// here's another slighly less abstract minimal pattern. :D
//#define LINE_TRUCHET

// I felt the pattern wasn't artistic enough, so I added some tiny holes. :)
#define HOLES

// Adjustable parameter for overall animation speed.
// A value of 1.0 is normal speed.
// Values > 1.0 will speed up the animation.
// Values < 1.0 will slow down the animation.
#define ANIMATION_SPEED 0.50


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){ 
    return fract(sin(mod(dot(p, vec2(27.619, 57.583)), 6.2831589))*43758.5453); 
}

// IQ's box formula -- modified for smoothing.
float sBoxS(in vec2 p, in vec2 b, in float rf){
 
    vec2 d = abs(p) - b + rf;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

// IQ's box formula.
float sBox(in vec2 p, in vec2 b){
    
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// This will draw a box (no caps) of width "ew" from point "a "to "b". I hacked
// it together pretty quickly. It seems to work, but I'm pretty sure it could be
// improved on. In fact, if anyone would like to do that, I'd be grateful. :)
float lBox(vec2 p, vec2 a, vec2 b, float ew){
    
    float ang = atan(b.y - a.y, b.x - a.x);
    p = rot2(ang)*(p - mix(a, b, .5));
    
    vec2 l = vec2(length(b - a), ew);
    return sBox(p, (l + ew)/2.) ;
}

float distField(vec2 p){
    
    // Cell ID and local cell coordinates.
    vec2 ip = floor(p) + .5;
    p -= ip;
    
    // Some random numbers.
    float rnd = hash21(ip + .37);
    float rnd2 = hash21(ip + .23);
    float rnd3 = hash21(ip + .72);
 
    
    // Cell boundary.
    float bound = sBox(p, vec2(.5)); 
    
    
    float d = 1e5; // Distance field.
    
    // Random 90 degree cell rotation.
    p *= rot2(floor(rnd*64.)*3.14159/2.);
    
    
    // Just adding a tiny hole to draw the eye to the... No idea why artists do 
    // this kind of thing, but it enables them to double the price, so it's
    // definitely worth the two second effort. :)
    float hole = 1e5;
    
    
    #ifdef LINE_TRUCHET
    
    // Three tiled Truchet pattern consisting of arc, straight line 
    // and dotted tiles.
    
    // Four corner circles.
    vec2 q = abs(p);
    float cir = min(length(q - vec2(0, .5)), length(q - vec2(.5, 0)));
    
    if(rnd3<.75){
        if(rnd2<.65){
            d = abs(min(length(p - .5), length(p + .5)) -.5) - .5/3.;
            
        }
        else {
            p = abs(p) - .5/3.;
            d = min(max(p.x, -(p.y - .5/8.)), p.y);
        }
        
    }
    else {
        // Four dots in the empty squares to complete the pattern.
        d = cir - .5/3.;
    }
    
    // Corner holes.
    hole = cir -.05;
    
    #else
    // Very common quarter arc and triangle Truchet pattern, which is a 
    // favorite amongst the abstract art crowd.
    if(rnd3<.75){;
        
        // Corner holes.
        hole = length(p - .325) - .05;
                    
        if(rnd2<.5){
            // Corner quarter circle... Well, it's a full one,
            // but it gets cut off at the grid boundaries.
            d = length(p - .5) - 1.;
        }
        else {
            // A corner diamond, but we'll only see the triangular part.
            p = abs(p - .5);
            d = abs(p.x + p.y)/sqrt(2.) - .7071;
        }
    }
    #endif
    
    #ifdef HOLES
    d = max(d, -hole);
    #endif
    
    // Cap to the cell boundaries. Sometimes, you have to do this
    // to stop rendering out of bounds, or if you wish to include
    // boundary lines in the rendering.
    //
    return max(d, bound);
}

// Cell grid borders.
float gridField(vec2 p){
    
    vec2 ip = floor(p) + .5;
    p -= ip;
    
    p = abs(p);
    float grid = abs(max(p.x, p.y) - .5) - .005;
    
    return grid;
}

// Compact, self-contained version of IQ's 2D value noise function.
float n2D(vec2 p){
    
    // Setup.
    // Any random integers will work, but this particular
    // combination works well.
    const vec2 s = vec2(1, 113);
    // Unique cell ID and local coordinates.
    vec2 ip = floor(p); p -= ip;
    // Vertex IDs.
    vec4 h = vec4(0., s.x, s.y, s.x + s.y) + dot(ip, s);
    
    // Smoothing.
    p = p*p*(3. - 2.*p);
    //p *= p*p*(p*(p*6. - 15.) + 10.); // Smoother.
    
    // Random values for the square vertices. The modulo is only there to 
    // accomodate my annoying AMD card that can't seem to wrap sinusoidals.
    h = fract(sin(mod(h, 6.2831853))*43758.5453);
    
    // Interpolation.
    h.xy = mix(h.xy, h.zw, p.y);
    return mix(h.x, h.y, p.x); // Output: Range: [0, 1].
}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }


vec3 pencil(vec3 col, vec2 p){
    
    // Rough pencil color overlay... The calculations are rough... Very rough, in fact, 
    // since I'm only using a small overlayed portion of it. Flockaroo does a much, much 
    // better pencil sketch algorithm here:
    //
    // When Voxels Wed Pixels - Flockaroo 
    // https://www.shadertoy.com/view/MsKfRw
    //
    // Anyway, the idea is very simple: Render a layer of noise, stretched out along one 
    // of the directions, then mix a similar, but rotated, layer on top. Whilst doing this,
    // compare each layer to it's underlying greyscale value, and take the difference...
    // I probably could have described it better, but hopefully, the code will make it 
    // more clear. :)
    // 
    // Tweaked to suit the brush stroke size.
    vec2 q = p*4.;
    const vec2 sc = vec2(1, 12);
    q += (vec2(n2D(q*4.), n2D(q*4. + 7.3)) - .5)*.03;
    q *= rot2(-3.14159/2.5);
    // I always forget this bit. Without it, the grey scale value will be above one, 
    // resulting in the extra bright spots not having any hatching over the top.
    col = min(col, 1.);
    // Underlying grey scale pixel value -- Tweaked for contrast and brightness.
    float gr = (dot(col, vec3(.299, .587, .114)));
    // Stretched fBm noise layer.
    float ns = (n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
    // Compare it to the underlying grey scale value.
    ns = gr - ns;
    //
    // Repeat the process with a couple of extra rotated layers.
    q *= rot2(3.14159/2.);
    float ns2 = (n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
    ns2 = gr - ns2;
    q *= rot2(-3.14159/5.);
    float ns3 = (n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
    ns3 = gr - ns3;
    //
    // Mix the two layers in some way to suit your needs. Flockaroo applied common sense, 
    // and used a smooth threshold, which works better than the dumb things I was trying. :)
    ns = min(min(ns, ns2), ns3) + .5; // Rough pencil sketch layer.
    //ns = smoothstep(0., 1., min(min(ns, ns2), ns3) + .5); // Same, but with contrast.
    // 
    // Return the pencil sketch value.
    return vec3(ns);
    
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    

    // Aspect correct screen coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    
    // Scaling factor.
    float gSc = 8.;
    
    // Smoothing factor.
    float sf = 1./iResolution.y*gSc;
    
    // Unperturbed coordinates.
    vec2 pBg = uv*gSc; 
    
    // Apply ANIMATION_SPEED to iTime where it affects the animation (e.g., noise functions)
    vec2 offs = vec2(fbm(uv/1. + iTime*ANIMATION_SPEED/4.), fbm(uv/1. + iTime*ANIMATION_SPEED/4. + .35));
    const float oFct = .04;
    uv -= (offs - .5)*oFct;
    
    // Scaled perturbed coordinates.. 
    vec2 p = uv*gSc;
    
    
    // The paper distance field.
    vec2 fw = vec2(6, 3);
    float bw = 1./3.;
    float paper = sBoxS(p, fw + bw, .05);
 
    // Mixing the static background coordinates with the wavy offset ones to
    // save calculating two functions for various things.
    vec2 pMix = mix(p, pBg, smoothstep(0., sf, paper));

    // Failed experiment with a moving pattern.
    //vec2 rnd22 = vec2(hash21(ip + 1.6), hash21(ip + 2.6));
    //rnd22 = smoothstep(.9, .97, sin(6.2831*rnd22 + iTime*ANIMATION_SPEED/2.)); // Modified for animation speed
    //float d = distField(p + rnd22);
    
    // The geometric pattern field.
    float d = distField(pMix);
    
    // Canvas pattern square ID.
    vec2 ip = floor(p) + .5;
    
    // Background. Nothing exciting, but theres' a subtle vertical gradient
    // to mimic an overhead light, or something to that effect.
    vec3 bg = vec3(.9, .82, .74)*.85;
    bg = mix(bg, bg*.9, -uv.y*.5 + .5);
    
    // Initialize the scene color to the background.
    vec3 col = bg;
    
    
    // Using the pattern distance field for a subtle background wall overlay.
    // Back in the old days (the 90s), you'd reuse whatever you could.
    col = mix(col, bg*.92, 1. - smoothstep(0., sf, d));
    col = mix(col, bg*.96, 1. - smoothstep(0., sf, d + .03)); 
    
 
    // The paper shadow distance field and application.
    vec2 shOff = normalize(vec2(1, -3))*.1;
    float dSh = sBoxS(p - shOff, fw + bw, .05);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*4., dSh))*.5);
    
    // Paper rendering.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, paper))*.1); 
    col = mix(col, vec3(1), (1. - smoothstep(0., sf, paper + .02))); 
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, paper + bw))); 
    
    
    /*
    // Distance field-based lines on the canvas. I tried a few quick things
    // for this example, and unfortunately, not a lot worked, but I've left
    // the workings in for anyone who wants to play around with this.
    const float lnN = 8.; // Number of concentric pattern lines.
    float pat = abs(fract(d*lnN*1. - .5) - .5)*2. - .05;
    pat = smoothstep(0., sf*lnN*2., pat)*.65 + .35;
    */
    
    
    // Random animated background color for each square.
    float rndC = hash21(ip + .23);
    rndC = sin(6.2831*rndC + iTime*ANIMATION_SPEED/2.);     // Modified for animation speed
    vec3 sqCol = .55 + .45*cos(6.2831*rndC + vec3(0, 1, 2)); // IQ's palette.
    col = mix(col, sqCol, (1. - smoothstep(0., sf, paper + bw + .0))); 


    // Render a colored Truchet pattern in one of two styles.
    
    // Restrict pattern rendering to the canvas.
    d = max(d, (paper + bw));
    
    
    // IQ's really cool, and simple, palette.
    vec3 shCol = .55 + .45*cos(6.2831*rndC + vec3(0, 1, 2) + 1.);

    // Subtle drop shadow, edge and coloring.
    col = mix(col, bg*.03, (1. - smoothstep(0., sf*4., d))*.5);
    col = mix(col, bg*.03, (1. - smoothstep(0., sf, d)));
    col = mix(col, shCol, (1. - smoothstep(0., sf, d + .02)));

    
    // Adding in some blinking offset color, just to mix things up a little.
    rndC = hash21(ip + .87);
    rndC = smoothstep(.8, .9, sin(6.2831*rndC + iTime*ANIMATION_SPEED*2.)*.5 + .5); // Modified for animation speed
    vec3 colB = mix(col, col.xzy, rndC/2.);
    col = mix(col, colB, 1. - smoothstep(0., sf, paper + bw));
    
    
    
    // Putting some subtle layerd noise onto the wall and paper.
    col *= fbm(pMix*48.)*.2 + .9;
    
    

    // Grid lines on the canvas.
    float grid = gridField(p);
    grid = max(grid, paper + bw);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*2., grid))*.5);
    
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, grid)));

    /*
    // Circles on the pattern... Too busy looking.
    vec3 svC = col/2.;
    float cir = length(p - ip) - .1;
    cir = max(cir, bord + bw);
    col = mix(col, bg*.07, (1. - smoothstep(0., sf, cir)));
    //col = mix(col, svC, (1. - smoothstep(0., sf, cir + .02)));
    */    
    
    
    // Recalculating UV with no offset to use with postprocessing effects. 
    uv = (fragCoord - iResolution.xy*.5)/iResolution.y; 

    float canv = smoothstep(0., sf*2., (paper + bw));
    float canvBord = smoothstep(0., sf*2., (paper));

    /*
    // Corduroy lines... Interesting texture, but I'm leaving it out.
    vec2 q3 = mix(uv, p/gSc, 1. - (canvBord));
    float lnPat = abs(fract((q3.x - q3.y)*80.) - .5)*2. - .01;
    float frM = smoothstep(0., sf, max(paper, -(paper + bw)));
    lnPat = smoothstep(0., sf*80./2., lnPat);
    col = mix(col, col*(lnPat*.25 + .75), frM);
    */
    
    
    // Boring, and admittedly, inefficient hanger and string calculations, etc.
    // A lot of it is made up on the spot. However, at the end of the day, this
    // is a pretty cheap example, so it'll do.
    vec2 q2 = uv;
    q2.x = mod(q2.x, 1.) - .5;
    q2 -= (offs - .5)*oFct + vec2(0, (3. + bw*.9)/gSc);
    // String, and string shadow. 
    float strg = lBox(q2, vec2(0), vec2(0, .5) - (offs - .5)*oFct, .002);
    float strgSh = lBox(q2 - shOff*.5,  vec2(0, .04), vec2(0, .5) - (offs - .5)*oFct, .002);
    // Rendering the strings and shadows.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf/gSc, strgSh))*.25);
    col = mix(col, vec3(.5, .4, .3), (1. - smoothstep(0., sf/gSc/2., strg)));
    // The little black hangers and corresponding shadow.
    float hang = sBoxS(q2, vec2(1, .5)*bw/gSc, .0);
    float hangBk = sBoxS(q2, vec2(1. + .05, .5)*bw/gSc, .0);
    float hangBkSh = sBoxS(q2 - vec2(.008, -.004), vec2(1. + .06, .5)*bw/gSc, .0);
    hangBk = max(hangBk, -paper);
    hangBkSh = max(hangBkSh, -paper);
    float hangSh = sBoxS(q2 - shOff*.1, vec2(1, .5)*bw/gSc, .0);
    // Rendering the hangers and shadows.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf/gSc*2., hangBkSh))*.5);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf/gSc*2., hangSh))*.35);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf/gSc, hangBk)));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf/gSc, hang)));
    col = mix(col, bg*oFct, 1. - smoothstep(0., sf/gSc, hang + .004));
    
    

    // Adding very subtle lighting to the wavy pattern... So subtle that it's
    // barely worth the effort, but it's done now. :)
    float eps = .01;
    vec2 offs2 = vec2(fbm(uv/1. + iTime*ANIMATION_SPEED/4. - eps), fbm(uv/1. + iTime*ANIMATION_SPEED/4. + .35 - eps)); // Modified for animation speed
    float z = max(dot(vec3(0, 1, -.5), vec3(offs2 - offs, eps)), 0.)/eps;
    col *= mix(1., .9 + z*.1, 1. - canvBord);
    
    
    // Subtle pencel overlay... It's cheap and definitely not production worthy,
    // but it works well enough for the purpose of the example. The idea is based
    // off of one of Flockaroo's examples.
    vec2 q = mix(uv*gSc*2., p, 1. - (canvBord));
    vec3 colP = pencil(col, q*iResolution.y/450.);
    //col *= colP*.8 + .5; 
    col *= mix(vec3(1), colP*.8 + .5, .8);
    //col = colP; 
    
    
    // Cheap paper grain... Also barely worth the effort. :)
    vec2 oP = floor(p/gSc*1024.);
    vec3 rn3 = vec3(hash21(oP), hash21(oP + 2.37), hash21(oP + 4.83));
    vec3 pg = .9 + .1*rn3.xyz  + .1*rn3.xxx;
    col *= mix(vec3(1), pg, 1. - canv);
    
    
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
    
}
