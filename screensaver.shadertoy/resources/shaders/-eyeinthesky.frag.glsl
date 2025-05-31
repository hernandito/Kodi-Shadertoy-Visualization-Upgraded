/*
    "Plasma" by @XorDev (Modified for Kodi)

    X Post:
    x.com/XorDev/status/1894123951401378051

    Modified for Kodi to replace tanh with a similar approximation.
*/
void mainImage( out vec4 O, in vec2 I )
{
    //Resolution for scaling
    vec2 r = iResolution.xy,
    //Centered, ratio corrected, coordinates
    p = (I+I-r) / r.y,
    //Z depth
    z,
    //Iterator (x=0)
    i,
    //Fluid coordinates
    f = p*(z+=4.-4.*abs(.7-dot(p,p)));

    //Clear frag color and loop 8 times
    for(O *= 0.; i.y++<8.;
        //Set color waves and line brightness
        O += (sin(f)+1.).xyyx * abs(f.x-f.y))
        //Add fluid waves
        f += cos(f.yx*i.y+i+iTime)/i.y+.7;

    // Tonemap and color gradient approximation using smoothstep
    vec4 x = 7.*exp(z.x-4.-p.y*vec4(-1,1,2,0))/O;

    // Adjusted approximation to better match tanh
    O = mix(vec4(0.0,0.0,0.0,0.0), vec4(1.0,1.0,1.0,1.0), smoothstep(-0.1, 1.1, x)); //even less haze
    O = O * 0.9;  //reduced brightness
    O = clamp(O, 0.0, 1.0);

    // Color Saturation Adjustment
    float saturation = 0.8; // Reduced saturation
    vec3 gray = vec3(dot(O.rgb, vec3(0.2126, 0.7152, 0.0722)));
    O.rgb = mix(gray, O.rgb, saturation);

}
