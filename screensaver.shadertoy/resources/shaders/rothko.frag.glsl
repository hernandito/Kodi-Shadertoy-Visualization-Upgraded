#define PI 3.14159265359
#define TWO_PI 6.28318530718

// --- Panning Animation Parameters ---
#define PAN_SPEED 0.015   // Speed of the horizontal panning effect (positive for right-to-left)

// --- Cream Color Brightness Animation Parameters ---
#define CREAM_BRIGHTNESS_ANIM_SPEED 0.042 // Speed of the subtle brightness variation
#define CREAM_BRIGHTNESS_ANIM_AMOUNT 0.39 // Intensity of the brightness variation (e.g., 0.05 for very subtle)
#define CREAM_BRIGHTNESS_ANIM_DETAIL 0.002 // Fineness/scale of the brightness texture (e.g., 0.001 for large, 0.01 for fine)

// Noise functions
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

float fbm(vec2 p) {
    float sum = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for(int i = 0; i < 6; i++) {
        sum += noise(p * freq) * amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    return sum;
}

// Voronoise - combines Voronoi and noise
float voronoise(vec2 p, float u, float v) {
    float k = 1.0 + 63.0 * pow(1.0 - v, 6.0);
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    vec2 a = vec2(0.0);
    
    for(int y = -2; y <= 2; y++) {
        for(int x = -2; x <= 2; x++) {
            vec2 g = vec2(x, y);
            vec3 o = vec3(hash(i + g)) * vec3(u, u, 1.0);
            vec2 d = g - f + o.xy;
            float w = pow(1.0 - smoothstep(0.0, 1.414, length(d)), k);
            a += vec2(o.z * w, w);
        }
    }
    
    return a.x / a.y;
}

// SDF functions
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Rotation function
mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

// Leaf pattern function
float leafPattern(vec2 uv, float scale, float time) {
    vec2 p = uv * scale;
    
    // Add some movement
    p.x += sin(p.y * 0.2 + time * 0.5) * 0.3;
    p.y += cos(p.x * 0.1 + time * 0.3) * 0.2;
    
    // Create leaf-like patterns
    float n1 = fbm(p + vec2(time * 0.1, 0.0));
    float n2 = fbm(p * 1.5 + vec2(0.0, time * 0.08));
    
    // Combine noise for complex leaf shadow patterns
    float pattern = smoothstep(0.4, 0.6, n1 * n2);
    
    // Add fine details
    pattern *= 0.8 + 0.2 * fbm(p * 5.0 + time * 0.05);
    
    return pattern;
}

// Moss texture function
float mossTexture(vec2 uv, float scale) {
    vec2 p = uv * scale;
    
    // Create base moss texture
    float base = fbm(p * 2.0);
    
    // Add clumping
    float clumps = smoothstep(0.3, 0.7, voronoise(p * 3.0, 0.8, 0.8));
    
    // Add fine details
    float details = fbm(p * 8.0) * 0.2;
    
    return base * clumps + details;
}

// Grass function
float grassBlades(vec2 uv, float scale, float time) {
    vec2 p = uv * scale;
    
    // Add swaying motion
    p.x += sin(p.y * 2.0 + time) * 0.1;
    
    // Create individual blades
    float blades = fbm(p * 3.0 + vec2(0.0, time * 0.1));
    blades = pow(blades, 1.5);
    
    // Add variation
    blades *= 0.8 + 0.2 * noise(p * 8.0 + time * 0.2);
    
    return blades;
}

// Sunbeam function
float sunbeams(vec2 uv, float time) {
    // Adjust UV to create beams from top
    vec2 p = uv - vec2(0.5, 1.0);
    p.x *= 1.5;
    
    // Rotate slightly
    p = rotate2D(sin(time * 0.1) * 0.2) * p;
    
    // Create rays
    float angle = atan(p.x, p.y);
    float dist = length(p);
    
    // Ray pattern
    float rays = sin(angle * 8.0 + time * 0.5) * 0.5 + 0.5;
    rays = pow(rays, 2.0);
    
    // Fade with distance
    rays *= smoothstep(1.5, 0.5, dist);
    
    // Add noise for volumetric effect
    rays *= 0.8 + 0.2 * noise(p * 5.0 + time * 0.1);
    
    return rays;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Apply horizontal panning displacement to fragCoord
    // This will scroll the entire image from right to left.
    vec2 pan_displacement = vec2(-iTime * PAN_SPEED * iResolution.x, 0.0);

    vec2 displaced_fragCoord = fragCoord + pan_displacement;

    // Adjust for aspect ratio
    vec2 uv = displaced_fragCoord / iResolution.xy;
    float aspectRatio = iResolution.x / iResolution.y;
    uv.x *= aspectRatio;
    
    // Center UV
    vec2 centeredUV = uv - vec2(aspectRatio * 0.5, 0.5);
    
    // Mouse influence
    vec2 mousePos = iMouse.xy / iResolution.xy;
    mousePos.x *= aspectRatio;
    float mouseDist = length(uv - mousePos);
    float mouseInfluence = smoothstep(0.5, 0.0, mouseDist);
    
    // Time variables
    float time = iTime * 0.2;
    
    // --- Cream Color Brightness Animation ---
    // Calculate a time-animated noise value based on original fragCoord.
    float cream_noise_val = fbm(fragCoord * CREAM_BRIGHTNESS_ANIM_DETAIL + iTime * CREAM_BRIGHTNESS_ANIM_SPEED);
    // Map noise from [0,1] to a subtle brightness range, e.g., [1-amount, 1+amount]
    float cream_brightness_modulator = 1.0 + (cream_noise_val - 0.5) * CREAM_BRIGHTNESS_ANIM_AMOUNT * 2.0;

    // Background gradient - sky color
    vec3 skyColor_lightBlue = vec3(0.6, 0.8, 0.9);
    vec3 skyColor_warmSunlight = vec3(0.9, 0.85, 0.6) * cream_brightness_modulator; // Apply modulator here

    vec3 skyColor = mix(
        skyColor_lightBlue,  // Light blue
        skyColor_warmSunlight,  // Warm sunlight (cream color) with brightness animation
        smoothstep(-0.5, 1.0, uv.y)
    );
    
    // Create leaf shadow patterns
    float leafScale = 3.0 + mouseInfluence * 2.0;
    float leafShadows = leafPattern(uv, leafScale, time);
    
    // Create moss texture
    float mossScale = 10.0 + mouseInfluence * 5.0;
    float moss = mossTexture(uv, mossScale);
    
    // Create grass
    float grassScale = 15.0;
    float grass = grassBlades(uv, grassScale, time);
    
    // Create sunbeams
    float beams = sunbeams(uv, time);
    beams *= 0.7 + mouseInfluence * 0.3;
    
    // Combine elements
    vec3 finalColor = vec3(0.0);
    
    // Base ground color - rich moss green
    vec3 groundColor = mix(
        vec3(0.2, 0.4, 0.1),  // Dark moss
        vec3(0.4, 0.6, 0.2),  // Light moss
        moss
    );
    
    // Add grass details
    groundColor = mix(
        groundColor,
        vec3(0.5, 0.7, 0.3),  // Grass color
        grass * 0.5
    );
    
    // Apply leaf shadows
    groundColor = mix(
        groundColor * 0.5,  // Shadowed ground
        groundColor,        // Lit ground
        leafShadows
    );
    
    // Blend ground with sky based on vertical position
    float groundMask = smoothstep(0.6, 0.4, uv.y);
    finalColor = mix(skyColor, groundColor, groundMask);
    
    // Add sunbeams
    finalColor = mix(
        finalColor,
        vec3(1.0, 0.9, 0.7),  // Warm sunlight color
        beams * 0.3 * (1.0 - groundMask * 0.7)
    );
    
    // Add mouse-reactive glow
    finalColor += vec3(0.8, 0.9, 0.5) * mouseInfluence * 0.2;
    
    // Enhance contrast
    finalColor = pow(finalColor, vec3(0.9));
    
    // Output final color
    fragColor = vec4(finalColor, 1.0);
}
