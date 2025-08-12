// Author: bitless
// Title: Halftone Metaballs
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders" and inspiration 

// --- Color Parameters ---
// Adjust these to change the background and effect colors.
#define BACKGROUND_COLOR vec3(0.094, 0.141, 0.098) // Default: Black
#define EFFECT_COLOR vec3(1, 0.588, 0)     // Default: White

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*4378.5453);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 st = fragCoord.xy/iResolution.xy;
    st.x *= iResolution.x/iResolution.y;
    vec3 color; // Declare color without immediate initialization

    // Scale
    st *= 4.;

    // Tile the space
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);

    float m =3.5;

    for (int j=-1; j<=1; j++ ) {
        for (int i=-1; i<=1; i++ ) {
            vec2 neighbor = vec2(float(i),float(j));
            vec2 point = random2(i_st + neighbor);
            point = 0.5 + 0.5*sin(iTime*0.4 + 6.2831*point);
            vec2 diff = neighbor + point - f_st;
            float dist = length(diff);
            
            m = min(m,m*dist);
        }
    }
    
    st *= 20.;
    vec2 pt = vec2(floor(st)+0.5);
    float c = (1.0-length(st-pt))*(1.0-m*0.5);
    
    // Mix the background and effect colors based on the 'c' value
    // When 'c' is high, it will lean towards EFFECT_COLOR, otherwise towards BACKGROUND_COLOR.
    color = mix(BACKGROUND_COLOR, EFFECT_COLOR, (1.0-smoothstep(0.,0.075,abs(0.4-c))));

    fragColor = vec4(color,1.0);
}
