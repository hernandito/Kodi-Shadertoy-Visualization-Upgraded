#define BRIGHTNESS 0.80
#define CONTRAST 2.50
#define SATURATION 0.230
#define PAPER_BASE_COLOR vec3(0.463, 0.467, 0.49) // #97989c

// Paper Noise Parameters
#define PAPER_NOISE_INTENSITY 0.3 // Adjust this value to control the visibility/strength of the noise
#define PAPER_NOISE_SCALE .50      // Adjust this value to control the size/frequency of the noise grains

// --------------------------------------
// Paper Noise Functions
// --------------------------------------
vec2 hash2(vec2 p) {
    return fract(sin(vec2(
        dot(p, vec2(127.1, 311.7)),
        dot(p, vec2(269.5, 183.3))
    )) * 43758.5453);
}

vec3 applyPaperNoise(vec3 color, vec2 uv, float intensity, float scale) {
    vec2 noise = (hash2(uv * scale) - 0.5) * 0.15;
    float noiseVal = (noise.x + noise.y) * 0.5;
    return color + intensity * noiseVal;
}

// --------------------------------------
// Main Shader Logic
// --------------------------------------
vec2 f(vec2 x, float t) {
    return vec2(cos(x.x+sin(t*3.0))+x.y+sin(t*2.)/2.0+0.5, sin(x.y+t+sin(t*5.))+x.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-iResolution.xy/2.0)/iResolution.y*30.+vec2(50, 0);
    vec2 x = uv;
    for(int i = 0; i < 10; i++) {
        x = f(x, iTime/15.0);
    }

    float t = length(x)/100.0;
    vec3 original_effect_color = pow(vec3(t), vec3(.994545, 0.9545, 0.08545));

    // Blend the original effect color with the paper base color.
    vec3 final_color = mix(PAPER_BASE_COLOR, original_effect_color, 0.7); // Adjust this mix factor further if needed

    // Compute UVs for the paper noise, normalized to [0,1]
    vec2 noise_uv = fragCoord.xy / iResolution.xy;

    // Apply the paper noise texture using the new user-adjustable parameters
    final_color = applyPaperNoise(final_color, noise_uv, PAPER_NOISE_INTENSITY, PAPER_NOISE_SCALE);

    fragColor = vec4(final_color, 1.0);

    // Apply BCS
    vec3 bcs_color = fragColor.rgb;

    // Saturation
    float luma = dot(bcs_color, vec3(0.2126, 0.7152, 0.0722));
    bcs_color = mix(vec3(luma), bcs_color, SATURATION);

    // Contrast
    bcs_color = ((bcs_color - 0.5) * CONTRAST) + 0.5;

    // Brightness
    bcs_color *= BRIGHTNESS;

    fragColor = vec4(bcs_color, fragColor.a);
}