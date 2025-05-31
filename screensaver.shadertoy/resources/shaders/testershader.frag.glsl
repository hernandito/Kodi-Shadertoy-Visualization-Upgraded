const float PI = 3.1415926;

#define TUBE_BRIGHTNESS 3.0   // Overall brightness of the light
#define GLOW_FALLOFF_POWER 5.5 // Higher values for sharper falloff

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Convert to uv
    vec2 uv = fragCoord/iResolution.xy;

    // Start and ending points of the neon light
    vec2 a = vec2(0.2, 0.4) + sin(iTime) * vec2(0.2, 0.4);
    vec2 b = vec2(0.7, 0.6) + sin(iTime) * vec2(0.1, -0.2);

    // Calculates the angle around the current pixel that is illuminated by the neon light
    float light = acos(dot(normalize(a - uv), normalize(b - uv))) / PI;

    // Output to screen with gamma correction, brightness, and falloff control
    vec3 col = pow(light, GLOW_FALLOFF_POWER) * vec3(1, 1, 1) * TUBE_BRIGHTNESS;
    fragColor = vec4(col, 1.0);
}