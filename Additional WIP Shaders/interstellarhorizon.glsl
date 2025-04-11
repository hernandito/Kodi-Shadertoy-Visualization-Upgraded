/*
    "Grok" - Warm Animated Version with Rotation, Drift & Fire-Like Effect
    + Secondary Blue Pulsating Ring with Animated Irregular Edges
    + Black Vignette Effect
*/

// 2D noise function to create randomness
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Smooth interpolation between noise samples
float smoothNoise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    float n00 = noise(i);
    float n10 = noise(i + vec2(1.0, 0.0));
    float n01 = noise(i + vec2(0.0, 1.0));
    float n11 = noise(i + vec2(1.0, 1.0));
    
    return mix(mix(n00, n10, u.x), mix(n01, n11, u.x), u.y);
}

// Fractal noise function for more detailed effects
float fractalNoise(vec2 uv, float time) {
    float n = 0.0;
    float amp = 1.0;
    for (int i = 0; i < 4; i++) {
        n += smoothNoise(uv * (6.0 + float(i) * 1.5) + time * amp * 1.3) * amp;
        amp *= 0.5;
    }
    return n;
}

void mainImage( out vec4 O, vec2 I )
{
    vec2 r = iResolution.xy;
    vec2 p = (I + I - r) / r.y;

    // Animation time factor
    float t = iTime * 0.13;

    // Center drift to prevent burn-in
    vec2 drift = vec2(0.12 * sin(t * 0.4), 0.12 * cos(t * 0.3));
    p += drift;

    // Apply rotating motion
    float angle = t * 0.2;
    mat2 rotation = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    p = rotation * p;

    // Pulsating effect
    float radius = 0.1 + 0.02 * sin(t * 0.7);

    // Warm fire-like color palette
    vec3 baseColor = vec3(.6, 0.31, 0.07); // Stronger fire tones (reddish-orange)

    // Animated brightness pulsing
    float brightness = 0.65 + 0. * sin(t * 0.2 + cos(t * 0.3));
    vec3 color = baseColor * brightness;

    // Adjusted intensity for a thicker glowing line
    float thickness = 0.07;
    float intensity = thickness / abs(length(p) - radius + .02 / (p.xxxx - p.y)).r;

    // Fire-like effect using animated noise
    float flameScale = 16.0;  
    float flameMovement = t * 1.2;  
    float fireNoise = smoothNoise(p * flameScale + flameMovement) * 0.1;
    float fireEffect = 0.051 / (abs(length(p) - radius - fireNoise) + 0.1);

    // **Secondary Blue Pulsating Ring with Irregular Animated Edges**
    float blueRingRadius = 0.03 + 0.003 * sin(t * .3); // Expanding/contracting motion
    float blueNoiseScale = 2.0;
    float blueNoiseSpeed = t * 10.0;
    float blueEdgeNoise = fractalNoise(p * blueNoiseScale, blueNoiseSpeed) * 0.03;
    float blueRingEffect = 0.05 / (abs(length(p) - blueRingRadius - blueEdgeNoise) + 0.05);
    
    vec3 blueColor = vec3(0.1, 0.2, 1.) * (0.4 + 0.1 * sin(t * 2.0)); // Glowing blue

    // Combine main fire glow with animated fire effect and blue plasma ring
    vec3 finalColor = color * (intensity + fireEffect) + blueColor * blueRingEffect;


    // Output final composition
    O = vec4(finalColor, 1.0);
}
