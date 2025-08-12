#define PI 3.14159265359
#define TWO_PI 6.28318530718
#define ANIMATION_SPEED 0.30 // Adjust this value to control animation speed (e.g., 0.5 for half speed, 2.0 for double speed)

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord/iResolution.x);
    vec2 uvR0 = (fragCoord/iResolution.x);
    vec2 uvR1 = (fragCoord/iResolution.x);
    
    float aspectRatio = (iResolution.y/iResolution.x);
    
    vec2 mouseN = ((iMouse.xy/iResolution.xy)-vec2(0.5,aspectRatio/2.0))*1.0;
    
    //uv.x = (uv.x-mouseN.x);
    //uv.y = (uv.y-mouseN.y);
    
    // move space from the center
    vec2 centerRot0 = vec2(0.5,0.25);
    uvR0 -= centerRot0;
    
    //uv = pow(uv,2.0);

    // rotate the space
    //uv = rotate2d( sin(iTime/2.0)*PI ) * uv;
    //uvR0 = rotate2d( iTime/2.154154560 ) * uvR0;
    
    uvR0 += centerRot0;
    
    vec2 centerRot1 = vec2(0.5,0.25);
    uvR1 -= centerRot1;
    //uvR1 = rotate2d( iTime/2.154154560 ) * uvR1;
    uvR1 += centerRot1;

    //vec2 desfasePoint = mouseN;

    
    // Use polar coordinates instead of cartesian
    //vec2 toCenter = vec2(0.5)-uv;
    vec2 toCenter = vec2(0.5,aspectRatio/2.0)-uv;
    vec2 toCenterR0 = vec2(0.5,aspectRatio/2.0)-uvR0;
    vec2 toCenterR1 = vec2(0.5,aspectRatio/2.0)-uvR1;
    
    //**********************************
    //vec2 desfasePoint = vec2(0.2,0.0);
    vec2 desfasePoint = mouseN;
    float angle0 = atan(toCenterR0.y+desfasePoint.y,toCenterR0.x+desfasePoint.x);
    float radius0 = length(toCenterR0+desfasePoint);

    float ang0 = angle0/TWO_PI;
    float vueltas0 = 20.0;
    float exponente0 = (2.0)/1.0;
    float exp0 = pow(radius0,exponente0);
    float brazos0 = 10.0;
    
    float color0 = ang0+exp0*(brazos0);
    
    //**********************************
    float angle1 = atan(toCenterR1.y,toCenterR1.x);
    float radius1 = length(toCenterR0);
    
    float ang1 = angle1/TWO_PI;
    float vueltas1 = 0.0;
    float exponente1 = (1.0)/1.0;
    float exp1 = pow(radius1,exponente1)*vueltas1;
    float brazos1 = -10.0;
    
    float color1 = ang1+radius1*(brazos1*sin(iTime * ANIMATION_SPEED / 8.0));
    //**********************************
    //**********************************
    vec2 desfasePoint1 = vec2(0.2,-0.2);
    //vec2 desfasePoint = mouseN;
    float angle2 = atan(toCenter.y+desfasePoint1.y,toCenter.x+desfasePoint1.x);
    float radius2 = length(toCenter+desfasePoint1);

    float ang2 = angle2/TWO_PI;
    float vueltas2 = 0.0;
    float exponente2 = (1.0)/1.0;
    float exp2 = pow(radius2,exponente2)*vueltas2;
    float brazos2 = -1.0;
    
    float color2 = (ang2+exp2)*brazos2;
    
    //**********************************
    
    //float bl = step(0.4,uv.y);
    float maskInf = (smoothstep(0.05,0.2,uv.y));
    float maskSup = 1.0-(smoothstep(0.3,0.5,uv.y));
    
    float color3 = uv.x*4.0;
    color3*=(maskSup*maskInf)*(2.50*sin(iTime * ANIMATION_SPEED / 50.0));


    //float s = (color0+ color1+ color2+ color3)/1.0;
    float s = (color0+color1)/1.0;
    
    
    //float lap = (s*100.0)/(sin(iTime/20.0)*100.0);
    float lap = (s)-(iTime * ANIMATION_SPEED * -0.1);
    
    float colLap = smoothstep(.01,.1,fract((1.0-lap)*8.0));
    
    float t = iTime * ANIMATION_SPEED * -0.1;
    //vec3 col = hsb2rgb(vec3(lap+t,1.0,1.0))*colLap;
    float soloLap = ((fract(s*2.0)+1.0)*0.5)*colLap;
    // Original grayscale output: vec3(soloLap, soloLap, soloLap)
    // Replaced with warm white and brown blend
    vec3 warmWhite = vec3(0.69, 0.62, 0.369); // Warm white color
    vec3 brown = vec3(0.38, 0.235, 0.086);  // Brown color for lines
    // Adjust soloLap with a power function to darken the starting point
    float adjustedSoloLap = pow(soloLap, 2.5); // Increase exponent to skew toward darker values
    vec3 col = mix(brown, warmWhite, adjustedSoloLap); // Blend from brown to warm white

    //col= vec3(color3, color3, color3);

    // Output to screen
    fragColor = vec4(col,1.0);
}