// A robust approximation for the tanh function, compatible with GLSL ES 1.0
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

#define T (iTime*.02 * .3)
#define N normalize
#define B 2.60 // Brightness
#define C 2.50 // Contrast
#define S 1.0 // Saturation
#define FOV 1.750 // Field of View

// @Shane
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
    
    n = max((abs(n) - 0.2)*7., 0.001);
    n /= max((n.x + n.y + n.z ), 1E-6);
    
    return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
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
    float s = 0.0, w = 0.0, l = 0.0;
    
    p.y -= 2.75;
    p *= vec3(.6, .5, .4);
    p += cos(p.yzx * 2. + p.xzy * 3. + p.zxy *4.)*.15;
    
    for (s=0.,w=.5; s++ < 8.; p *= l, w *= l )
        p  = abs(sin(p))-1.,
        l = 1.15/max(dot(p,p), 1E-6);

    return length(p)/w;
}

vec3 look(vec3 p, float zoffs) {
    float t = iTime*.5;
    vec4 tanh_input_1 = vec4(cos(t*.4)*.5);
    vec4 tanh_input_2 = vec4(cos(t*.6)*2.);
    vec4 tanh_input_3 = vec4(cos(t*.4)*4.);
    return p-vec3(
            tanh_approx(tanh_input_1).x * 6.,
            tanh_approx(tanh_input_2).x * 5. - 5.,
            zoffs+T*5.+tanh_approx(tanh_input_3).x*4.
        );
}

float map(vec3 p) {
    float s = 0.0;
    s = fractal(p);
    s = smin(s, 2. - p.y, length(p.xy));
    return s;
}


// @iq
float AO(in vec3 pos, in vec3 nor) {
    float sca = 2.2, occ = 0.0;
    for( int i=0; i<5; i++ ){
    
        float hr = 0.01 + float(i)*0.5/4.0;        
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

vec3 applyBCS(vec3 color) {
    // Brightness
    color = color * B;
    // Contrast
    color = ((color - 0.5) * C) + 0.5;
    // Saturation
    vec3 gray = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
    color = mix(gray, color, S);
    return color;
}

void mainImage(out vec4 o, in vec2 u) {
    float s = 0.0, d = 0.0, i = 0.0;
    vec3 r = iResolution.xyz;
    u = (u-r.xy/2.)/r.y * FOV;
    vec3 e = vec3(.01,0,0),
         p = vec3(0.0),
         ro=p=vec3(0,0,T*5.0),
         Z = N( ro - look(p,8.) - p),
         X = N(vec3(Z.z,0,-Z.x)),
         D = vec3(u, 1)* mat3(-X, cross(X, Z), Z);

    o = vec4(0.0);
    for(;i++ < 128.;)
        p = ro + D * d,
        d += s = map(p),
        o += .1*(1e1*vec4(9,2,1,0) + .1*vec4(1,2,6,0)/max(.001+abs(s), 1E-6));
        
    r =  N(map(p) - vec3(map(p-e.xyy), 
                          map(p-e.yxy), 
                          map(p-e.yyx)));
    
    o.rgb *= tex3D(iChannel0, p*.5, r);
    o *= o;
    o *= AO(p, r);
    o.rgb = applyBCS(o.rgb);
    vec4 tanh_input = sqrt(d * o / max(1e8, 1E-6) * exp(d/7.));
    o = tanh_approx(tanh_input);

}
