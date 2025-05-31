#define MOVEMENT_SPEED 0.1 // Adjust for faster/slower movement
#define MOVEMENT_RANGE 0.0125 // Fraction of screen height for movement (0.0 to 1.0)
#define DITHERING 1        // Set to 1 to enable dithering, 0 to disable
#define BRIGHTNESS -0.05     // Adjust brightness (-1.0 to 1.0)
#define CONTRAST 1.20       // Adjust contrast (0.0 upwards, 1.0 is default)
#define SATURATION 0.850     // Adjust saturation (0.0 to 1.0)

const vec3 tint = vec3(0.01, 0.25, 0.5);

// Random function for dithering
float random(vec2 p) {
    vec2 nf = floor(p);
    return fract(sin(dot(nf, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 changeExposure(vec3 col, vec3 b) {
    b *= col;
    return b/(b-col+1.);
}

vec3 changeExposure(vec3 col, float b) {
    return changeExposure(col, vec3(b));
}

float planet(vec2 p, vec2 offset, float radius) {
    float c = max(0., length(p - offset) - radius);
    float circle = exp2(1.) * exp( -iResolution.x * c );
    float glow =  exp2(1.) * exp( -61.8 * c );
    return mix(circle, glow, 0.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float time = iTime * MOVEMENT_SPEED;
    float screen_aspect = iResolution.x / iResolution.y;
    float vertical_offset_factor = 0.5 * (1.0 - cos(time * 2.0 * 3.14159));
    float vertical_movement = MOVEMENT_RANGE * vertical_offset_factor;
    vec2 sphere_vertical_offset = vec2(0., vertical_movement * 2.0 - MOVEMENT_RANGE);

    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.x;
    float vignette = length(uv-vec2(0.2*cos(time * 0.3), 1.));
    vignette = 1.2*1.5*exp(-1.2*vignette*vignette);

    vec2 planet_uv = (fragCoord-0.5*iResolution.xy)/iResolution.x;
    vec2 offset = sphere_vertical_offset;
    float circle = planet(planet_uv, offset, 1./6.);

    vec2 gradient_uv = fragCoord/iResolution.xy;
    float gradient = exp(-1.5*(1.-gradient_uv.y));

    vec3 col = changeExposure( tint, exp2(1.)*vignette * (1. + circle * 16.*pow(gradient_uv.y, 8.)) );

    // Apply Dithering
    if (DITHERING == 1) {
        vec3 dither_values = vec3(random(fragCoord));
        col += (dither_values - 0.5) / 255.0; // Add small random offset
    }

    // Apply Brightness
    col += BRIGHTNESS;

    // Apply Contrast
    col = (col - 0.5) * CONTRAST + 0.5;

    // Apply Saturation
    vec3 luma = vec3(0.299, 0.587, 0.114);
    float luminance = dot(col, luma);
    col = mix(vec3(luminance), col, SATURATION);

    fragColor = vec4(col,1.0);
}