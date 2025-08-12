/*

    Mobius Eggs
    -----------

    Pretty standard Mobius transform, followed by a spiral zoom. I've always liked 
    this particular combination, and so do plenty of others, since it's used to
    produce a lot of the interesting geometric pictures you see all over the net.

    This particular example is based off of a couple of snippets I came across in 
    Flexi and Dila's code... I think. I can't quite remember where it came from.
    The rest is just some raytraced, lit spheres. Pretty boring on their own, but 
    made to look more interesting when transformed.
    
    The egg shapes have been created using a cheap trick, which involves swapping
    the log polar transform for a log2 transform... which is not really a thing, but
    it has the desired effect. If you oomment out the "EGG" define, you'll get
    a regular circle pattern -- in the form of raytraced spheres.

    Anyway, the purpose of this was just to show the process. It's possible to make 
    far more interesting things.
    

    // Much simpler, easy to decipher example:
    Logarithmic Mobius Transform - Shane
    https://www.shadertoy.com/view/4dcSWs

    Other examples:

    bipolar complex - Flexi
    https://www.shadertoy.com/view/4ss3DB

    Mobius - dila
    https://www.shadertoy.com/view/MsSSRV

    Moebius Strip - dr2
    https://www.shadertoy.com/view/lddSW2

*/

// Parameters for the deep blood-red color of the main eggs
// The color is now defined as a single vec3.
#define BLOOD_RED_COLOR vec3(0.5, 0.0, 0.0) 

// Metallic properties for the red eggs
// Adjust these values to fine-tune the metallic appearance.
#define METALLIC_DIFFUSE_FACTOR 0.1  // How much diffuse light metals reflect (should be low, 0.0-1.0)
#define METALLIC_SPECULAR_INTENSITY 128.0 // How bright metallic highlights are (higher values for sharper reflections)
#define METALLIC_FRESNEL_STRENGTH 1.0 // How strong the Fresnel effect is for metallic (0.0 to 1.0, 1.0 is strong)


// Basically, we're using a log2 polar transform to distort the perfect
// circles, which uses a log polar transform. Uncommen to see.
#define EGG

// Two PI.
#define TAU 6.2831853

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// 2x2 hash algorithm. Used to add some light sprinkles to the background.
vec2 hash22(vec2 p) {

    // More concise, but wouldn't disperse things as nicely as other versions.
    float n = sin(mod(dot(p, vec2(41, 289)), TAU)); 
    return fract(vec2(8, 1)*262144.*n);

}

// Intersection of a sphere of radius "r".
float trace( in vec3 ro, in vec3 rd, float r){
    
    float b = dot(ro, rd);
    float h = b*b - dot(ro, ro) + r;
    if (h<0.) return -1.;
    return -b - sqrt(h);
    
}

// For all intents and purposes, this is just a grid full of raytraced spheres.
// They look like eggs due to the transform warping. All of it is standard, and
// most is just window dressing, like patterns, lighting, etc.
vec3 scene(vec2 uv){

    
    vec2 oUV = uv;
    // Partition space (the 2D canvas) into an offset hexagon-like grid, 
    // whilst taking angle into account. We're using a hexagon scaling to 
    // space out the raytraced spheres more evenly.
    vec2 sc = vec2(1, 1.732*(6./TAU));
    
    // Grid cell coordinates and ID. Used to color the spheres. In this case, 
    // white or red.
    // A little hacky, but it gets the job done.
    vec2 id = floor(uv/sc);
    uv -= (id + .5)*sc;
    float d = length(uv); // First cell length.
    
    vec2 uv2 = oUV - sc/2.; 
    vec2 id2 = floor(uv2/sc);
    uv2 -= (id2 + .5)*sc;
    float d2 = length(uv2); // Second cell length.
    
    int cellID = 0;
    // Find the closest.
    if(d2<d){
       uv = uv2;
       id = id2 + .5;
       cellID = 1;
    }

    
    // Draw a lit, raytraced sphere in each grid cell. From here it's just boring
    // intersection and lighting stuff.
    
    
    // Ray origin, unit ray and light.
    vec3 ro = vec3(0, 0, -2.4);
    vec3 rd = normalize( vec3(uv, 1.));
    vec3 lp = ro + vec3(cos(iTime), sin(iTime), 0)*4.;
    
    // Sphere intersection.
    float t = trace( ro, rd, 1.);
    
    
    // Dark background.
    vec3 col = vec3(1, .04, .1)*0.003 + length(hash22(uv + 7.31))*.005;
    
    if (t>0.){
        
        
        // Surface point.
        vec3 p = ro + rd*t;
        
        // Normal.
        vec3 n = normalize(p);
        
        // Point light.
        vec3 ld = lp - p;
        float lDist = max(length(ld), 0.001);
        ld /= lDist;

        float diff = max(dot(ld, n), 0.); // Diffuse.
        float spec = pow(max(dot(reflect(ld, n), rd), 0.), 32.); // Specular.
        
        
        // Determine the base color for the current egg
        vec3 baseEggColor = vec3(1, .5, .2); // Default for the other (yellowish) eggs
        bool isRedEgg = false;
        if(mod(id.y + id.x, 2.)<.25) { // This condition identifies the 'red eggs'
            baseEggColor = BLOOD_RED_COLOR; // Set to the desired blood-red
            isRedEgg = true;
        }
        
        // Adding a sinusoidal pattern to the base color
        float c = dot(sin(p*8. + id.xyx - cos(p.zxy*8. + TAU/2. + iTime)), vec3(1)/6.) + .5;
        float f = c*6.;
        c = clamp(sin(c*3.14159*6.)*2., 0., 1.);
        c = (c*.75 + .5); 
        baseEggColor *= c; // Apply pattern to the selected base color

        // Calculate environment reflection (rCol)
        p = reflect(rd, n)*.35;
        c = dot(sin(p*8. - cos(p.zxy*8. + 3.14159)), vec3(.166)) + .5;
        f = c*6.;
        c = clamp(sin(c*3.14159*6.)*2., 0., 1.);
        c = (c*.75 + .25);
        vec3 rCol = vec3(c, c*c, c*c*c); // Reflective color from environment

        // Producing the final lit color based on material properties
        vec3 sCol;
        if(isRedEgg) { 
            // Metallic lighting model for red eggs:
            // Very low diffuse component.
            // High, colored specular component.
            // Environment reflection is tinted by the material color and can be stronger.
            vec3 diffuse_component = baseEggColor * diff * METALLIC_DIFFUSE_FACTOR;
            vec3 specular_component = baseEggColor * spec * METALLIC_SPECULAR_INTENSITY; // Specular highlight is colored by material
            
            // Combine diffuse and specular. Add a small ambient term.
            sCol = diffuse_component + specular_component + baseEggColor * 0.05; // 0.05 is a small ambient light
            
            // Apply environment reflection (rCol) more strongly for metallic
            sCol += baseEggColor * rCol * METALLIC_FRESNEL_STRENGTH; // Environment reflection tinted by material color
        } else {
            // Original lighting for the other (yellowish) eggs:
            // More diffuse, white specular highlight.
            sCol = baseEggColor*(diff*diff*2. + .25 + vec3(1, .7, .4)*spec*32.);
            sCol += baseEggColor*rCol; // Original environment reflection
        }
        
        // Applying attenuation.
        sCol *= 1.5/(1. + lDist*.25 + lDist*lDist*.05);

        // Simple trick to antialias the edges of a raytraced sphere.
        float edge = max(dot(-rd, n), 0.);
        edge = smoothstep(0., .35, edge); // Hardcoding. A bit lazy.
        // Taper between the sphere edge and the background.
        col = mix(col, min(sCol, 1.), edge); 
        
    }
    

    
    // Clamp and perform some rough gamma correction.
    return clamp(col, 0., 1.);
}


// Complex multiply.
vec2 cmul(in vec2 a, in vec2 b){ return mat2(a, -a.y, a.x)*b; }

// Complex divide.
vec2 cdiv(in vec2 a, in vec2 b){ return cmul(a, vec2(b.x,-b.y))/dot(b, b); }

// Complex log polar.
vec2 clog(in vec2 z){ return vec2(log(length(z)), atan(z.y, z.x)); }
// Log2 polar. Not really a thing, but we're using it for distortion.
vec2 clog2(in vec2 z){ return vec2(log2(length(z)), atan(z.y, z.x)); }

// Mobius transform.
vec2 Mobius(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d){

    return cdiv(cmul(z, a) + b, cmul(z, c) + d);
}


/*
// Antialiased circle. The coordinates are mutated, so "fwidth" is used for
// concise, gradient-related, edge smoothing.
float circle(vec2 p) {
    
    p = fract(p) - .5;
    float d = length( p ); return smoothstep(0., fwidth(.4-d)*1.25, .4-d);
}
*/

// Global copy of the spiral center distance fields.
float gV;

// The complex transfor function. In this case, it's a
// Mobius sprial.
vec2 transform(vec2 uv){

    // Transform the screen coordinates.
    vec2 R = vec2(1, 0); // Real axis vector.
    vec2 pos1 = vec2(-iResolution.x/iResolution.y/2.5, 1./4.); // Spiral center one.
    vec2 pos2 = -pos1; // Spiral center two (screen opposite).
    
    // Move the positions a little.
    pos1 += rot2(iTime*.25)*vec2(1, .5)*.1;
    pos1 += rot2(-iTime*.25)*vec2(1, .5)*.1;
    
    // Combined spiral center distance field value, which is Used for 
    // shading at the end.
    float verts = min(length(uv - pos1), length(uv - pos2));
    gV = verts;
    
    // Mobius transform. Two position vectors and two negative real vectors -- 
    // That's how you apply a basic Mobius pattern prior to perfoming a log iTime
    // and spiral move... You're welcome. :D
    uv = Mobius(uv, -R, pos1, -R, pos2); 
    
    // This is how we create the egg shapes. It'd be possible to distort
    // the spheres in other ways, but this is simple. Using a log polar
    // with elongated cells and an actual ellipse trace would be the 
    // "proper" way to do it.
    #ifdef EGG
    uv = clog2(uv); // Log2 polar.
    #else
    uv = clog(uv); // Log polar.
    #endif
    
    
    // Spiral. Push the angle out by one or more units per revolution.
    // This one has been shifted a number of units in order for the
    // dual color spirals to line up.
    //
    // Due to the hexagonal pattern, odd numbers will work. However, I'm 
    // scaling by half as well (which looks more interesting), so only 
    // 3, 7, 11... Half the odd numbers starting from 3, or something like 
    // that. Yeah, math in real life is fiddly and annoying. :D 
    vec2 e = vec2(1, 3./TAU)/2.;
    uv = cmul(uv, e);
    
    // Animating the radial and angular components. Where in the process
    // you do this is up to you, but I'm doing it here.
    uv.x -= iTime*.03;
    uv.y += iTime*.015;
    
    return uv;
    
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Screen coordinates.
    vec2 iRes = iResolution.xy;
    vec2 uv = (2.*fragCoord - iRes.xy)/iRes.y;


    // Perform the Mobius spiral transform.
    uv = transform(uv);
    
    
    // Pass the transformed coordinates into the scene equation. 
    // Uncomment either, or both, or the lines above to see a less 
    // transformed version.
    
    // Draw some repeat lit spheres with the transformed coordinates. Just 
    // the one sphere is rendered, but it's repeated across a 2D grid.
    vec3 col = scene(uv*5.);
    
    // Much, much simpler version with plane circles. One could argue that it 
    // looks better too. :)
    //vec3 col = vec3(circle(uv*4.));
    
    // An interesting alternative. Worth looking at. Requires a wrappable
    // texture to be loaded into channel zero.
    //vec3 col = texture(iChannel0, uv).xyz; // Texture, if desired.
    
    
    // Shade the spiral centers to provide some faux depth.
    col *= vec3(1.1, 1, .9)*clamp(2. - 2./(1. + gV*gV), 0., 1.);
    
    // Apply a vignette and increase the brightness for that fake
    // spotlight effect.
    uv = fragCoord/iResolution.xy;
    col *= pow( 16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y), 1./8.)*1.15;

    // Rough gamma correction.
    fragColor = vec4(sqrt(min(col, 1.)), 1);
    

}