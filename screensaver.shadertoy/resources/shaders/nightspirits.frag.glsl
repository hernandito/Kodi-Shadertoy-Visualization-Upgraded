/*
    GLSL Shader: Street Lights Tunnel with Fog and Tanh Tonemap
    (Adapted for Kodi/GLSL ES 1.0/GLSL 1.00 environment)
*/

// --- USER PARAMETERS: Color Adjustment ---
#define BRIGHTNESS 1.00
#define CONTRAST   1.10
#define SATURATION 1.80
// -----------------------------------------

// --- UTILITY FUNCTIONS ---

// Custom Tanh function for older GLSL, with input clamping to prevent exp() overflow.
vec3 customTanh3(vec3 v) {
    // FIX: Clamp the input vector 'v' to a safe range (e.g., 0 to 15) 
    // to prevent exp() from overflowing and causing black artifacts.
    // Since accumulated color is always positive, we only clamp the max.
    v = clamp(v, 0.0, 15.0); 

    // Tanh(x) = (e^x - e^-x) / (e^x + e^-x)
    vec3 e_pos = exp(v);
    vec3 e_neg = exp(-v);
    return (e_pos - e_neg) / (e_pos + e_neg);
}

vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    // Adjust Brightness
    color += brightness - 1.0;
    
    // Adjust Contrast (pivot point is 0.5)
    color = (color - 0.5) * contrast + 0.5;
    
    // Adjust Saturation
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color = mix(grayscale, color, saturation);
    
    return color;
}

// --- CORE SHADER LOGIC ---

#define T (iTime*.15)
#define lightSpacing 10.0
#define lightIntensity 1.10

// Calculates the position of a single light orb
vec3 lightPos(float frac, float leftIsNOne){
    // leftIsNOne is 1.5 or -1.5 for left/right position
    return vec3(1.5 * leftIsNOne, 0.9, mod(2.0 - T + lightSpacing * frac, lightSpacing) - 2.0);
}

// Calculates the brightness contributed by the four moving light orbs
vec4 getBrightness(vec3 p) {
    
    // Define the 4 moving light positions
    vec3 lOrb1 = lightPos(0.0, -1.0);
    vec3 lOrb2 = lightPos(0.5, -1.0);
    vec3 rOrb1 = lightPos(0.25, 1.0);
    vec3 rOrb2 = lightPos(0.75, 1.0);
    
    // Distance to each orb
    float dL1 = length(p - lOrb1);
    float dL2 = length(p - lOrb2);
    float dR1 = length(p - rOrb1);
    float dR2 = length(p - rOrb2);
    
    // Distance to the nearest light source (used for fog/rstep calculation)
    float distToNearest = min(min(dL1, dL2), min(dR1, dR2));
    
    // Inverse square law for brightness falloff
    float brtL1 = lightIntensity / (dL1 * dL1);
    float brtL2 = lightIntensity / (dL2 * dL2);
    float brtR1 = lightIntensity / (dR1 * dR1);
    float brtR2 = lightIntensity / (dR2 * dR2);
    
    // Shade in a cone-like manner (like streetlights pointing down/forward)
    // The smoothstep function creates a soft edge to the light cone.
    brtL1 *= smoothstep(1.0, 0.0, (length(vec2(lOrb1.x, lOrb1.z) - vec2(p.x, p.z)) * 0.75 - (lOrb1.y - p.y)) * 2.0);
    brtL2 *= smoothstep(1.0, 0.0, (length(vec2(lOrb2.x, lOrb2.z) - vec2(p.x, p.z)) * 0.75 - (lOrb2.y - p.y)) * 2.0);
    brtR1 *= smoothstep(1.0, 0.0, (length(vec2(rOrb1.x, rOrb1.z) - vec2(p.x, p.z)) * 0.75 - (rOrb1.y - p.y)) * 2.0);
    brtR2 *= smoothstep(1.0, 0.0, (length(vec2(rOrb2.x, rOrb2.z) - vec2(p.x, p.z)) * 0.75 - (rOrb2.y - p.y)) * 2.0);
    
    // Apply distinct colors to each light (yellowish, magenta, white, cyan)
    vec3 totalB = vec3(1.0, 1.0, 0.8) * brtL1 + 
                  vec3(1.0, 0.9, 1.0) * brtL2 + 
                  vec3(1.0, 1.0, 1.0) * brtR1 + 
                  vec3(0.95, 1.0, 1.0) * brtR2;
    
    // Add a bit of ambient light from above
    float upness = max(p.y / length(vec2(p.x, p.z)), 0.0);
    totalB += upness * vec3(0.25, 0.21, 0.2);
    
    // Return total brightness (xyz) and distance to nearest light (w)
    return vec4(totalB, distToNearest);
}

void mainImage(out vec4 o, vec2 uv) {
    float d, a, e, i, rstep;
    float t = T; // Time variable
    
    vec3 pos = iResolution; // Use pos temporarily for screen resolution
    
    // Initialize output accumulator
    o = vec4(0.0);
    
    // Scale and center coordinates
    uv = (uv + uv - pos.xy) / pos.y;
    
    // Camera movement
    uv += vec2(cos(t * 0.1) * 0.3, cos(t * 0.3) * 0.1);
    
    d = 0.0; // Initial ray distance
    
    // Raymarching loop (20 steps)
    for(i = 0.0; i < 20.0; i++){
        
        // Convert screen coordinates/distance (d) into a 3D point (p)
        pos = vec3(uv * d, d + T); 
        
        // Get light data for the current 3D point (p) in the scene
        // pos.z-T is used because T is added to pos.z above, so we reverse it to get static Z.
        vec4 lightData = getBrightness(vec3(pos.xy, pos.z - T)); 
        
        // Stop rendering when we hit the ground level
        if (pos.y < -2.0){
            break;
        }
        
        // --- Fog/Noise (Space Warping) ---
        
        // Spin and twist the current position (pos.xy is the 3D point's X and Y)
        pos.xy *= mat2(cos(0.1 * t + pos.z / 8.0 + vec4(0.0, 33.0, 11.0, 0.0)));
        
        // Mirrored planes 4 units apart (rstep starts at 4 - distance from center)
        rstep = 4.0 - abs(pos.y);
        
        // Fractal loop to generate noise (the fog/smoke)
        for (a = 0.8; a < 32.0; a += a){
            // Apply turbulence
            pos += cos(0.7 * t + pos.yzx) * 0.2;
            
            // Apply noise (subtract from rstep)
            rstep -= abs(dot(sin(0.1 * t + pos * a ), 0.6 + pos - pos)) / a;
        }
        
        // --- Distance Accumulation and Color ---
        
        // e is the distance to the nearest light (w component of lightData)
        e = max(lightData.w, 0.1); 
        
        // rstep is the distance to the nearest surface or noise (clamped by light proximity)
        rstep = min(0.03 + 0.2 * abs(rstep), e);
        
        // Accumulate distance (move ray origin forward)
        d += rstep;
        
        // Accumulate color: Light data divided by distance (d) to simulate light attenuation/fog
        o += lightData / d;
        
    } // End raymarch loop
    
    
    // --- Post Processing ---

    // 1. Tanh Tone Mapping (Using the stable customTanh3 function)
    vec3 finalColor = customTanh3(o.xyz / 1e1);
    
    // 2. Apply Brightness, Contrast, Saturation (BCS) adjustment
    finalColor = applyBCS(finalColor, BRIGHTNESS, CONTRAST, SATURATION);

    // 3. Set output color (with opaque alpha)
    o = vec4(finalColor, 1.0);
}
