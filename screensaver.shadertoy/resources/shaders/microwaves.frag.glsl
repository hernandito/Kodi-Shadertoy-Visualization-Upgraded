// Author: bitless
// Title: Microwaves

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

precision mediump float; // Required for ES 2.0

#define p(t, a, b, c, d) ( a + b*cos( 6.28318*(c*t+d) ) ) //palette function (https://iquilezles.org/articles/palettes)
#define S(x,y,z) smoothstep(x,y,z)

// Define EPSILON for robustness in divisions
const float EPSILON = 1e-6;

// --- View Scale Parameter ---
// Adjusts the overall scale of the pattern.
// Higher values will make the pattern appear smaller, showing more repetitions.
// Lower values will make the pattern appear larger, showing fewer repetitions.
#define VIEW_SCALE 2.750 // Default scale

// --- Wave Amplitude Parameter ---
// Controls the overall amplitude (height) of the waves.
// Increase this value to make the waves more pronounced.
#define WAVE_AMPLITUDE_FACTOR 0.55 // Increased from 0.275 for slightly higher amplitude

float w(float x, float p){ //sin wave function
    x *= 5.;
    float t= p*.5+sin(iTime*.06)*10.5;
    // Apply the WAVE_AMPLITUDE_FACTOR to the final result
    return (sin(x*.25 + t)*5. + sin(x*4.5 + t*3.)*.2 + sin(x + t*3.)*2.3  + sin(x*.8 + t*1.1)*2.5) * WAVE_AMPLITUDE_FACTOR;
}


void mainImage( out vec4 fragColor, in vec2 g)
{
    vec2 r = iResolution.xy;
    // Enhance General Division Robustness for r.y
    vec2 st = (g+g-r)/max(r.y, EPSILON);

    // Apply the VIEW_SCALE to the normalized coordinates
    st *= VIEW_SCALE;

    float        th = .05; //thickness
    // Enhance General Division Robustness for r.y
    float        sm = 15./max(r.y, EPSILON)+.85*length(S(vec2(01.,.2),vec2(2.,.7),abs(st))); //smoothing factor
    float        c = 0.;
    float        t = iTime*0.15;
    float        n = floor((st.y+t)/.1);
    float        y = fract((st.y+t)/.1);
    
    // Explicitly initialize clr to prevent artifacts from garbage values
    vec3 clr = vec3(0.0); 

    for (float i = -5.;i<5.;i++)
    {
        float f = w(st.x,(n-i))-y-i;
        c = mix(c,0.,S(-0.3,abs(st.y),f));
        c += S(th+sm,th-sm,abs(f))
            *(1.-abs(st.y)*.75)
            + S(5.5-abs(f*0.5),0.,f)*0.25;
            
        clr = mix(clr,p(sin((n-i)*.15),vec3(.5),vec3(.5), vec3(.270), vec3(.0,.05,0.15))*c,S(-0.3,abs(st.y),f));
    }
    fragColor = vec4(clr,1.);
}
