const float pi = acos(0.0)*2.0;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    uv-=0.5;
    uv.x*=iResolution.x/iResolution.y;
    uv*=4.;
    
    float wavelength = 0.1;
    float crossSection = 0.;
    float phase = iTime;
    
    // Time varying pixel color
    vec3 col = vec3( cos( (phase+length(vec3(uv.x-0.5, uv.y, crossSection))*2.0*pi)/wavelength ) )/pow(length(vec3(uv.x-0.5, uv.y, crossSection)), .18);
    col += vec3( cos( (phase+length(vec3(uv.x+0.5, uv.y, crossSection))*2.0*pi)/wavelength ) )/pow(length(vec3(uv.x+0.5, uv.y, crossSection)), .18);
    col*=col*0.05;


    // Output to screen
    fragColor = vec4(abs(col/(col+1.)),1.0);
}