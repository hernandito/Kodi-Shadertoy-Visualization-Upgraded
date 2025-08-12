precision mediump float; // Set default precision for floats

// --- UNIFORMS (Removed explicit declarations for Kodi compatibility) ---
// iResolution, iTime, and iChannel0 are assumed to be implicitly available
// in OpenGL ES 1.0 environments like Kodi's Shadertoy addon.

/*

    Bumped Sinusoidal Warp
    ----------------------

    Sinusoidal planar deformation, or the 2D sine warp effect to people
    like me. The effect has been around for years, and there are
    countless examples on the net. IQ's "Sculpture III" is basically a
    much more sophisticated, spherical variation.

    This particular version was modified from Fabrice's "Plop 2," which in
    turn was a simplified version of Fantomas's "Plop." I simply reduced
    the frequency and iteration count in order to make it less busy.

    I also threw in a texture, added point-lit bump mapping, speckles...
    and that's pretty much it. As for why a metallic surface would be
    defying   the laws of physics and moving like this is anyone's guess. :)

    By the way, I have a 3D version, similar to this, that I'll put up at
    a later date.
    

    Related examples:

    Fantomas - Plop
    https://www.shadertoy.com/view/ltSSDV

    Fabrice - Plop 2
    https://www.shadertoy.com/view/MlSSDV

    IQ - Sculpture III (loosely related)
    https://www.shadertoy.com/view/XtjSDK

    Shane - Lit Sine Warp (far less code)
    https://www.shadertoy.com/view/Ml2XDV

*/

// --- GLOBAL PARAMETERS ---
#define ANIMATION_SPEED 0.2 // Controls the overall animation speed (1.0 = normal speed)

// --- POST-PROCESSING DEFINES (BCS) ---
#define BRIGHTNESS 0.90    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.2      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.10    // Saturation adjustment (1.0 = neutral)


// Warp function. Variations have been around for years. This is
// almost the same as Fabrice's version:
// Fabrice - Plop 2
// https://www.shadertoy.com/view/MlSSDV
vec2 W(vec2 p){
    
    p = (p + 3.0)*4.0; // Explicitly 3.0f, 4.0f

    float t = iTime * ANIMATION_SPEED / 2.0; // Apply ANIMATION_SPEED here, Explicitly 2.0f

    // Layered, sinusoidal feedback, with time component.
    for (int i=0; i<3; i++){ // Explicitly 3
        p += cos(p.yx*3.0 + vec2(t, 1.57))/3.0; // Explicitly 3.0f, 1.57f, 3.0f
        p += sin(p.yx + t + vec2(1.57, 0.0))/2.0; // Explicitly 1.57f, 0.0f, 2.0f
        p *= 1.3; // Explicitly 1.3f
    }

    // A bit of jitter to counter the high frequency sections.
    p +=  fract(sin(p+vec2(13.0, 7.0))*5e5)*0.03 - 0.015; // Explicitly 13.0f, 7.0f, 0.03f, 0.015f

    return mod(p, 2.0) - 1.0; // Range: [vec2(-1), vec2(1)], Explicitly 2.0f, 1.0f
    
}

// Bump mapping function. Put whatever you want here. In this case,
// we're returning the length of the sinusoidal warp function.
float bumpFunc(vec2 p){

    return length(W(p))*0.7071; // Range: [0, 1], Explicitly 0.7071f

}

/*
// Standard ray-plane intersection.
vec3 rayPlane(vec3 p, vec3 o, vec3 n, vec3 rd) {
    
    float dn = dot(rd, n);

    float s = 1e8;
    
    if (abs(dn) > 0.0001) {
        s = dot(p-o, n) / dn;
        s += float(s < 0.0) * 1e8;
    }
    
    return o + s*rd;
}
*/

vec3 smoothFract(vec3 x){ x = fract(x); return min(x, x*(1.0-x)*12.0); } // Explicitly 1.0f, 12.0f

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Screen coordinates.
    vec2 uv = (fragCoord - iResolution.xy*0.5)/max(iResolution.y, 1e-6); // Robust division, Explicitly 0.5f
    
    
    // PLANE ROTATION
    //
    // Rotating the canvas back and forth. I don't feel it adds value, in this case,
    // but feel free to uncomment it.
    //float th = sin(iTime*0.1)*sin(iTime*0.12)*2.;
    //float cs = cos(th), si = sin(th);
    //uv *= mat2(cs, -si, si, cs);
    

    // VECTOR SETUP - surface postion, ray origin, unit direction vector, and light postion.
    //
    // Setup: I find 2D bump mapping more intuitive to pretend I'm raytracing, then lighting a bump mapped plane
    // situated at the origin. Others may disagree. :)
    vec3 sp = vec3(uv, 0.0); // Surface posion. Hit point, if you prefer. Essentially, a screen at the origin. // Explicitly 0.0f
    vec3 rd = normalize(vec3(uv, 1.0)); // Unit direction vector. From the origin to the screen plane. // Explicitly 1.0f
    vec3 lp = vec3(cos(iTime * ANIMATION_SPEED)*0.5, sin(iTime * ANIMATION_SPEED)*0.2, -1.0); // Light position - Back from the screen. // Apply ANIMATION_SPEED, Explicitly 0.5f, 0.2f, -1.0f
    vec3 sn = vec3(0.0, 0.0, -1.0); // Plane normal. Z pointing toward the viewer. // Explicitly 0.0f, 0.0f, -1.0f

    
/*
    // I deliberately left this block in to show that the above is a simplified version
    // of a raytraced plane. The "rayPlane" equation is commented out above.
    vec3 rd = normalize(vec3(uv, 1));
    vec3 ro = vec3(0, 0, -1);

    // Plane normal.
    vec3 sn = normalize(vec3(cos(iTime)*.25, sin(iTime)*.25, -1));
    //vec3 sn = normalize(vec3(0, 0, -1));
    
    vec3 sp = rayPlane(vec3(0), ro, sn, rd);
    vec3 lp = vec3(cos(iTime)*.5, sin(iTime)*.25, -1);
*/    
    
    // BUMP MAPPING - PERTURBING THE NORMAL
    //
    // Setting up the bump mapping variables. Normally, you'd amalgamate a lot of the following,
    // and roll it into a single function, but I wanted to show the workings.
    //
    // f - Function value
    // fx - Change in "f" in in the X-direction.
    // fy - Change in "f" in in the Y-direction.
    vec2 eps = vec2(4.0/max(iResolution.y, 1e-6), 0.0); // Robust division, Explicitly 4.0f, 0.0f
    
    float f = bumpFunc(sp.xy); // Sample value multiplied by the amplitude.
    float fx = bumpFunc(sp.xy - eps.xy); // Same for the nearby sample in the X-direction.
    float fy = bumpFunc(sp.xy - eps.yx); // Same for the nearby sample in the Y-direction.
    
      // Controls how much the bump is accentuated.
    const float bumpFactor = 0.05; // Explicitly 0.05f
    
    // Using the above to determine the dx and dy function gradients.
    fx = (fx - f)/max(eps.x, 1e-6); // Robust division
    fy = (fy - f)/max(eps.x, 1e-6); // Robust division
    // Using the gradient vector, "vec3(fx, fy, 0)," to perturb the XY plane normal ",vec3(0, 0, -1)."
    // By the way, there's a redundant step I'm skipping in this particular case, on account of the
    // normal only having a Z-component. Normally, though, you'd need the commented stuff below.
    //vec3 grad = vec3(fx, fy, 0);
    //grad -= sn*dot(sn, grad);
    //sn = normalize(sn + grad*bumpFactor );
    sn = normalize(sn + vec3(fx, fy, 0.0)*bumpFactor); // Explicitly 0.0f
    // Equivalent to the following.
    //sn = cross(-vec3(1, 0, fx*bumpFactor), vec3(0, 1, fy*bumpFactor));
    //sn = normalize(sn);
    
    
    // LIGHTING
    //
    // Determine the light direction vector, calculate its distance, then normalize it.
    vec3 ld = lp - sp;
    float lDist = max(length(ld), 0.0001); // Explicitly 0.0001f
    ld /= max(lDist, 1e-6); // Robust division

    // Light attenuation.
    float atten = 1.0/(1.0 + lDist*lDist*0.15); // Explicitly 1.0f, 1.0f, 0.15f
    //float atten = min(1./(lDist*lDist*1.), 1.);
    
    // Using the bump function, "f," to darken the crevices. Completely optional, but I
    // find it gives extra depth.
    atten *= f*0.9 + 0.1; // Or... f*f*.7 + .3; //  pow(f, .75); // etc. // Explicitly 0.9f, 0.1f

    

    // Diffuse value.
    float diff = max(dot(sn, ld), 0.0); // Explicitly 0.0f
    // Enhancing the diffuse value a bit. Made up.
    diff = pow(diff, 4.0)*0.66 + pow(diff, 8.0)*0.34; // Explicitly 4.0f, 0.66f, 8.0f, 0.34f
    // Specular highlighting.
    float spec = pow(max(dot( reflect(-ld, sn), -rd), 0.0), 12.0); // Explicitly 0.0f, 12.0f
    //float spec = pow(max(dot(normalize(ld - rd), sn), 0.), 32.);
    
    
    // TEXTURE COLOR
    //
    // Combining the surface postion with a fraction of the warped surface position to index
    // into the texture. The result is a slightly warped texture, as a opposed to a completely
    // warped one. By the way, the warp function is called above in the "bumpFunc" function,
    // so it's kind of wasteful doing it again here, but the function is kind of cheap, and
    // it's more readable this way.
    vec3 texCol = texture2D(iChannel0, sp.xy + W(sp.xy)/8.0).xyz; // Explicitly 8.0f, Changed texture to texture2D
    texCol *= texCol; // Rough sRGB to linear conversion... That's a whole other conversation. :)
    // A bit of color processing.
    texCol = smoothstep(0.05, 0.75, pow(texCol, vec3(0.75, 0.8, 0.85))); // Explicitly 0.05f, 0.75f, 0.75f, 0.8f, 0.85f
    
    // Textureless. Simple and elegant... so it clearly didn't come from me. Thanks Fabrice. :)
    //vec3 texCol = smoothFract( W(sp.xy).xyy )*.1 + .2;
    
    
    
    // FINAL COLOR
    // Using the values above to produce the final color.
    vec3 col = (texCol*(diff*vec3(1.0, 0.97, 0.92)*2.0 + 0.5) + vec3(1.0, 0.6, 0.2)*spec*2.0)*atten; // Explicitly 1.0f, 0.97f, 0.92f, 2.0f, 0.5f, 1.0f, 0.6f, 0.2f, 2.0f
    
    // Faux environment mapping: I added this in at a later date out of sheer boredome, and
    // because I like shiny stuff. You can comment it out if it's not to your liking. :)
    float ref = max(dot(reflect(rd, sn), vec3(1.0)), 0.0); // Explicitly 1.0f, 0.0f
    col += col*pow(ref, 4.0)*vec3(0.25, 0.5, 1.0)*3.0; // Explicitly 4.0f, 0.25f, 0.5f, 1.0f, 3.0f
    
    // Rough gamma correction.
    vec3 finalColor = sqrt(clamp(col, 0.0, 1.0)); // Explicitly 0.0f, 1.0f

    // --- Apply BCS adjustments ---
    // Brightness
    finalColor += (BRIGHTNESS - 1.0);

    // Contrast
    finalColor = (finalColor - 0.5) * CONTRAST + 0.5; // Explicitly 0.5f, 0.5f

    // Saturation
    float luminance = dot(finalColor, vec3(0.2126, 0.7152, 0.0722)); // Standard Rec. 709 luminance
    vec3 grayscale = vec3(luminance);
    finalColor = mix(grayscale, finalColor, SATURATION);

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0); // Clamp final color to [0, 1] range, Explicitly 0.0f, 1.0f, 1.0f
}
