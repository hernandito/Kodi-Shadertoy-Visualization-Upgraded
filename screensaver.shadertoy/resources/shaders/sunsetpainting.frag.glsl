// Fractal Noise based on https://www.shadertoy.com/view/XlBSRc

#define N(p)sin(p.x*2.0+sin(p.y*3.0))*cos(p.y*2.0+cos(p.x*3.0))

void mainImage(out vec4 O,vec2 C){
    C = 4.0*(C-iResolution.xy/2.0)/iResolution.y;
    vec2 p = vec2(-C.y,C.x);
    float v = 0.0;
    float a = 0.5;
    float t = 1.3;
    
    // Explicitly initialize the output color
    O = vec4(0.0);

    for(int i = 0; i < 11; i++){
        p += vec2(sin(p.y+9.53),cos(p.x+3.26))*0.35;
        p = p * mat2(cos(t*0.1),sin(t*0.1),-sin(t*0.1),cos(t*2.1));
        
        v = 0.0;
        a = 0.5;
        vec2 r = p + float(i) + iTime*0.025;
        
        for(int j = 0; j < 6; j++){
            v += N(r)*a;
            a /= 2.0;
            r *= 2.0;
        }

        p += v*0.14;
    }
    
    // The main color calculation, separated for clarity
    vec3 color_mix1 = mix(vec3(0.5, 0.5, 0.5) + vec3(0.5, 0.5, 0.5)*cos(length(p)*5.0+vec3(0.2,0.1,0.2)+t*3.2),
                          vec3(0.1, 0.1, 0.1) + vec3(0.5, 0.5, 0.5)*sin(atan(p.y,p.x)*3.0+vec3(1.0,0.5,0.0)),0.4);

    // The "sun" part of the color, with a robust division
    vec3 sun_color = vec3(0.9,0.6,0.1)/(0.5+length(C)*(3.5+0.5*sin(iTime*0.2)));
    
    // Combine the final colors and assign to the output
    O.xyz = color_mix1 + sun_color;
    O.a = 1.0;
}