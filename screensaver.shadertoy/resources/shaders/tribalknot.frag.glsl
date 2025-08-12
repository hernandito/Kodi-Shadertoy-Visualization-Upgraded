precision mediump float; // Set default precision for floats

/* Creative Commons Licence Attribution-NonCommercial-ShareAlike
    phreax 2021
*/

// --- GLOBAL DEFINES ---
#define PI 3.141592
#define SIN(x) (sin(x)*.5+.5)
#define PHI 1.618033988749895

// GDF Vectors for Icosahedron
#define GDFVector3 normalize(vec3(1.0, 1.0, 1.0 ))
#define GDFVector4 normalize(vec3(-1.0, 1.0, 1.0))
#define GDFVector5 normalize(vec3(1.0, -1.0, 1.0))
#define GDFVector6 normalize(vec3(1.0, 1.0, -1.0))

#define GDFVector7 normalize(vec3(0.0, 1.0, PHI+1.0))
#define GDFVector8 normalize(vec3(0.0, -1.0, PHI+1.0))
#define GDFVector9 normalize(vec3(PHI+1.0, 0.0, 1.0))
#define GDFVector10 normalize(vec3(-PHI-1.0, 0.0, 1.0))
#define GDFVector11 normalize(vec3(1.0, PHI+1.0, 0.0))
#define GDFVector12 normalize(vec3(-1.0, PHI+1.0, 0.0))

#define GDFVector13 normalize(vec3(0.0, PHI, 1.0))
#define GDFVector14 normalize(vec3(0.0, -PHI, 1.0))
#define GDFVector15 normalize(vec3(1.0, 0.0, PHI))
#define GDFVector16 normalize(vec3(-1.0, 0.0, PHI))
#define GDFVector17 normalize(vec3(PHI, 1.0, 0.0))
#define GDFVector18 normalize(vec3(-PHI, 1.0, 0.0))

#define fGDFBegin float d_icosa = 0.0; // Renamed d to d_icosa to avoid conflict
#define fGDF(v) d_icosa = max(d_icosa, abs(dot(p, v)));
#define fGDFEnd return d_icosa - r;

// --- POST-PROCESSING DEFINES (BCS) ---
#define BRIGHTNESS 0.750    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.10      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.00    // Saturation adjustment (1.0 = neutral)

// --- ANIMATION PARAMETERS ---
#define ANIMATION_SPEED 0.350 // Global animation speed multiplier (1.0 = normal speed)

// --- COLOR PARAMETERS ---
#define GEOMETRY_BASE_COLOR vec3(0.6, 0.6, 0.600)     // Base color of the main geometry (torus knot)
#define ICOSAHEDRON_COLOR vec3(2.000, 1.2, 0.0)         // Color of the icosahedron
#define PLANE_COLOR vec3(0.616, 0.741, 0.769)         // Color of the plane (mat == 2.0)
#define GLOW_COLOR vec3(1.5000, 0.9, 0.0)              // Color of the glow effect

// --- END GLOBAL DEFINES ---

float tt = 0.0; // Explicitly initialized
float g_mat = 0.0; // Explicitly initialized
float g_gl = 0.0; // Explicitly initialized


float icosahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDF(GDFVector7) fGDF(GDFVector8) fGDF(GDFVector9) fGDF(GDFVector10)
    fGDF(GDFVector11) fGDF(GDFVector12)
    fGDF(GDFVector13) fGDF(GDFVector14) fGDF(GDFVector15) fGDF(GDFVector16) // Added missing GDFVectors
    fGDF(GDFVector17) fGDF(GDFVector18) // Added missing GDFVectors
    fGDFEnd
}

mat2 rot2(float a) { return mat2(cos(a), sin(a), -sin(a), cos(a)); }


// by Nusan
float curve(float t, float d_curve) { // Renamed d to d_curve to avoid conflict
  t /= max(d_curve, 1e-6); // Robust division
  return mix(floor(t), floor(t)+1.0, pow(smoothstep(0.0, 1.0, fract(t)), 10.0)); // Explicitly 1.0f, 0.0f, 1.0f, 10.0f
}

float box(vec3 p, vec3 r) {
    vec3 d_box = abs(p) - r; // Renamed d to d_box
    return min(max(d_box.x, max(d_box.y, d_box.z)), 0.0) + length(max(d_box, 0.0)); // Explicitly 0.0f
}

float rect( vec2 p, vec2 b, float r ) {
    vec2 d_rect = abs(p) - (b - r); // Renamed d to d_rect
    return length(max(d_rect, 0.0)) + min(max(d_rect.x, d_rect.y), 0.0) - r; // Explicitly 0.0f
}

vec3 transform(vec3 p) {

    float a = PI * 0.5 + iTime * ANIMATION_SPEED * 0.3; // Explicitly 0.5f, apply animation speed and user's multiplier
    p.xz *= rot2(a);
    p.xy *= rot2(a);
    
    return p;
}


float map(vec3 p) {

    vec3 bp = p; // Explicitly initialized
    
    // rotate
    float b = PI * 0.5; // Explicitly 0.5f
    p.xz *= rot2(b);
    p.xy *= rot2(b);

    // torus
    float r1 = mix(1.0, 2.0, SIN(tt)); // Explicitly 1.0f, 2.0f
    
    vec2 cp = vec2(length(p.xz) - r1, p.y); // Explicitly initialized
    
    float rev = 2.5; // Explicitly 2.5f
    
    // torus knots by BigWings
    float a = atan(p.z, p.x); // Explicitly initialized
    
    cp.x -= 0.5; // Explicitly 0.5f
    
    cp *= rot2(rev*a);
    cp = abs(cp) - 0.2; // Explicitly 0.2f

    cp = abs(cp) - mix(0.2, 0.4, SIN(tt)); // Explicitly 0.2f, 0.4f
    cp *= rot2(-rev*a-tt);
    
    cp = abs(cp) - 0.33*SIN(-tt*0.25); // Explicitly 0.33f, 0.25f
    
    float kn = rect(cp, vec2(mix(0.07, 0.12, SIN(0.5*tt))), 0.02); // Explicitly 0.07f, 0.12f, 0.5f, 0.02f
    
    float pl = box(bp-vec3(0.0, 0.0, 1.0), vec3(10.0, 10.0, 0.1)); // Explicitly 0.0f, 0.0f, 1.0f, 10.0f, 10.0f, 0.1f

    g_gl += 0.018 / max((0.1 + pow(abs(kn), 8.0)), 1e-6); // Robust division, Explicitly 0.018f, 0.1f, 8.0f // glow
    
    p = transform(p);
    
    float ic = icosahedron(p, 0.33); // Explicitly 0.33f
    
    g_mat = kn < ic ? 0.0 : 1.0; // Explicitly 0.0f, 1.0f
    
    float d_map = min(ic, kn); // Renamed d to d_map
    
    g_mat = d_map < pl ? g_mat : 2.0; // Explicitly 2.0f
    
    d_map = min (d_map, pl);
    return 0.8*d_map; // Explicitly 0.8f
}

// from iq
float softshadow( in vec3 ro_in, in vec3 rd_in, float mint, float maxt, float k ) // Renamed ro, rd to avoid conflict
{
    float res = 1.0; // Explicitly initialized
    float ph = 1e20; // Explicitly initialized
    for( float t=mint; t<maxt; ) // Explicitly initialized t
    {
        float h = map(ro_in + rd_in*t); // Explicitly initialized h
        if( h < 0.001 ) // Explicitly 0.001f
            return 0.0; // Explicitly 0.0f
        float y = h*h / max((2.0*ph), 1e-6); // Robust division, Explicitly 2.0f
        float d_shadow = sqrt(h*h-y*y); // Renamed d to d_shadow, Explicitly initialized
        res = min( res, k*d_shadow / max(0.0,t-y) ); // Robust division, Explicitly 0.0f
        ph = h;
        t += h;
    }
    return res;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / max(iResolution.y, 1e-6); // Robust division, Explicitly 0.5f

    
    vec3 ro = vec3(0.0, 0.0, -5.0); // Explicitly 0.0f, 0.0f, -5.0f
    vec3 rd = normalize(vec3(uv, 0.7)); // Explicitly 0.7f
    vec3 lp = vec3(-1.0, 4.0, -10.0); // Explicitly -1.0f, 4.0f, -10.0f
    
    vec3 p = ro; // Explicitly initialized
    vec3 col = vec3(0.0); // Explicitly initialized
    
    float t = 0.0; // Explicitly initialized
    float d = 0.1; // Explicitly initialized
    
    tt = (iTime * ANIMATION_SPEED + 7.4) * 0.5; // Explicitly 7.4f, 0.5f, apply animation speed
    tt = tt + 2.0 * curve(tt, 2.0); // Explicitly 2.0f, 2.0f
    
    float mat = 0.0; // Explicitly initialized
    float current_glow = 0.0; // Renamed gl to current_glow to avoid conflict with global g_gl
    
    for(float i=0.0; i<200.0; i++) { // Explicitly 0.0f, 200.0f
    
        d = map(p);
        mat = g_mat;
        current_glow = g_gl; // Assign local copy from global accumulator
        
        if(d < 0.0001 || t > 100.0) break; // Explicitly 0.0001f, 100.0f
        
        t += d;
        p += rd*d;
    }
    vec2 e = vec2(0.0035, -0.0035); // Explicitly initialized
    
    vec3 current_geometry_color; // Declare a variable to hold the chosen geometry color

    if(d < 0.001) { // Explicitly 0.001f
        vec3 n_normal = normalize( max(vec3(1e-6), e.xyy*map(p+e.xyy) + e.yyx*map(p+e.yyx) + // Robust normalize
                                 e.yxy*map(p+e.yxy) + e.xxx*map(p+e.xxx)) ); // Renamed n to n_normal
        
        
        vec3 l = normalize(lp-p); // Explicitly initialized
        float dif = max(dot(n_normal, l), 0.0); // Explicitly 0.0f
        float spe = pow(max(dot(reflect(-rd, n_normal), -l), 0.0),40.0); // Explicitly 0.0f, 40.0f
        
        float sss = smoothstep(0.0, 1.0, map(p + l * 0.4)) / max(0.4, 1e-6); // Robust division, Explicitly 0.0f, 1.0f, 0.4f
        float shd = softshadow(p, l, 0.01, 2.0, 15.0); // Explicitly 0.01f, 2.0f, 15.0f

        if(mat == 0.0) { // Torus knot
            current_geometry_color = GEOMETRY_BASE_COLOR;
        } else if (mat == 1.0) { // Icosahedron
            current_geometry_color = ICOSAHEDRON_COLOR;
        } else { // Plane (mat == 2.0)
            current_geometry_color = PLANE_COLOR;
        }
        
        col += current_geometry_color * mix(1.0, dif, 0.8) + 0.2*spe + 0.2*current_geometry_color*sss; // Explicitly 1.0f, 0.8f, 0.2f
        col *= mix(0.8, 1.0, shd); // Explicitly 0.8f, 1.0f
    
    }

    
    if(mat != 1.0) { // Explicitly 1.0f
      col += (0.1-0.18*pow(dot(uv, uv), 0.2))*current_glow*GLOW_COLOR; // Explicitly 0.1f, 0.18f, 0.2f, use GLOW_COLOR
      col += (0.08-0.22*pow(dot(uv, uv), 0.57))*current_glow*GLOW_COLOR; // Explicitly 0.08f, 0.22f, 0.57f, use GLOW_COLOR
    }
    col *= mix(0.1, 0.9, (1.5-pow(dot(uv, uv), 0.8))); // Explicitly 0.1f, 0.9f, 1.5f, 0.8f
    col = pow(col, vec3(0.6)); // Explicitly 0.6f
    
    // --- Apply BCS adjustments ---
    vec3 finalColor = col;
    // Brightness
    finalColor += (BRIGHTNESS - 1.0);

    // Contrast
    finalColor = (finalColor - 0.5) * CONTRAST + 0.5;

    // Saturation
    float luminance = dot(finalColor, vec3(0.2126, 0.7152, 0.0722)); // Standard Rec. 709 luminance
    vec3 grayscale = vec3(luminance);
    finalColor = mix(grayscale, finalColor, SATURATION);

    finalColor = clamp(finalColor, 0.0, 1.0); // Clamp final color to [0, 1] range

    // Output to screen
    fragColor = vec4(finalColor, 1.0 - t * 0.3); // Explicitly 1.0f, 0.3f
}
