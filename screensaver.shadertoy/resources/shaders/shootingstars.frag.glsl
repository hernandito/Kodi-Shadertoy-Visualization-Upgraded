/*
    "Shooting Stars" by @XorDev

    I got hit with inspiration for the concept of shooting stars.
    This is what I came up with.
    
    Tweet: twitter.com/XorDev/status/1604218610737680385
    Twigl: t.co/i7nkUWIpD8
    <300 chars playlist: shadertoy.com/playlist/fXlGDN
*/
void mainImage(out vec4 O, vec2 I)
{
    //Clear fragcolor
    O *= 0.;
    
    //Line dimensions (box) and position relative to line
    vec2 b = vec2(0,.32), p;
    //Rotation matrix
    mat2 R;
    //Iterate 20 times
    for(float i=.9; i++<28.;
        //Add attenuation
        O += 1e-4/length(clamp(p=R
        //Using rotated boxes
        *(fract((I/iResolution.y*i*.1+iTime*b)*R)-.5),-b,b)-p)
        //My favorite color palette
        *(cos(p.y/.1+vec4(0,1,2,3))+1.) )
        //Rotate for each iteration
        R=mat2(cos(i+vec4(0,33,11,0)));
}