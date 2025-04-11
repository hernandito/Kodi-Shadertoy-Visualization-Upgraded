// Assumes iTime, iResolution, and main() are provided by Kodi.
vec4 myTanh(vec4 x) {
    return (exp(2.0 * x) - 1.0) / (exp(2.0 * x) + 1.0);
}

// Simple 2D noise function for organic randomness.
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 r = iResolution.xy;
    
    // Apply slow, organic rotation.
    float angle = 0.05 * iTime + 0.1 * sin(iTime * 0.3);
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    
    vec2 p = (fragCoord + fragCoord - r) / r.y;
    vec2 rp = rot * p;
    
    float z = 4.0 - 4.0 * abs(0.7 - dot(rp, rp));
    vec2 f = rp * z;
    
    vec4 color = vec4(0.0);
    vec2 it = vec2(0.0);
    for(; it.y < 12.0; it.y += 1.0)
    {
        vec2 s = sin(f) + 1.0;
        vec4 s4 = vec4(s.x, s.y, s.x, s.y);
        
        float randomFactor = 0.2 + 0.1 * fract(sin(iTime + it.y * 13.0) * 43758.5453);
        color += s4 * randomFactor;
        
        float denom = (it.y == 0.0) ? 1.0 : it.y;
        float randOffset = 0.3 * fract(sin(iTime + it.y * 7.0) * 12345.6789);
        f += cos(f.yx * it.y + it.x + iTime + randOffset) / denom + (0.7 + randOffset);
    }
    
    vec4 safeColor = color + vec4(0.001);
    vec4 fadeTerm = exp(vec4(z) - 4.0 - rp.y * vec4(-1.0, 1.0, 2.0, 0.0));
    vec4 plasma = myTanh(2.0 * fadeTerm / safeColor);
    
    float whiteThreshold = smoothstep(0.35, 0.55, plasma.r);
    vec4 darker = plasma * 0.5;
    vec4 mixedColor = mix(plasma, darker, whiteThreshold);
    
    float edgeFade = smoothstep(1.0, 0.5, length(rp));
    mixedColor *= edgeFade;
    
    mixedColor.a = mix(0.5, 0.25, 0.5 + 0.5 * sin(iTime * 0.5));
    
    // 🌟 **Even More Warm Color Boost!**
    vec3 warmBoost = vec3(2.9, 2.5, 2.2); // Even stronger reds, oranges, yellows
    vec3 finalRGB = clamp(mixedColor.rgb * warmBoost, 0.0, 1.0);
    
    fragColor = vec4(finalRGB, mixedColor.a);
}
