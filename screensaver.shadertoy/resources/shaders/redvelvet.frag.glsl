#define PI 3.1415926535

mat2 rotate(float radiant) {
    return mat2(cos(radiant), -sin(radiant), sin(radiant), cos(radiant));
}

float turbulence(vec2 p) {
    float radiant = PI * 0.1;
    mat2 r = rotate(radiant);

    float freq = .2;

    for (float i = 0.; i < 10.; i += 1.) {
        float x = (p * r).y + iTime;
        p += r[0] * sin(freq * x) * 1.5;

        r *= rotate(radiant);
        freq *= 1.4;
    }
    
    return p.x;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 col = vec3(0.);
    vec2 uv_orig = gl_FragCoord.xy / iResolution.xy;
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;
    uv *= 20.;
    
    float m = turbulence(uv);

    vec3 base_color = vec3(0.3, 0.0, 0.0);   // Effect Color

    float x = log(m);
    float y = x - 2.;
    col = base_color * y;
    
    // Add a rectangular vignette with small quarter-round corners
    // Normalize coordinates to the center
    vec2 pos = uv_orig - 0.5;
    // Adjust for aspect ratio to make the vignette rectangular
    float aspect = iResolution.x / iResolution.y;
    pos.x *= aspect;
    // Define the rectangle dimensions (half-width and half-height)
    vec2 rectSize = vec2(0.4 * aspect, 0.4); // Rectangle size (adjusted for aspect ratio)
    // Compute the distance to the rectangle boundary
    vec2 d = abs(pos) - rectSize;
    float cornerRadius = 0.2; // Small radius for quarter-round corners
    // If inside the rectangle (d.x < 0 and d.y < 0), use the maximum distance to the edge
    // If outside, compute the distance to the nearest corner with rounding
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - cornerRadius;
    // Apply smooth falloff (adjusted range for the new calculation)
    float vignette = smoothstep(-0.1, 0.0, dist); // Negative inner value to start inside the rectangle
    // Apply the vignette by darkening the color
    col *= 1.0 - 0.5 * vignette; // 0.7 controls the vignette strength
    
    fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
    "title": "Turbulence with Rectangular Vignette",
    "description": "Generates a turbulent pattern with a rectangular vignette and small quarter-round corners",
    "model": "person"
}
*/