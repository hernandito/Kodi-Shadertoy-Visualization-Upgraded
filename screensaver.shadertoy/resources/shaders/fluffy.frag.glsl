// Shadertoy: 2D Smoke, Smooth Perlin-Style fBM with Mouse Interaction
//
// ---------------- USER PARAMETERS ----------------
#define BRIGHTNESS 1.0
#define CONTRAST   1.4
#define SATURATION 1.0
#define ANIMATION_SPEED .2
#define FOV .90
// -------------------------------------------------

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
    return -1.0 + 2.0*fract(sin(p)*43758.5453);
}

// A robust BCS function
vec4 bcs_final(vec4 color, float brightness, float contrast, float saturation) {
    color.rgb += brightness - 1.0;
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    
    // Using a luminance formula that is more robust for saturation
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color.rgb = mix(grayscale, color.rgb, saturation);
    
    return color;
}

float perlin(vec2 p) {
    vec2 pi = floor(p), pf = fract(p);
    vec2 bl = pi, br = pi + vec2(1.0,0.0), tl = pi + vec2(0.0,1.0), tr = pi + vec2(1.0,1.0);
    float a = dot(hash2(bl), pf-vec2(0,0));
    float b = dot(hash2(br), pf-vec2(1,0));
    float c = dot(hash2(tl), pf-vec2(0,1));
    float d = dot(hash2(tr), pf-vec2(1,1));
    vec2 u = pf*pf*pf*(pf*(pf*6.0-15.0)+10.0);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.54, f = 1.0;
    for(int i=0;i<5;i++) {
        v += a*perlin(p*f);
        f *= 2.1; a *= 0.47;
        p += 0.44*v;
    }
    return v;
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy - 0.5*iResolution.xy) / iResolution.y / FOV;
    uv.y -= 0.5;
 
    // Make mouse coordinates from -1 to +1, center = (0,0)
    vec2 mouse = iMouse.xy/iResolution.xy * 2.0 - 1.0;
    // Add mouse effect to the position (swirl, offset)
    float amt = iMouse.z > 0.0 ? 1.0 : 0.0;
    float mouseStr = 0.54 * amt;
    vec2 mouseDir = uv - mouse;
    float mouseDist = length(mouseDir);
    // Swirl field around mouse (adds movement, displacement, and curl)
    float swirl = 0.6*amt / (0.25 + 3.0*mouseDist);
    float ang = atan(mouseDir.y, mouseDir.x) + swirl * sin(iTime * 0.4 * ANIMATION_SPEED) * exp(-3.2*mouseDist);
    vec2 offset = mouseStr * smoothstep(0.48,0.01,mouseDist) * vec2(cos(ang),sin(ang));
    uv += offset;
    // You can let this "pull" the noise field as well for wild effects
    vec2 q = uv * 2.65 + offset*0.68;
    float t = iTime * 0.37 * ANIMATION_SPEED + 0.18*mouse.x - 0.11*mouse.y;
    float n = fbm(q + t*vec2(-0.19 + mouse.x, 0.22 - mouse.y));
    float m = fbm(q*1.36 - t*vec2(.13,-.30) + 0.8*n + mouse.yx*0.7);
    float smoke = smoothstep(0.42,1.86, m - 0.68*q.y);
    float smoke2 = smoothstep(0.32,.84, m - 0.88*q.x);
    float smoke4 = smoothstep(0.32,.84, m - 0.88*q.y);
    float smoke3 = smoothstep(0.12,.94, n - (0.8*q.y * sin(uv.x + (iTime * .05 * ANIMATION_SPEED + mouse.y*0.5))));
 
    float edge = 0.87-length(uv)*0.75;
    float alpha = clamp((smoke + smoke2 + smoke3 + smoke4)*edge*1.4, 0.0, 1.0);
 
    // Artistic palette, modulate with mouse for extra fun
    vec3 base = mix(vec3(0.92,0.94,0.97), vec3(0.49 + mouse.x*0.14,0.61 - mouse.y*0.12,0.82), n*0.78+0.11);
    vec3 high = vec3(0.81,0.92,1.00), low = vec3(0.09,0.13+mouse.x*0.07,0.22+mouse.y*0.11);
    vec3 col = mix(low,base,clamp(smoke*1.07+0.13,0.,1.));
    col = mix(col,high,0.15+0.21*n*(smoke + smoke4)-0.04*m);
    col *= vec3(alpha);
    col *= vec3(base.x, smoke2, smoke3); 
    col = pow(col,vec3(0.94));
    
    fragColor = bcs_final(vec4(col, alpha), BRIGHTNESS, CONTRAST, SATURATION);
}
