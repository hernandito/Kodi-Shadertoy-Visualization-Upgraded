precision highp float; // Added precision directive for GLSL ES 1.0

/*
    "Wormholes" by @XorDev
    Tweet: twitter.com/XorDev/status/1601770313230209024
    Twigl: t.co/k5mZbAg1ox
*/

// --- Post-processing functions for better output control (BCS) ---
vec4 saturate(vec4 color, float sat) {
    // Adjusts color saturation
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // Explicit float
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    // Applies brightness, contrast, and saturation adjustments
    color.rgb = (color.rgb - 0.5) * contrast + 0.5; // Explicit float
    color.rgb *= brightness;
    return saturate(color, saturation);
}
// -----------------------------------------------------------------

// --- Post-processing Parameters (BCS) ---
// Adjust these values to fine-tune the final image appearance.
// These are 'const float' values, which means you edit them directly in the code.
const float post_brightness = 0.75; // Controls overall lightness/darkness. Recommended start: 1.0
const float post_contrast   = 1.4; // Controls difference between light/dark areas. Recommended start: 1.0
const float post_saturation = 1.0; // Controls color intensity/purity. Recommended start: 1.0
// ----------------------------------------

// --- Animation Speed Parameter ---
// Adjust this value to control the overall speed of the animation.
// Increase for faster animation, decrease for slower animation.
const float animation_speed = 0.30; // Adjust this value for overall animation speed
// ---------------------------------


void mainImage(out vec4 O, vec2 I)
{
    //Clear frag color
    O *= 0.0; // Explicit float
    //Resolution for scaling
    vec2 r = iResolution.xy;
    //Initialize the iterator and ring distance
    for(float i=0.0,d; // Explicit float
    //Loop 50 times
    i++<50.0; // Explicit float for 5e1
    //Add ring color, with ring attenuation
    O += (cos(i*i+vec4(6.0,7.0,8.0,0.0))+1.0)/(abs(length(I-r*0.5+cos(r*i)*r.y/d+d/0.4)/r.y*d-0.2)+8.0/r.y)*min(d,1.0)/++d/20.0 ) // Explicit floats for all literals, 2e1 = 20.0
        //Compute distance to ring
        d = mod(i-iTime * animation_speed,50.0)+0.01; // Explicit float for 5e1, applied animation_speed
    
    // --- Apply Post-processing (BCS) ---
    O = applyPostProcessing(O, post_brightness, post_contrast, post_saturation);
    // -----------------------------------

    // Final clamp to ensure valid output range
    O = clamp(O, 0.0, 1.0); // Explicit float
}
