/*================================
=        Ink Quasar        =
=         Jaenam           =
================================*/

// Custom function for 2D rotation matrix
mat2 rot2D(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

// Custom swirl function
vec2 swirl(vec2 p, float strength, float speed) {
    float r = length(p);
    float a = atan(p.y, p.x) + strength / r * speed;
    return vec2(r * cos(a), r * sin(a));
}

// Custom warp/noise function
float warp(vec2 p, float speed) {
    float n1 = fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
    float n2 = fract(sin(dot(p + speed, vec2(12.9898, 78.233))) * 43758.5453);
    return mix(n1, n2, fract(speed));
}

// Simple Reinhard tonemapping function (more robust for low-precision environments)
vec3 reinhard_tonemap(vec3 color) {
    return color / (color + vec3(1.0));
}

void mainImage( out vec4 o, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 q = vec2(0.0);
    float v = 0.0;
    float l = 0.0;
    vec2 p = vec2(0.0);
    float noise = 0.0;
    float d = 0.0;
    vec3 pCol = vec3(0.0);
    vec3 c = vec3(0.0);
    
    // Vignette
    q = uv*(1.0-uv)*3.0; 
    v = pow(q.x*q.y, 0.9); 
    
    uv = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    
    // Pulsing light
    vec2 uv_rotated = uv * rot2D(-0.43);
    vec2 uv_powered = vec2(pow(abs(uv_rotated.x) * 2.0, 0.4), pow(abs(uv_rotated.y) * 0.8, 0.4));
    l = pow((0.6+0.3*abs(sin(1.2*iTime)))/length(uv_powered), 4.5);
    
    // Scale and rotate uv
    uv *= 2.0*mat2(0.7,-0.5,-0.4,1.2);
    
    // Swirl uv + noise
    p = swirl(uv, 2.0, 1.0);
    noise = 0.5*warp(p+0.1*iTime*0.1, 0.5*iTime*0.1)+0.5;
    p += noise + 0.5*iTime*0.1;
    
    // Ink style colorize
    d = smoothstep(0.0, 1.0, fract(p).y); 
    
    pCol = pow(0.5 + 0.45*cos(fract(p).x + vec3(0.0, 1.0, 2.0)*1.2), vec3(1.12, 1.12, 1.12));    
    c = pCol * pow(0.1/max(d, 1E-6), 0.4242);
    
    // Tonemap
    o = vec4(reinhard_tonemap((c*c+l*d+d*d)*v), 1.0);
}
