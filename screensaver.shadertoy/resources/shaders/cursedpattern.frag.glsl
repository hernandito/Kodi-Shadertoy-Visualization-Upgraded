
float dtoa(float d, float amount){
    return 1. / clamp(d*amount, 1., amount);
}

vec2 hex(vec2 i)
{
    vec2 o;
    o=ceil(i+=i.x*=.577);
    o-=step(i-=o,mod(o.x+o.y,3.)+--i.yx);
    o=mod(o,.8);
    return o;
}

mat2 rot2D(float r)
{
    float c = cos(r), s = sin(r);
    return mat2(c, s, -s, c);
}

vec2 warp(vec2 uv, out float sd) {
    float d = length(mod(uv+1.,2.)-1.);
    sd = d-1.;
    return uv*4.*(1.-d);
}

void mainImage(out vec4 o, vec2 O)
{
    float t = iTime+1e3;
    vec2 R = iResolution.xy
        ,V=(O-.5*R)/R.y
        ,N=O/R-.5
        ,P=O-R*.5
        ;
    
    V *= 2.;
    V *= rot2D(3.14159/4.);
    
    float sd;
    o = vec4(0.);

    for(float i = 1.; i >= 0.; --i) {
        V *= 2.;
        vec2 uvP = warp(V, sd);

        uvP *= rot2D(iTime*.01);
        uvP += iTime*.2;

        vec3 col = hex(uvP).xyy;

        col.rg *= rot2D(.4);
        col.br *= rot2D(-.8);
        col=clamp(col,0.,1.);

        float a = 1.-dtoa(-sd, 100.);
        col *= a;

        float a2 = pow(smoothstep(0.,1.,-sd), .4);
        col = mix(col, vec3(0,0,.2), 1.-a2);
        
      	o.rgb = mix(col, o.rgb, pow(o.a, .1));
        o.a += a;
    }

    //o = vec4(0,0,1,0);
    float v = 1.-dot(N,N);
    o.rgb = mix(vec3(o.r+o.g+o.b)/3.,o.rgb, pow(v,3.));
    v *= 1.-length(4.*pow(abs(N), vec2(2.)));// vingette
    o *= v;
    o=clamp(o,0.,1.);
    o *= 1.7;
    //o = fract(o);
    o=clamp(o,0.,1.);
    o = pow(o,o-o+.55);
    o *= 1.-step(.42,abs(N.y));
}





