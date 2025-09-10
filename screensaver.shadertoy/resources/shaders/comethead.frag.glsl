// Twitter-golfed loop expanded for Shadertoy
// - iResolution: viewport size
// - iTime: seconds
// Produces a folding/fractal-ish field with HSV shading.https://x.com/YoheiNishitsuji/status/1958876819803054146

// Adjustable BCS parameters (Brightness, Contrast, Saturation)
#define BRIGHTNESS 1.10 // Default brightness (current setting)
#define CONTRAST 1.5   // Default contrast (current setting)
#define SATURATION 1.0 // Default saturation (current setting)

// Adjustable FOV parameter
#define FOV 1.40 // Default FOV (current setting)

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// HSV -> RGB (h in [0,1], s,v can be any real; wrapping/clamping happens inside)
vec3 hsv(float h, float s, float v) {
    vec3 p = abs(fract(h + vec3(0.0, 1.0/3.0, 2.0/3.0)) * 6.0 - 3.0);
    return v * mix(vec3(1.0), clamp(p - 1.0, 0.60, .0), clamp(s, 0.0, 1.0));
}

// BCS adjustment function
vec3 adjustBCS(vec3 color, float brightness, float contrast, float saturation)
{
    // Brightness
    color *= brightness;
    
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    
    // Saturation
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(gray), color, saturation);
    
    return clamp(color, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 r = iResolution.xy;
    float t = iTime;

    // Normalized coordinates with slight upward offset like the original
    // FC = fragCoord, r = resolution in the tweet
    vec2 uv = (fragCoord - .45 * r) / r.x*1.5;
    uv *= FOV;

    vec3 col = vec3(0.0);

    // Accumulator "g" across the outer loop (matches the tweet)
    float g = 0.0;

    // Outer loop: ++i < 119 in the original golfed form
    for (int I = 0; I < 119; ++I)
    {
        // Build 3D point p = (uv + vec2(0, .9), g - 1)
        vec3 p = vec3(uv + vec2(0.0, 0.9), g - 1.0);

        // Rotate around Y by acting on (z,x)
        p.zx = rot(t * 0.05) * p.zx;

        // Inner dynamics: fold/abs + inversion-like step
        float s = 2.0; // starts at 2.0 each outer step
        float e = 0.0;

        // Inner loop: i++ < 25 in the original; we use fixed 25 iters
        for (int j = 0; j < 25; ++j) {
            // e = 5. / dot(p, p * .5);  s *= e;
            e = 5.0 / max(dot(p, p * 0.5), 1e-6);
            s *= e;

            // p = vec3(.1, 3.98, -.74) - abs( abs(p) * e - vec3(2.7, 3.94 + e*.15, 3.3 - g) )
            p = vec3(0.1, 3.98, -0.74)
                - abs(abs(p) * e - vec3(2.7, 3.94 + e * 0.15, 3.3 - g));
        }

        // Accumulate "g" using the current p.y and scale s
        g += p.y / max(s, 1e-6);

        // Log-scaling and quadratic mix for the value channel
        float val = log(max(s, 1e-6)) + g * g;

        // Additive color blend: 0.01 - hsv(0.61, p.y*.37-.4, val/900)
        col += 0.01 - hsv(0.61, p.y * 0.37 - 0.4, val / 900.0);
    }

    // Apply BCS adjustments
    col = adjustBCS(col, BRIGHTNESS, CONTRAST, SATURATION);
    
    fragColor = vec4(col, 1.0);
}