// Author: bitless
// Title: Abstract Rectangles

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.


#define p(t, a, b, c, d) ( a + b*cos( 6.28318*(c*t+d) ) ) //palette function (https://iquilezles.org/articles/palettes)
#define S(x,y,z) smoothstep(x,y,z)

void mainImage( out vec4 f, in vec2 g)
{
    vec2 r = iResolution.xy
        ,s = (g+g-r)/r.y*(1.3+sin(iTime)*.2);
    s.x += s.x*abs(s.x)*.4+.5;
    float y = s.y*(1.+abs(floor(s.x))*.2);
    s.y = y+iTime*0.1;
    vec2 l = floor(s)
        ,u = fract(s);
    
    float 	m = fwidth(s.y)
        	,c = (1.-abs(l.x)*.1) 			//edge faiding
                *(1.2-length(u-.5)*.5) 		//center spot
                *S(.5,.49-m,abs(.5-u.x))	//vertical borders
                *S(.5,.49-m,abs(.5-u.y))	// horizontal borders
        		*(1.-((l.x > 0.) ? S(.4,0.,u.x): //right side shadow
        		(l.x < 0.) ? S(.6,1.,u.x):0.)*.5)* //left side shadow
    			(1.-S(y*.3,0.,u.y)*max(0.,y*2.)*.2    //top shadow
         		-S(1.+(y)*.3,1.,u.y)*abs(min(0.,y*2.))*.2); //bottom shadow
    f = vec4(p(sin(l.x*.2),vec3(.5),vec3(.3),vec3(.6+sin(l.y)*.2),vec3(.1,.2,.3))*c,1.);
}