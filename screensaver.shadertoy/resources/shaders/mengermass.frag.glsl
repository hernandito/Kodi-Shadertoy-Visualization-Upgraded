#define T (iTime * .5)

#define MORPH_FREQ (T*.05)
#define P(z) (vec3(cos((z)*.1)*4.+tanh(cos((z) * .1) * 1.8) * 4., \
                   tanh(cos((z) * .15) * .4) * 8., (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize
#define inf 9e9


// #define NO_SHAKE if you don't want the shake
#define NO_SHAKE

vec2 shake() {
    return vec2(
        sin(T * 250.),
        cos(T * 570.)
    ) * 7.;
}

float length2(vec2 p){
    float k = (sin(MORPH_FREQ)*8.+4.);
    p = pow(abs(p), vec2(k));
    return pow(p.x + p.y, 1./k);
}

vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001);
    n /= (n.x + n.y + n.z );  
    
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

vec3 fog(vec3 rgb, float d) {
    float fogDistance = 20. + sin(T * 0.2) * 1.;
    float fogAmount = .15 + sin(T * 0.1) * 0.08;
    float fogColor = .9 + sin(T * 0.3) * 0.1;

    if(fogDistance != 0.0) {
        float f = d - fogDistance;
        if(f > 0.0) {
            f = min(1.0,f * fogAmount);
            rgb = mix(rgb, vec3(6,4,2)*vec3(0.2 + f * fogColor),f);
        }
    }
    return rgb;
}


// @Shane's Menger function hacked up
#define MENGERLAYER(scale, minmax, hole)\
    s /= (scale), \
    p = abs(fract(q/s)*s - s*.5), \
 	d = minmax(d, min(max(p.x, p.y), \
                  min(max(p.y, p.z), \
                  max(p.x, p.z))) - s/(hole))
float fractal(in vec3 q){
    vec3 p;
    float d=inf, s = 2.;
    MENGERLAYER(1., min, 3.);
    MENGERLAYER(3., max, 3.);
    MENGERLAYER(6., max, 3.);
    return d;
}

float tunnel(vec3 p) {
    float s = (sin(p.z*.6)*1.+2.) -
                   min(length(p.xy - P(p.z).x+4.),
                   min(length(p.x - p.y-10.),
                   min(length2(p.xy - P(p.z).xy),
                       length2(p.xy - P(p.z).y))));
   return s;
}

float map(vec3 p) {
    return max(tunnel(p), fractal(p));
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
    float s=.002,d=0.,i=0.,a;
    vec3  r = iResolution;
    
    #ifndef NO_SHAKE
    if(sin(MORPH_FREQ) < -.05 && sin(MORPH_FREQ) > -.45)
        u += shake();
    #endif 
    u = (u-r.xy/2.)/r.y;
    
    vec3  e = vec3(.01,0,0),
          p = P(T),ro=p,
          Z = N( P(T+1.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3(rot(tanh(sin(p.z*.03)*8.)*3.)*u, 1) 
             * mat3(-X, cross(X, Z), Z);
    o -= o;

    while(i++ < 200. && s > .001)
        p = ro + D * d,
        d += (s = map(p)*.35); // ugh
        
    r =  N(map(p) - vec3(map(p-e.xyy)-map(p+e.xyy), 
                         map(p-e.yxy)-map(p+e.yxy), 
                         map(p-e.yyx)-map(p+e.yyx)));
    if (mod(p.z, 10.) > 5.) 
        o.rgb= pow(tex3D(iChannel0, p*2.5, r), vec3(2.2));
    else
        o.rgb = pow(tex3D(iChannel1, p*1.5, r), vec3(2.2)),
        o *= 2.;

 
    vec3 lights = abs(vec3(3,2,1) /
                   dot(cos(.1*T+p*.1),vec3(.01)))*.11;


    o *= max(dot(r, normalize(ro-p)),.1);
    o *= AO(p, r);
    o.rgb *= lights;
    o.rgb = fog(o.rgb*exp(-d/3.)-dot(-u,u)*.1, d);
    o /= (o + 0.155) * 1.019;          
}