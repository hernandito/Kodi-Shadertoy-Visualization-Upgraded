// https://www.shadertoy.com/view/WclSWn

//Number of turbulence waves
#define TURB_NUM 10.0
//Turbulence wave amplitude
#define TURB_AMP 1.0
//Turbulence wave speed
#define TURB_SPEED 0.25
//Turbulence frequency
#define TURB_FREQ 3.5
//Turbulence frequency multiplier
#define TURB_EXP 1.7

// Signed distance to a circle
float sdfCircle(vec2 p, float r) {
    return length(p) - r;
}

// Apply turbulence to coordinates
vec2 turbulence(vec2 p)
{
    // Turbulence starting scale
    float freq = TURB_FREQ;
    
    // Turbulence rotation matrix
    mat2 rot = mat2(0.6, -0.8, 0.8, 0.6);
    
    // Loop through turbulence octaves
    for(float i = 0.0; i < TURB_NUM; i++)
    {
        // Scroll along the rotated y coordinate
        float phase = freq * (p * rot).y + TURB_SPEED * iTime + i;
        // Add a perpendicular sine wave offset
        p += TURB_AMP * rot[0] * sin(phase) / freq;
        
        // Rotate for the next octave
        rot *= mat2(0.6, -0.8, 0.8, 0.6);
        // Scale down for the next octave
        freq *= TURB_EXP;
    }
    
    return p;
}

vec3 random(float seed){
    vec3 n = texture(iChannel0, vec2(seed) + iTime * 0.0005).rgb - 0.5; // Adjust 0.002 to fine-tune texture animation speed
    return n;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy * 1.0 - iResolution.xy) / iResolution.y;
    vec3 col = vec3(1.0, 0.98, 0.94); // Set background to cream color (adjust RGB values to fine-tune shade)

    // Zoom level parameter
    // - Controls how much of the effect is visible on screen
    // - 1.0 = default zoom (original view before zoomLevel was introduced)
    // - < 1.0 = zoom out (see a wider view of the pattern, e.g., 0.5 shows more area)
    // - > 1.0 = zoom in (see a closer view of the pattern, e.g., 4.0 shows a more detailed view)
    float zoomLevel = 2.5; // Zoom in to focus on a closer view of the effect
    uv *= zoomLevel;

    uv.x = abs(uv.x);
  
    vec2 p = turbulence(uv);
    // vec2 p = uv;

    float d = 1.;

    for(float i = 0.; i < 20.; i++) {
        float seed = (i + 1. / i) * 0.1;

        vec3 n = random(seed);
        vec2 pos = n.xy * 4.;
        pos.x = abs(pos.x);
        float r = n.z + 0.2;
        float d1 = 1e10; // Initialize d1 to avoid uninitialized warning
        d1 = sdfCircle(p - pos, r);
        d = min(d, d1);
    }
    
    // Darken the cream background where splotches are present
    col *= (1.0 - smoothstep(0.0, 1.0, d)); // Adjust smoothstep range to fine-tune splotch contrast

    // Calculate alpha based on luminance, making black areas more transparent
    float luminance = dot(col, vec3(1.299, 1.587, 1.114));
    // Parameter 1: Transparency threshold
    // - This controls where transparency starts transitioning to full opacity
    // - 0.0 means transparency starts at pure black; 0.3 means it starts at a brighter gray
    // - Increase to 0.5 to make more areas transparent (even brighter areas get some transparency)
    // - Decrease to 0.1 to make only the darkest areas transparent
    float transparencyThreshold = 0.1;
    
    // Parameter 2: Minimum alpha
    // - This sets the transparency for the blackest areas (0.0 = fully transparent, 1.0 = fully opaque)
    // - 0.5 means 50% transparent
    // - Decrease to 0.3 for more transparency (70% transparent)
    // - Increase to 0.7 for less transparency (30% transparent)
    float minAlpha = 0.5;

    float alpha = smoothstep(0.0, transparencyThreshold, luminance);
    alpha = mix(minAlpha, 0.50, alpha);

    fragColor = vec4(col, alpha);
}