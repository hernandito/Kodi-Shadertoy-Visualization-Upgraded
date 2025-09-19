// Post-processing parameters for color adjustment
#define BRIGHTNESS .95
#define CONTRAST   1.1
#define SATURATION 1.2
#define COLOR_TINT vec3(1.0, 1.0, 1.0)

// A parameter to control the color of the rotating shape.
// Adjust the RGB values (0.0 to 1.0) to change the color.
#define SHAPE_COLOR vec3(0.851, 0.82, 0.749)

// Function for Brightness, Contrast, and Saturation adjustments
vec3 bcs(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    vec3 grayscale = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(grayscale, color, saturation);
    return color;
}

#define pi 3.14159265359;
#define rot(a) mat3( \
    cos(a), sin(a/2.)*sin(a), sin(a)*cos(a/2.), \
    0.0, cos(a/2.),-sin(a/2.), \
    -sin(a), sin(a/2.)*cos(a), cos(a/2.)*cos(a) \
)

float opSmoothSubtraction( float d1, float d2, float k ) {
    k *= 4.0;
    float h = max(k-abs(-d1-d2),0.0);
    return max(-d1, d2) + h*h*0.25/k;
}

float SDF(vec3 p) {
    p=rot(iTime*.1)*p; vec3 p1 = p;
    for (float i=1.0; i<50.0; i++)
        p1.zyx+=sin(p.xzy*4.0)/(i*4.0);
    return opSmoothSubtraction(length(p1)-2.6, (length(p)-2.6), 0.1);
}

vec3 color(vec3 p) {
    const float eps = 0.001;
    vec3 normal = normalize(vec3(
        SDF(p + vec3(eps, 0, 0)) - SDF(p - vec3(eps, 0, 0)),
        SDF(p + vec3(0, eps, 0)) - SDF(p - vec3(0, eps, 0)),
        SDF(p + vec3(0, 0, eps)) - SDF(p - vec3(0, 0, eps))
    ));
    
    vec3 next = 1.0-(normal*0.5+0.5);
    next = vec3(dot(next,vec3(1))/3.0);
    
    return SHAPE_COLOR - next*next;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float time = iTime;
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);
    
    vec3 ro = vec3(0, 0, -9.0);
    vec3 rd = normalize(vec3(uv, 3));
    
    float t = 0.0; vec3 p;
    for(int i = 0; i < 256; i++) {
        p = ro + rd * t;
        float d = SDF(p)/5.0;
        if(d < 0.005) break;
        if(t > 20.0) break;
        t += d;
    }
    
    vec3 finalColor;
    if(t < 20.0) {
        finalColor = color(p);
    } else {
        finalColor = vec3(0.1, 0.1, 0.1);
    }

    // Apply post-processing adjustments
    finalColor = bcs(finalColor, BRIGHTNESS, CONTRAST, SATURATION);
    finalColor *= COLOR_TINT;

    fragColor = vec4(finalColor, 1.0);
}