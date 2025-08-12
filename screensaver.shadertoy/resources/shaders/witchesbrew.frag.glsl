// Neon warp pattern with dark reds, magenta, blue, and glowing highlights.
// Based on Inigo Quilez's "warp" technique. Remix by ChatGPT 2025-06-20.
const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );

// --- Post-processing BCS Parameters ---
// Adjust these values to control Brightness, Contrast, and Saturation.
// BRIGHTNESS: Additive value. Positive makes brighter, negative makes darker. (Default: 0.0)
#define BRIGHTNESS 0.20
// CONTRAST: Multiplicative value around 0.5 gray. >1.0 increases, <1.0 decreases. (Default: 1.0)
#define CONTRAST 1.70
// SATURATION: Mixes color with its luminance. >1.0 increases, <1.0 decreases (0.0 is grayscale). (Default: 1.0)
#define SATURATION 1.20

// --- Turbulence Detail Parameter ---
// Increase this value to make the swirls smaller and more numerous (higher detail).
// A value of 1.0 is the default/original detail. Try 1.5, 2.0, or higher.
#define TURBULENCE_DETAIL_SCALE 1.25 // Adjust this value

float noise( in vec2 p )
{
    return sin(p.x)*sin(p.y);
}

float fbm4( vec2 p )
{
    float f = 0.0;
    f += 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); p = m*p*2.01;
    f += 0.0625*noise( p );
    return f/0.9375;
}

float fbm6( vec2 p )
{
    float f = 0.0;
    f += 0.500000*(0.5+0.5*noise( p )); p = m*p*2.02;
    f += 0.250000*(0.5+0.5*noise( p )); p = m*p*2.03;
    f += 0.125000*(0.5+0.5*noise( p )); p = m*p*2.01;
    f += 0.062500*(0.5+0.5*noise( p )); p = m*p*2.04;
    f += 0.031250*(0.5+0.5*noise( p )); p = m*p*2.01;
    f += 0.015625*(0.5+0.5*noise( p ));
    return f/0.96875;
}

vec2 fbm4_2( vec2 p )
{
    return vec2(fbm4(p), fbm4(p+vec2(7.8)));
}

vec2 fbm6_2( vec2 p )
{
    return vec2(fbm6(p+vec2(16.8)), fbm6(p+vec2(11.5)));
}

float func( vec2 q, out vec4 ron )
{
    q += 0.03*sin( vec2(0.27,0.23)*iTime + length(q)*vec2(4.1,4.3));
    // Apply TURBULENCE_DETAIL_SCALE to increase swirl frequency/detail
    vec2 o = fbm4_2( 0.9*q * TURBULENCE_DETAIL_SCALE );
    o += 0.04*sin( vec2(0.12,0.14)*iTime + length(o));
    vec2 n = fbm6_2( 3.0*o * TURBULENCE_DETAIL_SCALE );
    ron = vec4( o, n );
    float f = 0.5 + 0.5*fbm4( (1.8*q + 6.0*n) * TURBULENCE_DETAIL_SCALE );
    return mix( f, f*f*f*3.5, f*abs(n.x) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    float e = 2.0/iResolution.y;
    vec4 on = vec4(0.0);
    float f = func(p, on);

    // Adjusted palette: orangeish yellow to green
    vec3 neon1 = vec3(0.15, 0.1, 0.05);  // Muted dark olive/brown base
    vec3 neon2 = vec3(0.9, 0.4, 0.05);    // Vibrant orange
    vec3 neon3 = vec3(0.05, 0.3, 0.05);    // Darker green for contrast
    vec3 neon4 = vec3(0.7, 0.9, 0.1);      // Bright yellow-green
    vec3 neon5 = vec3(0.3, 1.0, 0.3);      // Bright green accent

    vec3 col = mix(neon1, neon2, f);
    col = mix(col, neon3, dot(on.zw, on.zw));
    col = mix(col, neon4, 0.2 + 0.5*on.y*on.y);
    col = mix(col, neon5, 0.22*smoothstep(1.2,1.3,abs(on.z)+abs(on.w)));
    col = clamp(col * f * 1.6, 0.0, 1.0);  

    // Lighting/shading - adjusted to match the new color scheme
    vec4 kk;
    vec3 nor = normalize( vec3( func(p+vec2(e,0.0),kk)-f, 2.0*e, func(p+vec2(0.0,e),kk)-f ) );
    vec3 lig = normalize( vec3( 0.9, 0.2, -0.4 ) );
    
    float dif = clamp( 0.3+0.7*dot( nor, lig ), 0.0, 1.0 ); 
    
    vec3 lin = vec3(0.7,0.5,0.1)*(nor.y*0.5+0.5) + vec3(0.5,0.3,0.05)*dif; // Orange/greenish
    col *= 1.08*lin;

    // Gamma for punch, but less aggressive
    col = pow(col, vec3(0.95)); 

    // Stronger highlight clamp to preserve shadows
    col = min(col, 0.98);

    fragColor = vec4(col, 1.0);

    // --- Post-processing BCS adjustments ---
    // Apply Brightness
    fragColor.rgb += BRIGHTNESS;

    // Apply Contrast (around 0.5 gray point)
    fragColor.rgb = (fragColor.rgb - 0.5) * CONTRAST + 0.5;

    // Apply Saturation
    float luma = dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722)); // Standard luminance calculation
    fragColor.rgb = mix(vec3(luma), fragColor.rgb, SATURATION);

    // Ensure final color values are within a valid range
    fragColor = clamp(fragColor, 0.0, 1.0);
}