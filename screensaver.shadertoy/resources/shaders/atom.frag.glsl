
#define MAX_MARCH_STEPS 50
#define MAX_MARCH_DIST 10.0
#define MIN_MARCH_DIST 0.01

#define PI 3.14159265359

// --- Main geometry color (rings) ---
#define COLOR vec3(0.9, 0.3, 0.0)
#define COLOR2 vec3(0.01, 0.01, 0.01) // Background color (and dimming factor for a light)

// --- Nucleus parameters ---
#define NUCLEUS_RADIUS 1.0 // Radius of the central sphere (nucleus)
#define NUCLEUS_SPHERE_COLOR vec3(0.91, 0.9, 0.9) // Change these RGB values for the sphere

// --- Robustness for divisions ---
const float EPSILON = 1e-6; 

vec3 rayDir(vec3 ro, vec3 origin, vec2 uv) {
    vec3 d = normalize(origin - ro);
    vec3 r = normalize(cross(vec3(0.,1.,0.), d));
    vec3 u = cross(d, r);
    return normalize(d + r*uv.x + u*uv.y);
}

mat2 rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

// https://www.shadertoy.com/view/4lsXDN
// The MIT License
// Copyright © 2015 Inigo Quilez
float sdEllipse( vec2 p, vec2 ab )
{
    p = abs( p );
    vec2 q = ab*(p-ab);
    float w = (q.x<q.y)? 1.570796327 : 0.0;
    for( int i=0; i<5; i++ )
    {
        vec2 cs = vec2(cos(w),sin(w));
        vec2 u = ab*vec2( cs.x,cs.y);
        vec2 v = ab*vec2(-cs.y,cs.x);
        // Added robustness for division by zero or very small values
        w = w + dot(p-u,v)/max((dot(p-u,u)+dot(v,v)), EPSILON); 
    }
    float d = length(p-ab*vec2(cos(w),sin(w)));
    return (dot(p/ab,p/ab)>1.0) ? d : -d;
}

float sdEllipseRing( vec3 p, float R1, float R2, float r )
{
    vec2 q = vec2(sdEllipse(p.xz,vec2(R1,R2)),p.y);
    return length(q)-r;
}

// New SDF for a sphere
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float opSmoothUnion( float d1, float d2, float k )
{
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}

// sdScene now returns vec4(color, distance)
vec4 sdScene(vec3 p_world) { 
    
    // Calculate nucleus distance using the untransformed world position
    float d_nucleus = sdSphere(p_world, NUCLEUS_RADIUS);

    // Calculate rings distance using the original progressive transformations
    vec3 p_rings = p_world; // Create a mutable copy for ring transformations
    p_rings.xy *= rot(iTime * 0.2);
    p_rings.yz *= rot(PI/2.);
    float d_rings_combined = sdEllipseRing(p_rings, 1.5, 4., 0.12); // Renamed for clarity

    mat2 r = rot(PI/3.);

    p_rings.xz *= r;
    d_rings_combined = opSmoothUnion(d_rings_combined,sdEllipseRing(p_rings, 1.5, 4., 0.16),0.05);

    p_rings.xz *= r;
    d_rings_combined = opSmoothUnion(d_rings_combined,sdEllipseRing(p_rings, 1.5, 4., 0.16),0.05);

    // Combine the rings and the nucleus
    float final_d = opSmoothUnion(d_rings_combined, d_nucleus, 0.05);

    // *** THIS IS THE KEY CHANGE FOR PER-OBJECT COLORING ***
    vec3 final_color = vec3(0.0);
    if (d_nucleus < d_rings_combined) {
        final_color = NUCLEUS_SPHERE_COLOR; // Use the specific sphere color
    } else {
        final_color = COLOR; // Use the main rings color
    }
    
    return vec4(final_color, final_d);
}


vec4 rayMarch(vec3 ro, vec3 rd) {
    vec4 res = vec4(-1.); // color = xyz, distance = w
    float t = 0.001f;

    for (int i = 0; i < MAX_MARCH_STEPS; ++i) {
        vec4 ds = sdScene(ro + rd*t); // ds.xyz now contains the actual object color
        if(ds.w < MIN_MARCH_DIST) {
            res = vec4(ds.xyz, t);
            break;
        }

        if (ds.w > MAX_MARCH_DIST) {
            res = vec4(0.0, 0.0, 0.0, -1);
            break;
        }
        t += ds.w;
    }
    return res;
}


// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal(vec3 p) // for function f(p)
{
    const float h = 0.0001; 
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*sdScene( p + k.xyy*h ).w +
                      k.yyx*sdScene( p + k.yyx*h ).w +
                      k.yxy*sdScene( p + k.yxy*h ).w +
                      k.xxx*sdScene( p + k.xxx*h ).w );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Added robustness for division by zero or very small values
    vec2 uv = (2.*fragCoord - iResolution.xy)/max(iResolution.y, EPSILON);

    vec3 origin = vec3(0.);

    vec3 ro = vec3(0., 0., -7.);
    vec3 rd = rayDir(ro, origin, uv);

    vec4 obj = rayMarch(ro, rd); // obj.xyz now contains the color set in sdScene


    vec3 col = vec3(0.0); // Initialize col
    if (obj.w > 0.) { // If an object was hit
        vec3 p = ro + rd*obj.w;
        vec3 n = calcNormal(p);

        float R0 = pow((1. - 0.46094)/(1. + 0.46094),2.);

        // --- Apply lighting to the object's base color (obj.xyz) ---
        // The coefficients here are crucial for brightness and were adjusted previously.
        // We use obj.xyz directly, which now holds the specific color of the hit object (ring or sphere).
        
        // Light 1
        {
            float dif = -n.y*.5 + .5;
            float spe = -reflect(rd, n).y;

            spe = smoothstep(0.3,0.9, spe);
            spe *= R0 + (1. - R0)*pow(1. - dot(rd, n), 5.) * 0.3;

            col += obj.xyz * dif * 0.01;
            col += obj.xyz * spe * dif * 0.1;
        }

        // Light 2 (This light was the main source of previous over-brightness)
        {
            float dif = n.y*.5 + .5;
            float spe = reflect(rd, n).y;

            spe = smoothstep(0.3,0.9, spe);
            spe *= R0 + (1. - R0)*pow(1. - dot(rd, n), 5.) * 10.;
            
            // This factor compensates for COLOR2's original dimness when it was multiplied here.
            // Now obj.xyz is a bright color, so we need to dim this light source accordingly.
            float light2_dim_factor = 0.01; 
            col += obj.xyz * dif * light2_dim_factor;
            col += obj.xyz * spe * dif * 0.8 * light2_dim_factor;
        }

        // Light 3
        {
            vec3 ld = normalize(vec3(1.0, 1.0, .0));
            float dif = max(0., dot(n, ld));

            vec3 hlf = normalize(-rd + ld);
            float spe = pow(max(0., dot(n, hlf)), 16.);
            spe *= R0 + (1. - R0)*pow(1. - dot(rd, n), 5.);

            col += dif * obj.xyz * 0.5;
            col += spe * obj.xyz * dif * 0.5;
        }

    } else {
        // background
        // Added robustness for division by zero or very small values
        col = COLOR2 * min(fragCoord.y/max(iResolution.y, EPSILON) + .15, 1.); 
    }

    // Gamma correct ^(1/2.2)
    col = pow(col, vec3(.4545));

    col = clamp(col, 0., 1.);
    col = smoothstep(0., 1., col);

    fragColor = vec4(col,1.0);
}