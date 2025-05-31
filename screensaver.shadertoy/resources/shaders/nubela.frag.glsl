//CBS
//Parallax scrolling fractal galaxy.
//Inspired by JoshP's Simplicity shader: https://www.shadertoy.com/view/lslGWr

const float speed = 0.1; // Overall animation speed (lower is slower)
//   - 0.1 makes animations 10x slower (e.g., 16 sec period becomes 160 sec)
//   - Adjust this value to change speed:
//     - Decrease (e.g., 0.05) to slow down further (20x slower)
//     - Increase (e.g., 0.5) to speed up (2x slower)
//     - Set to 1.0 for original speed
//     - Set to 0.0 to stop all animations

// http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/
float field(in vec3 p,float s) {
    float strength = 6.8; // Stabilized to reduce flicker (original range: 6.586 to 7.0)
    float accum = s/4.;
    float prev = 0.;
    float tw = 0.;
    for (int i = 0; i < 26; ++i) {
        float mag = dot(p, p);
        p = abs(p) / mag + vec3(-.5, -.4, -1.5);
        float w = exp(-float(i) / 7.);
        accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
        tw += w;
        prev = mag;
    }
    return max(0., 5. * accum / tw - .7);
}

// Less iterations for second layer
float field2(in vec3 p, float s) {
    float strength = 6.8; // Stabilized to reduce flicker (original range: 6.586 to 7.0)
    float accum = s/4.;
    float prev = 0.;
    float tw = 0.;
    for (int i = 0; i < 18; ++i) {
        float mag = dot(p, p);
        p = abs(p) / mag + vec3(-.5, -.4, -1.5);
        float w = exp(-float(i) / 7.);
        accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
        tw += w;
        prev = mag;
    }
    return max(0., 5. * accum / tw - .7);
}

vec3 nrand3( vec2 co )
{
    vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
    vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
    vec3 c = mix(a, b, 0.5);
    return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = 2. * fragCoord.xy / iResolution.xy - 1.;
    vec2 uvs = uv * iResolution.xy / max(iResolution.x, iResolution.y);
    vec3 p = vec3(uvs / 4., 0) + vec3(1., -1.3, 0.);
    float animTime = iTime * speed; // Scaled time for all animations
    p += .4 * vec3(sin(animTime / 16.), sin(animTime / 12.), sin(animTime / 128.));
    // Base periods: 16, 12, 128 seconds
    // Effective periods with speed=0.1: 160, 120, 1280 seconds
    // Amplitude increased to .4 (from .2) for more noticeable motion
    // Adjust 'speed' at the top to change animation speed
    
    float t = field(p, 0.2); // Audio reactivity removed, using constant 0.2
    float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));
    
    //Second Layer
    vec3 p2 = vec3(uvs / (4.+sin(animTime*0.11)*0.2+0.2+sin(animTime*0.15)*0.3+0.4), 1.5) + vec3(2., -1.3, -1.);
    // Base periods: 9.09, 6.67 seconds
    // Effective periods with speed=0.1: 90.9, 66.7 seconds
    // Adjust 'speed' at the top to change animation speed
    p2 += 0.5 * vec3(sin(animTime / 16.), sin(animTime / 12.), sin(animTime / 128.));
    // Same periods as first layer
    // Amplitude increased to .5 (from .25) for more noticeable motion
    float t2 = field2(p2, 0.2); // Audio reactivity removed, using constant 0.2
    // Adjusted coefficients to subdue the green color
    // Fine-tune these coefficients to adjust the color balance:
    // - First component (Red): 1.4
    // - Second component (Green): 1.0 (reduced from 1.8 to subdue the intensity)
    // - Third component (Blue): 0.24
    vec4 c2 = mix(.4, 1., v) * vec4(1.4 * t2 * t2 * t2, 1.0 * t2 * t2, 0.24 * t2, t2);
    
    //Let's add some stars
    //Thanks to http://glsl.heroku.com/e#6904.0
    vec2 seed = p.xy * 2.0;    
    seed = floor(seed * iResolution.x);
    vec3 rnd = nrand3( seed );
    vec4 starcolor = vec4(pow(rnd.y,70.0));
    
    //Second Layer
    vec2 seed2 = p2.xy * 2.0;
    seed2 = floor(seed2 * iResolution.x);
    vec3 rnd2 = nrand3( seed2 );
    starcolor += vec4(pow(rnd2.y,40.0));
    
    // Adjusted coefficients to subdue the green color
    // Fine-tune these coefficients to adjust the color balance:
    // - First component (Red): 0.32
    // - Second component (Green): 0.12 (reduced to subdue the intensity)
    // - Third component (Blue): 0.24
    fragColor = mix(0.0, 1., v) * vec4(0.32 * t * t * t, 0.12 * t * t, 0.24 * t, 1.0) + c2 + starcolor;
}