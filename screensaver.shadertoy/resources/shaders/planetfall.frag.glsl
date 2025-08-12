// Copyright Inigo Quilez, 2018 - https://iquilezles.org/
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

// Pretty much a modification to Klems' shader (https://www.shadertoy.com/view/XlcfRs)

#define AA 1

// Replaced iFrame with 0, as iFrame is not a standard uniform in Kodi's GLSL ES 1.00
#define ZERO 0

// BCS Adjustments (Post-processing parameters)
#define BRIGHTNESS 1.0 // Adjust overall brightness (1.0 for no change)
#define CONTRAST   1.0 // Adjust contrast (1.0 for no change, >1.0 for more contrast, <1.0 for less)
#define SATURATION 1.0 // Adjust saturation (1.0 for no change, >1.0 for more saturation, <1.0 for less)


//#define INTERACTIVE

mat3 makeBase( in vec3 w )
{
    float k = inversesqrt(1.0-w.y*w.y);
    return mat3( vec3(-w.z,0.0,w.x)*k, 
                 vec3(-w.x*w.y,1.0-w.y*w.y,-w.y*w.z)*k,
                 w);
}


// https://iquilezles.org/articles/intersectors
vec2 sphIntersect( in vec3 ro, in vec3 rd, in float rad )
{
    float b = dot( ro, rd );
    float c = dot( ro, ro ) - rad*rad;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b-h,-b+h);
}

// https://iquilezles.org/articles/distfunctions
float sdCapsule( in vec3 p, in float b, in float r )
{
    float h = clamp( p.z/b, 0.0, 1.0 );
    return length( p - vec3(0.0,0.0,b)*h ) - r;//*(0.2+1.6*h);
}

// modified Keinert et al's inverse Spherical Fibonacci Mapping
vec4 inverseSF( in vec3 p, const in float n )
{
    const float PI = 3.14159265359;
    const float PHI = 1.61803398875;

    float phi = min(atan(p.y,p.x),PI);
    float k   = max(floor(log(n*PI*sqrt(5.0)*(1.-p.z*p.z))/log(PHI+1.)),2.0);
    // Fix: Replaced round() with floor(x + 0.5)
    float Fk  = pow(PHI,k)/sqrt(5.0);
    vec2  F   = vec2(floor(Fk + 0.5), floor(Fk*PHI + 0.5));
    vec2  G   = PI*(fract((F+1.0)*PHI)-(PHI-1.0));    
    
    mat2 iB = mat2(F.y,-F.x,G.y,-G.x)/(F.y*G.x-F.x*G.y);
    vec2 c = floor(iB*0.5*vec2(phi,n*p.z-n+1.0));

    float ma = 0.0;
    vec4 res = vec4(0);
    for( int s=0; s<4; s++ )
    {
        // Fix: Replaced bitwise operators with arithmetic equivalents
        vec2 uv = vec2(float(s) - 2.0 * floor(float(s) / 2.0), floor(float(s)/2.0));
        float i = dot(F,uv+c);
        float phi = 2.0*PI*fract(i*PHI);
        float cT = 1.0 - (2.0*i+1.0)/n;
        float sT = sqrt(1.0-cT*cT);
        vec3 q = vec3(cos(phi)*sT, sin(phi)*sT,cT);
        float a = dot(p,q);
        if (a > ma)
        {
            ma = a;
            res.xyz = q;
            res.w = i;
        }
    }
    return res;
}

float map( in vec3 p, out vec4 color, const in bool doColor )
{
    float lp = length(p);
    float dmin = lp-1.0;
    {
    vec3 w = p/lp;
    vec4 fibo = inverseSF(w, 700.0);
    float hh = 1.0 - smoothstep(0.05,0.1,length(fibo.xyz-w));
    dmin -= 0.07*hh;
    color = vec4(0.05,0.1,0.1,1.0)*hh * (1.0+0.5*sin(fibo.w*111.1));
    }
    
    
    float s = 1.0;
    
    #ifdef INTERACTIVE
  //float tt = mod(iTime,5.0); // Modulo could still be an issue if not floats
    float tt = 4.0*iMouse.x/iResolution.x;
    vec3  fp = smoothstep(0.0,1.0,tt-vec3(0,1,2));
    #endif
    
    for( int i=0; i<3; i++ )
    {
        float h = float(i)/float(3-1);
        
        vec4 f = inverseSF(normalize(p), 65.0 + h*75.0);
        
        // snap
        p -= f.xyz;

        // orient to surface
        p = p*makeBase(f.xyz);

        // scale
        float scale = 6.6 + 2.0*sin(111.0*f.w);
        p *= scale;
        p.xy *= 1.2;
        
        //translate
        p.z -= 3.0 - length(p.xy)*0.6*sin(f.w*212.1);
            
        // measure distance
        s *= scale;
        #ifdef INTERACTIVE
        float d = sdCapsule( p+vec3(0,0,6), 6.0*fp[i], mix(-40.0,0.42*fp[i],smoothstep(0.0,0.1,fp[i])) );
        #else
        float d = sdCapsule( p, -6.0, 0.42 );
        #endif
        d /= s;

        if( d<dmin )
        {
            if( doColor )
            {
                color.w *= smoothstep(0.0, 5.0/s, dmin-d);

                if( i==0 ) 
                {
                    color.xyz = vec3(0.425,0.36,0.1)*1.1;  // fall
                  //color.xyz = vec3(0.4,0.8,0.1);        // summer
                  //color.xyz = vec3(0.4,0.4,0.8);        // winter
                }

                color.zyx += 0.3*(1.0-sqrt(h))*sin(f.w*1111.0+vec3(0.0,1.0,2.0));
                color.xyz = max(color.xyz,0.0);
            }
            dmin = d;
        }
        else
        {
          color.w *= 0.4*(0.1 + 0.9*smoothstep(0.0, 1.0/s, d-dmin));
        }
    }
    
    return dmin;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos, in float ep )
{
    vec4 kk;
    // prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        // The original logic creates combinations of (+1,-1) for the components of 'e'.
        // This 'if/else if' structure directly assigns the correct vectors without bitwise ops.
        vec3 temp_e;
        if (i==0) temp_e = vec3( 1.0, 1.0, 1.0);
        else if (i==1) temp_e = vec3(-1.0,-1.0, 1.0);
        else if (i==2) temp_e = vec3( 1.0,-1.0,-1.0);
        else /*i==3*/ temp_e = vec3(-1.0, 1.0,-1.0);

        n += 0.5773 * temp_e * map(pos+0.5773*temp_e*ep, kk, false);
    }
    return normalize(n);
}

// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, float tmin, float tmax, const float k )
{
    vec2 bound = sphIntersect( ro, rd, 2.1 );
    tmin = max(tmin,bound.x);
    tmax = min(tmax,bound.y);
    
    float res = 1.0;
    float t = tmin;
    for( int i=0; i<50; i++ )
    {
        vec4 kk;
        float h = map( ro + rd*t, kk, false );
        res = min( res, k*h/t );
        t += clamp( h, 0.02, 0.20 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float raycast(in vec3 ro, in vec3 rd, in float tmin, in float tmax  )
{
    vec4 kk;
    float t = tmin;
    for( int i=0; i<512; i++ )
    {
        vec3 p = ro + t*rd;
        float h = map(p,kk,false);
        if( abs(h)<(0.15*t/iResolution.x) ) break;
        t += h*0.5;
        if( t>tmax ) return -1.0;;
    }
    //if( t>tmax ) t=-1.0;

    return t;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float an = (iTime-10.0)*0.05;
    
    // camera    
    vec3 ro = vec3( 4.5*sin(an), 0.0, 4.5*cos(an) );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera-to-world rotation
    mat3 ca = makeBase( normalize(ta-ro) );

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
        // ray direction
        vec3 rd = ca * normalize( vec3(p.xy,2.2) );
    
        // background
        vec3 col = vec3(0.1,0.14,0.18) + 0.1*rd.y;

        // bounding volume
        vec2 bound = sphIntersect( ro, rd, 2.1 );
        if( bound.x>0.0 )
        {
        // raycast
        float t = raycast(ro, rd, bound.x, bound.y );
        if( t>0.0 )
        {
            // local geometry            
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos, 0.01);
            vec3 upp = normalize(pos);
            
            // color and occlusion
            vec4 mate; map(pos, mate, true);
            
            // lighting            
            col = vec3(0.0);
        
            // key ligh
            {
                // dif
                vec3 lig = normalize(vec3(1.0,0.0,0.7));
                float dif = clamp(0.5+0.5*dot(nor,lig),0.0,1.0);
                float sha = calcSoftshadow( pos+0.0001*nor, lig, 0.0001, 2.0, 6.0 );
                col += mate.xyz*dif*vec3(1.8,0.6,0.5)*1.1*vec3(sha,sha*0.3+0.7*sha*sha,sha*sha);
                // spec
                vec3 hal = normalize(lig-rd);
                float spe = clamp( dot(nor,hal), 0.0, 1.0 );
                float fre = clamp( dot(-rd,lig), 0.0, 1.0 );
                fre = 0.2 + 0.8*pow(fre,5.0);
                spe *= spe;
                spe *= spe;
                spe *= spe;
                col += 1.0*(0.25+0.75*mate.x)*spe*dif*sha*fre;
            }

            // back light
                {
                vec3 lig = normalize(vec3(-1.0,0.0,0.0));
                float dif = clamp(0.5+0.5*dot(nor,lig),0.0,1.0);
                col += mate.rgb*dif*vec3(1.2,0.9,0.6)*0.2*mate.w;
            }

            // dome light
            {
                float dif = clamp(0.3+0.7*dot(nor,upp),0.0,1.0);
                #if 0
                dif *= 0.05 + 0.95*calcSoftshadow( pos+0.0001*nor, upp, 0.0001, 1.0, 1.0 );
                col += mate.xyz*dif*5.0*vec3(0.1,0.1,0.3)*mate.w;
                #else
                col += mate.xyz*dif*3.0*vec3(0.1,0.1,0.3)*mate.w*(0.2+0.8*mate.w);
                #endif
            }
            
            // fake sss
            {
                float fre = clamp(1.0+dot(rd,nor),0.0,1.0);
                col += 0.3*vec3(1.0,0.3,0.2)*mate.xyz*mate.xyz*fre*fre*mate.w;
            }
            
            // grade/sss
            {
                col = 2.0*pow( col, vec3(0.7,0.85,1.0) );
            }
            
            // exposure control
            col *= 0.7 + 0.3*smoothstep(0.0,25.0,abs(iTime-31.0));
            
            // display fake occlusion
            //col = mate.www;
        }
        }
    
        // gamma
        col = pow( col, vec3(0.4545) );
    
        tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    // vignetting
    vec2 q = fragCoord/iResolution.xy;
    tot *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2 );
    
    fragColor = vec4( tot, 1.0 );
}