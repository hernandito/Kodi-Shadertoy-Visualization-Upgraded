//thanks to https://thebookofshaders.com/06/
vec3 hsv2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0), 6.0)-3.0)-1.0, 0.0, 1.0);
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}


vec3 lightPillars( out vec4 fragColor, in vec2 fragCoord )
{
    // create pixel coordinates & normalize
	vec2 uv = fragCoord.xy / iResolution.xy;
    float ratio = iResolution.y/iResolution.x;
    //uv.y *= ratio;

	// the sound texture is 512x2
    int tx = int(uv.x*512.0);
    
	// first row is frequency data (48Khz/4 in 512 texels, meaning 23 Hz per texel)
	float fft  = texelFetch( iChannel0, ivec2(tx,0), 0 ).x; 

    //adjust sound spike smoothness (0 for no smoothness)
    float texelSmoothness = 0.3;
    
    //adjust sound spike variety (1 for no variety)
    float texelPow = 17.0;
    
    //Value of final color
    float texelAlpha = fft;
    
    //generate alpha for mix function
    float alpha = smoothstep(pow(fft, texelPow)-texelSmoothness,fft, uv.y);
    
    //use alpha on colors
    vec3 col = mix(hsv2rgb(vec3(uv.x*0.8, 1.0, 1.0)), vec3(0.0,0.0,0.0), alpha) * texelAlpha;
    
    return col;
}


vec3 laserTimeline( out vec4 fragColor, in vec2 fragCoord )
{
    // create pixel coordinates & normalize
	vec2 uv = fragCoord.xy / iResolution.xy;
    float ratio = iResolution.y/iResolution.x;
    //uv.y *= ratio;

	// the sound texture is 512x2
    int tx = int(uv.x*512.0);
    
	// first row is frequency data (48Khz/4 in 512 texels, meaning 23 Hz per texel)
	float fft  = texelFetch( iChannel0, ivec2(tx,0), 0 ).x;
    
    //vec2 fft 

    //adjust sound spike smoothness (0 for no smoothness)
    float texelSmoothness = 0.3;
    
    //generate alpha for mix function
    float alpha = .90-fft + uv.y;
    
    //use alpha on colors
    vec3 col = mix(hsv2rgb(vec3(uv.x*0.8, 1.0, 1.0)), vec3(0.0,0.0,0.0), alpha);
    
    return col;
}


//thanks to https://www.shadertoy.com/view/MsdGzn
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col = laserTimeline(fragColor, fragCoord);
    
    //vec3 col = lightPillars(fragColor, fragCoord);
	
	fragColor = vec4(col,1.0);
}