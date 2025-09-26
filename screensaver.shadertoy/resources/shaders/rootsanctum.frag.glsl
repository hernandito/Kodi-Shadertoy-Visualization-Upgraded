// Robust Tanh Conversion Method
// This is a custom approximation for the tanh function, which is not
// supported in OpenGL ES 1.0. It's safe and prevents artifacts.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

#define T (iTime*.15)
#define P(z) (vec3((cos((z) * .2) * .3) * 10., \
                   (cos((z) * .15) * .3) * 10., (z)))
#define R(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize

bool hitRoot = false;

// @Shane
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
    n = max((abs(n) - 0.2)*7., 0.001);
    n /= max((n.x + n.y + n.z), 1e-6);
    
    return (texture(tex, p.yz).xyz*n.x + texture(tex, p.zx).xyz*n.y + texture(tex, p.xy).xyz*n.z);
}

// @Shane:
// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){
    float f = max(0., 1. - abs(b - a)/k);
    return min(a, b) - k*.25*f*f;
}

float fractal(vec3 p) {
    float s = 0.0, w = 0.7, l = 0.0;

    p.y *= .4;
    p += cos(p.yzx*12.)*.07;
    p.x -= 1.6;
    for (s=0.0; s++ < 7.0; p *= l, w *= l ) {
        p = abs(sin(p))-1.0;
        l = 1.5/max(dot(p,p), 1e-6);
    }
    return length(p)/max(w, 1e-6) - .0005;
}

float light(vec3 p) {
    p.xy -= P(p.z).xy;
    float t = iTime*.5;
    
    vec4 tanh_res_1 = tanh_approx(vec4(cos(t * 1.8) * 2.0));
    vec4 tanh_res_2 = tanh_approx(vec4(cos(t * 1.0) * 3.0));
    vec4 tanh_res_3 = tanh_approx(vec4(cos(t * 0.4) * 4.0));
    
    return length(p-vec3(
        tanh_res_1.x * 0.25,
        tanh_res_2.x * 0.3,
        4.0 + T + tanh_res_3.x * 1.0
    )) - 0.25;
}

float root(vec3 p){
    p.xy *= R(sin(p.z*2.)*.1 + sin(p.z*1.)*.3);
    p = mod(p, 1.) - .5;
    return .6*length(p.xy) - .01;
}

float map(vec3 p) {
    float s = 0.0, r = 0.0;
    r = root(p);
    
    p.xy -= P(p.z).xy;
    s = smin(fractal(p), 2. - abs(p.y), .8);
    hitRoot = r < s;
    s = min(s, r);
    return s;
}

// @iq
float AO(in vec3 pos, in vec3 nor) {
    float sca = 1.9, occ = 0.0;
    for( int i=0; i<5; i++ ){
        float hr = 0.01 + float(i)*0.5/4.0;      
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

void mainImage(out vec4 o, in vec2 u) {
    float s = 0.1, d = 0.0, i = 0.0;
    vec3 r = iResolution;
    u = (u-r.xy/2.)/r.y;
    vec3 e = vec3(0.001,0.0,0.0),
         p = P(T),ro=p,
         Z = N( P(T+1.) - p),
         X = N(vec3(Z.z,0.0,-Z.x)),
         D = vec3(R(sin(T*.2)*.4)*u, 1)
           * mat3(-X, cross(X, Z), Z);

    o = vec4(0.0);
    for(;i++ < 128.0;) {
        p = ro + D * d * .65;
        s = map(p);
        d += s;
        o += 4e1*vec4(6,9,1,0) + 1.0/max(s, 0.001);
    }
    
    r = N(vec3(map(p) - map(p-e.xyy), 
              map(p) - map(p-e.yxy), 
              map(p) - map(p-e.yyx)));
    
    o.rgb *= tex3D(iChannel0, p*.5, r);
    o *= o;
    o *= hitRoot ? .2*vec4(4,3,2,0) : vec4(1);
    o *= AO(p, r);
    
    // Applying the robust tanh approximation to the final color
    vec4 temp_val = vec4(d) * o / max(pow(abs(light(p)), 3.0), 1e-6) / 5e9;
    o = tanh_approx(sqrt(temp_val));
}
