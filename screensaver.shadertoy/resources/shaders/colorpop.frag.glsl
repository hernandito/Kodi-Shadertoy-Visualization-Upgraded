/*
    -6 chars from @FabriceNeyret2 (485 to 479)
    
    Thanks!!    :D
    
*/

// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 1.05
#define CONTRAST   1.350
#define SATURATION 0.9

vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    // Brightness
    color += brightness - 1.0;
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    // Saturation
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

#define P(z) vec3( cos( vec2(.15,.2)*(z) ) *5. , z )
#define R(a) mat2( cos( a +vec4(0,33,11,0)))

void mainImage(out vec4 o, vec2 u) {
    // Explicitly initialize variables
    float i = 0.0;
    float d = 0.0;
    float s = 0.0;
    float n = 0.0;
    float t = iTime * 0.3;
    
    vec3  res = iResolution;
    vec3  p = P(t);
    vec3  Z = normalize(P(t + 1.0) - p);
    vec3  X = normalize(vec3(Z.z, 0.0, -Z.x));
    vec3  D = vec3( R( tanh_approx(vec4(2.0*sin(p.z*0.1))).x ) * (u - res.xy / 2.0) / res.y, 1.0)
            * mat3(-X, cross(X, Z), Z);
    
    // Initialize output color
    o = vec4(0.0);

    for( o*=i ; i++ < 100.0 ; ) {
        p += D * s;
        s  = tanh_approx(vec4(length((p - P(p.z)).xy))).x;
        for( n = 0.3; n < 16.0;
             s -= abs( dot( sin( 0.05 * t + p * n ) , p - p + 0.2 ) ) / n,
             n += n
           );
        d += s = 0.001 + 0.8 * abs(s);
        o += ( 1.0 + cos(0.3 * p.z + vec4(5.0, 3.0, 1.0, 0.0)) ) / max(s, 1e-6);
    }
    
    // Apply tone mapping
    o = tanh_approx(o / 20000.0);
    
    // Apply BCS post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}










/* Original:

// just cruising through some colorful noise 😎

#define P(z) vec3(cos(vec2(.15,.2)*(z))*5.,z)  
#define R(a) mat2(cos(a+vec4(0,33,11,0)))
void mainImage(out vec4 o, vec2 u) {
    float i,d,s,n,t=iTime*2.;
    vec3  q = iResolution,
          p = P(t),
          Z = normalize( P(t+1.)- p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(R(tanh(sin(p.z*.1)*2.)*1.)*(u-q.xy/2.)/q.y, 1)  * mat3(-X, cross(X, Z), Z);
    for(o*=i; i++<1e2;) {
        p += D * s;
        s  = tanh(-length((p-P(p.z)).xy));
        for (n = .3; n < 16.;
            s += abs(dot(sin(.05*t+p * n), p-p+.2)) / n,
            n *= 2.);
        d += s = .001 + .8 * abs(s);
        o += (1.+cos(.3*p.z+vec4(5,3,1,0)))/s;
    }
    o = tanh(o / 2e4);
}
*/