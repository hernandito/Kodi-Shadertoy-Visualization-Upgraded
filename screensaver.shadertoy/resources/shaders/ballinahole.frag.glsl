void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    float dist = sqrt(abs((1.0+sin(iTime*.2*.5 )*.5 )- dot(uv, uv)));//adjust to change size
    dist = max(dist, 0.01); // Prevent near-zero values better aliasing. May be better solutions or adding smooth step

    vec2 texCoord = iTime*.325/8.0 + uv / dist;
    vec3 col = texture(iChannel0, texCoord).rgb * (0.3 + dist * 0.7);//adjust texture and brighness of it
    
    col *= dist * 0.5 + 0.5;

    fragColor = vec4(col, 1.0);
}
