// A robust approximation for the tanh function, compatible with GLSL ES 1.0
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Shader based on "Sunset" by @XorDev and "Checked Out" by Diatribes
// Combined and converted for Kodi's OpenGL ES 1.0 compatibility.

#define blend sin(iTime*0.025*2.0*3.141592)+0.15
#define speed 0.70
#define ZOOM 0.50
#define BRIGHTNESS 0.20
#define CONTRAST 1.40
#define SATURATION 1.0

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Explicit variable initialization
    float t = iTime*speed;
    vec2 I = fragCoord;
    vec2 o = fragCoord;
    vec4 O1 = vec4(0.0);
    float z = 0.0;
    float d1, s1;

    // Logic from original getMainImage
    for(float i1 = 0.0; ++i1 < 100.0; ) {
        // Corrected camera ray for proper perspective with zoom control
        vec2 uv = (I.xy - 0.5 * iResolution.xy) / iResolution.y;
        vec3 p = z * normalize(vec3(uv, ZOOM));
        
        p.x = abs(p.x);
        
        for(d1 = 2.0; d1 < 200.0; d1 += d1)
            p += 0.6 * sin(p.yzx * d1 - 0.2 * t) / d1;

        z += d1 = 0.005 + max(s1 = 0.3 - abs(p.y), -s1 * 0.2) / 4.0;
        O1 += (cos(s1 / max(0.07, 1e-6) + p.x + 0.5 * t - vec4(3, 4, 5, 0)) + 1.5) * exp(s1 / max(0.1, 1e-6)) / max(d1, 1e-6);
    }
    
    // Apply Robust Tanh Conversion for the first image
    vec4 img1 = tanh_approx(O1 * O1 / 5e8);

    // Explicit variable initialization for the second part
    vec4 color2 = vec4(0.0);
    float d2 = 0.0;
    float s2;

    // Logic from original getMainImage2
    for(float i2 = 0.0; ++i2 < 100.0;) {
        // Corrected camera ray for proper perspective with zoom control
        vec2 uv = (o.xy - 0.5 * iResolution.xy) / iResolution.y;
        vec3 p = d2 * normalize(vec3(uv, ZOOM));
        
        p.x = abs(p.x);
        p.y *= -1.0;
        p.z -= t;
        
        for(s2 = 0.1; s2 < 5.0;) {
            p -= dot(cos(t + p * s2 * 16.0), vec3(0.001)) / max(s2, 1e-6);
            p += sin(p.yzx * 0.9) * 0.1;
            s2 *= 1.42;
        }

        d2 += s2 = 0.02 + abs(3.0 - length(p.yx)) * 0.1;
        color2 += (1.0 + cos(d2 + vec4(4, 2, 1, 0))) / max(s2, 1e-6);
    }

    // Apply Robust Tanh Conversion for the second image
    vec4 img2 = tanh_approx(color2 / 3000.0);
    
    // Final blend
    vec4 finalColor = mix(img1, img2, blend);
    
    // Apply Brightness, Contrast, and Saturation
    vec3 gray = vec3(dot(finalColor.rgb, vec3(0.2126, 0.7152, 0.0722)));
    finalColor.rgb = mix(gray, finalColor.rgb, SATURATION);
    finalColor.rgb = (finalColor.rgb - 0.5) * CONTRAST + 0.5;
    finalColor.rgb += BRIGHTNESS;

    fragColor = finalColor;
}
