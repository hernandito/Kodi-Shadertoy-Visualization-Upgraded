//
//   Vignette Effect 
//   Simply paste the below code at the end of the shader to add a vignette effect.
//


// Vignette effect
vec2 uv = fragCoord.xy / RESOLUTION.xy;
uv *= 1.0 - uv.yx; // Transform UV for vignette
float vignetteIntensity = 25.0; // Intensity of vignette
float vignettePower = 0.60; // Falloff curve of vignette
float vig = uv.x * uv.y * vignetteIntensity;
vig = pow(vig, vignettePower);

// Apply dithering to reduce banding
const float ditherStrength = 0.05; // Strength of dithering (0.0 to 1.0)
int x = int(mod(fragCoord.x, 2.0));
int y = int(mod(fragCoord.y, 2.0));
float dither = 0.0;
if (x == 0 && y == 0) dither = 0.25 * ditherStrength;
else if (x == 1 && y == 0) dither = 0.75 * ditherStrength;
else if (x == 0 && y == 1) dither = 0.75 * ditherStrength;
else if (x == 1 && y == 1) dither = 0.25 * ditherStrength;
vig = clamp(vig + dither, 0.0, 1.0);

col *= vig; // Apply vignette by multiplying the color



/* void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
   
    uv *=  1.0 - uv.yx;   //vec2(1.0)- uv.yx; -> 1.-u.yx; Thanks FabriceNeyret !
    
    float vig = uv.x*uv.y * 35.0; // multiply with sth for intensity
    
    vig = pow(vig, 0.10); // change pow for modifying the extend of the  vignette

    
    fragColor = vec4(vig); 
}

*/