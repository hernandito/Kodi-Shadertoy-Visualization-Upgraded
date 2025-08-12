precision highp float;

// --- Animation Controls ---
#define ANIMATION_SPEED 0.20
#define SCREEN_SCALE 0.80
#define ROTATION_SPEED 0.02

// --- Post-Processing: Brightness / Contrast / Saturation ---
#define BRIGHTNESS -0.1750   // Range: -1.0 to 1.0
#define CONTRAST   1.0   // Range:  0.0 (flat) to 2.0+
#define SATURATION 1.250   // Range:  0.0 (grayscale) to 2.0+

float PI = 3.14159265;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float HAL(float x,float y,float x0,float y0,float d){
    return (- y + d * x + y0 - d * x0);
}

vec3 applyBCS(vec3 color) {
    // Brightness
    color += BRIGHTNESS;

    // Contrast
    color = (color - 0.5) * CONTRAST + 0.5;

    // Saturation
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(gray), color, SATURATION);

    return clamp(color, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.x;
    uv /= SCREEN_SCALE;

    // --- Slow rotation around off-center pivot ---
    vec2 pivot = vec2(0.45, 0.45);
    vec2 delta = uv - pivot;
    float angle = iTime * ROTATION_SPEED;
    float cosA = cos(angle);
    float sinA = sin(angle);
    mat2 rot = mat2(cosA, -sinA, sinA, cosA);
    uv = pivot + rot * delta;

    float s = 1.0;
    for(float xi = 0.1; xi < 1.0; xi += 0.2){
        for(float yi = 0.1; yi < 1.0; yi += 0.2){
            s *= HAL(uv.x,
                     uv.y,
                     xi + 0.03 * cos(-iTime * ANIMATION_SPEED * yi + xi),
                     yi + 0.03 * sin(-iTime * ANIMATION_SPEED * xi + yi),
                     rand(vec2(xi,yi)) > 0.5 ? 
                     3.0 + 0.25*sin((1.0 - xi) * yi * iTime * ANIMATION_SPEED * 6.5) :
                     0.25*cos(xi * (1.0 - yi) * iTime * ANIMATION_SPEED * 6.5));
        }
    }

    vec3 col1 = vec3(0.941, 0.824, 0.612);  // Paper (light yellow)
    vec3 col2 = vec3(0.267, 0.361, 0.255);  // Ink (green)

    vec3 color = s > 0.000000000005 ? col1 : col2;

    // --- Apply Brightness/Contrast/Saturation ---
    color = applyBCS(color);

    fragColor = vec4(color, 0.0);
}
