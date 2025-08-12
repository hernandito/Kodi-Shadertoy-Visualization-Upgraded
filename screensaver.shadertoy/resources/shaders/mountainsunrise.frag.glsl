#define F +texture(iChannel0,.3+p.xz*s/2500.0)/(s+=s)

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec4 p = vec4(fragCoord/iResolution.xy, 1.0, 1.0) - 0.5, d = p, t;
    p.xz += vec2(-8.0, 15.0) * iTime*.3;
    d.y -= 0.4;
    
    for(float i = 1.5; i > 0.0; i -= 0.002, p += d)
    {
        float s = 0.6;
        t = F F;
        vec3 mountainColor = mix(vec3(0.1, 0.2, 0.3), vec3(0.7, 0.8, 0.7), 1.0 - i / 1.5);
        fragColor = vec4(mountainColor, 1.0) * (1.0 + d.x - t*i) - vec4(0.0, 0.1, 0.1, 0.0);
        if(t.x > p.y * 0.007 + 1.3) break;
    }
    
    float z = length(fragCoord.xy / min(iResolution.x, iResolution.y) - vec2(0.7, 0.75));
    float occlusion = step(t.x, p.y * 0.007 + 1.3);
    float sun = smoothstep(0.09, 0.07, z) * occlusion;

    vec3 dawn = mix(vec3(1.0, 1.0, 0.8), vec3(0.878, 0.498, 0.282), 1.0 * sqrt(z));
    fragColor.rgb = mix(fragColor.rgb, dawn, occlusion);
    
    fragColor = mix(fragColor, vec4(1.0), sun);
}