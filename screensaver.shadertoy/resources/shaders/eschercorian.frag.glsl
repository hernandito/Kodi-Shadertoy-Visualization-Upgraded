// 3D version of https://www.shadertoy.com/view/WfXyWN
// variant of https://shadertoy.com/view/WfByDG

#define rot(a)  mat2(cos(a+vec4(0,11,33,0)))         // rotation

// Sub-Surface Scattering (SSS), Geometry Color, and AO parameters
#define SSS_AMOUNT 4.15
#define GEOMETRY_COLOR vec3(1.6, 1.4, 1.2)
#define AO_STRENGTH 0.7
#define AO_SPREAD 0.25

float S(vec3 q, vec3 C ) {                       // shape-in-cell SDF
    q -= C;
    float h = mod(floor(C.y-C.x),3.);
    q = h > 1. ? q.yzx : h > .0 ? q.zxy : q;     //  tile rotation

    q *= 2.0;
    vec3  a = abs(q);
    return max( min( abs(q.x+0.75)-0.25,         // thick face
                      fract( min(q.y,q.z) +0.5 ) -0.5      // bars
                    ),
                  max( a.x, max(a.y,a.z) ) - 1.0       // trucated to the cell cube
                ) / 2.0;
}

float map(vec3 q) {
    float s = 1.0 / sqrt(3.0),
          d = dot(q,vec3(s));                     // distance to plane
    
    // Replaced round() with floor(x + 0.5) for compatibility with OpenGL ES 1.0
    vec3  C = floor( q - d*s + 0.5 );            // sphere center

    s = C.x+C.y+C.z;
    return s==0.0 ?      S(q , C)                 // center on the cell pseudo-plane
                   :  min( S(q , C-vec3(s,0,0)),
                      min( S(q , C-vec3(0,s,0)),
                           S(q , C-vec3(0,0,s)) ));     // find the one in the neighborhood
}

// Simple Ambient Occlusion function
float ao(vec3 p, vec3 n) {
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = AO_SPREAD * float(i) / 5.0;
        occ += (h - map(p + n * h)) * sca;
        sca *= 0.5;
    }
    return clamp(1.0 - AO_STRENGTH * occ, 0.0, 1.0);
}

void mainImage(out vec4 O, vec2 U)
{
    float t = 9.0;
    
    vec3  R = iResolution;
    vec3  D = normalize(vec3((U+U-R.xy)/R.y, -5.0 ));    // ray direction
    vec3  p = vec3(0.0, 0.0, 15.0);
    vec3  q = vec3(0.0);
    vec3  a = vec3(0.0);
    vec3  M = iMouse.z > 0.0 ? iMouse.xyz/R - 0.5: 0.05 * cos(0.1*iTime+vec3(0.0,11.0,0.0)) - vec3(0.1,0.05,0.0);
    
    for ( O = vec4(1); O.x > 0.0 && t > 0.005; O -= 0.005 ) {
        q = p;
        q.xz *= rot(-6.3 * M.x);
        q.yz *= rot(0.5 - 6.3 * M.y);                      // rotations
        t = map(q);
        p += 0.5 * t * D;                                  // step forward = dist to obj
    }

    // Apply SSS after raymarching
    float sss_value = 1.0 - smoothstep(0.0, SSS_AMOUNT, t);
    vec3 final_color = mix(vec3(0.0), vec3(1.0), sss_value);
    
    O.rgb *= final_color;
    O -= t * 3.0;                                     // antibanding. thanks, hnh !
    
    // Calculate and apply AO
    vec3 normal = normalize(vec3(map(q + vec3(0.01, 0.0, 0.0)) - t,
                                 map(q + vec3(0.0, 0.01, 0.0)) - t,
                                 map(q + vec3(0.0, 0.0, 0.01)) - t));
    
    float ambient_occlusion = ao(q, normal);
    O.rgb *= ambient_occlusion;
    
    O *= O*O*O*O * vec4(GEOMETRY_COLOR, 1.0);                                // color scheme, adjusted for new param
}