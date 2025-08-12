/*

	Bioorganic Wall
	---------------

	Raymarching a textured XY plane. Basically, just an excuse to try out the new pebbled texture.

*/

// Camera movement speed control
#define CAMERA_SPEED 0.05

// Crevice color adjustments
#define CREVICE_GREEN_INTENSITY 2.9 // Controls green intensity (original value)
#define CREVICE_DESATURATION 5.5   // Controls desaturation (0.0 = original, higher values desaturate)

// Vignette effect controls
#define VIGNETTE_INTENSITY 15.0   // Intensity of vignette
#define VIGNETTE_POWER 1.10       // Falloff curve of vignette

// Effect animation speed control (for texture and light animations)
#define EFFECT_ANIMATION_SPEED 0.0010

// BCS Parameters
#define BRIGHTNESS 0.999   // Base brightness
#define CONTRAST 1.00      // Base contrast
#define SATURATION 0.9     // Base saturation


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
   
    n = max(n*n, 0.001);
    n /= (n.x + n.y + n.z );  
    
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
    
}

// Raymarching a textured XY-plane, with a bit of distortion thrown in.
float map(vec3 p){

    // A bit of cheap, lame distortion for the heaving in and out effect.
    p.xy += sin(p.xy*7. + cos(p.yx*13. + iTime))*.01;
    
    // Back plane, placed at vec3(0., 0., 1.), with plane normal vec3(0., 0., -1).
    // Adding some height to the plane from the texture. Not much else to it.
    return 1. - p.z - texture(iChannel0, p.xy).x*.1;

    
    // Flattened tops.
    //float t = texture(iChannel0, p.xy).x;
    //return 1. - p.z - smoothstep(0., .7, t)*.06 - t*t*.03;
    
}


// Tetrahedral normal, courtesy of IQ.
vec3 getNormal( in vec3 pos )
{
    vec2 e = vec2(0.002, -0.002);
    return normalize(
        e.xyy * map(pos + e.xyy) + 
        e.yyx * map(pos + e.yyx) + 
        e.yxy * map(pos + e.yxy) + 
        e.xxx * map(pos + e.xxx));
}

// Ambient occlusion, for that self shadowed look.
// Based on the original by IQ.
float calculateAO(vec3 p, vec3 n){

   const float AO_SAMPLES = 5.0;
   float r = 1.0, w = 1.0, d0;
    
   for (float i=1.0; i<=AO_SAMPLES; i++){
   
      d0 = i/AO_SAMPLES;
      r += w * (map(p + n * d0) - d0);
      w *= 0.5;
   }
   return clamp(r, 0.0, 1.0);
}

// Cool curve function, by Shadertoy user, Nimitz.
//
// It gives you a scalar curvature value for an object's signed distance function, which 
// is pretty handy for all kinds of things. Here, it's used to darken the crevices.
//
// From an intuitive sense, the function returns a weighted difference between a surface 
// value and some surrounding values - arranged in a simplex tetrahedral fashion for minimal
// calculations, I'm assuming. Almost common sense... almost. :)
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
float curve(in vec3 p){

    const float eps = 0.02, amp = 7., ampInit = 0.5;

    vec2 e = vec2(-1., 1.)*eps; //0.05->3.5 - 0.04->5.5 - 0.03->10.->0.1->1.
    
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    
    return clamp((t1 + t2 + t3 + t4 - 4.*map(p))*amp + ampInit, 0., 1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    
    // Unit directional ray.
    vec3 rd = normalize(vec3(fragCoord - iResolution.xy*.5, iResolution.y*1.5));
    
    
    // Rotating the XY-plane back and forth, for a bit of variance.
    // Compact 2D rotation matrix, courtesy of Shadertoy user, Fabrice Neyret.
    vec2 a = sin(vec2(1.5707963, 0) + sin(iTime * EFFECT_ANIMATION_SPEED)*0.3);
    rd.xy = mat2(a, -a.y, a.x)*rd.xy;
    
    // Ray origin. Moving in the X-direction to the right.
    vec3 ro = vec3(iTime*CAMERA_SPEED*.25, 0., 0.);
    
    
    // Light position, hovering around camera.
    vec3 lp = ro + vec3(cos(iTime * EFFECT_ANIMATION_SPEED)*0.5, sin(iTime * EFFECT_ANIMATION_SPEED)*0.5, 0.);
    
    // Standard raymarching segment. Because of the straight forward setup, very few 
    // iterations are needed.
    float d, t=0.;
    for(int j=0;j<16;j++){
      
        d = map(ro + rd*t); // distance to the function.
        
        // The plane "is" the far plane, so no far plane break is needed.
        if(d<0.001) break; 
        
        t += d*.7; // Total distance from the camera to the surface.
    
    }
    
   
    // Surface postion, surface normal and light direction.
    vec3 sp = ro + rd*t;
    vec3 sn = getNormal(sp);
    vec3 ld = lp - sp;
    
    
    // Retrieving the texel at the surface postion. A tri-planar mapping method is used to iTime
    // give a little extra dimension. The time component is responsible for the texture movement.
    float c = 1. - tex3D(iChannel0, sp*8. - vec3(sp.x, sp.y, iTime * EFFECT_ANIMATION_SPEED + sp.x + sp.y), sn).x;
    
    // Taking the original grey texel shade and colorizing it. Most of the folowing lines are
    // a mixture of theory and trial and error. There are so many ways to go about it.
    //
    vec3 orange = vec3(min(c*1.5, 1.), pow(c, 2.), pow(c, 8.)); // Cheap, orangey palette.
    
    vec3 oC = orange; // Initializing the object (bumpy wall) color.
    
    // Old trick to shift the colors around a bit. Most of the figures are trial and error.
    oC = mix(oC, oC.zxy, cos(rd.zxy*6.283 + sin(sp.yzx*6.283))*.25+.75);
    oC = mix(oC.yxz, oC, (sn)*.5+.5); // Using the normal to colorize.
    
    oC = mix(orange, oC, (sn)*.25+.75);
    oC *= oC*1.5;
    
    // Plain, old black and white. In some ways, I prefer it. Be sure to comment out the above, though.
    //vec3 oC = vec3(pow(c, 1.25)); 
    
    
    // Lighting.
    //
    float lDist = max(length(ld), 0.001); // Light distance.
    float atten = 1./(1. + lDist*.125); // Light attenuation.
    
    ld /= lDist; // Normalizing the light direction vector.
    
    float diff = max(dot(ld, sn), 0.); // Diffuse.
    float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.); // Specular.
    float fre = clamp(dot(sn, rd) + 1., .0, 1.); // Fake fresnel, for the glow.

    
    // Shading.
    //
    // Note, there are no actual shadows. The camera is front on, so the following two 
    // functions are enough to give a shadowy appearance.
    float crv = curve(sp); // Curve value, to darken the crevices.
    float ao = calculateAO(sp, sn); // Ambient occlusion, for self shadowing.

    // Crevice color with adjustable green intensity and desaturation.
    float greenBase = crv * CREVICE_GREEN_INTENSITY;
    vec3 crvC = vec3(crv, greenBase, crv*.7) * (1.0 - min(CREVICE_DESATURATION, 1.0)) + vec3(crv) * min(CREVICE_DESATURATION, 1.0);
    crvC = crvC * .25 + crv * .75;
    crvC *= crvC;
    
    // Combining the terms above to light up and colorize the texel.
    vec3 col = (oC*(diff + .5) + vec3(.5, .75, 1.)*spec*2.) + vec3(.3, .7, 1.)*pow(fre, 3.)*5.;
    // Applying the shades.
    col *= (atten*crvC*ao);

    // Vignette effect
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv *= 1.0 - uv.yx; // Transform UV for vignette
    float vig = uv.x * uv.y * VIGNETTE_INTENSITY;
    vig = pow(vig, VIGNETTE_POWER);
    col *= vig;

    // Apply BCS adjustments
    float luminance = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), col, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    col = contrasted + (BRIGHTNESS - 1.0);
    col = clamp(col, 0.0, 1.0); // Ensure final color is within valid range

    // Presenting to the screen.
	fragColor = vec4(sqrt(max(col, 0.)), 1.);
}