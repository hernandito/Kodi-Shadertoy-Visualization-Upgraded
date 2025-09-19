// Shadertoy uniforms: iTime, iResolution
precision highp float;

// ---------------- USER PARAMETERS ----------------
#define BRIGHTNESS 1.2
#define CONTRAST   1.6
#define SATURATION 1.3
#define OFFSET_X   .2 // Center offset in the X direction (0.0 = no offset)
#define OFFSET_Y   -0.20 // Center offset in the Y direction (0.0 = no offset)
// -------------------------------------------------

// Robust Tanh Conversion Method
// This is a custom approximation for the tanh function, which is not
// supported in OpenGL ES 1.0. It's safe and prevents artifacts.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// A robust BCS function
vec3 bcs_final(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    
    // Using a luminance formula that is more robust for saturation
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color = mix(grayscale, color, saturation);
    
    return color;
}

float dist(vec3 p)
{
    vec2 twist = cos(p.z*0.05 - iTime*0.1 + vec2(0.0, 11.0));
    float tp = -(smoothstep(-1.0, 1.0, sin(iTime)) * 5.0 + 50.0 - abs(dot(p.xy, twist))) * 0.325;
    return tp;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Explicitly initializing all variables to prevent undefined behavior.
    vec2 fragCoord_offset = fragCoord - vec2(iResolution.x * OFFSET_X, iResolution.y * OFFSET_Y);
    
    vec3 d = normalize(vec3(2.0*fragCoord_offset, 0.0) - iResolution.xyy);
    vec3 p = vec3(0.0, 0.0, -5.0 * iTime);
    vec3 l = vec3(0.0, 0.0, 0.0);

    for(float i = 0.0; i < 70.0; i++)
    {
        float s = dist(p);
        p += d * s;
        // Robust division: prevents NaN/Inf issues if the denominator gets too small.
        l += exp(cos(p.z*0.1 + vec3(1.0, 2.2, 3.0)) * 0.30) * 8e-6 / max((5e-4 + s*s), 1e-6);
    }
    
    // Hacky diffuse directional derivative light by Shane
    vec3 ld = normalize(vec3(0.0, 1.0, 1.0));
    float n = 0.5 + smoothstep(0.0, 0.1, dist(p + ld*0.1) - dist(p));
    
    // Convert the final color to vec4 before applying the tanh approximation.
    vec4 final_color = vec4(n * l * l, 0.0);
    
    // Apply the custom tanh approximation.
    fragColor = tanh_approx(final_color);
    
    // Set alpha to 1.0 as the tanh_approx function operates on all components.
    fragColor.a = 1.0;
    
    // Apply BCS post-processing adjustments
    fragColor.rgb = bcs_final(fragColor.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}
