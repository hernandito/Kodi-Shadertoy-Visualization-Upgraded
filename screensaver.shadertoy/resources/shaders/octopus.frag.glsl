const float MATH_PI = float( 3.14159265359 );

// New Post-Processing Parameters for BCS
#define BRIGHTNESS_POST 0.80     // Adjusts overall brightness (1.0 for neutral)
#define SATURATION_POST 0.0     // Adjusts color intensity (1.0 for neutral, 0.0 for grayscale)
#define POST_CONTRAST 1.2       // Adjusts contrast (1.0 for neutral, >1.0 for more contrast)

// New: Overall Animation Speed Control
#define ANIMATION_SPEED 0.40     // Controls the speed of all animations (1.0 for original speed)

// New: Sepia Color Control
#define SEPIA_COLOR vec3(1.2, 1.0, 0.8) // Adjusts the sepia tone (e.g., warmer/cooler)

// General purpose small epsilon for numerical stability
const float TINY_EPSILON = 1e-6; 

float saturate( float x )
{
    return clamp( x, 0.0, 1.0 );
}

float Smooth( float x )
{
    return smoothstep( 0.0, 1.0, saturate( x ) );    
}

float Sphere( vec3 p, float s )
{
    return length( p ) - s;
}

float Capsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a; // Explicitly initialized
    vec3 ba = b - a; // Explicitly initialized
    float h = clamp( dot(pa,ba)/max(dot(ba,ba), TINY_EPSILON), 0.0, 1.0 ); // Robustness for division
    return length( pa - ba*h ) - r;
}

float Union( float a, float b )
{
    return min( a, b );
}

float UnionRound( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 * ( b - a ) / max(k, TINY_EPSILON), 0.0, 1.0 ); // Robustness for division
    return mix( b, a, h ) - k * h * ( 1.0 - h );
}

float SubstractRound( float a, float b, float r ) 
{
    vec2 u = max( vec2( r + a, r - b ), vec2( 0.0, 0.0 ) ); // Explicitly initialized
    return min( -r, max( a, -b ) ) + length( u );
}

float Displace( float scale, float ampl, vec3 p )
{
    p *= ampl;
    return scale * sin( p.x ) * sin( p.y ) * sin( p.z );
}

float RepeatAngle( inout vec2 p, float n ) 
{
    float angle = 2.0 * MATH_PI / max(n, TINY_EPSILON); // Robustness for division
    float a = atan( p.y, p.x ) + angle / 2.0; // Explicitly initialized
    float r = length( p ); // Explicitly initialized
    float c = floor( a / angle ); // Explicitly initialized
    a = mod( a, angle ) - angle / 2.;
    p = vec2( cos( a ), sin( a ) ) * r;
    return c;
}

void Rotate( inout vec2 p, float a ) 
{
    p = cos( a ) * p + sin( a ) * vec2( p.y, -p.x );
}

float Tentacle( vec3 p, float animatedTime ) // Pass animatedTime
{    
    p.y += 0.3;
    
    float scale = 1.0 - 2.5 * saturate( abs( p.y ) * 0.25 );    
    
    p.x = abs( p.x );
    
    p -= vec3( 1.0, -0.5, 0.0 );
    Rotate( p.xy, 0.4 * MATH_PI );
    p.x -= sin( p.y * 5.0 + animatedTime * 1.6 ) * 0.05; // Use animatedTime
    
    vec3 t = p;    
    
    float ret = Capsule( p, vec3( 0.0, -1000.0, 0.0 ), vec3( 0.0, 1000.0, 0.0 ), 0.25 * scale );

    p.z = abs( p.z );
    p.y = mod( p.y + 0.08, 0.16 ) - 0.08;
    p.z -= 0.12 * scale;
    float tent = Capsule( p, vec3( 0.0, 0.0, 0.0 ), vec3( -0.4 * scale, 0.0, 0.0 ), 0.1 * scale );
    
    float pores = Sphere( p - vec3( -0.4 * scale, 0.0, 0.0 ), mix( 0.04, 0.1, scale ) );
    tent = SubstractRound( tent, pores, 0.01 );
  
    ret = UnionRound( ret, tent, 0.05 * scale );
    ret += texture2D( iChannel0, vec2( t.xy * 0.5 ) ).x * 0.01; // Changed textureLod to texture2D for GLSL ES 1.00
    
    return ret;
}

float Scene( vec3 p, float animatedTime ) // Pass animatedTime
{    
    p.z += cos( p.y * 0.2 + animatedTime ) * 0.11; // Use animatedTime
    p.x += sin( p.y * 5.0 + animatedTime ) * 0.05;    // Use animatedTime
    p.y += sin( animatedTime * 0.51 ) * 0.1; // Use animatedTime
    
    Rotate( p.yz, 0.45 + sin( animatedTime * 0.53 ) * 0.11 ); // Use animatedTime
    Rotate( p.xz, 0.12 + sin( animatedTime * 0.79 ) * 0.09 ); // Use animatedTime
    
    vec3 t = p; // Explicitly initialized
    RepeatAngle( t.xz, 8.0 );
    float ret = Tentacle( t, animatedTime ); // Pass animatedTime

    p.z += 0.2;
    p.x += 0.2;
        
    float body = Sphere( p - vec3( -0.0, -0.3, 0.0 ), 0.6 ); // Explicitly initialized
    
    t = p;    // Explicitly initialized
    t.x *= 1.0 - t.y * 0.4;
    body = UnionRound( body, Sphere( t - vec3( -0.2, 0.5, 0.4 ), 0.8 ), 0.3 ); 
    
    body += Displace( 0.02, 10.0, p );
    body += texture2D( iChannel0, vec2( p.xy * 0.5 ) ).x * 0.01; // Changed textureLod to texture2D
    
    ret = UnionRound( ret, body, 0.05 );    
    
    ret = SubstractRound( ret, Sphere( p - vec3( 0.1, -1.0, 0.2 ), 0.4 ), 0.1 );        
    
    return ret;
}

float CastRay( in vec3 ro, in vec3 rd, float animatedTime ) // Pass animatedTime
{
    const float maxd = 10.0;
    
    float h = 1.0; // Explicitly initialized
    float t = 0.0; // Explicitly initialized
    
    for ( int i = 0; i < 50; ++i )
    {
        if ( h < 0.001 || t > maxd ) 
        {
            break;
        }
        
        h = Scene( ro + rd * t, animatedTime ); // Pass animatedTime
        t += h;
    }

    if ( t > maxd )
    {
        t = -1.0;
    }
    
    return t;
}

vec3 SceneNormal( in vec3 pos, float animatedTime ) // Pass animatedTime
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 ); // Explicitly initialized
    vec3 normal = vec3( // Explicitly initialized
        Scene( pos + eps.xyy, animatedTime ) - Scene( pos - eps.xyy, animatedTime ), // Pass animatedTime
        Scene( pos + eps.yxy, animatedTime ) - Scene( pos - eps.yxy, animatedTime ), // Pass animatedTime
        Scene( pos + eps.yyx, animatedTime ) - Scene( pos - eps.yyx, animatedTime ) ); // Pass animatedTime
    return normalize( normal );
}

vec3 WaterKeyColor  = vec3( 0.208, 0.439, 0.42 ); // Explicitly initialized
vec3 WaterFillColor = vec3( 0.059, 0.133, 0.278 ); // Explicitly initialized

vec3 Water( vec3 rayDir, float animatedTime ) // Pass animatedTime
{
    Rotate( rayDir.xy, -0.2 ); 
    vec3 color = mix( WaterKeyColor, WaterFillColor, Smooth( -1.2 * rayDir.y + 0.6 ) ); // Explicitly initialized
    return color;
}

float Circle( vec2 p, float r )
{
    return ( length( p / max(r, TINY_EPSILON) ) - 1.0 ) * r; // Robustness for division
}

void BokehLayer( inout vec3 color, vec2 p, vec3 c, float radius, float animatedTime )     // Pass animatedTime
{    
    float wrap = 350.0; // Explicitly initialized    
    if ( mod( floor( p.y / wrap + 0.5 ), 2.0 ) == 0.0 )
    {
        p.x += wrap * 0.5;
    }    
    
    vec2 p2 = mod( p + 0.5 * wrap, wrap ) - 0.5 * wrap; // Explicitly initialized
    float sdf = Circle( p2, radius ); // Explicitly initialized
    color += c * ( 1.0 - Smooth( sdf * 0.01 ) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Apply animation speed globally
    float animatedTime = iTime * ANIMATION_SPEED;

    vec2 q = fragCoord.xy / max(iResolution.xy, TINY_EPSILON); // Explicitly initialized, robustness for division
    vec2 p_main = -1.0 + 2.0 * q; // Renamed to p_main to avoid conflict, Explicitly initialized
    p_main.x *= iResolution.x / max(iResolution.y, TINY_EPSILON); // Robustness for division

    vec3 rayOrigin    = vec3( -0.5, -0.5, -4.0 ); // Explicitly initialized
    vec3 rayDir       = normalize( vec3( p_main.xy, 2.0 ) ); // Explicitly initialized

    vec3 background = Water( rayDir, animatedTime ); // Pass animatedTime
        
    // p is already modified for background bokeh layers, use p_main for this part.
    // Ensure all `iTime` references in BokehLayer calls use `animatedTime`.
    BokehLayer( background, p_main * 400.0 + vec2( 125.0, -120.0 * animatedTime ), vec3( 0.1 ), 0.5, animatedTime );
    BokehLayer( background, p_main * 1.5 * 400.0 + vec2( 546.0, -80.0 * animatedTime ), vec3( 0.07 ), 0.25, animatedTime ); 
    BokehLayer( background, p_main * 2.3 * 400.0 + vec2( 45.0, -50.0 * animatedTime ), vec3( 0.03 ), 0.1, animatedTime ); 

    vec3 color = background; // Explicitly initialized
    float t = CastRay( rayOrigin, rayDir, animatedTime ); // Pass animatedTime
    if ( t > 0.0 )
    {        
        vec3 pos = rayOrigin + t * rayDir; // Explicitly initialized
        vec3 normal = SceneNormal( pos, animatedTime ); // Pass animatedTime
        
        float specOcc = Smooth( 0.5 * length( pos - vec3( -0.1, -1.2, -0.2 ) ) ); // Explicitly initialized

        vec3 c0    = vec3( 0.95, 0.99, 0.43 ); // Explicitly initialized
        vec3 c1    = vec3( 0.67, 0.1, 0.05 ); // Explicitly initialized
        vec3 c2    = WaterFillColor; // Explicitly initialized
        vec3 baseColor = normal.y > 0.0 ? mix( c1, c0, saturate( normal.y ) ) : mix( c1, c2, saturate( -normal.y ) ); // Explicitly initialized
                
        vec3 reflVec = reflect( rayDir, normal ); // Explicitly initialized       
        float fresnel = saturate( pow( 1.2 + dot( rayDir, normal ), 5.0 ) ); // Explicitly initialized
        color = 0.8 * baseColor + 0.6 * Water( reflVec, animatedTime ) * mix( 0.04, 1.0, fresnel * specOcc ); // Pass animatedTime

        float transparency = Smooth( 0.9 + dot( rayDir, normal ) ); // Explicitly initialized
        color = mix( color, background, transparency * specOcc );
    }
    
    // Vignette effect (applied to final color)
    vec2 uv_vignette = fragCoord.xy / iResolution.xy; // Use original fragCoord for vignette
    uv_vignette *= 1.0 - uv_vignette.yx; // Transform UV for vignette
    float vignetteIntensity = 25.0; // From snippet
    float vignettePower = 0.60; // From snippet
    float vig = uv_vignette.x * uv_vignette.y * vignetteIntensity; // Explicitly initialized
    vig = pow(vig, vignettePower);

    // Apply dithering to reduce banding (from snippet)
    int x_dither = int(mod(fragCoord.x, 2.0));
    int y_dither = int(mod(fragCoord.y, 2.0));
    float dither = 0.0; // Explicitly initialized
    if (x_dither == 0 && y_dither == 0) dither = 0.25 * 0.05; // Using 0.05 as default from snippet
    else if (x_dither == 1 && y_dither == 0) dither = 0.75 * 0.05;
    else if (x_dither == 0 && y_dither == 1) dither = 0.75 * 0.05;
    else if (x_dither == 1 && y_dither == 1) dither = 0.25 * 0.05;
    vig = clamp(vig + dither, 0.0, 1.0);

    color *= vig; // Apply vignette to the final color (affects both foreground and background)
    
    // Apply BCS post-processing
    // Brightness
    color *= BRIGHTNESS_POST;
    // Saturation (mix between grayscale and original color)
    color = mix(vec3(dot(color, vec3(0.2126, 0.7152, 0.0722))), color, SATURATION_POST);
    // Contrast (adjust around 0.5 gray level)
    color = (color - 0.5) * POST_CONTRAST + 0.5;

    // NEW: Apply Sepia Tone Effect (as the very last post-process)
    // Convert to grayscale first (luminance)
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    // Multiply by the sepia color
    color = gray * SEPIA_COLOR;

    fragColor = vec4( color, 1.0 );
}
