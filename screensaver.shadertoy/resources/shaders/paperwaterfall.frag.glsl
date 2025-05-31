#define ANIMATION_SPEED 0.20 // Default animation speed

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv-=0.5;
    uv.x*= iResolution.x/iResolution.y;

    float dist,dist1,dist2,mask,l,final = 1.0;
    //This parameter controls how many sheets are in the picture
    float s = 0.03;

    float amp,freq;
    uv.x-=iResolution.x/iResolution.y;

    //This parameter controls when the algorithm stop drawing sheets (-1 is no sheet, 1 all sheets)
    float factorSheets = iResolution.x/iResolution.y;
    //Optional: very funny :)
    //factorSheets*=sin(0.4*iTime * ANIMATION_SPEED);

    vec3 currentCol;
    vec3 col = texture(iChannel0,vec2(0.0,0.0)).rgb;

    for(float f = -iResolution.x/iResolution.y;f<factorSheets;f+=s){
        uv.x+=s;
        //This parameter controls the frequency of the waves, modulated by an exp along the x-axis
        freq = 5.0*exp(-5.0*(f*f));
        //This parameter controls the amplitude of the waves, modulated by an exp along the x-axis
        amp = 0.15*exp(-5.0*(f*f));
        dist = amp*pow(sin(freq*uv.y+2.0*iTime * ANIMATION_SPEED +100.0*sin(122434.0*f)),2.0)*exp(-5.0*uv.y*uv.y)-uv.x;
        mask = 1.0-smoothstep(0.0,0.005,dist);

        //Draw each line of the sheet
        dist1 = abs(dist);
        dist1 = smoothstep(0.0,0.01,dist1);

        //Draw the shadow of each line
        dist2 =abs(dist);
        dist2 = smoothstep(0.0,0.04,dist2);
        dist2 = mix(0.6,1.0,dist2);
        dist2 *= mask;

        //Combine shadow and line
        l = mix(dist1,dist2,mask);
        //Combine the current sheet with the last drawn
        final=mix(l,l*final,mask);

        //Color to each sheet, based on the pixel color of a random texture

        float index = f;
        //More funny
        //index+=0.01*iTime * ANIMATION_SPEED;

        currentCol = texture(iChannel0,vec2(index,0.0)).rgb;
        col=mix(currentCol,col,mask);
    }

    //Add some color
    vec3 curvecolor = vec3(0.0,0.0,0.0);
    vec3 color = mix(curvecolor,col,final);

    fragColor = vec4(color,1.0);
}