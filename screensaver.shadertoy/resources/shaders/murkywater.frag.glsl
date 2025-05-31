#define t (iTime*.01)

// === BCS Parameters ===
// Brightness: -1.0 to 1.0 (0.0 = no change, positive brightens, negative darkens)
// Contrast: 0.0 to 2.0 (1.0 = no change, higher increases contrast, lower reduces)
// Saturation: 0.0 to 2.0 (1.0 = no change, 0.0 = grayscale, higher increases saturation)
const float post_brightness = -0.1; // Default: no change
const float post_contrast = 1.05;   // Default: no change
const float post_saturation = 1.1; // Default: no change

float sphere(vec3 p, vec3 rd, float r){
    float b = dot( -p, rd ),
          inner = b*b - dot(p,p) + r*r;
    return inner < 0. ?  -1. : b - sqrt(inner);
}

vec3 kset(vec3 p) {
    float m=1000., mi=0., l;
    for (float i=0.; i<20.; i++) {
        p = abs(p)/dot(p,p) - 1.;
        l=length(p);
        if (l < m) m=l, mi=i;
    }
    return normalize( 3.+texture(iChannel0,vec2(mi*.218954)).xyz )
           * pow( max(0.,1.-m), 2.5+.3*sin(l*25.+t*50.) );
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

void mainImage( out vec4 o, vec2 uv )
{
    vec2 R = iResolution.xy,  
         mo = iMouse.z<.1 ? vec2(.1,.2) : iMouse.xy/R-.5;
    uv = (uv-.5*R)/ R.y;
    
    vec3 ro = -vec3(mo, 2.5-.7*sin(t*3.7535)),
         rd = normalize(vec3(uv,3.)),
         v = vec3(0), p;
    float tt, c=cos(t), s=sin(t);
    mat2 rot = mat2(c,-s,s,c);
    
    for (float i=20.; i<50.; i++) {
        tt = sphere(ro, rd, i*.03);
        p = ro+rd*tt;
        p.xy *= rot;
        p.xz *= rot;
        v = .9*v + .5*kset(p+p)*step(0.,tt);
    }

    o.xyz = v*v * vec3(1.2, 1.05, .9);
    
    // Apply BCS adjustments
    o.xyz = applyBCS(o.xyz);
}