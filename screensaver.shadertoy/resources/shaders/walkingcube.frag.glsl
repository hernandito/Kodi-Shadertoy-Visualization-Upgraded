#define rot(a)    mat2(cos(a+vec4(0,11,33,0)))         // rotation

float map(vec3 q) {                                    // cube + sphere
    vec3 a = abs(q);
    return min(length(q) - 1.2, max(a.x, max(a.y, a.z)) - 1.);
}

void mainImage(out vec4 O, vec2 U) {
    float t = 9., h, T = 3. - iTime*.2;
    
    vec3 R = iResolution,
         D = normalize(vec3((U + U - R.xy) / R.y, -10.)),   // ray direction
         p = vec3(0, 0, 30), q, r, a,                     // marching point along ray
         M = iMouse.z > 0. ? (iMouse.xyz / R - .5) * vec3(1, .3, 0)  // camera
                           : vec3(-.3, 0, 0) + vec3(1, 1, 0) / 1e2 * cos(.5 * iTime + vec3(0, 11, 0));

    // Original color set to white here: O = vec4(1), faded with O -= .005
    // Changed to muted teal, scaled up to ensure fade: O = vec4(0.7, 1.0, 1.0, 1.0) * 0.5  iTime
    //  Decent Teal color:   0.812, 0.91, 0.886
    //  Rust color:   0.82, 0.718, 0.655   -   0.722, 0.612, 0.506
    for (O = vec4(0.675, 0.761, 0.651, 1.0); O.x > 0. && t > .005; O -= .005) {
        q = p,
        q.yz *= rot(.5 - 6.3 * M.y),                       // rotations
        q.xz *= rot(-6.3 * M.x),
        q.x -= 1.274 * T,                                // camera translation
        
        r = q, r.x = mod(r.x, 2.) - 1., r.y += .1,
        t = min(9., max(-map(r), q.y + 1.)),              // floor
        q.xy -= 1.4 * cos(mod(T, 1.57) + .785 + vec2(0, 11)), // cube walk
        q.x += 2. * floor(T / 1.57),
        q.y++,
        q.xy *= rot(T),                                   // rotation
        t = min(t, map(q)),                               // draw cube
        p += .2 * t * D;                                  // step forward
    }

    // Add more aggressive dithering to eliminate banding
    vec2 uv = gl_FragCoord.xy / R.xy; // Normalized pixel coordinates
    float dither = 0.0;
    int x = int(mod(gl_FragCoord.x, 2.0));
    int y = int(mod(gl_FragCoord.y, 2.0));
    if (x == 0 && y == 0) dither = 0.0 / 4.0;
    if (x == 1 && y == 0) dither = 2.0 / 4.0;
    if (x == 0 && y == 1) dither = 3.0 / 4.0;
    if (x == 1 && y == 1) dither = 1.0 / 4.0;
    dither = (dither - 0.5) * 0.03; // Scale to ±0.015 for more aggressive dither
    O.rgb += vec3(dither, dither, dither); // Apply dither to all channels
}