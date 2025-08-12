#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))

float cube(vec3 p, vec3 c)
{
    return length(max(abs(p)-c,0.));
}

//Signed Distance Function? / SDF
float scene(vec3 p)
{
    float period= 1.5;
    vec3 id = floor(p/period);
    
    p.xy *= rot(sin(iTime*.06 + id.z*0.2));
    
    p = mod(p, period)-period*0.5;//modulo
    
    
    float d = cube(p, vec3(0.25));
    d = max(d, -(length(p)-0.3));
    return d;
    
}

// --- NEW PARAMETERS ---
// Adjust these values to change the 'black' and 'white' points of the shader's gradient.
#define SHADER_BLACK_COLOR vec3(0.0, 0.0, 0.250) // Adjusted black color (RGB)
#define SHADER_WHITE_COLOR vec3(1.0, 1.0, 1.0) // Default white (RGB)
// --- END NEW PARAMETERS ---

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 main_uv = (2.0 * fragCoord-iResolution.xy)/iResolution.y; // Renamed to avoid conflict with vignette uv

    vec3 ro = vec3(0.0,0.0,-1.0), rd = normalize(vec3(main_uv,1.0)),p=ro,
    col = SHADER_BLACK_COLOR; // Initialize color to the defined black color
    bool hit = false;
    float iteration;
    
    for (float i=0.0; i<100.0; i++)
    {
        float d = scene(p); //distance which is our scene
        if(d< 0.001)
        {
            hit = true;
            iteration = i/60.0; // iteration goes from ~0 to ~1 (when i is ~60)
            break;
        }
        
        p+= d*rd;
    }
    if(hit)
    {
        // Mix between the defined black and white colors.
        // 1.0 - iteration will be close to 1.0 for early hits (more white)
        // and close to 0.0 for later hits (more black).
        col = mix(SHADER_BLACK_COLOR, SHADER_WHITE_COLOR, 1.0 - iteration);
    }

    // --- Vignette Effect ---
    // Simply paste the below code at the end of the shader to add a vignette effect.
    vec2 vignette_uv = fragCoord.xy / iResolution.xy; // Separate UV for vignette calculation
    vignette_uv *= 1.0 - vignette_uv.yx; // Transform UV for vignette
    float vignetteIntensity = 25.0; // Intensity of vignette
    float vignettePower = 0.60; // Falloff curve of vignette
    float vig = vignette_uv.x * vignette_uv.y * vignetteIntensity;
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
    // --- End Vignette Effect ---

    // Output to screen
    fragColor = vec4(col,1.0);
}