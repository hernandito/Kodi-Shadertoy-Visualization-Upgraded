// Copyright Inigo Quilez, 2017 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work in any form,
// including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it.
// I share this Work for educational purposes, and you can link to it,
// through an URL, proper attribution and unmodified screenshot, as part
// of your educational material. If these conditions are too restrictive
// please contact me and we'll definitely work it out.


// Code for the making of this video:
// https://www.youtube.com/watch?v=aNR4n0i2ZlM


// --- BCS (Brightness, Contrast, Saturation) Post-Processing Parameters ---
// Adjust these values to modify the final image appearance.
// BRIGHTNESS: Adds or subtracts from the color (e.g., 0.1 for brighter, -0.1 for darker)
#define BRIGHTNESS 0.1
// CONTRAST: Scales the color around a midpoint of 0.5 (e.g., 1.2 for more contrast, 0.8 for less)
#define CONTRAST 1.4
// SATURATION: Interpolates between grayscale and original color (e.g., 1.5 for more vivid, 0.5 for desaturated)
#define SATURATION 1.0
// -----------------------------------------------------------------------

// --- Background Control Parameters ---
// BACKGROUND_BASE_COLOR: Base color of the background (dark blue/grey default)
#define BACKGROUND_BASE_COLOR vec3(0.2, 0.2, 0.4)
// BACKGROUND_BRIGHTNESS_SCALE: Overall brightness multiplier for the background
#define BACKGROUND_BRIGHTNESS_SCALE 0.7
// BACKGROUND_VIGNETTE_STRENGTH: Controls the intensity of the radial darkening effect towards the edges
#define BACKGROUND_VIGNETTE_STRENGTH 0.5
// -------------------------------------------------------------------

// --- Light Parameters ---
// MAIN_LIGHT_POS: Position of the primary light source in 3D space
#define MAIN_LIGHT_POS vec3(3.0, 4.0, 4.0)
// AMBIENT_LIGHT_COLOR: Constant color added to the diffuse illumination (general scene light)
#define AMBIENT_LIGHT_COLOR vec3(0.2, 0.2, 0.4)
// RIM_LIGHT_COLOR: Color of the rim/backlight effect
#define RIM_LIGHT_COLOR vec3(0.2, 0.1, 0.1)
// RIM_LIGHT_STRENGTH: Multiplier for the intensity of the rim/backlight effect
#define RIM_LIGHT_STRENGTH 3.0
// ------------------------

// --- Functions for Morphing Object (from original shader) ---
float sdSphere(vec3 p, float r )
{
  return length(p) - r;
}

float hash1( vec2 p ) // Overloaded hash1 for vec2
{
    p  = 50.0*fract( p*0.3183099 );
    return fract( p.x*p.y*(p.x+p.y) );
}

float hash1( float n ) // Original hash1 for float
{
    return fract( n*17.0*fract( n*0.3183099 ) );
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    #if 1
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    #else
    vec3 u = w*w*(3.0-2.0*w);
    #endif
    

    float n = 111.0*p.x + 317.0*p.y + 157.0*p.z;
    
    float a = hash1(n+(  0.0+  0.0+  0.0));
    float b = hash1(n+(111.0+  0.0+  0.0));
    float c = hash1(n+(  0.0+317.0+  0.0));
    float d = hash1(n+(111.0+317.0+  0.0));
    float e = hash1(n+(  0.0+  0.0+157.0));
    float f = hash1(n+(111.0+  0.0+157.0));
    float g = hash1(n+(  0.0+317.0+157.0));
    float h = hash1(n+(111.0+317.0+157.0));

    float k0 =    a;
    float k1 =    b - a;
    float k2 =    c - a;
    float k3 =    e - a;
    float k4 =    a - b - c + d;
    float k5 =    a - c - e + g;
    float k6 =    a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);
}
const mat3 m3  = mat3( 0.00,  0.80,  0.60,
                      -0.80,  0.36, -0.48,
                      -0.60, -0.48,  0.64 );
float fbm_4( in vec3 x )
{
    float f = 2.0;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    for( int i=0; i<4; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m3*x;
    }
    return a;
}
float fbm_2( in vec3 x )
{
    float f = 2.0;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    for( int i=0; i<2; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m3*x;
    }
    return a;
}

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }
float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}
    
float map(vec3 p){
    float s;

    float s1 =sdSphere(p+vec3(1.0,0.1,0.0), 1.7*(sin(iTime+p.x)*0.105+1.0));
    float s2 =sdSphere(p+vec3(-1.0,0.0,0.1), 1.8*(sin(iTime+p.x+1.0)*0.105+1.0));
    s = opSmoothUnion(s1,s2,0.5);
    
    vec3 noiseP =p*0.7;

    float n =smoothstep(-0.2,1.0,fbm_4(noiseP*2.0+fbm_4(noiseP*2.0)*1.5))*0.1;
    s-=n;
    
    float skin = smoothstep(0.5,1.0,1.0-n*5.0);
    s+=skin*smoothstep(-1.0,1.0,fbm_2(noiseP*50.0)*fbm_2(noiseP*4.0))*0.02;

    return s;
}

vec4 getColor(vec3 p){
    vec3 noiseP =p*0.7;
    float n1=abs(fbm_2(noiseP*1.0));
    
    float n =smoothstep(-0.2,1.0,fbm_4(noiseP*2.0+fbm_4(noiseP*2.0)*1.5));
    vec3 base1 = mix(vec3(0.2,0,0.1),vec3(0.9,0.2,0.3),vec3(n));
    vec3 lum = vec3(0.299, 0.587, 0.114);
    vec3 gray = vec3(dot(lum, base1));
    vec4 color =vec4(0,0,0,0);
    color.xyz = mix(base1, gray, vec3(pow(n1,2.0)));
    color.w =40.0;
    float s = smoothstep(0.2,0.4,n);
    color.w -=s*20.0;
    color.xyz+=vec3(s)*vec3(0.7,0.7,0.4)*0.5;
    return color;
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005; // epsilon
    float r = 1.; // radius of sphere
    return normalize(
      e.xyy * map(p + e.xyy) +
      e.yyx * map(p + e.yyx) +
      e.yxy * map(p + e.yxy) +
      e.xxx * map(p + e.xxx));
}

float rayMarch(vec3 ro, vec3 rd, float start, float end) {
    float depth = start;

    for (int i = 0; i < 100; i++) {
        vec3 p = ro + depth * rd;
        
        float d =map(p);
        
        depth += d;
        if (d < 0.001 || depth > end) break;
    }

    return depth;
}
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    float ph = 1e10; // big, such that y = 0 on the first iteration
    
    for( int i=0; i<16; i++ )
    {
        float h = map( ro + rd*t );

        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, 10.0*d/max(0.0,t-y) );
        ph = h;
        
        t += h;
        
        if( res<0.0001 || t>tmax ) break;
        
    }
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =           ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    float time =sin( iTime*0.2)*0.2+1.3;
    // camera    
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    vec3 ro = ta + vec3( 10.0*cos(time ), 0, 10.0*sin(time ) );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;


    // focal length
    const float fl = 3.5;
            
    // ray direction
    vec3 rd = ca * normalize( vec3(p,fl) );

    vec3 col = vec3(0);


    float d = rayMarch(ro, rd, 0., 100.);    

    if (d > 100.0)    
    {
        // Original background calculation, now controlled by #define parameters
        col = BACKGROUND_BASE_COLOR * BACKGROUND_BRIGHTNESS_SCALE * (1.0 - pow(length(p) * BACKGROUND_VIGNETTE_STRENGTH, 2.0));
    }    
    else    
    {
        vec3 pos = ro + rd * d; // point on sphere we discovered from ray marching
        vec3 N = calcNormal(pos);
        vec4 colin = getColor(pos);
        vec3 albedo = colin.xyz;
        vec3 lightpos = MAIN_LIGHT_POS; // Using new define for main light position
        vec3 L = normalize(lightpos - pos);
        
        float shadow = calcSoftshadow(pos,L, 0.01, 3.0);
        // Using new define for ambient light color
        vec3 irr = vec3(max(0.0,dot(N,L))*2.0)*shadow + AMBIENT_LIGHT_COLOR;
        col =irr*albedo;
        
        vec3  ref = reflect(rd,N);             
        float fre = clamp(1.0+dot(N,rd),0.0,1.0);
        float spe = (colin.w/15.0)*pow( clamp(dot(ref,L),0.0, 1.0), colin.w )*2.0*(0.5+0.5*pow(fre,42.0));
        col += spe*shadow;
        
        // Rim/Backlight (now active and controlled by defines)
        col += vec3(pow(1.0+dot(rd,N),2.0)) * RIM_LIGHT_COLOR * RIM_LIGHT_STRENGTH;

    }

    // --- Apply BCS (Brightness, Contrast, Saturation) adjustments ---
    col += BRIGHTNESS;
    col = (col - 0.5) * CONTRAST + 0.5;
    float luma = dot(col, vec3(0.299, 0.587, 0.114)); // Calculate luminance
    col = mix(vec3(luma), col, SATURATION); // Mix between grayscale and original color
    // -----------------------------------------------------------------

    // Ensure color values remain within valid range [0, 1] after adjustments
    col = clamp(col, 0.0, 1.0);

    // Output to screen
    fragColor = vec4(col, 1.0);
}
