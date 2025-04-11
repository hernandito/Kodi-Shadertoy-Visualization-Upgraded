// Created by inigo quilez - iq/2013
//   https://www.youtube.com/c/InigoQuilez
//   https://iquilezles.org/
// I share this piece (art and code) here in Shadertoy and through its Public API, only for educational purposes. 
// You cannot use, sell, share or host this piece or modifications of it as part of your own commercial or non-commercial product, website or project.
// You can share a link to it or an unmodified screenshot of it provided you attribute "by Inigo Quilez, @iquilezles and iquilezles.org". 
// If you are a teacher, lecturer, educator or similar and these conditions are too restrictive for your needs, please contact me and we'll work it out.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (2.0*fragCoord-iResolution.xy)/min(iResolution.y,iResolution.x);
	
    // background color
    vec3 bcol = vec3(.0,.0,.0);

    // animate
    float tt = mod(iTime,3.)/2.7;
    float ss = pow(tt,.2)*2.5 + 0.5;
    ss = 1.0 + ss*0.5*sin(tt*6.2831*3.0 + p.y*0.5)*exp(-tt*4.0);
    p *= vec2(0.5,1.5) + ss*vec2(0.5,-0.5);

    // shape
	p.y -= 0.125;
    float a = atan(p.x,p.y)/8.;
    float r = length(p);
    float h = abs(a);
    float d = (43.0*h - 8.0*h*h + 10.0*h*h*h)/(6.0-5.0*h);
    
	// color
	float s = 0.6 + 0.7*p.x;
	s *= 1.0-0.54*r;
	s = 0.3 + 0.77*s;
	s *= 0.5+0.5*pow( 1.0-clamp(r/d, 0.0, 1.0 ), 0.1 );
	vec3 hcol = vec3(.850,0.0*r,0.0)*s;
	
    vec3 col = mix( bcol, hcol, smoothstep( -0.02, 0.02, d-r) );

    fragColor = vec4(col,1.0);
}