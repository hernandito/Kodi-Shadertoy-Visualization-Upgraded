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


#define NUM 9.0

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
	vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);
	return textureLod( iChannel0, (uv+0.5)/256.0, 0.0 ).x;
}

float map( in vec2 x, float t )
{
    return noise( 2.5*x - sin(6.2831*t/15.0+vec2(1.5,0.0)) );
}

float shapes( in vec2 uv, in float r, in float e )
{
	float p = pow( 32.0, r - 0.5 );
	float l = pow( pow(abs(uv.x),p) + pow(abs(uv.y),p), 1.0/p );
	float d = l - pow(r,0.6) - e*0.2 + 0.05;
	float fw = fwidth( d )*0.5;
	fw *= 1.0 + 10.0*e;
	return (r)*smoothstep( fw, -fw, d ) * (1.0-0.2*e)*(0.4 + 0.6*smoothstep( -fw, fw, abs(l-r*0.8+0.05)-0.1 ));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 qq = fragCoord/iResolution.xy;
	vec2 uv = fragCoord/iResolution.xx;
    
    uv *= 1.5;
	
	float time = 11.0 + (iTime + 0.8*sin(iTime)) / 1.8;
	
	uv += 0.01*noise(12.0*uv + 0.1*time );
	
    vec3 col = 0.0*vec3(1.0) * 0.15 * abs(qq.y-0.5);
	
	vec2 pq, st; float f; vec3 coo;
	
    // teal
    pq = floor( uv*NUM ) / NUM;
	st = fract( uv*NUM )*2.0 - 1.0;
	coo = (vec3(0.506, 0.702, 0.506) + 0.3*sin(10.0*pq.x)*sin(13.0*pq.y))*0.6;
	col += 1.0*coo*shapes( st, map(pq, time), 0.0 );
	col += 0.6*coo*shapes( st, map(pq, time), 1.0 );

	// orange
    pq = floor( uv*NUM+0.5 ) / NUM;
	st = fract( uv*NUM+0.5 )*2.0 - 1.0;
    coo = (vec3(1.0,0.5,0.3) + 0.3*sin(10.0*pq.y)*cos(11.0*pq.x))*1.0;
	col += 1.0*coo*shapes( st, 1.0-map(pq, time), 0.0 );
	col += 0.4*coo*shapes( st, 1.0-map(pq, time), 1.0 );

	col *= pow( 16.0*qq.x*qq.y*(1.0-qq.x)*(1.0-qq.y), 0.05 );
	
	fragColor = vec4( col, 1.0 );
}