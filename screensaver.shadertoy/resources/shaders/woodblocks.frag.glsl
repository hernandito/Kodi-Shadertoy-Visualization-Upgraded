// Copyright Inigo Quilez, 2014 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

#define ANTIALIAS 1

#define ANIMATE

//#define FULL_PROCEDURAL

// Adjustable parameters
#define LINE_THICKNESS 0.25    // Controls line thickness (default: 0.5, range: 0.1 to 1.0, lower = thinner)
#define ANIMATION_SPEED 0.50   // Controls animation speed (default: 1.0, range: 0.5 to 2.0)

// === BCS Parameters ===
// Brightness: -1.0 to 1.0 (0.0 = no change, positive brightens, negative darkens)
// Contrast: 0.0 to 2.0 (1.0 = no change, higher increases contrast, lower reduces)
// Saturation: 0.0 to 2.0 (1.0 = no change, 0.0 = grayscale, higher increases saturation)
const float post_brightness = 0.10; // Default: no change
const float post_contrast = 1.10;   // Default: no change
const float post_saturation = 1.30; // Default: no change

float hash1(float n) { return fract(sin(n)*43758.5453); }
vec2 hash2(vec2 p) { p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))); return fract(sin(p)*43758.5453); }

#ifdef FULL_PROCEDURAL
float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    return mix(mix(hash1(n+0.0), hash1(n+1.0), f.x),
               mix(hash1(n+57.0), hash1(n+58.0), f.x), f.y);
}

vec3 texturef(in vec2 p) {
    vec2 q = p;
    p = p*vec2(6.0, 128.0);
    float f = 0.0;
    f += 0.500*noise(p); p = p*2.02;
    f += 0.250*noise(p); p = p*2.03;
    f += 0.125*noise(p); p = p*2.01;
    f /= 0.875;
    
    vec3 col = 0.6 + 0.4*sin(f*2.5 + 1.0 + vec3(0.0, 0.5, 1.0));
    col *= 0.7 + 0.3*noise(8.0*q.yx);
    col *= 0.8 + 0.2*clamp(2.0*noise(256.0*q.yx), 0.0, 1.0);
    col *= vec3(1.0, 0.65, 0.5) * 0.85;
    return col;
}
#else
vec3 texturef(in vec2 p) {
    return texture(iChannel0, p).xyz;
}
#endif

vec4 voronoi(in vec2 x, out vec2 resUV, out float resOcc) {
    vec2 n = floor(x);
    vec2 f = fract(x);
    
    vec2 uv = vec2(0.0);
    vec4 m = vec4(8.0);
    float m2 = 9.0;
    for (int j = -2; j <= 2; j++)
    for (int i = -2; i <= 2; i++) {
        vec2 g = vec2(float(i), float(j));
        vec2 o = hash2(n + g);
        #ifdef ANIMATE
        o = 0.5 + 0.5*sin(0.5*iTime*ANIMATION_SPEED + 6.2831*o);
        #endif    
        vec2 r = g - f + o;
        
        vec2 u = vec2(dot(r, vec2(0.5, 0.866)), 
                      dot(r, vec2(0.5, -0.866)));
        vec2 d = vec2(-r.y, 1.0);
        float h = 0.5*abs(r.x) + 0.866*r.y;
        if (h > 0.0) {
            u = vec2(h, r.x);
            d = vec2(0.866*abs(r.x) + 0.5*r.y, 0.5*step(0.0, r.x));
        }
        
        if (d.x < m.x) {
            m2 = m.x;
            m.x = d.x;
            m.y = dot(n + g, vec2(7.0, 113.0));
            m.z = d.y;
            m.w = max(r.y, 0.0);
            uv = u;
        } else if (d.x < m2) {
            m2 = d.x;
        }
    }
    resUV = uv;
    resOcc = m2 - m.x;
    return m;
}

// Apply BCS adjustments
vec3 applyBCS(vec3 col) {
    // Apply brightness
    col = clamp(col + post_brightness, 0.0, 1.0);
    // Apply contrast
    col = clamp((col - 0.5) * post_contrast + 0.5, 0.0, 1.0);
    // Apply saturation
    vec3 grayscale = vec3(dot(col, vec3(0.299, 0.587, 0.114))); // Luminance
    col = mix(grayscale, col, post_saturation);
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 tot = vec3(0.0);
    
    #ifdef ANTIALIAS
    for (int j = 0; j < ANTIALIAS; j++)
    for (int i = 0; i < ANTIALIAS; i++) {
        vec2 off = vec2(float(i), float(j)) / float(ANTIALIAS);
    #else
        vec2 off = vec2(0.0);
    #endif
        
        vec2 q = (fragCoord + off) / iResolution.xy;
        vec2 p = -1.0 + 2.0*q;
        p.x *= iResolution.x / iResolution.y;
        vec2 uv = vec2(0.0);
        
        vec2 dp = vec2(0.004, 0.0);
        
        float occ = 0.0;
        vec4 c = voronoi(3.5*p, uv, occ);
        
        vec2 tmp; float tmp2;
        float d = abs(voronoi(3.5*(p + dp.xy), tmp, tmp2).z - voronoi(3.5*(p - dp.xy), tmp, tmp2).z) +
                  abs(voronoi(3.5*(p + dp.yx), tmp, tmp2).z - voronoi(3.5*(p - dp.yx), tmp, tmp2).z);
        
        // Color
        c.y = hash1(c.y);
        vec3 col = 0.6 + 0.4*sin(c.y*2.5 + 1.0 + vec3(0.0, 0.5, 1.0));
        col *= 0.4 + 0.6*smoothstep(0.1, 0.25, abs(hash1(c.y + 0.413) - 0.5));
        
        // Texture    
        col *= 1.7*pow(texturef(uv), vec3(0.4));
        
        // Lighting
        col *= clamp(0.65 + c.z*0.35, 0.0, 1.0);
        col *= sqrt(clamp(1.0 - c.x, 0.0, 1.0));
        col *= clamp(1.0 - 0.3*c.w, 0.0, 1.0);
        col *= 0.6 + 0.4*vec3(sqrt(clamp(8.0*occ, 0.0, 1.0)));
        
        // Pattern
        if (hash1(c.y) > 0.6) {
            float pa = sin(c.w + (1.0 - 0.7*c.y)*25.0*uv.y)*sin((1.0 - 0.7*c.y)*25.0*uv.x);
            col *= smoothstep(0.0, 0.3, abs(pa - 0.6));
            col *= 1.0 - 0.35*smoothstep(0.6, 0.7, pa);
        }
        
        // Wireframe with adjustable thickness
        col *= 1.0 - d * LINE_THICKNESS;
        
        // Tint 
        col = pow(col, vec3(1.0, 1.0, 0.8));
        
        // Vignette effect
        vec2 vigUV = q;
        vigUV *= 1.0 - vigUV.yx;
        float vignetteIntensity = 25.0; // Adjusted for softer effect
        float vignettePower = 0.7;     // Adjusted for smoother falloff
        float vig = vigUV.x * vigUV.y * vignetteIntensity;
        vig = pow(vig, vignettePower);
        
        // Apply dithering to reduce banding
        const float ditherStrength = 0.02; // Reduced strength
        int x = int(mod(fragCoord.x, 2.0));
        int y = int(mod(fragCoord.y, 2.0));
        float dither = 0.0;
        if (x == 0 && y == 0) dither = 0.25 * ditherStrength;
        else if (x == 1 && y == 0) dither = 0.75 * ditherStrength;
        else if (x == 0 && y == 1) dither = 0.75 * ditherStrength;
        else if (x == 1 && y == 1) dither = 0.25 * ditherStrength;
        vig = clamp(vig + dither, 0.0, 1.0);
        
        col *= vig;
        
        tot += col;
    }
    
    #ifdef ANTIALIAS
    tot /= float(ANTIALIAS*ANTIALIAS);
    #endif
    
    // Apply BCS adjustments
    tot = applyBCS(tot);
    
    fragColor = vec4(tot, 1.0);
}