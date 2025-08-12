precision mediump float; // Required for GLSL ES 1.0

// Helper for rotation matrix
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

// Helper function to replace array access for 'f'
// GLSL ES 1.0 does not support array constructors or non-constant indexing,  iTime
// so we use a series of if/else if statements.
// This function must be defined at global scope, outside mainImage.
vec3 get_f_val(int index) {
    if (index == 0) return vec3(1.0,0.0,0.0); // Z.zxx
    else if (index == 1) return vec3(0.0,0.0,1.0); // Z
    else if (index == 2) return vec3(0.0,-1.0,0.0); // -Z.xzx
    else if (index == 3) return vec3(0.0,0.0,-1.0); // -Z
    else if (index == 4) return vec3(1.0,0.0,0.0); // Z.zxx
    else if (index == 5) return vec3(0.0,0.0,1.0); // Z
    else if (index == 6) return vec3(0.0,1.0,0.0); // Z.xzx
    else if (index == 7) return vec3(0.0,0.0,-1.0); // -Z
    else if (index == 8) return vec3(0.0,1.0,0.0); // Z.xzx
    return vec3(0.0); // Fallback, should not be reached with valid indices
}

// Main image function (entry point for shaders)
void mainImage(out vec4 O, vec2 U)
{   
    // Initialize output color to black for the background
    O = vec4(0.0, 0.0, 0.0, 1.0); // Explicitly black background

    // Get resolution and normalize UV coordinates
    vec2 R = iResolution.xy;
    vec2 u = ( U+U - R ) / R.y;

    // Discard fragments outside the unit circle (circular vignette)
    if( dot(u,u) > 1.0 ) {
        discard; 
    }
    
    // Define a constant vector Z (used for basis vectors)
    #define Z vec3(0.0,0.0,1.0)   

    // --- Highlight Power Control ---
    // Increased for crisper highlights. Adjust higher for sharper, lower for more diffuse.
    #define HIGHLIGHT_POWER 100.0 

    // --- Transparency/Translucency Control ---
    // Adjust this value to control the transparency/light absorption.
    // Higher values (e.g., 1.2, 1.5) increase transparency.
    // Lower values (e.g., 0.8, 0.5) decrease transparency (more opaque).
    #define TRANSPARENCY_FACTOR 1.90 
    
    // Initialize ray origin 'o' and ray direction 'r'
    vec3 o = -8.0 * Z;
    vec3 r = normalize(vec3(u, 2.0));
    
    // Declare other variables used in the loop
    vec3 x, y, z, w, c, p;
             
    // Initialize raymarch distance 'd', total distance 'h', and time 't'
    float d = 0.0; 
    float h = 0.0; 
    float t = iTime * 0.1; // Animation time factor
    float L; // Length variable
    
    int N = 3; // Constant value for N
    int j = 0; // Loop counter for raymarching
    int i, k, e, s; // Loop counters and intermediate variables

    // Main raymarching loop
    for( ; j < 256 && h < 20.0 ; j++ ) // Increased iterations and max distance for robustness
    {
        p = o + r * h; // Current point along the ray
        c = vec3(-1.0, 2.0, -3.0); // Color/lighting vector
        
        // Apply rotations - expanded from original M(x) macro logic
        p.xy *= rot(t + vec4(0.0, 11.0, 33.0, 0.0).x);
        c.xy *= rot(t + vec4(0.0, 11.0, 33.0, 0.0).x);
        
        p.xz *= rot(t + vec4(0.0, 11.0, 33.0, 0.0).y);
        c.xz *= rot(t + vec4(0.0, 11.0, 33.0, 0.0).y);
        
        p.yz *= rot(t + vec4(0.0, 11.0, 33.0, 0.0).z);
        c.yz *= rot(t + vec4(0.0, 11.0, 33.0, 0.0).z);

        // Inner loop for fractal folding
        for(k=1,i=0,s=0 ; i < N; i++ )
        {                       
            w = sign(p); 
            w.y *= w.x; 
            w.z *= -w.y;
            
            e = int( dot( vec3(4.0, 2.0, 1.0) , w * 0.5 + 0.5) );             
            
            s = s * 8 + (k < 0 ? 7 - e : e);            
                                        
            x = get_f_val(e); 
            y = get_f_val(e + 1);
            z = cross(x, y);     
            
            if( p.z < 0.0 && e > 0 ) z = -z;     
            if( e < 2 || e == 3 || e == 5 ) { 
                vec3 w_temp = -x;
                x = -y; 
                y = w_temp; 
                k = -k; 
            }
            mat3 m = mat3(x, y, z);                   
            p += p - 2.0 * sign(p);    
            p *= m; 
            c *= m;
        }
        
        if( s > 0 && s < int(pow(2.0, float(N * 3)) - 1.0) )
        {
            if( -p.x < p.y ) {
                p = -p.yxz; 
                c = -c.yxz;
            }
        }
        
        p.x = max(0.0, abs(p.x + 1.0) - 1.0);
        L = length(p);      
        
        d = (L - 1.0) / pow(2.0, float(N + 1));

        if( d < 0.02 )
        {
            d = 0.5 + dot(p / L, c) / 7.5;
            // Reintroduced the power term for highlights, now controlled by HIGHLIGHT_POWER
            O =  ( 0.8 - 0.1 * d + pow(d, HIGHLIGHT_POWER) ) 
                * exp(-0.4 * TRANSPARENCY_FACTOR * (h + o.z + 2.0)) // Applied TRANSPARENCY_FACTOR here
                * vec4(1, 0.902, 0.643, 1.0); // This is the pinkish color
            break;
        }               
        h += d;
    }
}
