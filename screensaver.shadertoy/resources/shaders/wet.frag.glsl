// Copyright Inigo Quilez, 2014 - https://iquilezles.org/
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

// Adjustable parameters
#define ANIMATION_SPEED 0.25 // Global animation speed (1.0 = current speed, <1.0 slows, >1.0 speeds up)

vec3 shape( in vec2 p )
{
    p *= 2.20;
    
    vec3 s = vec3( 0.0 );
    vec2 z = p;
    for( int i=0; i<8; i++ ) 
    {
        // transform        
        z += cos(z.yx + cos(z.yx + cos(z.yx + 0.5 * iTime * ANIMATION_SPEED) ) );

        // orbit traps        
        float d = dot( z-p, z-p ); 
        s.x += 1.0/(1.0+d);
        s.y += d;
        s.z += sin(atan(z.y-p.y,z.x-p.x));
    }
    
    return s / 8.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
    vec2 pc = (2.0*fragCoord.xy-iResolution.xy)/min(iResolution.y,iResolution.x);

    vec2 pa = pc + vec2(0.04,0.0);
    vec2 pb = pc + vec2(0.0,0.04);
    
    // shape (3 times for differentials)    
    vec3 sc = shape( pc );
    vec3 sa = shape( pa );
    vec3 sb = shape( pb );

    // color    
    vec3 col = mix( vec3(0.08,0.02,0.15), vec3(0.6,1.1,1.6), sc.x );
    col = mix( col, col.zxy, smoothstep(-0.5,0.5,cos(0.5 * iTime * ANIMATION_SPEED)) );
    col *= 0.15*sc.y;
    col += 0.4*abs(sc.z) - 0.1;

    // light    
    vec3 nor = normalize( vec3( sa.x-sc.x, 0.01, sb.x-sc.x ) );
    float dif = clamp(0.5 + 0.5*dot( nor,vec3(0.5773) ),0.0,1.0);
    col *= 1.0 + 0.7*dif*col;
    col += 0.3 * pow(nor.y,128.0);

    // vignetting    
    col *= 1.0 - 0.21*length(pc);
    
    fragColor = vec4( col, 1.0 );
}