#define PI       3.1415926535
#define SQRT2    1.41421356237
#define SQRT05   0.707106781187

#define maxDist 20.
#define maxStep 100

// =========================================================================
// USER-TUNABLE PARAMETERS
// =========================================================================

// SKY COLOR LIGHTNESS (Based on locked ratio of user's colors)
// Use 1.0 for default brightness. Use values < 1.0 to darken, > 1.0 to brighten.
#define SKY_BRIGHTNESS_SCALE 0.80  

// POST-PROCESSING PARAMETERS (Brightness, Contrast, Saturation)
#define BRIGHTNESS -0.10   // Adjusts overall lightness (-1.0 to 1.0)
#define CONTRAST 1.20      // Adjusts the intensity difference (0.0 to 2.0)
#define SATURATION 1.0     // Adjusts color vividness (0.0 for grayscale, 1.0 for normal)

// =========================================================================
// SIGNED DISTANCE FUNCTION (SDF)
// =========================================================================

float getDist(vec3 p) {

    // parameters :

    float size = 1.;

    int iterations = 5;
    
    vec3 offset = vec3(2.,0.,6.);

    const vec2 k = vec2(0.541196100146, -1.30656296488); 
        
    //

    p.y = abs(p.y);
    
    p.z = - size*0.25 - p.z;

    float incr = 0.2 / float(iterations-1);
    float n = 0.;
            
    for ( int i = 0; i++ < iterations; ) {

        n += incr;
        size *= 0.6 - n;
        
        // fold and rotate xy 8 times
        p.x = abs(p.x);
        p.xy = (p.y < p.x) ? p.xy : p.yx;
        p.xy -= min(dot(p.xy,k),0.)*k;

        //rotate xz by -PI/8.
        p.xz = (p.z + vec2(p.x, -p.x)) * SQRT05; 

        p = abs(p) - offset*size;

    }
    
    // we draw our shape

    p.xy = abs(p.xy);
    p.xy = (p.y < p.x) ? p.xy : p.yx; 
    
    p.x -= 1.25*size;
    
    float roundness = 0.25;
    vec3 q = abs(p) - (vec3(0.75,2.,0.75)-roundness)*size;
    float t2 = (length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0)) - roundness*size;
    
    return t2;

}

// the floor is not included in the sdf,
// but needed for ao computation
float getDistAndFloor(vec3 p) {
    return min(getDist(p), p.z);
}

// custom ambient occlusion
float ao(vec3 p, vec3 n) {
    float range = 0.05;
    float res  = clamp(getDistAndFloor(p + n*range    ) / range * 2. , 0., 1.) * 0.5
               + clamp(getDistAndFloor(p + n*range*2.) / range      , 0., 1.) * 0.3
               + clamp(getDistAndFloor(p + n*range*4.) / range * 0.5, 0., 1.) * 0.2;
    
    vec3 p2 = p*vec3(0.25,0.25,2.);
    float shadowBlob = min(dot(p2,p2),1.);
    return res * min(0.25+0.75*shadowBlob, 1.);
}

// simple raymarching
float rayMarch( vec3 ro, vec3 rd, float tMax ) {

    float t = 0.;
    int i = 0;

    while ( i < maxStep && t < tMax ) {

        float r = abs( getDist( ro + rd*t ) );

        if ( r <= t*0.001 ) break;
        t += r;
        i ++;
    }
    
    return t;
}

// normal approximation
vec3 distance_field_normal(vec3 pos) {
    vec2 eps = vec2(0.0001,0.0);
    float nx = getDist(pos + eps.xyy);
    float ny = getDist(pos + eps.yxy);
    float nz = getDist(pos + eps.yyx);
    return normalize(vec3(nx, ny, nz) - getDist(pos));
}

// the image is rendered here
vec3 render( vec3 ro, vec3 rd ) {
    // parameters :

    const vec3 flrCol  = vec3(.75 );
    const vec3 objCol  = vec3( 0.85 );

    // Base colors (locked ratio based on user's input)
    const vec3 BASE_UPPER = vec3( 0.059, 0.133, 0.678 );
    const vec3 BASE_LOWER = vec3( 0.278, 0.441, 0.761 );

    // Final sky colors scaled by the single brightness factor
    const vec3 skyCol1 = BASE_UPPER * SKY_BRIGHTNESS_SCALE; // up
    const vec3 skyCol2 = BASE_LOWER * SKY_BRIGHTNESS_SCALE; // down

    vec3 lightDir = normalize(vec3(0.1,-0.2,1.));
    
    //        
    
    float floorDist = - ro.z / rd.z;
    float maxDist2  = (floorDist > 0.) ? min(maxDist, floorDist) : maxDist;
    float objDist   = rayMarch( ro, rd, maxDist2 );
            
    if ( floorDist < 0. && objDist > maxDist2 ) {
    
        // sky
        float sun   = rd.z;
        float horiz = pow(max(1.-abs(rd.z),0.),6.0);
        float light = sun + horiz - horiz * sun ;
        return sqrt(mix(skyCol1, skyCol2, light));
        
    } 

    vec3 hit, nor, col;
    float specularity, closestDist;

    if (objDist < maxDist2 && (floorDist < 0. || objDist < floorDist) ) {

        // object
        hit = ro + rd*objDist;
        nor = distance_field_normal(hit);
        col = objCol;
        specularity = 0.25;
        closestDist = objDist;            

    } else {

        // floor
        hit = ro + rd*floorDist;
        nor = vec3(0.,0.,1.);
        col = flrCol;
        specularity = 0.;
        closestDist = floorDist;

    }

    float dot1 = dot(lightDir, nor);
    
    // diffuse light, ambient light, ao
    float diffuse = mix(max(dot1,0.0), dot1*0.5 + 0.5, 0.75) * (ao(hit, nor)*0.95 + 0.05)*0.97 + 0.03;
    
    // specular light
    vec3 reflectDir = reflect(lightDir,nor);
    float specular  = pow (max (dot (rd, reflectDir), 0.0), 10.0);

    vec3 finalCol = ( col + specular*specularity ) * diffuse;
    
    // fog
    finalCol = mix(skyCol2, finalCol, exp(-closestDist*0.005));
    
    // gamma correction
    return pow(finalCol, vec3(1./2.2));
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    vec2 p = (2.0*fragCoord.xy - iResolution.xy) / iResolution.y;
    vec2 m = (2.0*iMouse.xy     - iResolution.xy) / iResolution.y;
    
    
    // camera angle and matrices
    // NOTE: This line was updated per your request
    float ang1 = - iTime*.5 *0.1 + m.x*2. - 0.75; 
    float ang2 = 0.;
    
    vec4 cs  = vec4(cos(ang1),sin(ang1), cos(ang2),sin(ang2));
    mat3 rot = mat3( cs.y,cs.wz*cs.x, cs.x,-cs.wz*cs.y, 0.,cs.z,-cs.w );

    // ray origin and direction
    vec3 rd = normalize( vec3(p,-2.0) )     * rot;
    vec3 ro = vec3( 0., 0., (iMouse.y == 0.) ? 7. : 5.*(1.-m.y) ) * rot;
        
    // camera height
    ro.z += 1.125;
    
    //
    
    vec3 finalCol = render( ro, rd );
    
    // ----------------------------------------------------
    // Apply Brightness, Contrast, Saturation (BCS)
    // ----------------------------------------------------
    
    vec3 col = finalCol;
    
    // 1. Brightness
    col += BRIGHTNESS; 
    
    // 2. Contrast (pivots around 0.5 gray)
    col = (col - 0.5) * CONTRAST + 0.5;
    
    // 3. Saturation (standard luma weights: 0.2126, 0.7152, 0.0722)
    float gray = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(gray), col, SATURATION); 
    
    finalCol = col;
            
    fragColor = vec4( finalCol, 1.);
    
}
