#define  PI      3.14159265359
#define  _2_PI   6.28318530718

// Post-processing parameters
#define BRIGHTNESS .90
#define CONTRAST   1.30
#define SATURATION 1.0

vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( _2_PI*(c*t+d) );
}

vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    // Brightness
    color += brightness - 1.0;
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    // Saturation
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2.5*fragCoord - iResolution.xy) / iResolution.y;

    vec3 result;
    float t = iTime*.05;
    float d = length(p);
    
    float phi = 5./(d+0.2) + t * sin(t);
    float intensity = 0.1 * sqrt(pow(1./abs(sin(phi)), 2.) - 1.);
    
    // Custom implementation of the round function, as it's not supported in OpenGL ES 1.0
    int index = int(floor(phi / PI + 0.5));

    // Lighting from the rings
    intensity = clamp(intensity, 0., 1.);
    
    float angle = atan(p.y, p.x) + PI;
    float phase = 0.2 * t * sin(t);
    vec3 color = palette(angle / _2_PI, vec3(0.5), vec3(0.5), vec3(float(index)), vec3(0, 0.1, 0.2) + phase);

    result = vec3(intensity * color);

    // Background
    vec3 bg = (0.6 + 0.4*sin(2.*t)) * palette(abs(mod((angle + t) / PI, 2.) - 1.), vec3(0.5), vec3(0.5), vec3(1.0, 0.7, 0.4), vec3(0.0, 0.15, 0.20));
    result += pow(bg, vec3(0.8));
    
    // Apply BCS post-processing
    result = bcs(result, BRIGHTNESS, CONTRAST, SATURATION);

    fragColor = vec4(result, 1);
}