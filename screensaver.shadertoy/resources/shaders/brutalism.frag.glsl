// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

// This shader code is adapted from an original work by Inigo Quilez, 2013,
// which can be found at https://iquilezles.org/articles/voxellines.
// This version includes modifications for Kodi compatibility and additional controls.

// --- Animation Speed Control ---
// Adjust this value to control the overall animation speed.
// 1.0 = normal speed
// 0.5 = half speed
// 2.0 = double speed
#define ANIMATION_SPEED_MULTIPLIER 0.1

#define T (iTime * ANIMATION_SPEED_MULTIPLIER) // Now incorporates the speed multiplier
#define P(z) (vec3((cos((z) * .4) * .3) * 8., \
                   (cos((z) * .3) * .4) * 8., (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize
#define inf 9e9

// Robust Tanh Approximation for vec4 (for color processing)
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + abs(x));
}

// Robust Tanh Approximation for vec3 (for spatial coordinates)
vec3 tanh_approx(vec3 x) {
    return x / (1.0 + abs(x));
}

// Robust Tanh Approximation for float (for scalar values)
float tanh_approx(float x) {
    return x / (1.0 + abs(x));
}


vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
    n = max((abs(n) - 0.2)*7., 0.001);
    n /= (n.x + n.y + n.z );
    
    return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}


float tunnel (vec3 p, float r) {
    p.xy -= P(p.z).xy;
    return r - length(p.xy);
}

float gyroid(vec3 p) {
    return dot(tanh_approx(p), sin(p+cos(T+p.yzx)));
}

float map(vec3 p) {
    return min(tunnel(p, 6.),
               max(tunnel(p, .3), gyroid(p)));
}

float AO(in vec3 pos, in vec3 nor) {
    float sca = 2.0, occ = 0.0;
    for( int i=0; i<5; i++ ){
        float hr = 0.01 + float(i)*0.5/4.0;
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );
}

void mainImage(out vec4 o, in vec2 u) {
    float s=.02,d=0.,i=0.,a;
    vec3  r = iResolution;
    u = (u-r.xy/2.)/r.y;
    
    vec3  e = vec3(.001,0,0),
          p = P(T),ro=p,
          Z = N( P(T+1.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3(-rot(tanh_approx(sin(p.z*.2)*3.)*3.5)*u, 1)
            * mat3(-X, cross(X, Z), Z);
            
    o *= 0.;
    while(i++ < 99. && s > .01)
        p = ro + D * d * .5,
        d += map(p);
        
    r =  N(map(p) - vec3(map(p-e.xyy),
                         map(p-e.yxy),
                         map(p-e.yyx)));
    
    o.rgb = pow(tex3D(iChannel0, p*.5, r), vec3(2.2));
    for (i = .2; i < .8;
        o += abs(dot(sin(o.rgb * i * 8.), vec3(.5))) / i,
        i *= 1.4142);
    vec4 lights = abs(o /
                      dot(cos(.75*T+p*.3),vec3(.1)));
 
    o *= max(dot(r, normalize(ro-p)), .05);
    o *= AO(p, r);
    o *= lights;
    
    // --- Robust Tanh Conversion Method Applied ---
    float inv_denom = 1.0 / (max(d, 1e-5) * 300.0);
    o = tanh_approx(o * inv_denom);
    // --- End Robust Tanh Conversion ---
}