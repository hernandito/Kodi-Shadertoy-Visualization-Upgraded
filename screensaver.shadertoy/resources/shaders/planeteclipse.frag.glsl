// --- Planet Zoom Animation Controls ---
// Minimum scale value for the planet (e.g., 0.5 for smaller)
#define MIN_PLANET_SCALE 0.3 
// Maximum scale value for the planet (e.g., 1.5 for larger)
#define MAX_PLANET_SCALE .145 
// Speed of the zoom in/out animation (e.g., 0.5 for slower, 2.0 for faster)
#define ZOOM_SPEED .05 

// --- iChannel0 Texture Post-processing Parameters ---
// Adjust brightness for the iChannel0 texture (1.0 is default, >1.0 brighter, <1.0 darker)
#define TEXTURE_BRIGHTNESS 0.8
// Adjust contrast for the iChannel0 texture (1.0 is default, >1.0 more contrast, <1.0 less contrast)
#define TEXTURE_CONTRAST 1.4
// Adjust saturation for the iChannel0 texture (1.0 is default, >1.0 more saturated, <1.0 desaturated)
#define TEXTURE_SATURATION 1.0

void mainImage(out vec4 O,vec2 I)
{
    I -= .5*iResolution.xy; //Center
    O -= O;

    // --- Calculate animated planet scale ---
    // Get a value oscillating between 0.0 and 1.0
    float t_zoom = (sin(iTime * ZOOM_SPEED) + 1.0) * 0.5;
    // Apply smoothstep for ease-in/ease-out motion
    float eased_t_zoom = smoothstep(0.0, 1.0, t_zoom);
    // Interpolate between min and max scale values
    float animated_planet_scale = mix(MIN_PLANET_SCALE, MAX_PLANET_SCALE, eased_t_zoom);

    // The planet's size is controlled by the division of 'I'.
    // To make the planet larger, we divide the original scaling factor (300.0) by animated_planet_scale.
    float scaled_I_divisor = 300.0 / animated_planet_scale;

    // Sample iChannel0 texture
    vec4 sampled_texture_raw = texture(iChannel0, iTime/100.0 //Scrolling texture - converted 1e2 to 100.0
                                    +.6/(O += 1.-O+sqrt(max(1.-dot(I/=scaled_I_divisor,I),0.))).x*I);

    vec3 sampled_texture_rgb = sampled_texture_raw.rgb;

    // Apply BCS adjustments to the sampled texture ONLY
    // Brightness
    sampled_texture_rgb += (TEXTURE_BRIGHTNESS - 1.0);

    // Contrast
    sampled_texture_rgb = ((sampled_texture_rgb - 0.5) * TEXTURE_CONTRAST) + 0.5;

    // Saturation
    float luma = dot(sampled_texture_rgb, vec3(0.2126, 0.7152, 0.0722));
    sampled_texture_rgb = mix(vec3(luma), sampled_texture_rgb, TEXTURE_SATURATION);

    // Reconstruct the output color O with the adjusted texture
    O = mix(vec4(sampled_texture_rgb, sampled_texture_raw.a) * // Use adjusted RGB, keep original alpha
            max(I.x*.3+I.y*.9+--O*.1+.5,.1), //Lighting
            vec4(0.82,.3,.1,1)/dot(I,I),--O*O); //Radiant light
}
