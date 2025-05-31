// Created by inigo quilez - iq/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// Other "Iterations" shaders:
//
// "trigonometric"   : https://www.shadertoy.com/view/Mdl3RH
// "trigonometric 2" : https://www.shadertoy.com/view/Wss3zB
// "circles"         : https://www.shadertoy.com/view/MdVGWR
// "coral"           : https://www.shadertoy.com/view/4sXGDN
// "guts"            : https://www.shadertoy.com/view/MssGW4
// "inversion"       : https://www.shadertoy.com/view/XdXGDS
// "inversion 2"     : https://www.shadertoy.com/view/4t3SzN
// "shiny"           : https://www.shadertoy.com/view/MslXz8
// "worms"           : https://www.shadertoy.com/view/ldl3W4
// "stripes"         : https://www.shadertoy.com/view/wlsfRn


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord / iResolution.x + 0.01*iTime;
    uv *= 0.75;
    
    vec2 gra = vec2(0.0);
    vec3 col = vec3(0.0);
    vec2 ouv = uv;
    for( int i=0; i<64; i++ )
    {
        uv += (0.1/64.0)*cos( 6.2831*cos(6.2831*uv.yx + 0.02*iTime*vec2(1.7,2.1)) + 0.1*iTime*vec2(2.1,1.3) );
        vec3 tex = texture( iChannel0, uv ).xyz;
        col += tex*(1.0/64.0);
        gra += vec2( tex.x - texture( iChannel0, uv+vec2(1.0/iChannelResolution[0].x,0.0) ).x,
                     tex.x - texture( iChannel0, uv+vec2(0.0,1.0/iChannelResolution[0].y) ).x );
    }
    
    col *= 12.0*length( uv - ouv );
    col += 0.08*(gra.x + gra.y);
    
	fragColor = vec4( col, 1.0 );
}