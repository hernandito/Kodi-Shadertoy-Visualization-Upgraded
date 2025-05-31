// Define constants for time and hue calculation
#define T (iTime/3e2)
#define H(a) (cos(radians(vec3(180., 90., 0.))+(a)*6.2832)*.5+.5)  // hue

// Custom rounding function for GLSL ES compatibility
// Handles both positive and negative numbers without relying on 'sign()'
float round_compat(float x) {
    if (x >= 0.0) {
        return floor(x + 0.5);
    } else {
        return ceil(x - 0.5);
    }
}

// Signed Distance Function (SDF) for the 3D shape
float map(vec3 u, float v)  // sdf
{
    float t = T,    // speed of animation
          l = 5.,   // loop iterations for detail/clipping reduction
          a = 9.,   // amplitude of waves
          f = 1e10, i = 0., y, z; // f: min distance, i: loop counter, y, z: intermediate variables
    
    // Convert XY coordinates to polar form (angle, radius)
    u.xy = vec2(atan(u.x, u.y), length(u.xy));  // polar transform
    // Add counter-rotation based on time and pattern scale
    u.x += t*v*3.1416*.7;  // counter rotation
    
    // Loop to create the repeating tube structure
    for (; i++<l;)
    {
        vec3 p = u; // Current point in 3D space
        // Calculate y-coordinate for the current tube layer, rounded for discrete layers
        y = round_compat((p.y-i)/l)*l+i;
        p.x *= y; // Scale x-coordinate by y for spiral effect
        p.x -= y*y*t*3.1416; // Add a time-based offset to x
        // Wrap x-coordinate around 2*PI (a full circle), rounded to nearest multiple
        p.x -= round_compat(p.x/6.2832)*6.2832;
        p.y -= y; // Offset y-coordinate
        // Calculate z-wave component based on y and time
        z = cos(y*t*6.2832)*.5+.5;  // z wave
        // Combine distance to XY plane (tubes) and Z-offset (wave)
        f = min(f, max(length(p.xy), -p.z-z*a) -.1 -z*.2 -p.z/1e2);  // tubes calculation
    }
    return f; // Return the shortest distance to the surface
}

// Main image function, similar to Shadertoy's mainImage
void mainImage( out vec4 C, vec2 U )
{
    vec2 R = iResolution.xy, j; // R: resolution, j: 2D coordinates for brightness
    vec2 m = (iMouse.xy - R/2.)/R.y; // Mouse coordinates, centered and aspect-ratio corrected
    
    // Default mouse position if mouse is not active or near origin (for non-interactive use)
    if (iMouse.z < 1. && iMouse.x+iMouse.y < 10.) m = vec2(0., .5);
    
    vec3 o = vec3(0., 0., -130.);  // Camera origin (position)
    vec3 u = normalize(vec3(U - R/2., R.y));  // Normalized 3D ray direction from camera through pixel
    vec3 c = vec3(0.); // Accumulator for final color
    vec3 p, k; // p: current raymarch point, k: color component
    
    float t = T; // Current time (scaled)
    float v = -o.z/3.;  // Pattern scale factor based on camera distance
    float i = 0., d = i; // i: raymarch step counter, d: current ray distance
    float s, f, z, r; // s: SDF result, f: multiples factor, z: z-warp factor, r: radius
    
    bool b; // Boolean to check if inside a certain radius
    
    // Raymarching loop
    for (; i++<70.;)  // Iterate up to 70 steps for raymarching
    {
        p = u*d + o; // Calculate current 3D point along the ray
        p.xy /= v;           // Scale down XY for pattern application
        r = length(p.xy);    // Calculate radius in the scaled XY plane
        z = abs(1.-r*r);     // Calculate Z-warp factor for spherizing effect
        b = r < 1.;          // Check if the point is within a unit circle in XY
        if (b) z = sqrt(z);  // Apply square root to z-warp if inside
        p.xy /= z+1.;        // Spherize the XY coordinates
        p.xy -= m;           // Apply mouse movement offset
        p.xy *= v;           // Scale XY back up
        // Add a wave along the Z-axis based on Z-position, time, and Z-warp
        p.xy -= cos(p.z/8. +t*3e2 +vec2(0., 1.5708) +z/2.)*.2;  // wave along z
        
        s = map(p, v);  // Get the signed distance from the current point to the SDF surface
        
        r = length(p.xy);                  // Recalculate radius after transformations
        // Calculate 'multiples' factor based on rounded radius and time
        f = cos(round_compat(r)*t*6.2832)*.5+.5;  // multiples
        k = H(.2 -f/3. +t +p.z/2e2);       // Calculate base color (hue)
        if (b) k = 1.-k;                   // Flip color if inside the unit circle
        
        // Accumulate color based on various factors
        c += min(exp(s/-.05), s)           // Shape shading (exponential falloff near surface)
           * (f+.01)                       // Apply pattern shading
           * min(z, 1.)                    // Darken edges based on Z-warp
           * sqrt(cos(r*6.2832)*.5+.5)     // Shade between rows based on radius
           * k*k;                          // Apply squared color (for intensity)
        
        // Break conditions for raymarching
        if (s < 1e-3 || d > 1e3) break; // If hit surface (s very small) or ray went too far
        d += s*clamp(z, .3, .9); // Advance ray distance, clamped to avoid overstepping
    }
    
    // Reflection effect using iChannel0 (assuming it's an environment map)
    // The u.xy * 0.5 + 0.5 maps the normalized ray direction's XY components to [0,1] texture coordinates.
    c += texture2D(iChannel0, u.xy * 0.5 + 0.5).rrr // Sample iChannel0 (e.g., environment map)
       * vec3(0., .4, s)*s*z*.03;  // Apply color and shading to reflection
    
    // Light tips (additional lighting effect)
    c += min(exp(-p.z-f*9.)*z*k*5., 1.);
    
    j = p.xy/v+m;  // Calculate 2D coordinates for brightness adjustment
    c /= clamp(dot(j, j)*4., .04, 4.);  // Adjust brightness based on distance from center
    
    // Final color output, applying gamma correction
    C = vec4(exp(log(c)/2.2), 1.);
}
