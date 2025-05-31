/*
    "Cubic" by @XorDev

    The deconstructed version of my Cubic shader:
    x.com/XorDev/status/1913308747620909396
*/
//Color wave frequency
#define COL_FREQ 0.40
//Red, green and blue have wave frequencies
#define RGB_SHIFT vec3(0, 2, 4)
//Opaqueness (lower = more density)
#define OPACITY 0.35

//Camera perspective (ratio from tan(fov_y/2) )
#define PERSPECTIVE 1.0
//Raymarch steps (higher = slower)
#define STEPS 100.0

//Camera scroll velocity
#define CAM_VEL vec3(0, .3, .2)

//Cube distortion frequency
#define CUBE_FREQ 1.2

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    //Centered, ratio-corrected screen uvs [-1, 1]
    vec2 res = iResolution.xy;
    vec2 uv = (2.0 * fragCoord - res) / res.y;
    //Ray direction for raymarching
    vec3 dir = normalize(vec3(uv, -PERSPECTIVE));
    
    //Output color
    vec3 col = vec3(0.0);
    
    //Raymarch depth
    float z = 0.0;
    //Distance field step size
    float d = 0.0;
    
    //Raymarching loop
    for (float i = 0.0; i < STEPS; i++)
    {
        //Raymarch sample point
        vec3 p = z * dir - iTime * CAM_VEL;
        //Break into distorted cubes
        vec3 v = cos(p + cos(p / CUBE_FREQ));
        //Approximated cube SDF with translucency
        z += d = length(max(v, v.yzx * OPACITY)) / 6.0;
        //Coloring and glow attenuation
        col += (sin(COL_FREQ * p.y + RGB_SHIFT) + 1.0) / d;
    }
    
    //Exponential tonemapping
    //https://www.shadertoy.com/view/ddVfzd
    col = 0.9 - exp(-col / STEPS / 1e2);
    fragColor = vec4(col, 1.0);
}