/*
        -1 chars from @FabriceNeyret2
        
        Thanks!  :D
*/

// Robust Tanh Approximation
vec4 tanh_approx(vec4 x) { const float EPSILON = 1e-6; return x / (1.0 + max(abs(x), EPSILON)); }

void mainImage(out vec4 o, vec2 u) {
    float i = 0.0, // iterator
          d = 0.0, // total distance
          s = 0.0, // signed distance
          n = 0.0; // noise iterator
    // p is temporarily resolution, then raymarch position
    vec3 p = vec3(0.0);
    // Set t to iTime outside the loop for animation
    float t = iTime;
    
    // scale coords
    u = (u-iResolution.xy/2.0)/iResolution.y;
    
    // clear o, up to 100, accumulate distance, grayscale color
    for(o=vec4(0.0); i++<1e2; d += s = 0.01+abs(s)*0.8, o += 1.0/s)
        // march, equivalent to p = ro + rd * d, p.z += d+t+t
        for (p = vec3(u * d, d+t+t),
             // twist by p.z, equivalent to p.xy *= rot(p.z*.2)
             p.xy *= mat2(cos(p.z*0.2+vec4(0,33,11,0))),
             // dist to our spiral'ish thing that will be distorted by noise
             s = sin(p.y+p.x),
             // start noise at 1, until 32, grow by n+=n
             n = 1.0; n < 32.0; n += n )
                 // subtract noise from s, pass .3*t+ through sin for some movement
                 s -= abs(dot(cos(0.3*t+p*n), vec3(0.3))) / n;
    // divide down brightness and make a light in the center
    o = tanh_approx(o/max(2e4*max(length(u), 1e-6), 1e-6));
}