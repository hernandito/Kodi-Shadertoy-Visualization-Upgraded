/*

	Triangle Grid Leaf Pattern
	--------------------------
    
    Rendering repeat spiral arcs inside triangle cells to create a simple 
    leaf pattern. I like the pattern, but it wasn't really interesting enough 
    in its own right, so I applied a Mobius spiral transform to it in order 
    to give it some extra dimension.
    
    I hacked away to create this without a lot of forethought, so there'd
    be way better ways to do the same. It's a 2D example, so there's not a 
    lot of incentive to make it more efficient. Anyway, it's not that exciting, 
    but I thought I'd post it for anyone like myself who appreciates simple
    geometric patterns.
    

	
    Other leaf related examples:
    
    // Great example. IQ has some pretty sophisticated greenery 
    // related demonstrations on here, but here's one of his simpler ones.
    Clover -- IQ
    https://www.shadertoy.com/view/XsXGzn
 - 
    // Really nice.
    Autumn Leaf -- Whyatt
    https://www.shadertoy.com/view/4sfWX
    
    // A 3D leaf example.
    Elephant Ear Plants -- hsiangyun 
    https://www.shadertoy.com/view/XsVGzm

*/

// Leaf pattern. There are so many, but I've there are only two here.
// Fern : 0, Concentric: 1.
#define LEAF_TYPE 0

// Show the triangle grid that the pattern is based on...
// Probably a little redundant in this case, but it's there.
//#define SHOW_GRID

// Enable Mobius transform
#define MOBIUS

// PI and 2PI.
#define PI 3.14159265358979
#define TAU 6.283185307179

// Animation speed control
// Adjust this value to fine-tune the animation speed:
// - 1.0: Original speed
// - 0.2: 5x slower (current setting)
// - 0.1: 10x slower
// - 2.0: 2x faster
const float ANIMATION_SPEED = 0.05;

// Brightness and vibrancy control
// Adjust these values to fine-tune the display:
// - brightnessFactor: 1.0 (neutral), <1.0 (darker), >1.0 (brighter)
// - saturationFactor: 1.0 (neutral), >1.0 (more vibrant)
const float brightnessFactor = .40;
const float saturationFactor = 1.0;

// Standard 2D rotation formula.
mat2 rot2(float a) { 
    float c = cos(a), s = sin(a); 
    return mat2(c, -s, s, c); 
}

// --- OpenGL ES 1.0 Compatible Hash Function ---
float hash21_float(vec2 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yx + 33.33);
    return fract((p.x + p.y) * p.x);
}

////////
// A 2D triangle partitioning.

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s) { 
    return mat2(1.0, -s.y, -s.x, 1.0) * p; 
}

// --- OpenGL ES 1.0 Compatible Inverse Matrix ---
mat2 inverse_mat2(mat2 m) {
    float det = m[0][0] * m[1][1] - m[0][1] * m[1][0];
    det = 1.0 / (det + 1e-6);
    return mat2(m[1][1] * det, -m[0][1] * det, -m[1][0] * det, m[0][0] * det);
}

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s) { 
    return inverse_mat2(mat2(1.0, -s.y, -s.x, 1.0)) * p; 
}

// Triangle scale: Smaller numbers mean smaller triangles, oddly enough. :)
#ifdef MOBIUS
const float scale = 1.0 / 2.0;
#else
const float scale = 1.0 / 4.0;
#endif

// Rectangle scale.
const vec2 rect = (vec2(1.0 / 0.8660254, 1.0)) * scale;

float gTri;

// --- OpenGL ES 1.0 Compatible getTriVerts ---
vec4 getTriVerts(vec2 p, out vec2 vID[3], out vec2 v[3]) {
    // Skewing half way along X, and not skewing in the Y direction.
    const vec2 sk = vec2(rect.x * 0.5, 0.0) / scale;

    // Skew the XY plane coordinates.
    p = skewXY(p, sk);

    // Unique position-based ID for each cell.
    vec2 id = floor(p / rect) + 0.5;
    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
    p -= id * rect;

    // Base on the bottom (-1.) or upside down (1.).
    gTri = dot(p, 1.0 / rect) < 0.0 ? 1.0 : -1.0;

    // Putting the skewed coordinates back into unskewed form.
    p = unskewXY(p, sk);

    // Vertex IDs for each partitioned triangle.
    if (gTri < 0.0) {
        vID[0] = vec2(-1.5, 1.5);
        vID[1] = vec2(1.5, -1.5);
        vID[2] = vec2(1.5, 1.5);
    } else {
        vID[0] = vec2(1.5, -1.5);
        vID[1] = vec2(-1.5, 1.5);
        vID[2] = vec2(-1.5, -1.5);
    }

    // Triangle vertex points.
    for (int i = 0; i < 3; i++) {
        v[i] = unskewXY(vID[i] * rect / 3.0, sk);
    }

    // Centering at the zero point.
    vec2 ctr = v[2] / 3.0;
    p -= ctr;
    for (int i = 0; i < 3; i++) {
        v[i] -= ctr;
    }

    // Centered ID, taking the inflation factor of three into account.
    vec2 ctrID = vID[2] / 3.0;
    id = id * 3.0 + ctrID;
    for (int i = 0; i < 3; i++) {
        vID[i] -= ctrID;
    }

    // Triangle local coordinates (centered at the zero point) and 
    // the central position point (which acts as a unique identifier).
    return vec4(p, id);
}

// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 p, vec2 a, vec2 b) {
    p -= a;
    b -= a;
    float h = clamp(dot(p, b) / dot(b, b), 0.0, 1.0);
    return length(p - b * h);
}

// Adx's considerably more concise version of Fizzer's circle solver.
void solveCircle(vec2 a, vec2 b, out vec2 o, out float r) {
    vec2 m = a + b;
    o = dot(a, a) / dot(m, a) * m;
    r = length(o - a);
}

///////////////////////////

// Real and imaginary vectors. Handy to have.
#define R vec2(1, 0)

// Common complex arithmetic functions.
vec2 conj(vec2 a) { return vec2(a.x, -a.y); }
vec2 cmul(vec2 a, vec2 b) { return mat2(a, -a.y, a.x) * b; }
vec2 cinv(vec2 a) { return vec2(a.x, -a.y) / dot(a, a); }
vec2 cdiv(vec2 a, vec2 b) { return cmul(a, cinv(b)); }
vec2 clog(vec2 z) { return vec2(log(length(z)), atan(z.y, z.x)); }

// The Mobius function.
vec2 mobius(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d) {
    return cdiv(cmul(z, a) + b, cmul(z, c) + d);
}

//////////////////////

// The complex metaball transformation function.
vec2 transform(vec2 z, vec2 p0, vec2 p1) {
    z = mobius(z, -R, p0, -R, p1);
    z = clog(z);
    float hCW = rect.x * 2.0 / TAU;
    vec2 e = vec2(1.0, 1.0 * hCW);
    z = cmul(z, e);
    z /= 2.0;
    z.y *= 6.0 / TAU;
    // Adjusted for slower animation speed
    z -= vec2(-0.5, 0.5) * (iTime * ANIMATION_SPEED) * scale;
    return z;
}

////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Aspect correct screen coordinates.
    float res = min(iResolution.y, 800.0);
    vec2 uv = (fragCoord.xy - iResolution.xy * 0.5) / res;

    // Coordinate copy.
    vec2 oUV = uv;

    // Global scale factor.
    const float sc = 1.0;
    // Smoothing factor.
    float sf = sc / res;
    float shF = iResolution.y / 450.0;

    // Scene rotation, scaling, and translation.
    mat2 sRot = rot2(3.14159 / 9.0);
    vec2 camDir = sRot * normalize(vec2(1.732, 1.0));
    vec2 ld = sRot * normalize(vec2(1.0, -1.0));
    vec2 p = sRot * uv * sc;
    #ifndef MOBIUS
    #ifndef LOG_SPHERICAL
    p += camDir * (iTime * ANIMATION_SPEED) * scale / 4.0;
    #endif
    #endif

    // Radial coordinate factor. Used for shading.
    float r = 1.0;

    // Mobius spiral transformation.
    #ifdef MOBIUS
    // Animation, adjusted for slower speed
    float tm = (iTime * ANIMATION_SPEED) / 8.0;
    float dir = mod(tm, 2.0) < 1.0 ? -1.0 : 1.0;
    tm = dir * smoothstep(0.35, 0.65, fract(tm)) * PI + 0.2;
    // Pivot points, adjusted to be further apart
    // Adjust this vector to fine-tune the distance between nodes:
    // - vec2(0.5, 0.3): Original distance
    // - vec2(0.7, 0.4): 40% wider and 33% taller (current setting)
    // - vec2(1.0, 0.5): Even further apart
    vec2 p0 = vec2(cos(tm), sin(tm)) * vec2(1.30, 0.7);
    vec2 p1 = -p0;
    if (dir < 0.0) { vec2 tmp = p0; p0 = p1; p1 = tmp; }

    // Hacky depth shading, but it works. :)
    r = min(length(p - p0), length(p - p1));

    // Transform the screen coordinates.
    p = transform(p, p0, p1);
    #endif

    // Scaling the smoothing factor by "r".
    sf /= r;

    // Triangle IDs and vertices.
    vec2 vID[3];
    vec2 v[3];

    // Returns the local coordinates (centered on zero), cellID, the 
    // triangle vertex ID and relative coordinates.
    vec4 p4 = getTriVerts(p, vID, v);
    // Local cell coordinates
    p = p4.xy;
    // Unique triangle ID (cell position based).
    vec2 ctrID = p4.zw;

    // Reversing coordinates in alternating triangles.
    if (gTri < 0.0) {
        vec2 tmp = vID[0];
        vID[0] = vID[2];
        vID[2] = tmp;
        p.x = -p.x;
    }

    // Equilateral triangle cell side length.
    float sL = length(v[0] - v[1]);

    // Line, vertices, mid-points.
    float ln = 1e5, vert = 1e5, mid = 1e5;

    // Edge width.
    float ew = 0.025 * scale;

    // Precalculating the edge points and edge IDs.
    vec2 e[3];
    vec2 eID[3];
    int ip1;
    for (int i = 0; i < 3; i++) {
        // Manual modulo for OpenGL ES 1.0: (i + 1) % 3
        ip1 = int(floor(float(i + 1) - 3.0 * floor(float(i + 1) / 3.0)));
        eID[i] = mix(vID[i], vID[ip1], 0.5);
        e[i] = mix(v[i], v[ip1], 0.5);
    }

    for (int i = 0; i < 3; i++) {
        // Manual modulo for OpenGL ES 1.0: (i + 1) % 3
        ip1 = int(floor(float(i + 1) - 3.0 * floor(float(i + 1) / 3.0)));
        // Vertex points.
        float vI = length(p - v[i]);
        vert = min(vert, vI);
        // Triangle border lines.
        float lnI = distLine(p, v[i], v[ip1]);
        ln = min(ln, lnI);
    }

    // Line width.
    ln -= ew / 1.5;

    // Inner spiral arc pattern. thicknesses
    vec3 ln3;
    vec3 ln3B;

    for (int i = 0; i < 3; i++) {
        // Manual modulo for OpenGL ES 1.0: (i + 1) % 3
        ip1 = int(floor(float(i + 1) - 3.0 * floor(float(i + 1) / 3.0)));
        // Leaf spiral arcs. One for each side.
        vec2 o;
        float r;
        solveCircle(e[i], e[ip1], o, r);
        // Circular distance.
        vec2 q = rot2(3.14159 / 16.0 * 0.0) * e[i] * 2.0;
        float arc = length(p - q) - length(q);
        ln3[i] = arc;
        q = e[ip1] * 2.0;
        ln3B[i] = length(p - q) - length(q);
    }

    // Inner leaf line pattern.
    float lNum = 10.0 / scale;
    vec3 pat = (abs(fract(ln3B * lNum + 0.35) - 0.5) * 2.0 - 0.35) / lNum;

    #if LEAF_TYPE == 0
    pat = smoothstep(0.0, sf, pat);
    #else
    pat = smoothstep(0.0, sf, (abs(fract(ln3 * lNum - 0.5) - 0.5) * 2.0 - 0.5) / lNum);
    #endif

    // Leaf line CSG.
    ln3 = max(ln3, -ln3.yzx);

    // Initializing the scene color to black to prevent grey leakage
    vec3 col = vec3(0.0);

    for (int i = 0; i < 3; i++) {
        // Leaf color.
        float rnd = hash21_float(ctrID + eID[i] + 0.1);
        vec3 sCol = 0.5 + 0.45 * cos(6.2831853 * rnd / 8.0 + vec3(0.0, 1.0, 2.0) * 2.0 - 2.0);
        sCol *= pat[i];
        sCol *= max(-ln3[i] / scale * 4.0, 0.0) * 0.8 + 0.4;

        // Faux 3D shadowing.
        col = mix(col, col * 0.5, (1.0 - smoothstep(0.0, sf * shF * 32.0, ln3[i])));
        // Inner and outer lines.
        col = mix(col, sCol, (1.0 - smoothstep(0.0, sf, ln3[i] + ew)));
    }

    #if LEAF_TYPE == 0
    // Rendering the triangle edges as solid black
    if (1.0 - smoothstep(0.0, sf, ln) > 0.0) col = vec3(0.0);
    #endif

    // Gradient.
    col = mix(col, col.zyx, oUV.y + 0.5);

    // Extra shading about the central radial points.
    col *= r + 0.5;

    #ifdef SHOW_GRID
    // Rendering the grid lines as solid black
    if (1.0 - smoothstep(0.0, sf, ln) > 0.0) col = vec3(0.0);
    if (1.0 - smoothstep(0.0, sf, abs(ln) - 0.002) > 0.0) col = vec3(0.0);
    #endif

    // Adjust vibrancy (saturation)
    vec3 grey = vec3(dot(col, vec3(0.299, 0.587, 0.114)));
    col = mix(grey, col, saturationFactor);

    // Apply brightness
    col *= brightnessFactor;

    // Vignette.
    uv = fragCoord / iResolution.xy;
    col *= pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 1.0 / 16.0);

    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.0)), 1.0);
}