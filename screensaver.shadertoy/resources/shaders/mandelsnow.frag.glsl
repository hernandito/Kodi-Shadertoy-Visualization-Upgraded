precision highp float;

// Animation parameters from original COMMON tab
const float maxIters = 30.0;
const float animCycleFreq = 0.07;
const float cMovementExponent = 8.0;
const float iterOscillateExponent = 1.4;
const float brightnessFreq = 0.24;
const float pi = 3.14159265359;
const float tau = 6.28318530718;
const float scale = 0.9; // Screen scaling (1.0 = default, <1.0 zooms in, >1.0 zooms out)

// Post-processing BCS parameters
#define BRIGHTNESS 0.0 // Adjust brightness (-0.2 to 0.2, 0.0 = default)
#define CONTRAST 1.20   // Adjust contrast (0.8 to 1.2, 1.0 = default)
#define SATURATION 1.0 // Adjust saturation (0.5 to 1.5, 1.0 = default)

// Hash function from BUFFER A
float hash14(vec4 p4)
{
    p4 = fract(p4 * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.x + p4.y) * (p4.z + p4.w));
}

const int SAMPLES = 3;
#define ITERBIAS 0.9
#define DITHER
const float phi = 2.0 / (1.0 + sqrt(5.0));

// Globals
vec2 C;
float currentMaxIters, brightness;

vec2 cSquare(vec2 z)
{
    return vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y);
}

float orbitTrap(vec2 point)
{
    point.y = abs(point.y);
    return max(point.x, dot(point, vec2(-0.5, 0.5 * sqrt(3.0))));
}

vec3 image(highp vec2 fragCoord)
{
    vec2 z = scale * 1.3 * (2.0 * fragCoord - iResolution.xy)
           / min(iResolution.x, iResolution.y);

    float minOrbitDist = 1e5;
    float iter;
    for (iter = 0.0; iter < floor(currentMaxIters); iter += 1.0)
    {
        z = cSquare(z) + C;
        float orbitDist = orbitTrap(z);
        
        if (orbitDist > 10.0)
            break;

        #ifdef ITERBIAS
            orbitDist *= pow(ITERBIAS, iter);
        #endif
        
        minOrbitDist = min(minOrbitDist, orbitDist);
    }
    
    if (fract(currentMaxIters) > 0.0)
    {
        z = cSquare(z) + C;
        float orbitDist = orbitTrap(z);
        
        #ifdef ITERBIAS
            orbitDist *= pow(ITERBIAS, iter);
        #endif
        
        minOrbitDist = mix(minOrbitDist, min(minOrbitDist, orbitDist),
                           fract(currentMaxIters));
    }

    float intensity = 1.0 / (minOrbitDist + 1.0);
    
    #ifdef ITERBIAS
        brightness *= ITERBIAS;
    #endif
    
    intensity = mix(intensity, 
                    intensity * intensity * (3.0 - 2.0 * intensity), brightness);
    
    vec3 exponents = vec3(8.0, 4.0, 1.0); // Ice blue
    
    #ifdef ITERBIAS
        exponents /= ITERBIAS;
    #endif

    return pow(vec3(intensity), exponents);
}

void mainImage(out vec4 fragColor, in highp vec2 fragCoord)
{
    float cycle = animCycleFreq * iTime;
    float oscillate = 0.5 - 0.5 * cos(cycle * tau);
    oscillate = pow(oscillate, iterOscillateExponent);
    currentMaxIters = 1.0 + (maxIters - 1.0) * oscillate;
    
    brightness = 0.5 - 0.5 * cos(brightnessFreq * iTime * tau);

    // Simulate RANDTEXEL with a slow-changing seed
    float randVal = hash14(vec4(floor(iTime * 0.01), 0.0, 0.0, 0.0)); // Changes every 100s

    float movement = 2.0 * fract(max(cycle, 0.5)) - 1.0;
    movement = 0.5 * sign(movement) * pow(abs(movement), cMovementExponent);
    
    float theta = 4.0 * phi * (floor(cycle) + movement) + 0.01 * iTime
                + randVal * tau;
    
    float sinPhase = mod(theta / pi + 1.0, 2.0) - 1.0;
    sinPhase = sign(sinPhase) * pow(abs(sinPhase), 0.7);
    theta += 0.7 * sin(pi * sinPhase);
    
    float r = 0.6 - 0.5 * cos(theta);
    C = r * vec2(cos(theta), sin(theta));
    C.x += 0.25; // Fixed offset, no mouse

    highp vec3 color = vec3(0.0);
    if (SAMPLES > 1 && abs(fragCoord.x - 0.5 * iResolution.x) / iResolution.x < 0.375)
    {
        for (int i = 0; i < SAMPLES; i++)
        {
            float theta = float(i) * (tau / float(SAMPLES));
            highp vec2 offset = 0.25 * vec2(cos(theta), sin(theta));
            color += image(fragCoord + offset);
        }
        color /= float(SAMPLES);
    }
    else
    {
        color = image(fragCoord);
    }
    
    // Apply BCS post-processing
    #ifdef DITHER
        // Store original color for dithering
        highp vec3 origColor = color;
    #endif
    
    // Brightness
    color += BRIGHTNESS;
    
    // Contrast
    color = (color - 0.5) * CONTRAST + 0.5;
    
    // Saturation
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(lum), color, SATURATION);
    
    // Clamp to valid range
    color = clamp(color, 0.0, 1.0);
    
    #ifdef DITHER
        // Use original color for dithering to avoid quantizing BCS effects
        const float steps = 255.0;
        highp vec3 substep = fract(origColor * steps);
        color = floor(origColor * steps) / steps;
        
        highp vec2 noiseUV = mod(fragCoord, vec2(256.0)) / vec2(256.0);
        highp vec3 threshold = vec3(texture(iChannel0, noiseUV).r);
        
        color += vec3(greaterThan(substep, threshold)) / steps;
        
        // Reapply BCS after dithering
        color += BRIGHTNESS;
        color = (color - 0.5) * CONTRAST + 0.5;
        float lumPost = dot(color, vec3(0.299, 0.587, 0.114));
        color = mix(vec3(lumPost), color, SATURATION);
        color = clamp(color, 0.0, 1.0);
    #endif
    
    fragColor = vec4(color, 1.0);
}