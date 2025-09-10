// Added `tanh_approx` function for OpenGL ES 1.0 compatibility.
// This is a robust approximation of the hyperbolic tangent function.
// Modified to work with vec4 inputs to fix the compile error.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

#define PI 3.1415
#define SIZE 0.3

mat2 scale(vec2 _scale){
    return mat2(_scale.x,0.0,
                0.0,_scale.y);
}

void mainImage(out vec4 o, vec2 fragCoord) {
    float t = iTime*.05;
    vec2 u = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
    u += vec2(sin(t) / 2., cos (t * 2.0) /4.);
    u = scale(vec2(sin(t * 0.5) + 1.3)) * u;

    
    o = vec4(0.0);
    float d = 0.0;
    

    // Raymarch!
    for (int i = 0; i <70; i++) {
        vec3 p = vec3(u * vec2(1.2, 1.2) * d,  pow(d, 0.78) + 2.*t);

        // Spiral twist - rotate around Z axis
        float angle = p.z * 0.1 + t / 10.;
        angle = t / 10. + d / 20.;
        float ca = cos(angle);
        float sa = sin(angle);

        mat2 rot = mat2(ca, -sa, sa, ca);

        p.xy += vec2(0.7 + sin(t)*2., 0.3 + cos(t) * 4.);
        p.xy = rot * p.xy;
        p.xy += vec2(0.6+ sin(t)*2., 0.3  + cos(t) * 2.);
        // starting 'signed distance'
        float s = 0.16;

        // Add distraction
        float n = 1.0;
        while (n < 4.0) {
            vec3 noiseInput = vec3(1.7, 1.7, 1.1 * pow(n, 1.6)) * p;
            float noise = abs(dot(cos(noiseInput), vec3(0.3, 0.3, 0.3))) / n;
            s -= (0.99)*noise;
            n += 0.8*n;
          
        }

        // Distance and color accumulation over Z axis (ray marching loop)
        float eps = 0.01 + abs(s) * 0.6;
        d += eps;
        o += vec4(1.4 / eps);
    }
    // Replaced tanh() with tanh_approx() and added robustness to the division.
    o = tanh_approx(o / max((10000. * length(u)), 1E-6));
    o.z = 1.5 * (o.x  * 0.3 + o.y * 0.9);

}
