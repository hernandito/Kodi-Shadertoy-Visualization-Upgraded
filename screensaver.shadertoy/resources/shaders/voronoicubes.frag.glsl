// Copyright Inigo Quilez, 2014 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work in any form,
// including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it.
// I share this Work for educational purposes, and you can link to it,
// through an URL, proper attribution and unmodified screenshot, as part
// of your educational material. If these conditions are too restrictive
// please contact me and we'll definitely work it out.

// Adjustable parameters
#define CUBE_DURATION 0.0      // Duration of the cube phase in seconds
#define VORONOI_DURATION 18.0  // Total duration of the Voronoi morphing phase (Manhattan + Triangular)
#define TRANSITION_DURATION 0.0 // Duration of each transition in seconds
#define VORONOI_SCALE 16.0     // Scale factor for Voronoi repetitions (higher = more repetitions)
#define ANIMATION_SPEED .20    // Global animation speed (1.0 = current speed, <1.0 slows, >1.0 speeds up)

float hash1( float n ) { return fract(sin(n)*43758.5453); }
vec2  hash2( vec2  p ) { p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) ); return fract(sin(p)*43758.5453); }

// Custom timing function to control phase durations
float getMode(float time) {
    float adjustedTime = time * ANIMATION_SPEED;
    float totalCycle = CUBE_DURATION + VORONOI_DURATION + 3.0 * TRANSITION_DURATION;
    float cycle = mod(adjustedTime, totalCycle);
    float mode;

    // Phase timings:
    // 0.0 to TRANSITION_DURATION: Transition to Euclidean
    // TRANSITION_DURATION to (TRANSITION_DURATION + CUBE_DURATION): Euclidean (cubes)
    // (TRANSITION_DURATION + CUBE_DURATION) to (2*TRANSITION_DURATION + CUBE_DURATION): Transition to Manhattan
    // (2*TRANSITION_DURATION + CUBE_DURATION) to (2*TRANSITION_DURATION + CUBE_DURATION + VORONOI_DURATION/2): Manhattan
    // (2*TRANSITION_DURATION + CUBE_DURATION + VORONOI_DURATION/2) to (3*TRANSITION_DURATION + CUBE_DURATION + VORONOI_DURATION/2): Transition to Triangular
    // (3*TRANSITION_DURATION + CUBE_DURATION + VORONOI_DURATION/2) to (3*TRANSITION_DURATION + CUBE_DURATION + VORONOI_DURATION): Triangular
    // (3*TRANSITION_DURATION + CUBE_DURATION + VORONOI_DURATION) to totalCycle: Transition back to Euclidean

    float t1 = TRANSITION_DURATION;
    float t2 = t1 + CUBE_DURATION;
    float t3 = t2 + TRANSITION_DURATION;
    float t4 = t3 + VORONOI_DURATION / 2.0;
    float t5 = t4 + TRANSITION_DURATION;
    float t6 = t5 + VORONOI_DURATION / 2.0;

    if (cycle < t1) {
        mode = 0.0 + smoothstep(0.0, t1, cycle) * 0.1; // Transition to Euclidean
    } else if (cycle < t2) {
        mode = 0.1; // Euclidean phase (cubes)
    } else if (cycle < t3) {
        mode = 0.1 + smoothstep(t2, t3, cycle) * (1.0 - 0.1); // Transition to Manhattan
    } else if (cycle < t4) {
        mode = 1.0; // Manhattan phase
    } else if (cycle < t5) {
        mode = 1.0 + smoothstep(t4, t5, cycle) * (2.0 - 1.0); // Transition to Triangular
    } else if (cycle < t6) {
        mode = 2.0; // Triangular phase
    } else {
        mode = 2.0 + smoothstep(t6, totalCycle, cycle) * (3.0 - 2.0); // Transition back to Euclidean (2 seconds)
    }
    return mode;
}

vec4 voronoi( in vec2 x, float mode )
{
    vec2 n = floor( x );
    vec2 f = fract( x );

    vec3 m = vec3( 8.0 );
    float m2 = 8.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = vec2( float(i),float(j) );
        vec2 o = hash2( n + g );

        // animate
        o = 0.5 + 0.5*sin( iTime * ANIMATION_SPEED + 6.2831*o );

        vec2 r = g - f + o;

        // euclidean        
        vec2 d0 = vec2( sqrt(dot(r,r)), 1.0 );
        // manhattam        
        vec2 d1 = vec2( 0.71*(abs(r.x) + abs(r.y)), 1.0 );
        // triangular        
        vec2 d2 = vec2( max(abs(r.x)*0.866025+r.y*0.5,-r.y), 
                        step(0.0,0.5*abs(r.x)+0.866025*r.y)*(1.0+step(0.0,r.x)) );

        vec2 d = d0; 
        if( mode<3.0 ) d=mix( d2, d0, fract(mode) );
        if( mode<2.0 ) d=mix( d1, d2, fract(mode) );
        if( mode<1.0 ) d=mix( d0, d1, fract(mode) );
        
        if( d.x<m.x )
        {
            m2 = m.x;
            m.x = d.x;
            m.y = hash1( dot(n+g,vec2(7.0,113.0) ) );
            m.z = d.y;
        }
        else if( d.x<m2 )
        {
            m2 = d.x;
        }
    }
    return vec4( m, m2-m.x );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float mode = getMode(iTime);
    mode = floor(mode) + smoothstep(0.0, 1.0, fract(mode)); // Smoother transition over 2 seconds
    
    vec2 p = fragCoord.xy/iResolution.xx;
    vec4 c = voronoi( VORONOI_SCALE*p, mode );

    vec3 col = 0.5 + 0.5*sin( c.y*2.5 + vec3(1.0,1.0,1.9) );
    col *= sqrt( clamp( 1.0 - c.x, 0.0, 1.0 ) );
    col *= clamp( 0.5 + (1.0-c.z/2.0)*0.5, 0.0, 1.0 );
    col *= 0.4 + 0.6*sqrt(clamp( 4.0*c.w, 0.0, 1.0 ));
    
    fragColor = vec4( col, 1.0 );
}