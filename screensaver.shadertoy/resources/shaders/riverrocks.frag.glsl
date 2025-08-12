// --- Post-processing Parameters ---
// Adjust brightness (1.0 is default, >1.0 brighter, <1.0 darker)
#define BRIGHTNESS .70
// Adjust contrast (1.0 is default, >1.0 more contrast, <1.0 less contrast)
#define CONTRAST 1.4
// Adjust saturation (1.0 is default, >1.0 more saturated, <1.0 desaturated)
#define SATURATION 1.3

// Adjust overall animation speed (1.0 is default, >1.0 faster, <1.0 slower)
#define ANIMATION_SPEED .2

// Texture offset for iChannel0 mapping to shift seams
// Adjust these values (e.g., 0.0 to 1.0) to shift the texture origin.
// A value of 0.5 will center the texture, potentially moving the seam to the edges.
#define TEXTURE_OFFSET_X 0.5 
#define TEXTURE_OFFSET_Y 0.5 

#define time (iTime * ANIMATION_SPEED) // Global time variable, now affected by ANIMATION_SPEED

// uniform sampler2D iChannel0; // Removed as per user instruction.
// The shader relies on the environment providing iChannel0 implicitly.

float sfract(float n)
{
    return smoothstep(0.0,1.0,fract(n));
}

float rand(vec2 n)
{
    return fract(abs(sin(dot(n,vec2(5.3357,-5.8464))))*256.75+0.325);    
}

float noise(vec2 n)
{
    float h1 = mix(rand(vec2(floor(n.x),floor(n.y))),rand(vec2(ceil(n.x),floor(n.y))),sfract(n.x));
    float h2 = mix(rand(vec2(floor(n.x),ceil(n.y))),rand(vec2(ceil(n.x),ceil(n.y))),sfract(n.x));
    float s1 = mix(h1,h2,sfract(n.y));
    return s1;
}

void doCamera( out vec3 camPos, out vec3 camTar, in float current_time, in float mouseX )
{
    vec2 dir = ((iMouse.xy/iResolution.xy)*vec2(1.0,-0.5)+vec2(0.0,0.75))*6.28;
    vec3 pos = vec3(0.0,0.5,0.0);//vec3(noise((current_time/32.0)*vec2(1.0,0.0)),0.05,noise((current_time/32.0)*vec2(0.0,1.0)))*20.0;
    camPos =  pos;//vec3(cos(current_time/4.0)*8.0,1.0,sin(current_time/4.0)*8.0);
    camTar = pos+vec3(cos(dir.x)*cos(dir.y),sin(dir.y),sin(dir.x)*cos(dir.y));
}

vec3 doBackground( in vec3 dir)
{
    float sky = dot(dir,vec3(0.0,-1.0,0.0))*0.5+0.5;
    float sun = pow(dot(dir,normalize(vec3(1.0,0.7,0.9)))*0.5+0.5,32.0);
    vec2 p = vec2(dir.x+dir.z,dir.y-dir.z);
    float clouds = noise(p*8.0)*noise(p*9.0)*noise(p*10.0)*noise(p*11.0)*sky;
    vec3 total = vec3(sky*0.6+0.05+sun+clouds,sky*0.8+0.075+pow(sun,1.5)+clouds,sky+0.2+pow(sun,4.0)+clouds);
    
    // Original texture mapping: (dir.xz)/dir.y
    // Apply offset to the texture coordinates *after* division to shift the tiling seam
    vec2 tex_coords = (dir.xz)/dir.y + vec2(TEXTURE_OFFSET_X, TEXTURE_OFFSET_Y);
    // Removed .rrr and *vec3(1.1,1.0,0.9) to remove image processing effect
    vec3 ground = texture(iChannel0, tex_coords).rgb; 
    
    return mix(total,ground,clamp((sky-0.6)*64.0,0.0,1.0));
}
    
float doModel( vec3 pos )
{
    // 'time' is already defined as iTime * ANIMATION_SPEED
    vec3 p = pos+vec3(time*0.2,0.0,0.0)+vec3(noise(pos.xz),0.0,noise(pos.xz+8.0))*0.2;//Distort coordinates
    float height = 0.1*pow(noise(p.xz+vec2(time*0.7,time*0.6))*0.5+noise(p.xz*8.0+vec2(time))*0.35+noise(p.xz*16.0+vec2(0.0,time*0.5))*0.1+noise(p.xz*24.0)*0.05,0.25);
    float model = p.y-height;
    return model;
}

vec3 doMaterial(in vec3 rd, in vec3 nor )
{
    vec3 ref = doBackground(reflect(rd,nor));
    return mix(doBackground(refract(rd,nor,0.8)),ref,clamp(dot(ref,vec3(1.0/3.0))*1.5,0.0,1.0));
}

float calcSoftshadow( in vec3 ro, in vec3 rd );

vec3 doFog( in vec3 rd, in float dis, in vec3 mal )
{
    vec3 col = mal;
    col = mix(doBackground(rd),col,1.0-clamp(dis*dis/90.0,0.0,1.0));

    return col;
}

float calcIntersection( in vec3 ro, in vec3 rd )
{
    const float maxd = 10.0;            // max trace distance
    const float precis = 0.001;         // precission of the intersection
    float h = precis*2.0;
    float t = 0.0;
    float res = -1.0;
    for( int i=0; i<90; i++ )           // max number of raymarching iterations is 90
    {
        if( h<precis||t>maxd ) break;
        h = doModel( ro+rd*t );
        t += h*.8;
    }

    if( t<maxd ) res = t;
    return res;
}

vec3 calcNormal( in vec3 pos )
{
    const float eps = 0.002;             // precision of the normal computation

    const vec3 v1 = vec3( 1.0,-1.0,-1.0);
    const vec3 v2 = vec3(-1.0,-1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0,-1.0);
    const vec3 v4 = vec3( 1.0, 1.0, 1.0);

    return normalize( v1*doModel( pos + v1*eps ) + 
                      v2*doModel( pos + v2*eps ) + 
                      v3*doModel( pos + v3*eps ) + 
                      v4*doModel( pos + v4*eps ) );
}

float calcSoftshadow( in vec3 ro, in vec3 rd )
{
    float res = 1.0;
    float t = 0.5;                      // selfintersection avoidance distance
    float h = 1.0;
    for( int i=0; i<40; i++ )           // 40 is the max numnber of raymarching steps
    {
        h = doModel(ro + rd*t);
        res = min( res, 64.0*h/t );    // 64 is the hardness of the shadows
        t += clamp( h, 0.02, 2.0 );    // limit the max and min stepping distances
    }
    return clamp(res,0.0,1.0);
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (-iResolution.xy + 2.0*fragCoord.xy)/iResolution.y;
    vec2 m = iMouse.xy/iResolution.xy;
    
    // camera movement
    vec3 ro, ta;
    doCamera( ro, ta, iTime, m.x ); // iTime is passed directly here as per original code

    // camera matrix
    mat3 camMat = calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll
    
    // create view ray
    vec3 rd = normalize( camMat * vec3(p.xy,2.0) ); // 2.0 is the lens length

    vec3 col = doBackground(rd);

    // raymarch
    float t = calcIntersection( ro, rd );
    if( t>-0.5 )
    {
        // geometry
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);

        // materials
        vec3 mal = doMaterial(rd, nor );

        col = doFog( rd, t, mal );
    }
    // gamma
    col = pow( clamp(col,0.0,1.0), vec3(0.4545) );
    
    // --- Post-processing: Brightness, Contrast, Saturation ---
    // Apply Brightness
    col += (BRIGHTNESS - 1.0);

    // Apply Contrast
    col = ((col - 0.5) * CONTRAST) + 0.5;

    // Apply Saturation
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(luma), col, SATURATION);

    fragColor = vec4( col, 1.0 );
}
