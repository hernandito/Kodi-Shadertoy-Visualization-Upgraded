/*

    Faceted Torus Rendering
    -----------------------
    
    There are countless hand drawn geometric images online, and a lot of
    tutorials showing people how to draw them. Most involve multiple
    simplistic repetitive steps and measurements, which make their
    construction well suited to a computer.
    
    The downside is that computers do such a good job that the results tend
    to look too flawless, which means some of the artistry gets lost in
    translation. Ironically, we then have to complicate things to put the
    flaws back in. In this case, I've done that via a basic post-processing
    algorithm. It works, but there are better ones out there. Flockaroo has
    some great examples of various rendering styles for anyone interested.
    
    This particular geometric rendering is a faceted twisted torus and is
    simple to produce. In fact, anyone with basic geometric knowledge can do
    it easily: Start off with an n-gon (the default is an octagon), then
    render some radial quad strips for each side using basic vector addition
    and trigonometry. How one goes about it is up to the individidual, but
    you can check to see how I've done it below.
    
    Obviously, this is a 2D rendering of a 3D object, but it's possible to
    render a 3D version in the same style, which I plan to put together in
    due course. I'll leave the short version to the code golfers. :)
    
    

    
    Other 2D polygon-based sketch examples:
    
    
    // Very watchable, and with virtually no code.
    Cube Circle Sketch - Shane
    https://www.shadertoy.com/view/3dtBWX
    

*/

// Background: Plain: 0, Sunset: 1, Light blue: 2.
#define BACKGROUND 2

// Sketch only.
//#define SKETCH

// Offset scribbled edges.
//#define OFFSET_EDGES

// Vertices.
//#define VERTICES

// Face center marking.
//#define FACE_CENTER

// Light panels... Yeah, it's a bit much, but I had to try. :)
#define PANELS

// Rotate the torus about the XY plane.
//#define ROTATE

// N-gon degree. The default is octagonal, but numbers 4 to about 16
// work well enough.
#define N 16

// Adjust to zoom in/out (smaller value zooms in, larger zooms out)
#define FOV_SCALE 1.10


// --- UTILITY FUNCTIONS (FROM COMMON TAB) ---

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){
    // Using mod() for floats is allowed in GLSL ES 1.00
    return fract(sin(mod(dot(p, vec2(27.619, 57.583)), 6.2831589))*43758.5453);
}


// IQ's line distace formula.
float sdLine(in vec2 p, in vec2 a, in vec2 b){

    p -= a;
    b -= a;
    return length(p - b*clamp(dot(p, b)/dot(b, b), 0.0, 1.0));
}

// Entirely based on IQ's signed distance to a 2D triangle. I've expanded it
// to work with convex quads and generalized it a bit, but I doubt it would
// translate to speed. It would be easy to generalize to convex polyons though.
float quad(in vec2 p, in vec2[4] v){

    // Lines between successive vertex points.
    vec2[4] e;
    e[0] = v[1] - v[0];
    e[1] = v[2] - v[1];
    e[2] = v[3] - v[2];
    e[3] = v[0] - v[3];
    
    // Winding related sign.
    float s = sign(e[0].x*e[3].y - e[0].y*e[3].x);
    
    vec2 d = vec2(1e5);
    
    for(int i = 0; i < 4; i++){
        
        // Minimum point to line calculations.
        vec2 vi = p - v[i];
        vec2 qi = vi - e[i]*clamp(dot(vi, e[i])/dot(e[i], e[i]), 0.0, 1.0);
        d = min(d, vec2(dot(qi, qi), s*(vi.x*e[i].y - vi.y*e[i].x)));
    }

    // Quad distance.
    return -sqrt(d.x)*sign(d.y);
}



// Compact, self-contained version of IQ's 2D value noise function.
float n2D(vec2 p){
    
    // Setup.
    // Any random integers will work, but this particular
    // combination works well.
    const vec2 s = vec2(1.0, 113.0);
    // Unique cell ID and local coordinates.
    vec2 ip = floor(p); p -= ip;
    // Vertex IDs.
    vec4 h = vec4(0.0, s.x, s.y, s.x + s.y) + dot(ip, s);
    
    // Smoothing.
    p *= p*(3.0 - 2.0*p);
    //p *= p*p*(p*(p*6.0 - 15.0) + 10.0); // Smoother.
    
    // Random values for the square vertices.
    // mod(vec4, float) is allowed
    h = fract(sin(mod(h, 6.2831589))*43758.5453);
    
    // Interpolation.
    h.xy = mix(h.xy, h.zw, p.y);
    return mix(h.x, h.y, p.x); // Output: Range: [0, 1].
}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*0.533 + n2D(p*2.0)*0.267 + n2D(p*4.0)*0.133 + n2D(p*8.0)*0.067; }


vec3 pencil(vec3 col, vec2 p, int drkLns){
    
    // Rough pencil color overlay... The calculations are rough... Very rough, in fact,
    // since I'm only using a small overlayed portion of it. Flockaroo does a much, much
    // better pencil sketch algorithm here:
    //
    // When Voxels Wed Pixels - Flockaroo
    // https://www.shadertoy.com/view/MsKfRw
    //
    // Anyway, the idea is very simple: Render a layer of noise, stretched out along one
    // of the directions, then mix similar, but rotated, layers on top. Whilst doing this,
    // compare each layer to it's underlying greyscale value, and take the difference...
    // I probably could have described it better, but hopefully, the code will make it
    // more clear. :)
    //
    // Tweaked to suit the brush stroke size.
    vec2 q = p*4.0;
    const vec2 sc = vec2(1.0, 12.0);
    q += (vec2(n2D(q*4.0), n2D(q*4.0 + 7.3)) - 0.5)*0.03;
    q *= rot2(-3.14159/4.5);
    // I always forget this bit. Without it, the grey scale value will be above one,
    // resulting in the extra bright spots not having any hatching over the top.
    col = min(col, 1.0);
    // Underlying grey scale pixel value -- Tweaked for contrast and brightness.
    float gr = (dot(col, vec3(0.299, 0.587, 0.114)));
    // Stretched fBm noise layer.
    float ns = (n2D(q*sc)*0.66 + n2D(q*2.0*sc)*0.34);
    //
    // Repeat the process with a few extra rotated layers.
    q *= rot2(3.14159/3.0); q += 1.5;
    float ns2 = (n2D(q*sc)*0.66 + n2D(q*2.0*sc)*0.34);
    q *= rot2(-3.14159/5.2); q += 3.0;
    float ns3 = (n2D(q*sc)*0.66 + n2D(q*2.0*sc)*0.34);
    q *= rot2(3.14159/3.7); q += 6.0;
    float ns4 = (n2D(q*sc)*0.66 + n2D(q*2.0*sc)*0.34);
    //
    // Compare it to the underlying grey scale value.
    //
    // Mix the two layers in some way to suit your needs. Flockaroo applied common sense,
    // and used a smooth threshold, which works better than the dumb things I was trying. :)
    const float contrast = 1.0;
    if(drkLns==0){
        // Same, but with contrast.
        ns = (0.5 + (gr - (max(max(ns, ns2), max(ns3, ns4))))*contrast);
    }
    else {
        // Different contrast.
        ns = smoothstep(0.0, 1.0, 0.5 + (gr - max(max(ns, ns2), max(ns3, ns4))));
    }
    //
    // Return the pencil sketch value.
    return vec3(clamp(ns, 0.0, 1.0));
    
}


// --- MAIN IMAGE FUNCTION (FROM IMAGE TAB) ---

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Aspect correct screen coordinates.
    float iRes = min(iResolution.y, 800.0);
    vec2 uv = (fragCoord - iResolution.xy*0.5)/iRes;
    
    // Scaling and translation.
    float gSc = 1.0 * FOV_SCALE; // Apply FOV_SCALE here
    
    // Smoothing factor.
    float sf = gSc/iRes;
    
    // Scaling, translation, etc.
    vec2 p = uv*gSc;
    
    // Coordinate perturbation. There's small rigid one to enhance the hand-drawn look, and
    // a larger animated one to wave the paper around a bit.
    vec2 offs = vec2(fbm(p*16.0), fbm(p*16.0 + 0.35));
    vec2 offs2 = vec2(fbm(p*1.0 + iTime/4.0), fbm(p*1.0 + 0.5 + iTime/4.0));
    const float oFct = 0.007;
    const float oFct2 = 0.04;
    p -= (offs - 0.5)*oFct;
    p -= (offs2 - 0.5)*oFct2;
    
    
    
    // Set the background to something neutral.
    float lgt = dot(rot2(-3.14159/6.0)*uv, vec2(0.5)) + 0.5;
    #if BACKGROUND == 0
    vec3 col = mix(vec3(0.6, 0.55, 0.45), vec3(0.9, 0.85, 0.8), lgt);
    #elif BACKGROUND == 1
    vec3 col = mix(vec3(0.7, 0.2, 0.3), vec3(1.0, 0.7, 0.3), lgt);
    col = mix(col, col.yzx, 0.15);
    #else
    vec3 col = vec3(0.65, 0.85, 1.0)*mix(0.8, 1.2, lgt);
    #endif

    
    // Edge width.
    const float ew = 0.00165;
    
    // N-Gon degree.
    const float fN = float(N);
    
    // Center to vertex vector.
    vec2 vi = vec2(-0.15, 0.0);
    
    // Quad side length vector, used to construct the faces.
    vec2 sL = vec2(0.0, abs(vi.x*sin(6.2831/fN/2.0)*2.0));
    
    
    // Whole object, hit polygon and line distance fields.
    float obj = 1e5, polyMin = 1e5, line = 1e5;
    
    // Offset edges.
    float edge = 1e5;
    
    // The object vertices.
    #ifdef ROTATE
    vec2 q = rot2(iTime/8.0)*p;
    #else
    vec2 q = p;
    #endif
    
    // Hit quad vertices.
    vec2[4] pV;
    // Hit quad ID.
    vec2 id;
    
    
    // Quad circular strip for this edge.
    // Removed iFrame as it's not supported in Kodi.
    for(int i = 0; i < N; i++){

        // First quad for this particular edge.
        vec2[4] vR;
        
        vR[0] = rot2(-6.2831/fN*float(i) + 3.14159/fN)*vi;
        vR[1] = vR[0]+ rot2(3.14159/fN)*sL;
        vR[2] = vR[1] + sL;
        vR[3] = vR[0] + sL;
                
        // Edging out quad by quad in a circular fashion.
        for(int j = 0; j < N - 1; j++){
        
            // Quad value.
            float qud = quad(q, vR);
            
            // The combined quads, or the whole object.
            obj = min(obj, qud);
            if(qud < polyMin){
            
               // Update the minimum quad distance.
               polyMin = qud;
               
               // Quad ID.
               id = vec2(float(i), float(j));
               
               // Hit vertices. GLSL ES 1.00 does not support whole array assignment
               pV[0] = vR[0];
               pV[1] = vR[1];
               pV[2] = vR[2];
               pV[3] = vR[3];
              
            }
        
            
            // Drawing the helper grid lines.
            vec2 nrm = normalize(vR[2] - vR[3]);
            // Replaced j%2==0 with float modulo check
            if(mod(float(j), 2.0) < 0.1) line = min(line, sdLine(q, vR[2] - nrm, vR[3] + nrm));
            
            // Offset edges, if chosen.
            #ifdef OFFSET_EDGES
            // Offset polygon edges.
            for(int l = 0; l < 3; l++){
                for(int k = 0; k < 4; k++){
                    float a = 1.0/float(l + 1);
                    vec2 pk = pV[k];
                    // Replaced (k + 1)%4 with integer arithmetic for GLSL ES 1.00
                    vec2 pk1 = pV[(k + 1) - 4 * int(floor(float(k + 1) / 4.0))];
                    
                    vec2 offs1 = (vec2(hash21(pk + vec2(0.45*a, 0.0)).x, hash21(pk + vec2(0.73*a, 0.0)).y) - 0.5); // Use hash21(vec2)
                    vec2 offs2 = (vec2(hash21(pk1 + vec2(0.29*a, 0.0)).x, hash21(pk1 + vec2(0.87*a, 0.0)).y) - 0.5); // Use hash21(vec2)
                    vec2 pA = pk - offs1*0.0125;
                    vec2 pB = pk1 - offs2*0.0125;
                    vec2 nm = normalize(pB - pA);
                    edge = min(edge, sdLine(q, pA - nm*0.01, pB + nm*0.01));

                }
            }
            #endif
            
            // Produce the vertices for the next quad in the strip. As you can see,
            // each quad starts with the last vertices from the prevous quad, and the
            // new end vertices are created by adding a rotated side edge.
            vR[0] = vR[3];
            vR[1] = vR[2];
            vR[2] = vR[1] + rot2(-3.14159/fN*float(j+1))*sL;
            vR[3] = vR[0] + rot2(-3.14159/fN*float(j+1))*sL;            
            
        }
    
        // Rotate the side length vector to the right position for the next inner vertex.
        sL = rot2(-6.283/fN)*sL;
        
        // Fake break to counter unrolling and slow compile times.
        if(length(sL) > 1e5) break;
        
    }
    
    
    
    
    // Coloring and shading, based on polygon ID (side band number, or position within the band).
    float rt = 0.0;
    #ifdef ROTATE
    rt = iTime/8.0;
    #endif
    float sh = sin((float(N) - id.x)*6.2831/fN*1.3 - rt)*0.25 + 0.75;
    sh *= id.y/(fN - 2.0)*0.5 + 0.5;
    
    // Polygon color.
    vec3 polyCol = (0.55 + 0.45*cos(-6.2831*sh/3.5 + vec3(0.0, 1.0, 2.0) + 2.2))*1.5;
    polyCol = mix(polyCol, polyCol.yzx, 0.05);
    
    
    // Object drop shadow and outside edges.
    col = mix(col, vec3(0.0), (1.0 - smoothstep(0.0, sf*24.0*iRes/450.0, obj))*0.35);
    col = mix(col, polyCol/32.0, (1.0 - smoothstep(0.0, sf, obj - ew*3.0))*0.85);
    
    
    #ifdef OFFSET_EDGES
    col = mix(col, polyCol, (1.0 - smoothstep(0.0, sf, polyMin)));
    #else
    col = mix(col, polyCol/3.0, (1.0 - smoothstep(0.0, sf, polyMin)));
    col = mix(col, polyCol, (1.0 - smoothstep(0.0, sf, polyMin + ew*2.0)));
    #endif
    
    #ifdef PANELS
    // Lit face windows.
    col = mix(col, polyCol*2.0, (1.0 - smoothstep(0.0, sf*12.0, polyMin + ew*28.0)));
    col = mix(col, polyCol/2.0, (1.0 - smoothstep(0.0, sf, abs(polyMin + ew*12.0) - ew)));
    col = mix(col, polyCol/2.0, (1.0 - smoothstep(0.0, sf, abs(polyMin + ew*22.0) - ew)));
    #endif
    
    #ifdef VERTICES
    // Render vertex points.
    float vert = min(length(q - pV[0]), length(q - pV[1]));
    vert = min(vert, min(length(q - pV[2]), length(q - pV[3])));
    vert -= ew*5.0;
    col = mix(col, vec3(0.0), (1.0 - smoothstep(0.0, sf, vert)));
    col = mix(col, polyCol.xzy*0.7, (1.0 - smoothstep(0.0, sf*2.0, vert + ew*4.0)));
    #endif

    
    #ifdef FACE_CENTER
    // Face center points.
    vec2 cntr = (pV[0] + pV[1] + pV[2] + pV[3])/4.0;
    float cVert = length(q - cntr) - ew*4.0;
    col = mix(col, vec3(0.0), (1.0 - smoothstep(0.0, sf, cVert)));
    col = mix(col, polyCol.xzy*0.7, (1.0 - smoothstep(0.0, sf*2.0, cVert + ew*3.0)));
    #endif
    
    #ifndef ROTATE
    #ifndef SKETCH
    // Fake construction lines when the object isn't rotating.
    line -= ew;
    line = max(line, obj - 0.4);
    float alpha = mix(0.15, 0.15, 1.0 - smoothstep(0.0, sf*2.0, obj));
    col = mix(col, polyCol/32.0, (1.0 - smoothstep(0.0, sf, line))*alpha);
    #endif
    #endif
    
    #ifdef OFFSET_EDGES
    col = mix(col, polyCol/3.0, 1.0 - smoothstep(0.0, sf, edge - ew/3.0));
    #endif
    
    // Just a cheap way to seperate the foreground object coordinates from
    // those in the background.
    p = mix(p, q, 1.0 - smoothstep(0.0, sf*2.0, obj));
    
    
    // Subtle pencil overlay... It's cheap and definitely not production worthy,
    // but it works well enough for the purpose of the example. The idea is based
    // off of one of Flockaroo's examples.
    vec2 qq = p*8.0;
    #ifdef SKETCH
    int drkLns = 1;
    #else
    int drkLns = 0;
    #endif
    vec3 colP = pencil(col, qq*iRes/450.0, drkLns);
    #ifdef SKETCH
    // Just the pencil sketch. The last factor ranges from zero to one and
    // determines the sketchiness of the rendering... Pun intended. :D
    col = colP;
    #else
    col = mix(col, 1.0 - exp(-(col*2.0)*(colP + 0.15)), 0.85);
    #endif
    
    // Cheap paper grain... Also barely worth the effort. :)
    vec2 pp = p;
    // Ensure hash21 is called with vec2. The original hash21(vec2) from COMMON tab is used.
    vec3 rn3 = vec3(hash21(pp), hash21(pp + vec2(2.37, 0.0)), hash21(pp + vec2(4.83, 0.0)));
    vec3 pg = 0.9 + (rn3.xyz*0.35 + rn3.xxx*0.65)*0.2;
    col *= min(pg, 1.0);
    
    // Rough gamma correction and output to screen.
    fragColor = vec4(sqrt(max(col, 0.0)), 1.0);
}
