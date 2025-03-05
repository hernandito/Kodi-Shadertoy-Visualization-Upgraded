#define S(a, b, t) smoothstep(a, b, t)

// distance to a line segment, by projecting your point onto the line
float DistLine( vec2 p, vec2 a, vec2 b ) {
    vec2 pa = p-a;
    vec2 ba = b-a;
    float t = clamp(dot( pa, ba ) / dot(ba, ba), 0.0, 1.0 );
    
    return length( pa - ba * t );
}

// 2-to-1 hash
float N21( vec2 p ) {
    p = fract( p * vec2( 233.34, 851.73 ) );
    p += dot( p, p + 23.45 );
    return fract( p.x * p.y );
}

// 2-to-2 hash
vec2 N22( vec2 p ){
    float n = N21( p );
    return vec2( n, N21( p + n ) );
}

// get the position for a given grid id, and offset for the neighbor cells
vec2 GetPos( vec2 id, vec2 offset ){
    vec2 n = N22( id + offset )*iTime;
    return offset + vec2( sin( n.x ), cos( n.y ) ) * 0.4; 
}

// distance to a line, but with the mapping applied
float Line( vec2 p, vec2 a, vec2 b ){
    float d = DistLine( p, a, b );
    
    float m = S( 0.03, 0.01, d );
    
    float d2 = length( a - b );
    
    m *= S(1.2, 0.8, d2)*0.5 + S(0.05, 0.03, abs(d2 - 0.75));
    return m;
}

float Layer( vec2 uv ) {    
    float m = 0.0; // initial value of mapped distance
    
    // creating grid cells across the screen
    vec2 gv = fract( uv ) - 0.5; // position within the grid cell
    vec2 id = floor( uv );      // the id of the grid cell
    
    vec2 p[ 9 ]; // randomly moving points, for the neighboring cells
    
    int i = 0; // loop across these neighbors
    for(float y = -1.0; y <= 1.0; y++ )
        for(float x = -1.0; x <= 1.0; x++ )
            p[ i++ ] = GetPos( id, vec2( x, y ) ); // get the random position for all neigbhors


    float t = iTime * 10.0;
    for( int j = 0; j < 9; j++ ){
        m += Line( gv, p[ 4 ], p[ j ] ); // evaluate lines between current cell position and neighbors
        
        vec2 a = (p[j] - gv) * 20.;
        float sparkle = 1. / dot(a,a);
        
        m += sparkle * (sin(t + fract(p[j].x) * 10.) * 0.5 + 0.5);
        
    }
    m += Line( gv, p[1], p[3]);
    m += Line( gv, p[1], p[5]);
    m += Line( gv, p[7], p[3]);
    m += Line( gv, p[7], p[5]);

    return m;

}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    // mapped point on the screen
    vec2 uv = ( fragCoord - 0.5 * iResolution.xy ) / iResolution.y;
   //  uv *= 1.5; // rescale this to have more range on the screen
    
    vec2 mouse = (iMouse.xy/iResolution.xy) - 0.5;
       
    float m = 0.;    
    float t = iTime * 0.1;
    float s = sin(t);
    float c = cos(t);
    mat2 rot = mat2(c, -s, s, c);
    
    uv *= rot;
    mouse *= rot;
    
    for( float i = 0.; i <= 1.; i += 1./4. ){
        float z = fract( i + t );
        float size = mix( 25., 0.5, z );
        float fade = S( 0., 0.5, z ) * S( 1.0, 0.8, z );
        
        m += Layer( uv * size + i * 20. - mouse ) * fade;
    }
    
    float fft = texelFetch( iChannel0, ivec2(0.7, 0. ), 0 ).x;
     
    vec3 base = sin( t * 10. * vec3( 0.345, 0.456, 0.657 ) ) * 0.4 + 0.6; 
    // color is mapped distance to line
    vec3 col = m * base;
    col += uv.y * base * fft;

    // draw outlines between grid cells 
    //vec2 gv = fract( uv ) - 0.5; // position within the grid cell
    //if( gv.x > 0.48 || gv.y > 0.48 )
        //col = vec3( 1.0, 0.0, 0.0 ); // color red on the boundary

    // Output to screen
    fragColor = vec4( col, 1.0 );
}