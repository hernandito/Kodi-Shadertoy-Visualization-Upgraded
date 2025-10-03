/*
    GLSL Shader: Psychedelic Bands with Rotation
    
    Features:
    - Animation Speed Control
    - Brightness, Contrast, Saturation (BCS) Post-Processing
    - Central Glare Intensity and Reach Controls
    - Strand Thickness Control
*/

/* --- CONTROL PARAMETERS --- */
#define ANIMATION_SPEED 0.2   /* Master speed multiplier for internal animations. */
#define ROTATION_SPEED 0.1     /* Speed of the global clockwise rotation. Use a positive value for faster rotation. */

/* --- STRAND PARAMETERS --- */
#define STRAND_OPACITY_THRESHOLD 1.20 /* Controls the width/thickness of the main bands. Higher value (closer to 1.0) results in thinner strands. Lower value (closer to 0.0) results in thicker, wider strands. */

/* --- BRIGHTNESS / CONTRAST / SATURATION (BCS) --- */
#define BRIGHTNESS 0.20        /* Range: -1.0 (darker) to 1.0 (brighter) */
#define CONTRAST 2.00          /* Range: 0.0 (flat gray) to 2.0 (high contrast) */
#define SATURATION 1.40        /* Range: 0.0 (grayscale) to 2.0 (vivid) */

/* --- GLOW/GLARE PARAMETERS --- */
/* Controls the central RGB moving lights */
#define CENTRAL_GLARE_INTENSITY 0.0 /* Controls the overall strength/brightness of the central RGB lights. */
#define CENTRAL_GLARE_FALLOFF 8.0  /* Controls the light's reach. Higher value means less reach. */

/* Controls the white-ish base core */
#define CORE_INTENSITY 0.0         /* Controls the strength of the main, static core light. */


/* Global constant for saturation calculation (Luminosity coefficients) */
const vec3 LUM_COEFF = vec3(0.2126, 0.7152, 0.0722);


/* Function to apply Brightness, Contrast, and Saturation */
vec3 apply_bcs(vec3 color) {
    vec3 processed_color = color;
    
    /* 1. Brightness */
    processed_color += BRIGHTNESS;

    /* 2. Contrast */
    processed_color = (processed_color - 0.5) * CONTRAST + 0.5;

    /* 3. Saturation (using global luminosity coefficients) */
    float luminance = dot(processed_color, LUM_COEFF);
    vec3 gray = vec3(luminance);
    
    /* Mix the original color with the grayscale version */
    processed_color = mix(gray, processed_color, SATURATION);
    
    return processed_color;
}

/* Color palette function */
vec3 palette( float t ) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);
    return a + b*cos( 6.28318*(c*t+d) );
}

/* Main image function (Kodi compatible signature) */
void mainImage( out vec4 o, in vec2 u )
{
    float t = iTime * ANIMATION_SPEED;
    
    /* Map screen coordinates (u) to centered, aspect-corrected UV space (uv) */
    vec2 uv = (u.xy / iResolution.xy) * 1.5 - 1.0; 
    uv.x *= iResolution.x / iResolution.y;
    
    /* --- APPLY GLOBAL ROTATION --- */
    float rotation_angle = iTime * ROTATION_SPEED;
    float cosA = cos(rotation_angle);
    float sinA = sin(rotation_angle);

    /* Clockwise rotation matrix: [cos(A), sin(A); -sin(A), cos(A)] */
    vec2 rotated_uv;
    rotated_uv.x = uv.x * cosA + uv.y * sinA;
    rotated_uv.y = uv.y * cosA - uv.x * sinA; 

    uv = rotated_uv;
    /* ----------------------------- */
    
    float r = length(uv);
    float core = exp(-5.0 * r); 
    core = pow(core, 0.8);
    
    core *= 0.6 + 0.1*sin(10.0*r - t*2.0);
    
    float a = atan(uv.y, uv.x);
    
    float numStrands = 12.0; 
    
    float spiral = r * 5.0 - t * 2.0;
    float strandAngle = a * numStrands + spiral;
    
    float majorWave = sin(t * 1.5 + r * 9.0 + a * 2.0) * 0.6;
    float minorWave = sin(t * 2.3 + r * 8.0 + a * 4.0) * 0.4;
    strandAngle += majorWave + minorWave;
    
    float branchFreq = 5.0;
    float branchPhase = sin(t * 1.2 + r * 4.0);
    float branchEffect = sin(strandAngle * branchFreq + branchPhase * 3.14159) * exp(-2.0 * abs(sin(r * 2.0 - t * 0.5))) * 0.8;
    strandAngle += branchEffect;
    
    float bands = sin(strandAngle);
    
    /* --- STRAND THICKNESS CONTROL --- */
    bands = smoothstep(STRAND_OPACITY_THRESHOLD, 1.0, bands); 
    
    float thinBands = sin(strandAngle * 2.0 + 1.57);
    thinBands = smoothstep(0.9, 0.99, thinBands) * 0.3;
    bands = max(bands, thinBands);
    
    float colorInput = (a + spiral * 0.1) / 6.28318 + t * 0.15 + r * 0.3 + branchEffect * 0.2;
    vec3 bandColor = palette(colorInput);
    
    vec3 col;
    
    /* 1. RGB Glare (Strength and Falloff controlled) */
    col.r = CENTRAL_GLARE_INTENSITY * exp(-CENTRAL_GLARE_FALLOFF*length(uv*1.0 + 0.01*sin(t+0.0)));
    col.g = CENTRAL_GLARE_INTENSITY * exp(-CENTRAL_GLARE_FALLOFF*length(uv*1.0 + 0.01*sin(t+2.0)));
    col.b = CENTRAL_GLARE_INTENSITY * exp(-CENTRAL_GLARE_FALLOFF*length(uv*1.0 + 0.01*sin(t+4.0)));
    
    /* 2. White Core (Intensity controlled) */
    col += vec3(1.0) * core * CORE_INTENSITY;
    
    /* 3. Outer Bands */
    col += bandColor * bands * exp(-2.0*r);
    
    /* --- Post-Processing Stage --- */
    vec3 final_col = apply_bcs(col);
    
    o = vec4(final_col, 1.0);
}
