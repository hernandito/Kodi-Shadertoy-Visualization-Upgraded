// "Hypercomplex" by Alexander Alekseev aka TDM - 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

precision mediump float; // Ensure medium precision for GLSL ES 1.00

// New Post-Processing Parameters for BCS
#define BRIGHTNESS_POST 0.450     // Adjusts overall brightness (1.0 for neutral)
#define SATURATION_POST .9     // Adjusts color intensity (1.0 for neutral, 0.0 for grayscale)
#define POST_CONTRAST 1.03       // Adjusts contrast (1.0 for neutral, >1.0 for more contrast)

// New: Overall Animation Speed Control
#define ANIMATION_SPEED .2     // Controls the speed of all animations (1.0 for original speed)

// New: Stripe Color Adjustment Parameters (as multipliers for the base background)
#define STRIPE_MOD_DARK 0.6     // Multiplier for the darker parts of the stripes
#define STRIPE_MOD_BRIGHT .66   // Multiplier for the brighter parts of the stripes (0.8 + 0.2 from original)

// New: Vignette Parameters for Background
#define VIGNETTE_INTENSITY 35.0 // Intensity of vignette effect
#define VIGNETTE_POWER .10     // Falloff curve of vignette
#define DITHER_STRENGTH 0.05    // Strength of dithering to reduce banding


// General purpose small epsilon for numerical stability (from previous directives)
const float TINY_EPSILON = 1e-6; 

// The Robust Tanh Conversion Method: tanh_approx functions
// These are included as per the directive, even though 'tanh' is not directly used in this specific shader.
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), TINY_EPSILON));
}

vec3 tanh_approx(vec3 x) {
    return x / (1.0 + max(abs(x), TINY_EPSILON));
}


const int NUM_STEPS = 128;
const int AO_SAMPLES = 3;
const float INV_AO_SAMPLES = 1.0 / float(AO_SAMPLES);
const float EPSILON = 1e-5; // Kept as original shader defines it.
const vec3 RED = vec3(0.6,0.03,0.08);
const vec3 ORANGE = vec3(0.3,0.1,0.1);
const vec3 BG = vec3(0.05,0.05,0.075);

// lighting
float diffuse(vec3 n,vec3 l,float p_pow) { return pow(dot(n,l) * 0.4 + 0.6, p_pow); } // Renamed 'p' parameter to 'p_pow' to avoid conflict
float specular(vec3 n,vec3 l,vec3 e,float s) {      
    float nrm = (s + 18.0) / max((3.1415 * 13.0), TINY_EPSILON); // Robustness for division
    return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
}
float specular(vec3 n,vec3 e,float s) {      
    float nrm = (s + 8.0) / max((3.1415 * 8.0), TINY_EPSILON); // Robustness for division
    return pow(max(1.0-abs(dot(n,e)),0.0),s) * nrm;
}

// julia based on iq's implementation
float julia(vec3 p,vec4 q_julia) { // Renamed 'q' parameter to 'q_julia' to avoid conflict
    vec4 nz = vec4(0.0); // Explicitly initialized
    vec4 z = vec4(p,0.0); // Explicitly initialized
    float z2 = dot(p,p); // Explicitly initialized
    float md2 = 1.0; // Explicitly initialized      
    for(int i = 0; i < 11; i++) {
        md2 *= 4.0*z2;
        nz.x = z.x*z.x-dot(z.yzw,z.yzw);
        nz.y = 2.0*(z.x*z.y + z.w*z.z);
        nz.z = 2.0*(z.x*z.z + z.w*z.y);
        nz.w = 2.0*(z.x*z.w - z.y*z.z);
        z = nz + q_julia; // Uses renamed parameter
        z2 = dot(z,z);
        if(z2 > 4.0) break;
    }      
    return 0.25*sqrt(z2/max(md2, TINY_EPSILON))*log(z2); // Robustness for division
}

float rsq(float x) {
    x = sin(x);
    return pow(abs(x),3.0) * sign(x);
}

// world
float map(vec3 p) {
    const float M = 0.6;
    float animatedTime = iTime * ANIMATION_SPEED; // Apply animation speed
    float time = animatedTime + rsq(animatedTime*0.5) * 2.0; // Uses animatedTime
    return julia(p,vec4(  
        sin(time*0.96456)*0.451*M,
        cos(time*0.59237)*0.435*M,
        sin(time*0.73426)*0.396*M,
        cos(time*0.42379)*0.425*M
    ));
}
    
vec3 getNormal(vec3 p) {
    vec3 n = vec3(0.0); // Explicitly initialized
    n.x = map(vec3(p.x+EPSILON,p.y,p.z));
    n.y = map(vec3(p.x,p.y+EPSILON,p.z));
    n.z = map(vec3(p.x,p.y,p.z+EPSILON));
    return normalize(n-map(p));
}
float getAO(vec3 p,vec3 n) {      
    const float R = 3.0;
    const float D = 0.8;
    float r = 0.0; // Explicitly initialized
    for(int i = 0; i < AO_SAMPLES; i++) { // Loop counter explicitly int
        float f = float(i)*INV_AO_SAMPLES; // Explicitly initialized
        float h = 0.1+f*R; // Explicitly initialized
        float d = map(p + n * h); // Explicitly initialized
        r += clamp(h*D-d,0.0,1.0) * (1.0-f);
    }      
    return clamp(1.0-r,0.0,1.0);
}

float spheretracing(vec3 ori, vec3 dir, out vec3 p) {
    float t = 0.0; // Explicitly initialized      
    for(int i = 0; i < NUM_STEPS; i++) { // Loop counter explicitly int
        p = ori + dir * t;
        float d = map(p); // Explicitly initialized
        if(d <= 0.0 || t > 2.0) break;
        t += max(d*0.3,EPSILON); // Robustness for 'd*0.3'
    }      
    return step(t,2.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv_frag = fragCoord.xy / iResolution.xy; // Explicitly initialized and renamed
    vec2 uv = uv_frag * 2.0 - 1.0; // Explicitly initialized
    uv.x *= iResolution.x / max(iResolution.y, TINY_EPSILON); // Robustness for iResolution.y      
    
    float animatedTime = iTime * ANIMATION_SPEED; // Apply animation speed
    float time = animatedTime * 0.1; // Uses animatedTime
    vec2 sc = vec2(sin(time),cos(time)); // Explicitly initialized
    
    // tracing of distance map
    vec3 p_trace = vec3(0.0); // Explicitly initialized, renamed to avoid conflict
    vec3 ori = vec3(0.0,0.0,1.5); // Explicitly initialized
    vec3 dir = normalize(vec3(uv.xy,-1.0)); // Explicitly initialized      
    ori.xz = vec2(ori.x * sc.y - ori.z * sc.x, ori.x * sc.x + ori.z * sc.y);
    dir.xz = vec2(dir.x * sc.y - dir.z * sc.x, dir.x * sc.x + dir.z * sc.y);
          
    float mask = spheretracing(ori,dir,p_trace); // Uses renamed 'p_trace'
    vec3 n = getNormal(p_trace); // Uses renamed 'p_trace'
    float ao = pow(getAO(p_trace,n), 2.2); // Uses renamed 'p_trace'
    ao *= n.y * 0.5 + 0.5;
          
    // bg          
    // Initialize bg with solid BG color, then apply only the stripe modulation
    vec3 bg = BG; 
    bg *= STRIPE_MOD_DARK + (STRIPE_MOD_BRIGHT - STRIPE_MOD_DARK) * smoothstep(0.1,0.0,sin((uv.x-uv.y)*40.0));
    
    // NEW: Apply Vignette effect to the background only
    vec2 vignette_uv = fragCoord.xy / iResolution.xy; // Use fragCoord.xy for vignette
    vignette_uv *= 1.0 - vignette_uv.yx; // Transform UV for vignette
    float vig = vignette_uv.x * vignette_uv.y * VIGNETTE_INTENSITY; // Use define
    vig = pow(vig, VIGNETTE_POWER); // Use define

    // Apply dithering to reduce banding
    int x_dither = int(mod(fragCoord.x, 2.0));
    int y_dither = int(mod(fragCoord.y, 2.0));
    float dither_val = 0.0; // Explicitly initialized
    if (x_dither == 0 && y_dither == 0) dither_val = 0.25 * DITHER_STRENGTH;
    else if (x_dither == 1 && y_dither == 0) dither_val = 0.75 * DITHER_STRENGTH;
    else if (x_dither == 0 && y_dither == 1) dither_val = 0.75 * DITHER_STRENGTH;
    else if (x_dither == 1 && y_dither == 1) dither_val = 0.25 * DITHER_STRENGTH;
    vig = clamp(vig + dither_val, 0.0, 1.0);

    bg *= vig; // Apply vignette to background color
          
    // color
    vec3 l0 = normalize(vec3(-0.0,0.0,-1.0)); // Explicitly initialized
    vec3 l1 = normalize(vec3(0.3,0.5,0.5)); // Explicitly initialized
    vec3 l2 = normalize(vec3(0.0,1.0,0.0)); // Explicitly initialized
    vec3 color = RED * 0.4; // Explicitly initialized
    color += specular(n,l0,dir,1.0) * RED;
    color += specular(n,l1,dir,1.0) * ORANGE * 1.1;   
    color = color*ao*4.0;
          
    color = mix(bg,color,mask);
              
    // color = vec3(ao);
    // color = n * 0.5 + 0.5;
          
    // Apply BCS post-processing
    // Brightness
    color *= BRIGHTNESS_POST;
    // Saturation (mix between grayscale and original color)
    color = mix(vec3(dot(color, vec3(0.2126, 0.7152, 0.0722))), color, SATURATION_POST);
    // Contrast (adjust around 0.5 gray level)
    color = (color - 0.5) * POST_CONTRAST + 0.5;

    fragColor = vec4(pow(color,vec3(0.4545)),1.0);
}
