float value(vec2 p)
{
 	vec2 f = floor(p);
    vec2 s = (p-f);
    s *= s*(3.-2.*s);
    
    return texture(iChannel0,(f+s-.5)/128.).r;
}
void mainImage(out vec4 Color, in vec2 Coord)
{
    vec2 u = Coord/iResolution.xy;
    vec2 c = u*3.;
    vec2 h = vec2(0);
    float a = 1.;
    float s = 1.;
    for(float i = 0.;i<10.;i++)
    {
        a*=1.8;
        s*=2.;
        h += vec2(value(c*s+iTime*vec2(.2,-.1*a)+h.x*a/s*vec2(4,6)),1)/a;
    }
   	float g = smoothstep(-.8,.8,h.x/h.y-u.y);
	vec3 v = 1.+smoothstep(.2,1.,length(u-.5))*vec3(4,6,8)*value(vec2(iTime));
    float n = 1.+.05*g*g*cos(value(Coord*.2+vec2(g,0)*10.)/.1+iTime/.1);
    Color = vec4(exp(-vec3(2,6,11)*g*v)*n,1);
}