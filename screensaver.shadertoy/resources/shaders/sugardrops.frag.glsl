/*

    I was playing with super sphere geometry seen in recent @mrange

    shaders, they're fun and easy to get on the screen, see here

    for an example that I used as a reference:

        https://www.shadertoy.com/view/3cGXDh

        

    I was trying to avoid a spiral thing but it just happened...

*/

// Robust Tanh Conversion Method: tanh_approx function
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Offset and zoom parameters
#define OFFSET_X 90.0         // X-axis offset: 0.0 for centered, positive or negative to shift
#define OFFSET_Y 120.0         // Y-axis offset: 0.0 for centered, positive or negative to shift
#define ZOOM_SCALE 1.10       // Zoom scale: 1.0 for default, >1.0 to zoom in, <1.0 to zoom out

#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

void mainImage(out vec4 o, vec2 u) {

    // init
    float i = 0.0;
    float d = 0.0;
    float s = 0.0;
    float t = 0.0;
    vec3 p = vec3(0.0);
    
    float T = iTime*.2; // Define T based on iTime
    p = iResolution;    
    u = ((u - p.xy / 2.0) + vec2(OFFSET_X, OFFSET_Y)) / max(p.y, 1E-6) * ZOOM_SCALE; // Apply offset and zoom
    
    // clear o, 100 steps, apply and cycle color
    for(o = vec4(0.0); i++ < 1e2; o += (1.0 + cos(0.05 * T + d + vec4(3.0, 1.0, 0.0, 1.0))) / max(s, 1E-6))
        // march, i.e., p = ro + rd * d, d -= t,
        p = vec3(u * d, d - T),
        // slight @Xor style turbulence
        p += cos(0.3 * p.z + T + p.yzx * 2.0) * 0.1,
        // twist
        p.xy *= rot(p.z * 0.1),
        // rotate
        p.xy *= rot(-T * 0.2),
        // don't get hit
        p -= 1.0,
        // min of: repeat p with sin, repeat p with cos
        p = min(sin(p), cos(p)),
        // super sphere power
        p = p * p * p * p,
        // .001 + abs for translucency
        s = 0.001 + abs(
            // the pow(dot,scale)-radius is the super sphere
            pow(dot(p, p), 0.3) - 0.2),
        // accumulate distance
        d += s * 0.75;

    // tanh to tone map, divide down brightness,
    // add an off screen light to the upper-right for fun :)
    vec2 tempU = u - 1.0; // Adjust u for length calculation
    o = tanh_approx(o / 1e4 / max(length(tempU), 1E-6)); // Safeguard division
}