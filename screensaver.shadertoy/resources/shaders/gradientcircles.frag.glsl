#define PI 3.14159265359
#define NUM_LIGHTS 8

//https://www.shadertoy.com/view/lscGDr
float gradientNoise(vec2 uv) {
    const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract(magic.z * fract(dot(uv, magic.xy)));
}

//https://www.shadertoy.com/view/ll2GD3
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}


float map(float value, float inMin, float inMax, float outMin, float outMax) {
    return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = ( 2.* fragCoord - iResolution.xy ) / iResolution.y; 
    float time = iTime * 0.35;
    
    vec3 finalColor = vec3(0.0);
    float sumWeights = 0.0;
    
    vec3 bgColor = vec3(0.35);
    float bgWeight = 0.025;
	finalColor += bgColor * bgWeight;
	sumWeights += bgWeight;
    
    for (float i = 0.; i < float(NUM_LIGHTS); i++) {
        float n = i / float(NUM_LIGHTS);
		float wave = sin(n * PI + time ) * 0.5 + 0.5;
       
        float distance = 0.6 + wave * 0.125;
        vec2 position = vec2(cos(n * PI * 2. + time * 0.1) * distance, sin(n * PI * 2. + time * 0.1) * distance);
        
        float d = 0.2;
        
        vec2 toLight = position - uv;
        float distFragLight = length(toLight);
        distFragLight = distFragLight < d ? 1000. : distFragLight; 
        
        float angle = atan(toLight.y, toLight.x);
        angle = angle / (PI * 2.) + 0.5; //normalize
        angle += time * 0.25;
        
        float decayRate = map(wave, 0., 1., 6., 16.);
        
        float distanceFactor = exp(-1.0 * decayRate * distFragLight);
             
        vec3 color = palette(distanceFactor + angle, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );
        vec3 lightColor = color  * distFragLight * distanceFactor;
      
        finalColor += lightColor;
        sumWeights += distanceFactor * distFragLight;
    }
    
    finalColor = finalColor / sumWeights;
    finalColor = pow(finalColor, vec3(1. / 1.4)); //gammma
    finalColor += (1.0/255.0) * gradientNoise(fragCoord) - (0.5/255.0); //banding
    
    fragColor = vec4(finalColor, 1.0);
}
   
        
        
