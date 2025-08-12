/*

    Hexagon Blocks
    --------------
    
    I wrote this a long time ago. I'm not sure what the most common hexagon grid
    pattern would be, but isometric boxes would have to be a contender, possibly
    because they're very easy to make, and the results are reasonably satisfying.
    
    They are constructed by producing a hexagon grid, then partitioning each hexagon
    cell into three quads to represent cube faces. If you know how to render
    polygons, then it should be pretty easy. Textured and shadowed examples are
    less common, but that's pretty easy to do also, and is explained below.
    
    Anyway, this example is definitely not that interesting, but hopefully, it'll
    be useful to someone out there.    

    
    
    
    Other hexagonal pattern examples:

    // With more effort, you can add stairs, doors, and all kinds of things.
    hexastairs: ladder like + doors -- FabriceNeyret2
    https://www.shadertoy.com/view/wsyBDm
    
    // Another simple, but effective, hexagon grid-based pattern.
    Repeating Celtic Pattern (360ch) -- FabriceNeyret2
    https://www.shadertoy.com/view/wsyXWR

    // JT has a heap of grid-based patterns that I like looking through.
    // Here are just a couple:
    //
    // hexagonally grouped weaved lines  -- jt
    // https://www.shadertoy.com/view/DdccDr
    //
    // three directions city grid parts -- jt
    // https://www.shadertoy.com/view/DdccR8
    
    

*/

// Diagonal face pattern, or not.
#define DIAGONAL

// Randomly invert some of the boxes. It's a pretty standard move and
// makes the pattern look a little more interesting.
//
// Commenting it out will produce the cleaner, but more basic pattern.
//#define RANDOM_INVERT

// Show the hexagon grid that the pattern is based on...
// Probably a little redundant in this case, but it's there.
//#define SHOW_GRID

// Flat top hexagons, instead of pointed top.
//#define FLAT_TOP

// --- Post-processing and Animation Control Parameters ---
// Adjust brightness (1.0 is default, >1.0 brighter, <1.0 darker)
#define BRIGHTNESS .99
// Adjust contrast (1.0 is default, >1.0 more contrast, <1.0 less contrast)
#define CONTRAST 1.01
// Adjust saturation (1.0 is default, >1.0 more saturated, <1.0 desaturated)
#define SATURATION 1.0

// Adjust overall animation speed (1.0 is default, >1.0 faster, <1.0 slower)
#define ANIMATION_SPEED .30


// --- UTILITY FUNCTIONS (COMBINED FROM COMMON TAB) ---

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Replaced Fabrice's hash21 (which uses floatBitsToUint and uvec2, not supported in GLSL ES 1.00)
// with a GLSL ES 1.00 compatible hash function. This is a common one.
float hash21(vec2 p){
    return fract(sin(mod(dot(p, vec2(27.619, 57.583)), 6.2831589))*43758.5453);
}

// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a;
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}

// Flat top hexagon, or pointed top.
#ifdef FLAT_TOP
const vec2 s = vec2(1.732, 1.0); // Ensure float literal
#else
const vec2 s = vec2(1.0, 1.732); // Ensure float literal
#endif

// Helper function to get hexagon vertex IDs (replaces const array initialization)
vec2 getVID(int index) {
    #ifdef FLAT_TOP
    if (index == 0) return vec2(-4.0, 0.0);
    if (index == 1) return vec2(-2.0, 6.0);
    if (index == 2) return vec2(2.0, 6.0);
    if (index == 3) return vec2(4.0, 0.0);
    if (index == 4) return vec2(2.0, -6.0);
    if (index == 5) return vec2(-2.0, -6.0);
    #else
    if (index == 0) return vec2(-6.0, -2.0);
    if (index == 1) return vec2(-6.0, 2.0);
    if (index == 2) return vec2(0.0, 4.0);
    if (index == 3) return vec2(6.0, 2.0);
    if (index == 4) return vec2(6.0, -2.0);
    if (index == 5) return vec2(0.0, -4.0);
    #endif
    return vec2(0.0); // Should not happen
}

// Helper function to get hexagon edge IDs (replaces const array initialization)
vec2 getEID(int index) {
    #ifdef FLAT_TOP
    if (index == 0) return vec2(-3.0, 3.0);
    if (index == 1) return vec2(0.0, 6.0);
    if (index == 2) return vec2(3.0, 0.0);
    if (index == 3) return vec2(3.0, -3.0);
    if (index == 4) return vec2(0.0, -6.0);
    if (index == 5) return vec2(-3.0, 0.0);
    #else
    if (index == 0) return vec2(-6.0, 0.0);
    if (index == 1) return vec2(-3.0, 3.0);
    if (index == 2) return vec2(3.0, 3.0);
    if (index == 3) return vec2(6.0, 0.0);
    if (index == 4) return vec2(3.0, -3.0);
    if (index == 5) return vec2(-3.0, -3.0);
    #endif
    return vec2(0.0); // Should not happen
}


// Hexagonal bound: Not technically a distance function, but it's
// good enough for this example.
float getHex(vec2 p){
    
    // Flat top and pointed top hexagons.
    #ifdef FLAT_TOP
    return max(dot(abs(p.xy), s/2.0), abs(p.y*s.y)); // Ensure float literal
    #else    
    return max(dot(abs(p.xy), s/2.0), abs(p.x*s.x)); // Ensure float literal
    #endif
}

// Hexagonal grid coordinates. This returns the local coordinates and the cell's center.
// The process is explained in more detail here:
//
// Minimal Hexagon Grid - Shane
// https://www.shadertoy.com/view/Xljczw
//
vec4 getGrid(vec2 p){
    
    vec4 ip = floor(vec4(p/s, p/s - 0.5)); // Ensure float literal
    vec4 q = p.xyxy - vec4(ip.xy + 0.5, ip.zw + 1.0)*s.xyxy; // Ensure float literals
    // The ID is multiplied by 12 to account for the inflated neighbor IDs above.
    return dot(q.xy, q.xy)<dot(q.zw, q.zw)? vec4(q.xy, ip.xy*12.0) : vec4(q.zw, ip.zw*12.0 + 6.0); // Ensure float literals
}


// Face pattern. Nothing exciting. Just a pseudo maze pattern.
float cubeTex(vec2 p, vec2 gIP){

    #ifdef DIAGONAL
    float sc = 6.0; // Ensure float literal
    #else
    float sc = 8.0*0.7071; // Ensure float literal
    p *= rot2(3.14159/4.0); // Ensure float literal
    #endif
    
    p *= sc;    
    
    // Square cell partiioning.
    vec2 ip = floor(p);
    p -= ip + 0.5; // Ensure float literal
    
    // Random rotation.
    float rnd = hash21(ip + gIP*0.123 + 0.01); // Ensure float literals
    if(rnd < 0.5) p.y = -p.y; // Ensure float literal
    
    // Diagonal lines.
    vec2 ap = abs(p - 0.5); // Ensure float literal
    float d = abs((ap.x + ap.y)*0.7071 - 0.7071); // Ensure float literal
    ap = abs(p);
    d = min(d, abs((ap.x + ap.y)*0.7071 - 0.7071)); // Ensure float literal
    d -= 0.1666; // Ensure float literal
    
    // Scale back and return.
    return -d/sc;
}

// Manual inverse for a 2x2 matrix, as inverse() is not available in GLSL ES 1.00
mat2 inverseMat2(mat2 m) {
    float det = m[0][0] * m[1][1] - m[0][1] * m[1][0];
    // Avoid division by zero, though for this shader, it's unlikely to be singular.
    if (abs(det) < 0.0001) return mat2(0.0); // Return zero matrix or handle error
    float invDet = 1.0 / det;
    return mat2(m[1][1] * invDet, -m[0][1] * invDet,
                -m[1][0] * invDet, m[0][0] * invDet);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Aspect correct screen coordinates.
    vec2 res = iResolution.xy;
    vec2 uv = (fragCoord.xy - res.xy*0.5)/res.y; // Ensure float literal
    
    // Global scale factor.
    const float sc = 4.0; // Ensure float literal
    // Smoothing factor.
    float sf = sc/res.y;
    
    // Scene rotation, scaling and translation.
    mat2 sRot = mat2(1.0, 0.0, 0.0, 1.0);//rot2(3.14159/12.0); // Scene rotation. Ensure float literals
    vec2 camDir = sRot*normalize(s); // Camera movement direction.
    vec2 ld = sRot*normalize(vec2(1.0, -1.0)); // Light direction. Ensure float literals
    vec2 p = sRot*uv*sc + camDir*iTime*ANIMATION_SPEED/3.0; // Apply ANIMATION_SPEED
    
    
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p);
    
    
    // The vertex and edge IDs are multiplied by 12, so we're factoring that in.
    vec2 sDiv12 = s/12.0; // Ensure float literal

    
    #ifdef RANDOM_INVERT
    // Random flipping number.
    float rndT = hash21(p4.zw + 0.01) < 0.5 ? -1.0 : 1.0; // Ensure float literals
    
    // Randomly flip the coordinates.
    if(rndT < 0.0) p4.y = -p4.y; // Ensure float literal
    #endif

    // Center to edge lines.
    float vLn[6];
    
    
    // Hexagon shape.
    float hexShape = getHex(p4.xy) - 0.5; // Ensure float literal
    
    // Iterate through all six sides of the hexagon cell.
    for(int i = 0; i < 6; i++){ // Ensure float literal
        
        // Center to edge lines.
        vLn[i] = distLineS(p4.xy, vec2(0.0), getVID(i)*sDiv12); // Use getVID function

        // Border lines (start with "hexShape = -1e5;").
        //float bord = distLineS(p4.xy, getVID(i)*sDiv12, getVID((i + 1)%6)*sDiv12); // Use getVID
        // Hexagon shape.
        //hexShape = max(hexShape, bord);

    }
    
    // Cube faces.
    vec3 cube;
    
    // Top, left and right cube sides.
    cube.x = max(max(hexShape, vLn[1]), -vLn[3]);
    cube.y = max(max(hexShape, vLn[3]), -vLn[5]);
    cube.z = max(max(hexShape, vLn[5]), -vLn[1]);
    
    
    // The overall color and shade.
    vec3 col = vec3(0.0); // Ensure float literal
    vec3 shade = vec3(0.9, 0.5, 0.4); // Ensure float literals
    
    // Cube shadows.
    vec3 shad = vec3(1e5);
    // Render quarter-wing shadow portions on two of the faces, then put the
    // remaining face completely in shadow. It's a simple, but effective, trick.
    shad.x = max(cube.x, distLineS(p4.xy, getVID(3)*sDiv12, getEID(1)*sDiv12)); // Use getVID, getEID
    shad.y = max(cube.y, distLineS(p4.xy, getEID(4)*sDiv12, getVID(3)*sDiv12)); // Use getEID, getVID
    shad.z = cube.z;
    #ifdef RANDOM_INVERT
    if(rndT < 0.0){ shad.xy = cube.xy; } // All in shade, if the hexagons are inverted. Ensure float literal
    
    // Shift the shades to match the faces of the hexagons with flipped orientation.
    if(rndT < 0.0) shade = shade.xzy; // Ensure float literal
    #endif
    

    // Applying the colors, patterns, etc, to the cube faces.
    //
    // Hmmm... I could've used cleaner color logic here, but it seems to work,
    // so I'll leave it for now. I might tidy it up later.
    for(int i = 0; i < 3; i++){ // Ensure float literal
    
        // Matrix containing the vertex-based basis vectors, which in turn is
        // used for oriented texturing.
        // Replaced (i*2 + 1)%6 with integer arithmetic for GLSL ES 1.00
        int vID_idx1 = (i * 2 + 1) - 6 * int(floor(float(i * 2 + 1) / 6.0));
        // Replaced (i*2 + 3)%6 with integer arithmetic for GLSL ES 1.00
        int vID_idx2 = (i * 2 + 3) - 6 * int(floor(float(i * 2 + 3) / 6.0));
        // Use inverseMat2 function
        mat2 mR = inverseMat2(mat2((getVID(vID_idx1)*sDiv12), (getVID(vID_idx2)*sDiv12)));
        // Correctly oriented texture coordinates for this particular face.
        vec2 txC = mR*p4.xy;
        // Using the coordinates to create the face pattern.
        float pat = cubeTex(txC, p4.zw*3.0 + float(i)); // Ensure float literal
        
        // Random face color -- It's just a shade of green.
        float rnd4 = hash21(p4.zw*3.0 + float(i)*1.0 + 0.3); // Ensure float literals
        vec3 patCol = 0.5 + 0.45*cos(6.2831*rnd4/4.0 + vec3(0.0, 1.0, 2.0).yxz*1.4); // Ensure float literals
    
        // Running a bit of a blue gradient through the colors.    
        patCol = mix(patCol, patCol.zyx, clamp(-p4.x*0.5 - p4.y + 0.5, 0.0, 1.0)); // Ensure float literals

        // Running screen-based gradients throughout.
        float uvx = uv.x*res.x/res.y;
        patCol = mix(patCol, patCol.xzy, 1.0 - smoothstep(0.0, 1.0, -uv.x/3.0 + uv.y + 0.5)); // Ensure float literals
        patCol = mix(patCol, patCol.yxz, 1.0 - smoothstep(0.2, 0.5, -uvx/2.0 + 0.5)); // Ensure float literals
        patCol *= 2.5; // Ensure float literal
    
        // Face, edge and trim colors.
        vec3 faceCol = vec3(0.9, 1.0, 1.2); // Ensure float literals
        vec3 edgeCol = faceCol/10.0; // Ensure float literal
        vec3 trimCol = vec3(1.6, 0.8, 0.2)*mix(faceCol, patCol, 0.3); // Ensure float literals
        
        // Applying the pattern to the faces.
        faceCol = mix(edgeCol, patCol, 1.0 - smoothstep(0.0, sf, pat)); // Ensure float literal
        
        // Applying the face shades.
        edgeCol *= shade[i];
        trimCol *= shade[i];
        faceCol *= shade[i];
    
        // Add the cube quads.
        col = mix(col, edgeCol, (1.0 - smoothstep(0.0, sf, cube[i]))); // Ensure float literal
        col = mix(col, trimCol, (1.0 - smoothstep(0.0, sf, cube[i] + 1.0/56.0))); // Ensure float literal
        col = mix(col, edgeCol, (1.0 - smoothstep(0.0, sf, cube[i] + 1.0/56.0 + 1.0/28.0))); // Ensure float literal
        col = mix(col, faceCol, (1.0 - smoothstep(0.0, sf, cube[i] + 2.5/56.0 + 1.0/28.0))); // Ensure float literals
        
        
    }
    

    // Applying shadows.
    for(int i = 0; i < 3; i++){ // Ensure float literal
        col = mix(col, col*0.25, (1.0 - smoothstep(0.0, sf*6.0*res.y/450.0, shad[i] + 0.015))); // Ensure float literals
    }
    
    // A bit of false ambient occusion.
    #ifdef RANDOM_INVERT
    if(rndT > 0.0) col *= max(1.0 - length(p4.xy)*0.95, 0.0); // Ensure float literals
    else col *= max(0.25 + length(p4.xy)*0.75, 0.0); // Ensure float literals
    #else
    col *= max(1.0 - length(p4.xy)*0.95, 0.0); // Ensure float literals
    #endif
    
    #ifdef SHOW_GRID
    // A little bit redundant, but here are the hexagon border lines.
    col = mix(col, vec3(1.0), (1.0 - smoothstep(0.0, sf, abs(hexShape) - 0.005))); // Ensure float literals
    #endif
    
    // Vignette.
    //uv = fragCoord/iResolution.xy;
    //col *= pow(16.0*uv.x*uv.y*(1.0 - uv.x)*(1.0 - uv.y) , 1.0/16.0); // Ensure float literals

    // --- Post-processing: Brightness, Contrast, Saturation ---
    // Apply Brightness
    col += (BRIGHTNESS - 1.0);

    // Apply Contrast
    col = ((col - 0.5) * CONTRAST) + 0.5;

    // Apply Saturation
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(luma), col, SATURATION);

    // Rough gamma correction.
    fragColor = vec4(pow(max(col, 0.0), vec3(1.0/2.2)), 1.0); // Ensure float literals
    
}
