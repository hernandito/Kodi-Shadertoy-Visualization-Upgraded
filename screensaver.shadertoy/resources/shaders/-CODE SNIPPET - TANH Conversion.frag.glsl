
I have a new Shadertoy shader that I need to make compatible with Kodi's Shadertoy addon. The addon only suports OpenGL ES 1.0. The below shader code uses tanh statements that dont work with Kodi. You have succesfully converted tanh shader in the past by using the below Tanh Conversion Method directive. Please apply this method to the below code.


"The Robust Tanh Conversion Method" (Updated Definition)
When you say: "Please apply the Robust Tanh Conversion Method to this shader," I'll know to:

    Include the tanh_approx function:
        Add the robust vec4 tanh_approx(vec4 x) { const float EPSILON = 1e-6; return x / (1.0 + max(abs(x), EPSILON)); } function at the top of the shader.
    Replace tanh() calls:
        Change any tanh(value) calls in the shader to tanh_approx(value).
    Ensure Explicit Variable Initialization:
        Crucially, go through all declared variables (e.g., float, vec2, vec3, vec4s) and explicitly initialize them to appropriate default values (e.g., 0.0, vec4(0.0)) before their first use or before they are accumulated. This prevents undefined behavior common in minified GLSL code.

    Enhance General Division Robustness:
        Identify any divisions X / Y within the shader's core logic (especially in accumulation steps or distance calculations) and replace them with X / max(Y, 1E-6) (or a suitable small epsilon) to prevent NaN (Not a Number) or Inf (Infinity) issues when Y approaches zero.

NEW SHADER CODE:




    Convert iTime to iChannelTime[0]:
        Replace all instances of iTime with iChannelTime[0] for compatibility with host environments like Kodi.
###############################################################################

For a successful tanh conversion without artifacts, you can refer to it as:

"The Robust Tanh Conversion Method"

When you say: "Please apply the Robust Tanh Conversion Method to this shader," I'll know to:

    Include the tanh_approx function (vec4 tanh_approx(vec4 x) { return x / (1.0 + abs(x)); }).
    Replace any tanh() calls with tanh_approx().
    Most importantly, carefully adjust the scaling (division) of the values going into tanh_approx to prevent artifacts, and ensure robustness against division by zero with max(value, epsilon).

This phrase encapsulates the key elements that have proven successful in resolving those artifact issues for you.

CONVERSION EXAMPLES:

 From our experience, we can spend a long time making adjustments without good results. After the Robust method above, it was always the first version of the converted code that worked.Below I will give you before and after codes for a couple of succesful conversion shaders. Please do note on some of the codes, we added other adjustments after the conversion for things like animation speed, camera, BCS, colros, etc. Theseadditional adjustments can be ignored.


ANGRY CLOUD SHADER - BEFORE:

// I originally saw this noise function in Elsio's shaders

// It's explained a bit here

// https://www.shadertoy.com/view/WcXGRM

// And it's really nicely on display here

// https://www.shadertoy.com/view/M3yBWK


// It has a neat effect when used without diffuse lighting

// It looks like a cloud or fluffy smoke thing


// Hold down lmb to make it angrier :D


#define T (iTime * 1.8)

#define m iMouse

vec3 path(float zd) {

    float t = T * 5.;

    return vec3(

        tanh(cos(t * .08) * 1.) * 5.3,

        tanh(cos(t * .05) * 4.) * 1.3,

        zd + T + tanh(cos(T * zd / 20.) * zd / 2.) * zd * .5);

}

   

void mainImage(out vec4 o, in vec2 u) {

    vec2 r = iResolution.xy; 

         u = (u - r.xy / 2.) / r.y;

    vec3 p,

         ro = vec3(0.,0.,T),

         la = path(6.3);

    vec3 laz = normalize(la - ro),

         lax = normalize(cross(laz, vec3(0., -1., 0))),

         lay = cross(lax, laz);

    vec3 rd = vec3(u, 1.) * mat3(-lax, lay, laz) * .1;

    float d = 0., od1;

    for (float i = 0.; i < 100.; i++) {

        p = ro + rd * d;


        od1 = length(p - la) - 1.3;


        float hit = od1;

        hit = min(hit, 4. - length(p.y - ro.y));

       

        float n = 0.;

        for (float a = .2; a < 8.;

            n -= abs(dot(sin(p * a * 4.), vec3( .08))) / a,

            a += a);

        float s = hit + n;

        

        d += s;

        if (d > 100. || s < .01) {

            break;

        }

    }

    float f = abs(tanh(cos(T*1.)*13.)) +

                          sin(T*2.)+cos(T*1.)+sin(T*.5)

                          *.04+sin(T);

    vec3 l = clamp(vec3(1./f),vec3(.5),vec3(5.));

    vec3 rgb = m.z > 40. ?

               vec3(l/od1) : vec3(1.);

    rgb *= vec3(.4, .3, .2);

    o = vec4(pow(

        vec3(rgb*d/(od1*30.)), vec3(.45)), 1.)

        - dot(u,u)*.2;

}


ANGRY CLOUD SHADER - AFTER:

// I originally saw this noise function in Elsio's shaders

// It's explained a bit here

// https://www.shadertoy.com/view/WcXGRM

// And it's really nicely on display here

// https://www.shadertoy.com/view/M3yBWK


// It has a neat effect when used without diffuse lighting

// It looks like a cloud or fluffy smoke thing


// Hold down lmb to make it angrier :D


// --- Animation Speed Control ---

// Adjusts the overall speed of the animation.

// 1.0 is normal speed, values > 1.0 make it faster, < 1.0 make it slower.

#define ANIMATION_SPEED .20


#define T (iTime * 1.8 * ANIMATION_SPEED) // iTime is now scaled by ANIMATION_SPEED

#define m iMouse


// --- Post-Processing BCS Parameters (Adjust these for final image look) ---

#define BRIGHTNESS -0.450         // Adjusts the overall brightness. 0.0 is no change, positive values brighten, negative values darken.

#define CONTRAST 1.7           // Adjusts the overall contrast. 1.0 is no change, values > 1.0 increase contrast, < 1.0 decrease.

#define SATURATION 1.0         // Adjusts the overall saturation. 1.0 is no change, values > 1.0 increase saturation, < 1.0 decrease.

#define MAX_WHITE_VALUE 0.8 // Add this line. Adjust 1.0 to your desired maximum white (e.g., 0.8 for less intense whites).


// --- Robust Tanh Conversion Method ---

// Approximation of tanh(x)

// The denominator 1.0 + abs(x) ensures robustness against division by zero.

float tanh_approx(float x) {

    return x / (1.0 + abs(x));

}


// Helper function to apply scaled tanh_approx.

// The scale_factor is crucial for mimicking the saturation behavior of the original tanh.

float scaled_tanh_approx(float x, float scale_factor) {

    return tanh_approx(x * scale_factor);

}

// --- End Robust Tanh Conversion Method ---


/**

 * @brief Defines the path for the camera/light source.

 * This function now uses the `tanh_approx` function with carefully chosen

 * scaling factors to mimic the original `tanh` behavior for Kodi compatibility.

 *

 * @param zd A depth-related parameter that influences the path.

 * @return A vec3 representing a point in 3D space for the path.

 */

vec3 path(float zd) {

    float t = T * 5.; // T already incorporates ANIMATION_SPEED

    return vec3(

        // Original: tanh(cos(t * .08) * 1.) * 5.3

        // Input to tanh is in [-1, 1]. scaled_tanh_approx with factor ~3.2 matches tanh(1).

        scaled_tanh_approx(cos(t * .08) * 1., 3.2) * 5.3,

        // Original: tanh(cos(t * .05) * 4.) * 1.3

        // Input to tanh is in [-4, 4]. Use a larger scale factor to push towards saturation.

        scaled_tanh_approx(cos(t * .05) * 4., 5.0) * 1.3,

        // Original: zd + T + tanh(cos(T * zd / 20.) * zd / 2.) * zd * .5

        // Input to tanh is around [-3.15, 3.15]. Use a larger scale factor for saturation.

        zd + T + scaled_tanh_approx(cos(T * zd / 20.) * zd / 2., 5.0) * zd * .5);

}


/**

 * @brief Applies Brightness, Contrast, and Saturation adjustments to a color.

 *

 * @param color The input RGB color.

 * @param brightness The brightness adjustment.

 * @param contrast The contrast adjustment.

 * @param saturation The saturation adjustment.

 * @return The adjusted RGB color.

 */

vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {

    // Apply brightness

    color += brightness;


    // Apply contrast

    // Midpoint for contrast adjustment is 0.5 (gray).

    color = ((color - 0.5) * contrast) + 0.5;


    // Apply saturation

    // Convert to grayscale (luminance)

    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));

    // Interpolate between grayscale and original color based on saturation

    color = mix(vec3(luminance), color, saturation);


    return color;

}

     

/**

 * @brief The main shader entry point.

 *

 * This function calculates the final color for each pixel on the screen,

 * simulating a raymarching effect through a noise field.

 * Post-processing BCS adjustments are applied as a final step.

 *

 * @param o The output color of the pixel.

 * @param u The screen-space coordinate of the current pixel.

 */

void mainImage(out vec4 o, in vec2 u) {

    vec2 r = iResolution.xy; 

    // Normalize fragment coordinates to [-aspect_ratio/2, aspect_ratio/2] range

    u = (u - r.xy / 2.) / r.y;


    vec3 p,

         ro = vec3(0.,0.,T), // Ray origin, moving along Z-axis with time (scaled by ANIMATION_SPEED)

         la = path(6.3);    // Look-at target, determined by the path function


    // Calculate camera basis vectors

    vec3 laz = normalize(la - ro); // Z-axis (forward)

    vec3 lax = normalize(cross(laz, vec3(0., -1., 0))); // X-axis (right)

    vec3 lay = cross(lax, laz); // Y-axis (up)


    // Ray direction based on normalized fragment coordinates and camera basis

    vec3 rd = vec3(u, 1.) * mat3(-lax, lay, laz) * .1;


    float d = 0., od1; // d: current distance, od1: distance to target sphere


    // Raymarching loop

    for (float i = 0.; i < 100.; i++) {

        p = ro + rd * d; // Current point along the ray


        od1 = length(p - la) - 1.3; // Distance to a sphere centered at 'la' with radius 1.3


        float hit = od1;

        // Limit the raymarch by the vertical distance from the ray origin

        hit = min(hit, 4. - length(p.y - ro.y));

         

        float n = 0.;

        // Apply a noise function based on 'p'

        // This loop generates a sum of absolute sine waves at different frequencies,

        // creating a cloud-like effect.

        for (float a = .2; a < 8.;

            n -= abs(dot(sin(p * a * 4.), vec3( .08))) / a,

            a += a);

        

        float s = hit + n; // Combined distance field value

         

        d += s; // Advance the ray by the step 's'

        // Break conditions: if ray goes too far or step size is too small (hit a surface)

        if (d > 100. || s < .01) {

            break;

        }

    }


    // Calculate 'f' based on time and a highly saturated tanh approximation

    // Original: abs(tanh(cos(T*1.)*13.))

    // Input to tanh is in [-13, 13]. This requires a significantly larger scale factor

    // to approximate the strong saturation of tanh for large inputs.

    float f = abs(scaled_tanh_approx(cos(T*1.)*13., 20.0)) +

              sin(T*2.)+cos(T*1.)+sin(T*.5)

              *.04+sin(T); // T already incorporates ANIMATION_SPEED


    // Clamp 'l' (light intensity factor) based on 'f'

    vec3 l = clamp(vec3(1./f),vec3(.5),vec3(5.));


    // Determine base RGB color based on mouse button state

    // If left mouse button is held down (m.z > 40.0), use 'l/od1' for a more "angry" look,

    // otherwise use vec3(1.) (white).

    vec3 rgb = m.z > 40. ?

               vec3(l/od1) : vec3(1.);

    

    // Apply a base color tint

    rgb *= vec3(.4, .3, .2);


    // Final color calculation: power function for gamma correction/contrast,

    // and a vignette effect based on fragment distance from center.

    vec3 finalColor = pow(vec3(rgb * d / (od1 * 30.)), vec3(.45));


    // --- Apply Post-Processing: Brightness, Contrast, Saturation ---

    finalColor = applyBCS(finalColor, BRIGHTNESS, CONTRAST, SATURATION);


    // Apply vignette

    finalColor -= dot(u,u)*.2;


    finalColor = clamp(finalColor, 0.0, MAX_WHITE_VALUE);


    // Output the final color

    o = vec4(finalColor, 1.);

}


HYPERSPACE 2 SHADER _ BEFORE:

/*

    "Hyperspace 2" by @XorDev

    

    https://x.com/XorDev/status/1929956178454311413

*/

void mainImage(out vec4 O, vec2 I)

{

    //Time for animation

    float t = iTime,

    //Raymarch iterator

    i,

    //Raymarched depth

    z,

    //Raymarch step distance

    d,

    //Signed distance for coloring

    s;

    //Clear fragcolor and raymarch 10 steps

    for(O *= i; i++<1e1;)

    {

        //Resolution for centering and scaling

        vec3 r = iResolution,

        //Centered coordinates

        c = vec3(I + I, 0) - r,

        //Raymarched sample point

        p = z*normalize(c);

        

        //Minified turbulence loop

        //https://mini.gmshaders.com/p/turbulence

        for(d=6.; d<2e2; d+=d)

            p += sin(p.yzx*d-t)/d;

        

        //Distance to top and bottom

        z += d = .005+abs(s=.3-abs(p.y))/4.;

        

        //Radial gradient

        O += tanh(length(c)*2./r.y)*

        //Coloring

        (cos(s/.1+p.x/.2+t-vec4(6,1,2,3)-3.)+1.5)/d;

    }

    //Tanh tonemapping

    O = tanh(O*O/1e6);

}


HYPERSPACE 2 SHADER - AFTER:

/*

    "Hyperspace 2" by @XorDev

    

    

    WEB LINK:  https://www.shadertoy.com/view/wfcSDn

    

    https://x.com/XorDev/status/1929956178454311413

*/

precision mediump float; // Required for GLSL ES 1.00


// Robust Tanh Conversion Method: tanh_approx function for vec4

// Denominator 1.0 + abs(x) is inherently robust against division by zero.

vec4 tanh_approx(vec4 x) {

    return x / (1.0 + abs(x));

}


// Scalar version for float inputs

float tanh_approx_scalar(float x) {

    return x / (1.0 + abs(x));

}


// --------------------------------------

// Robust Tanh Conversion Parameters

// Adjust these to fine-tune the approximation's behavior.

// --------------------------------------

// Scaling factor for the input to the first tanh_approx (radial gradient).

// A value > 1.0 will push the input values further, making the tanh_approx

// output closer to 1.0 (more saturated/clamped) for large inputs, similar to original tanh.

// Start at 1.0 and adjust (e.g., 1.0 to 3.0) if radial banding or lack of intensity is observed.

#define FIRST_TANH_INPUT_SCALE 1.5 


// Denominator for the tonemapping tanh_approx (originally 1e6).

// This value controls the overall brightness and contrast of the final tonemapped image.

// A larger value will make the image darker and more compressed (more aggressive tonemapping).

// A smaller value will make it brighter and less compressed.

// Original was 1,000,000.0, adjust as needed if the final image is too dark/bright or lacking contrast.

#define TONEMAP_DENOMINATOR 1000000.0 // (Original 1e6)



// --------------------------------------

// Dither Effect Parameters

// --------------------------------------

// Pseudo-random number generator for dithering

float hash22(vec2 p) {

    p = fract(p * vec2(123.45, 678.90));

    p += dot(p, p + 45.67);

    return fract(p.x * p.y);

}


// Strength of the dither effect.

// Typical values for 8-bit displays are 1.0/255.0 to 4.0/255.0.

// Adjust this to reduce banding without introducing excessive noise.

#define DITHER_STRENGTH (2.0 / 255.0) // A good starting point, adjust as needed


void mainImage(out vec4 O, vec2 I)

{

    //Time for animation

    float t = iTime*0.2;

    

    //Raymarched depth (initialized to 0.0 for robustness in GLSL ES 1.00)

    float z = 0.0;

    //Raymarch step distance

    float d;

    //Signed distance for coloring

    float s;

    

    // Clear fragcolor (O) and initialize loop.

    // Original: for(O *= i; i++<1e1;) - This is highly compact but problematic for GLSL ES 1.00

    // Fix: Explicitly initialize O and use a standard for loop.

    O = vec4(0.0);

    for(int i = 0; i < 10; ++i) // Loop runs 10 times (from 0 to 9)

    {

        //Resolution for centering and scaling

        vec3 r = iResolution.xyz; // Ensure r is a vec3 for consistency with c

        //Centered coordinates

        vec3 c = vec3(I + I, 0.0) - r; // Explicit 0.0 for float

        //Raymarched sample point

        vec3 p = z*normalize(c);

        

        //Minified turbulence loop

        // Standard loop initialization for GLSL ES 1.00.

        // d is reused as loop counter here, as in the original compact shader.

        for(d = 6.0; d < 200.0; d += d) // Explicit floats for 6.0 and 200.0 (original 2e2)

            p += sin(p.yzx*d-t)/d;

        

        //Distance to top and bottom

        z += d = 0.005 + abs(s = 0.3 - abs(p.y)) / 4.0; // Explicit floats

        

        //Radial gradient

        // Replaced tanh() with tanh_approx_scalar() and applied FIRST_TANH_INPUT_SCALE

        O += tanh_approx_scalar(length(c) * 2.0 / r.y * FIRST_TANH_INPUT_SCALE) * // Explicit 2.0 for float

        //Coloring

        (cos(s / 0.1 + p.x / 0.2 + t - vec4(6.0, 1.0, 2.0, 3.0) - 3.0) + 1.5) / d; // Explicit floats

    }

    

    // Tanh tonemapping

    // Replaced tanh() with tanh_approx() and used TONEMAP_DENOMINATOR

    O = tanh_approx(O * O / TONEMAP_DENOMINATOR);


    // --------------------------------------

    // Apply Dither Effect

    // --------------------------------------

    // Generate pseudo-random noise based on pixel coordinates and time

    // Time component ensures the dither pattern slowly animates, preventing static noise artifacts.

    float dither_value = (hash22(gl_FragCoord.xy + iTime * 0.01) - 0.5) * DITHER_STRENGTH;

    O.rgb += dither_value; // Add dither to the RGB channels

    

    // Final output color, clamped to 0-1 range to prevent over-exposure/under-exposure after dither

    gl_FragColor = vec4(clamp(O.rgb, 0.0, 1.0), 1.0); // Assuming gl_FragColor for Kodi output

} 