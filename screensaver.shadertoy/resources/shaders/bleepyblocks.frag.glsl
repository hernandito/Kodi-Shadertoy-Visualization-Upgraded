#define pi  3.14159

// from iq
float expStep( float x, float k, float n ){
    return exp( -k*pow(x,n) );
}

mat2 rot(float rads)
{
    return mat2(cos(rads), sin(rads), -sin(rads), cos(rads));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2. * fragCoord.xy - iResolution.xy) / iResolution.y;
    p = rot(iTime * .60) * p;
    p = vec2(p.x, -p.y) + .05;
    
    float r = length(p);
    float a = atan(p.y, p.x);
    a += 1. * sin(a);
    float coord = fract(a / pi + expStep(r, .4, .5) * 9. + 0.3 * iTime);
    vec3 col = mix(vec3(.05,.05,.05), vec3(0,0,0), step(.5, coord));
    
 
    fragColor.rgb = col;
}
