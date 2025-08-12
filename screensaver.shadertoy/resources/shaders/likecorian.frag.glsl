// Author: bitless
// Title: another triangular voronoi 
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders" and inspiration
// Thanks to aiekick and iq for some code from https://www.shadertoy.com/view/ltK3WD and https://www.shadertoy.com/view/MdSGRc

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define PI 3.1415926
#define ZOOM_SCALE 5. // Zoom scale factor (default 1.5, decrease to zoom out further, increase to zoom in)
#define BRIGHTNESS 0.0 // Brightness adjustment for post-processing (default 0.0, positive to brighten, negative to darken)
#define CONTRAST 1.0 // Contrast adjustment for post-processing (default 1.0, > 1.0 increases contrast, < 1.0 decreases)
#define SATURATION 1.0 // Saturation adjustment for post-processing (default 1.0, > 1.0 increases saturation, < 1.0 decreases)

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 st = fragCoord.xy/iResolution.xy;
    vec2 m = vec2(0.5,0.5); 
    
    if (iResolution.y > iResolution.x ) {
        st.y *= iResolution.y/iResolution.x;
        m.y *= iResolution.y/iResolution.x;
    }       
    else {
        st.x *= iResolution.x/iResolution.y;
        m.x *= iResolution.x/iResolution.y;
    }
    vec3 color = vec3(.0);

    // Scale with adjustable zoom factor
    st -= m;
    st *= ZOOM_SCALE; // Use zoom scale parameter

    // Tile the space
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);
    
    float m_dist = 9.;  // minimun distance

    vec2 p; 
    vec4 f;
    f.x = 9.;
    
    for(int x=-2;x<=2;x++)
    for(int y=-2;y<=2;y++)
    {	
        p = vec2(x,y); //neightbour
        p += 0.5*sin(iTime*0.2+6.2831*random2(i_st+p)); //animate
		p += .5  - f_st;

        f.y = max(abs(p.x)*.866 - p.y*.5, p.y); 
        if (f.y < f.x)
        {
            m_dist = f.x;
            f.x = f.y;
            f.zw = p;
        }
        else if( f.y < m_dist )
		{
			m_dist = f.y;
		}
    }
	
    m_dist -= f.x;
    
    vec3 n = vec3(0);
    
    if ((f.x - (-f.z*.866 - f.w*.5)) < .0001) n = vec3(0.940, 0.860, 0.907); 
	if ((f.x - (f.z*.866 - f.w*.5)) < .0001) n = vec3(0.970, 0.949, 0.888);
	if ((f.x - f.w) < .0001) n = vec3(0.871, 0.900, 0.960);
	
    color = n * (0.6 + length(f.x)); //base color + distance field shadow
    color -= 0.45 * pow(clamp(m_dist * 4.0, 0.0, 1.0), 0.2); //edges
    color *= 1.0 - smoothstep(0.0, 10.0, mod(length(f.x) * 100.0, 15.0)) * 0.06; //gradient stripes
    color *= 1.0 - step(2.0, mod(length(f.x) * 100.0, 15.0)) * 0.05; //thin light stripes

    // Apply post-processing adjustments (Brightness, Contrast, Saturation)
    color = (color - 0.5) * CONTRAST + 0.5; // Contrast adjustment
    color += BRIGHTNESS; // Brightness adjustment
    float lum = dot(color, vec3(0.299, 0.587, 0.114)); // Luminance for saturation
    color = mix(vec3(lum), color, SATURATION); // Saturation adjustment

    fragColor = vec4(color, 1.);
}