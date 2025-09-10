// A robust tanh function to be used in place of the built-in tanh.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters
#define BRIGHTNESS 1.10
#define CONTRAST   1.40
#define SATURATION 1.40

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
    // Shadertoy uniform mappings:
    // iResolution = resolution (r in twigl geek mode)
    // iTime = time (t in twigl geek mode)
    // fragCoord = gl_FragCoord (FC in twigl geekest mode)
    
    vec2 r = iResolution.xy;
    float t = iTime * 0.1;
    vec4 FC = vec4(fragCoord, 0.0, 1.0); // Convert vec2 to vec4 like gl_FragCoord
    vec2 mouse = iMouse.xy / r;
    
    // Explicitly initialize all variables to prevent undefined behavior.
    float i = 0.0;
    float z = 1.0;
    float f = 0.0;
    vec4 o = vec4(0.0); // output color
    vec3 x = vec3(9.0, 0.0, 0.0);
    vec3 c = vec3(0.0);
    vec3 p = vec3(0.0);
    
    // The main loop.
    for(i=0.0; i++ < 50.0; p = mix(c, p, 0.3), z += f = 0.2 * (abs(p.z + p.x + 16.0 + tanh_approx(vec4(p.y, 0.0, 0.0, 0.0)).x / 0.1) + sin(p.x - p.z + t + t) + 1.0), o += (cos(p.x * 0.2 + f + vec4(6.0, 1.0, 2.0, 0.0)) + 2.0) / max(f, 1e-6) / max(z, 1e-6))
    {
        // This loop is for visualization of the effect.
        for(c=p=z*normalize((FC.rgb+vec3(-r.x*0.15,0,0))*2.-r.xyy),p.y*=f=.3;f++<5.;p+=cos(p.yzx*f+i+z+x*t)/f);
    }
    
    // Refined Tanh Application: compute value and apply tanh_approx.
    vec4 tanhValue = o / 30.0;
    o = tanh_approx(tanhValue);
    
    // Apply BCS post-processing
    o.rgb = bcs(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);

    // The final output color is assigned to fragColor.
    fragColor = o;
}