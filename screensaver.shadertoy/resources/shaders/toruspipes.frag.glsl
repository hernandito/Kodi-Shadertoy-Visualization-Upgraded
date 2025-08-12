// Copyright Inigo Quilez, 2019 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither as it is or
// altered, here on Shadertoy or anywhere else, in any form including physical
// and digital. You cannot use this Work in any commercial or non-commercial
// product, website or project. You cannot sell this Work and you cannot mint
// an NFTs of it or train a neural network with it without permission. I share
// this Work for educational purposes, and you can link to it, through an URL,
// proper attribution and unmodified screenshot, as part of your educational
// material. If these conditions are too restrictive please contact me and we'll
// definitely work it out.

// 0 or 1
#define SHOW_STRIPS 0


#define AA 1

// BCS Adjustments (Post-processing parameters)
#define BRIGHTNESS .9 // Adjust overall brightness (1.0 for no change)
#define CONTRAST   1.50 // Adjust contrast (1.0 for no change, >1.0 for more contrast, <1.0 for less)
#define SATURATION .9 // Adjust saturation (1.0 for no change, >1.0 for more saturation, <1.0 for less)

// Background Color/Gradient Parameters
#define BG_LUMINANCE_BASE           0.06  // Base lightness of the background (0.0 to 1.0)
#define BG_LUMINANCE_DIST_FACTOR    0.015 // Intensity of the circular gradient (higher value means stronger effect from center distance)
#define BG_LUMINANCE_VERTICAL_FACTOR 0.05 // Intensity of the vertical gradient (higher value means stronger vertical effect)


// https://www.shadertoy.com/view/tl23RK
float sdSqCappedTorus(in vec3 p, in vec2 sc, in float ra)
{
    p.x = abs(p.x);
    float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
    return dot(p,p) + ra*ra - 2.0*ra*k;
}

vec3 hash( float n )
{
    vec3 m = n*vec3(23.0,41.0,17.0) + vec3(9.0,1.0,31.0);
    return fract( m*fract( m*0.3183099 ) );
}

vec2 map( in vec3 pos )
{
    vec3 pp = vec3(0.0);
    vec3 ww = vec3(0.0,1.0,0.0);

    float d = length(pos-pp);

    vec4 data = vec4(0.0);

    for( int i=0; i<32; i++ )
    {
        // segment parameters
        vec3 ran = hash(float(i));
        float ra = 0.13 + 0.08*ran.x; // radius
        float ap = 1.10 + 0.80*ran.y; // aperture
        vec3  up = normalize( sin(75.0*ran.z+vec3(0.0,1.0,4.0))); // orientation

        // world to torus transformation
        vec2 sc = vec2(sin(ap),cos(ap));
        vec3 ou = normalize(cross(ww,up));
        vec3 vv = cross(ou,ww);
        vec3 uu =  sc.x*ou + sc.y*ww;
              ww = -sc.y*ou + sc.x*ww;
        vec3 cpos = (pos-pp)*mat3(uu,ww,vv) + ra*vec3(-sc.x,sc.y,0.0);

        // distance evaluation
        float tmp = sdSqCappedTorus(cpos, sc, ra );
        if( tmp<d )
        {
            d = tmp;
            data = vec4( float(i), cpos.xy, ap );
        }

        // prepare next segment
        pp += 2.0*ra*sc.x*uu;
        ww = sc.y*uu - sc.x*ww;
    }

    return vec2(sqrt(d) - 0.035, // distance
                 data.x + 0.5+0.5*(atan(data.y,data.z))/data.w // u
                );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.001;
    return normalize( e.xyy*map( pos + e.xyy*eps ).x +
                      e.yyx*map( pos + e.yyx*eps ).x +
                      e.yxy*map( pos + e.yxy*eps ).x +
                      e.xxx*map( pos + e.xxx*eps ).x );
}

#define ZERO 0

float calcAO( in vec3 pos, in vec3 nor )
{
    float ao = 0.0;

    vec3 v = normalize(vec3(0.7,0.5,0.2));
    for( int i=ZERO; i<12; i++ )
    {
        float h = abs(sin(float(i)));
        vec3 kv = v + 2.0*nor*max(0.0,-dot(nor,v));
        ao += clamp( map(pos+nor*0.01+kv*h*0.2).x*3.0, 0.0, 1.0 );
        v = v.yzx;
        // Replaced modulo operator with floor-based check for oddness
        if( floor(floor(float(i)/2.0) / 2.0) != (floor(float(i)/2.0) / 2.0) ) v.yz *= -1.0;
    }
    ao /= 12.0;
    ao = ao + 2.0*ao*ao;
    return clamp( ao*2.5, 0.0, 1.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // camera movement
    float an = 0.15*(iTime-8.0);
    vec3 ta = vec3( 0.25, -0.06, -0.75 );
    vec3 ro = ta + vec3( 1.7*cos(an), 0.6, 1.7*sin(an) );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv =         ( cross(uu,ww));

    // render
    vec3 tot = vec3(0.0);

    #if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
        #else
        vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
        #endif

        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 1.6*ww );

        // raymarch
        const float tmax = 3.5;
        float t = 0.5;
        float m = 0.0;
        for( int i=0; i<256; i++ )
        {
            vec3 pos = ro + t*rd;
            vec2 h = map(pos);
            m = h.y;
            if( h.x<0.001 || t>tmax ) break;
            t += h.x;
        }

        // shade/light
        // Use the new background parameters here:
        vec3 col = vec3(BG_LUMINANCE_BASE - BG_LUMINANCE_DIST_FACTOR*length(p) + BG_LUMINANCE_VERTICAL_FACTOR*rd.y );
        if( t<tmax )
        {
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);
            float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
            float occ = calcAO(pos, nor);
            float amb = 0.5 + 0.5*nor.y;
            // material
            vec3 mat = 0.5 + 0.5*cos( m*0.06 + vec3(0.00,1.0,1.8) + 1.0 );
            mat += 0.05*nor;
            // lighting
            col = mat*1.5*occ*vec3(amb+fre*fre*col*0.4);

            #if SHOW_STRIPS==1
            col *= 1.0-smoothstep( 0.8, 0.9, sin(20.0*(m+iTime*0.25)) );
            #endif

            col += fre*occ*0.5*vec3(0.5,0.7,1.0)*smoothstep(0.0,0.1,reflect(rd,nor).y);
            col *= 1.4;
        }

        tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    // gamma
    tot = pow( tot, vec3(0.4545) );

    // Apply BCS Adjustments
    // Contrast
    tot = (tot - 0.5) * CONTRAST + 0.5;
    // Brightness
    tot *= BRIGHTNESS;
    // Saturation
    float luma = dot(tot, vec3(0.2126, 0.7152, 0.0722)); // Standard luminance calculation
    tot = mix(vec3(luma), tot, SATURATION);


    // cheap dithering
    tot += sin(fragCoord.x*114.0)*sin(fragCoord.y*211.1)/512.0;

    fragColor = vec4( tot, 1.0 );
}