// GLSL ES 1.0 / Shadertoy Cross-Compatible Water Shader
//
// Configuration Defines:
#define USE_TEXTURE 1               // 1 to use iChannel0 texture, 0 for solid medium gray background.
#define FOAM_THICKNESS_CONTROL 0.01 // Controls the line width of the white foam net (Smaller value = thinner line).
#define EFFECT_SCALE 4.0            // Controls the zoom. Increase this value to "zoom out" and see more of the effect.

// New Shadow/Black Net Controls
#define SHADOW_SOFTNESS_MULTIPLIER 3.5 // Multiplier for the black net's blur/softness. 1.0 is sharp. Higher = softer/more blurred.
#define SHADOW_OPACITY 0.08          // Controls the transparency of the black net. 1.0 is fully black
#define SHADOW_HAS_TAPER 1.0        // 1.0 to apply the thinning/tapering noise (like the foam), 0.0 for uniform shadow thickness.

// NEW: Controls how aggressively the faint parts of the shadow disappear. 
// Set to user's preferred value for cleaner taper-off.
#define SHADOW_FADE_POWER 6.20 

precision mediump float;
precision mediump int;

// ------------------------------------------------------------------
// 1. Utility Hash & Voronoi Distance
// ------------------------------------------------------------------

vec2 hash(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(1.0, 57.0)), dot(p, vec2(53.0, 113.0)))) * 43758.5453);
}

vec3 voronoiDistance( in vec2 x )
{
    vec2 p = vec2(floor( x ));
    vec2 f = fract( x );

    vec2 mb;
    vec2 mr;
    float res = 8.0;

    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 b = vec2(float(i), float(j));
        vec2 r = vec2(b) + hash(p+b)-f;
        float d = dot(r,r);

        if( d < res )
        {
            res = d;
            mr = r;
            mb = b;
        }
    }

    res = 8.0;
    
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 b = mb + vec2(float(i), float(j));
        vec2 r = vec2(b) + hash(p+b) - f;
        float d = dot(0.5*(mr+r), normalize(r-mr)); 
        
        if(!(i==0 && j==0)) 
            res = min( res, d );
    }

    // Return the distance component
    return vec3(res); 
}

// ------------------------------------------------------------------
// 2. ES 1.0 Compatible Octave Value Noise 
// ------------------------------------------------------------------

float noise2D_internal(vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    
    // Hash corners
    float a = hash(ip).x;
    float b = hash(ip + vec2(1.0, 0.0)).x;
    float c = hash(ip + vec2(0.0, 1.0)).x;
    float d = hash(ip + vec2(1.0, 1.0)).x;
    
    // Smoothing function (3t^2 - 2t^3)
    vec2 u = fp * fp * (3.0 - 2.0 * fp); 
    
    // Bilinear interpolation
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float perlinNoise(vec2 position, int frequency, int octaveCount, float persistence, float lacunarity, float seed) {
    float total = 0.0;
    float amplitude = 1.0;
    float freq = float(frequency);
    
    position += seed * 0.005;

    // Fixed max loop count for ES 1.0 compatibility
    for (int i = 0; i < 5; i++) { 
        if (i >= octaveCount) break;

        // Shift range from [0, 1] to [-1, 1]
        total += (noise2D_internal(position * freq) * 2.0 - 1.0) * amplitude;

        amplitude *= persistence;
        freq *= lacunarity;
    }
    return total;
}

// Function to calculate the base tapering noise
float getTaperNoise(vec2 uvPerlin, float seedA, float seedB) {
    float noiseA = perlinNoise(abs(uvPerlin), 1, 2, 0.5, 2.0, seedA);
    float noiseB = perlinNoise(abs(uvPerlin), 1, 2, 0.5, 2.0, seedB);
    return min(noiseA, noiseB) * 0.055; 
}


// ------------------------------------------------------------------
// 3. Main Shader Logic
// ------------------------------------------------------------------

// This function calculates line density based on Voronoi distance and tapering noise
float getLineDensity( in vec2 p , float thickness_scale, float noise_value)
{
    float d = voronoiDistance( p ).x; 
    
    // The pre-calculated noise value is subtracted from the distance field
    return max(1.0 - smoothstep(0.001, thickness_scale, d - noise_value), 0.0);
}


// The signature uses 'o' as the output variable for Kodi compatibility.
void mainImage( out vec4 o, in vec2 fragCoord )
{
    // SETTINGS
    vec3 waterColor = vec3(0.2, 0.275, 0.361);    // 0.369, 0.506, 0.671   darkerblue = 0.2, 0.275, 0.361   
    float floorDetail = 0.4;
    
    vec2 uv = fragCoord/iResolution.y;
    
    // Apply EFFECT_SCALE (zoom control)
    vec2 uvWater = EFFECT_SCALE * uv;
    vec2 time = iTime * vec2(-0.3, 0.2);
    
    float offsetWave = sin(1.5 * (uvWater.x * 0.3 - uvWater.y - iTime * 1.1)) * 0.2 + 0.25;
    
    vec2 refractionDir = vec2(0.15, -0.3);
    vec2 uvRefr = uvWater + offsetWave * refractionDir;
    
    vec3 colFloor;
    
    // Conditional Texture Usage and Desaturation
#if USE_TEXTURE
    // Sample texture 
    colFloor = texture(iChannel0, uvRefr - 0.2).xyz; 
    
    // Desaturate the texture to monochrome (Luminance calculation)
    float luminance = dot(colFloor.rgb, vec3(0.299, 0.587, 0.114));
    colFloor.rgb = vec3(luminance);
#else
    // Use a solid medium gray color as the background
    colFloor = vec3(0.5); 
#endif
    
    colFloor.xy += (0.4 - offsetWave) * 0.75;
    
    // --- FIX: Restored original, faster speed (time * 1.0 instead of time * 0.2) ---
    vec2 uvFoam = 2.5 * uvWater + time * 1.0 - vec2(0.0, 0.66) * offsetWave;
    
    // Base Perlin UV coordinates
    vec2 uvPerlin = (uv * 1.25) * (EFFECT_SCALE/3.0) + time * 0.3;
    
    // --- Taper Noise Calculations ---

    // The shadow displacement vector (total offset from uvFoam)
    // NOTE: This expression is mathematically identical to the original code's displacement
    vec2 shadowVoronoiOffset = offsetWave * refractionDir * 1.66 - 0.2;
    
    // The Voronoi field is scaled by 2.5. We must apply the inverse scaling to the Perlin UV coordinates.
    vec2 shadowPerlinDisplacement = shadowVoronoiOffset / 2.5; 
    
    // 1. Foam Taper Noise (Base)
    vec2 uvPerlinFoam = uvPerlin;
    float foamTaperNoise = getTaperNoise(uvPerlinFoam, 107.0, 123.0);
    
    // 2. Shadow Taper Noise (Displaced)
    vec2 uvPerlinShadow = uvPerlin - shadowPerlinDisplacement;
    float shadowTaperNoise = getTaperNoise(uvPerlinShadow, 107.0, 123.0) * SHADOW_HAS_TAPER; 


    // --- Independent Foam and Shadow Calculations ---
    
    // 1. White net (Foam)
    float valFoam = getLineDensity(uvFoam, FOAM_THICKNESS_CONTROL, foamTaperNoise);

    // 2. Black net (Shadow)
    float shadowThicknessControl = FOAM_THICKNESS_CONTROL * SHADOW_SOFTNESS_MULTIPLIER;
    vec2 uvShadow = uvFoam - shadowVoronoiOffset;
    
    float valShadow = getLineDensity(uvShadow, shadowThicknessControl, shadowTaperNoise);
    
    // --- Aggressively fade faint shadow parts (User Preference) ---
    valShadow = pow(valShadow, SHADOW_FADE_POWER);

    // 3. Combine layers
    // Base color + White foam
    o = vec4(valFoam + (1.0 - floorDetail + floorDetail * colFloor) * waterColor, 1.0);
    
    // Apply shadow (the "black net" element) with SHADOW_OPACITY control.
    // valShadow is the amount of shadow, (1.0 - valFoam) ensures shadow is not applied over the white foam.
    o.rgb -= vec3(valShadow * (1.0 - valFoam) * SHADOW_OPACITY);
    
    // Clamp the final color 
    o.rgb = max(o.rgb, 0.0);
}
