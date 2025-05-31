// Main reference and study example: https://www.shadertoy.com/view/ltSczW by Shane

// Editable Parameters
#define TIME_SCALE       0.25        // Speed of scroll and ball motion
#define TILE_AMOUNT      4.0         // Number of tiles visible
#define MAX_BALL_ST_HEIGHT 2.6       // Maximum height of ball's trajectory
#define BALL_RADIUS      0.4         // Radius of the ball
#define BALL_COLOR       vec3(1.1, 0.7, 0.0)  // Yellow (affects ball and step highlight)
#define SHADOW_DARKNESS  0.95        // Darkness factor for the ball shadow (0.0 to 1.0, lower is darker)
#define cols0            vec3(0.7, 0.7, 0.7)  // Light Gray (top section of hex)
#define cols1            vec3(0.4, 0.4, 0.4)  // Medium Gray (bottom-left section of hex)
#define cols2            vec3(0.2, 0.2, 0.2)  // Dark Gray (bottom-right section of hex)
#define VIGNETTE_INTENSITY 11.0      // Intensity of the vignette effect (increase for stronger darkening, decrease for weaker)
#define VIGNETTE_POWER   0.40        // Power to control the extent of the vignette (lower for wider spread, higher for narrower)

// Math
#define PI     3.141592653
#define PI_2   6.283185307
#define SQRT_2       1.41421356237
#define SQRT_3       1.73205080757
#define SQRT_3D2     0.8660254
#define SQRT_3D6     0.28867513
#define EPSILON_F 0.001
#define HS 0.816496581
#define HEX_SCALING     vec2(1.0, 1.7320508)
#define INV_HEX_SCALING vec2(1.0, 0.577350272)

// Array of colors for hex sections
vec3 cols[3];

// Custom round function for GLSL ES 1.00 compatibility
float customRound(float x) {
    return floor(x + 0.5);
}

vec2 customRound(vec2 v) {
    return vec2(customRound(v.x), customRound(v.y));
}

float time() { return iTime * TIME_SCALE; }

// 2D rotation matrix construction
mat2 r2(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Diamond distance-field
float isoDiamond(vec2 p) {
    return dot(abs(p), vec2(HEX_SCALING.x * 0.5, HEX_SCALING.y * 0.5)); 
}

// Hexagon parameters from uv
vec3 hexagon(vec2 st) {
    vec2 snap = customRound(st * INV_HEX_SCALING);
    vec2 center = floor(st * INV_HEX_SCALING) + vec2(0.5);
    
    snap   *= HEX_SCALING;
    center *= HEX_SCALING;

    float d_center = distance(center, st);
    float d_snap   = distance(snap, st);
    
    return d_center < d_snap ? vec3(center, d_center) : vec3(snap, d_snap);
}

// Ball physics (parabola trajectory of projectile motion)
vec2 ballProjectileMotion() {
    float ballX = 4.0 - abs(8.0 * fract(0.5 * time()) - 4.0);
    return vec2(ballX - 2.0, ballX * 1.225 - 0.30625 * ballX * ballX + BALL_RADIUS);
}

// Hexagon AO
float computeAO(vec2 p, float k) {    
    float t1 = p.y;
    float t2 = 0.5 * SQRT_3 * p.x - 0.5 * p.y;
    float t3 = -0.5 * SQRT_3 * p.x - 0.5 * p.y;

    float d = max(0.0, -min(t1, min(t2, t3)));
    return 1.0 - exp(-k * d);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {    
    // Initialize the colors array
    cols[0] = cols0;  // Light Gray (top section of hex)
    cols[1] = cols1;  // Medium Gray (bottom-left section of hex)
    cols[2] = cols2;  // Dark Gray (bottom-right section of hex)

    vec2 uv = (2.0 * fragCoord - iResolution.xy) * TILE_AMOUNT / iResolution.y;
    vec2 offset = time() * HEX_SCALING;
    vec2 st = uv + offset;
    
    // Hexagon grid geometry values
    vec3 hex = hexagon(st); // xy - center coords, z - distance to center
    vec2 prel = st - hex.xy; // position relative to center
    
    // Diamonds division
    float id = (prel.x < 0.0 && -prel.y * HEX_SCALING.y > prel.x * HEX_SCALING.x) ? 1.0 : 
               (prel.y * HEX_SCALING.y > prel.x * HEX_SCALING.x) ? 0.0 : 2.0; // Counterclockwise from top
    float dimondDist = isoDiamond(r2(PI_2 * id / 3.0) * prel - vec2(0.0, SQRT_3D6)) * 4.0; // * 4.0 as maximum possible distance in our rhombus is 0.25
    float edgeMaskGrid = (smoothstep(1.0, 0.93, dimondDist) + smoothstep(0.77, 0.85, dimondDist) - smoothstep(0.75, 0.83, dimondDist)) * 0.6 + 0.4;
    
    // Ball motion
    vec2 ballLoacalPos = ballProjectileMotion();
    vec2 ballSTpos = ballLoacalPos + offset + vec2(0.0, SQRT_3D6);
    
    // Ball shape
    vec2 ballCoords = st - ballSTpos;
    float ballMask = smoothstep(BALL_RADIUS, BALL_RADIUS * 0.95, length(ballCoords));
    float ballEdge = smoothstep(BALL_RADIUS, BALL_RADIUS * 0.8, length(ballCoords)) * 0.4 + 0.6;

    // Start calculating scene color   
    vec3 col = edgeMaskGrid * cols[int(id)];

    // Original highlight logic
    float stepTime = floor(time());
    float xCoord = mod(stepTime, 2.0) == 0.0 ? -2.0 : 2.0;
    vec2 hilightCoords = -vec2(xCoord, 0.0) - stepTime * HEX_SCALING;
    if (length(hex.xy + hilightCoords) < EPSILON_F) {
        float timeFract = fract(time());
        float highlightEffectFade = 1.0 - pow(2.0 * timeFract - 1.0, 2.0);
        
        vec3 effectColor = id == 0.0 ? BALL_COLOR * (mix(1.5, 1.5 + sin((dimondDist - sqrt(timeFract)) * 34.0), float(dimondDist < sqrt(timeFract)))) : BALL_COLOR;
        float effectEdgeMask = smoothstep(1.0, 0.92, dimondDist) * 0.6 + 0.4;
        col = mix(col, effectEdgeMask * effectColor, highlightEffectFade);
    }
   
    // Calculate AO and add to the scene.
    vec2 stAO = st + vec2(0.5, SQRT_3D6);
    float AO = computeAO(stAO - hexagon(stAO).xy, 5.0) * 0.5 + 0.6;
    col *= AO;
    
    // Shadow calculation
    vec2 PRELuw = vec2(prel.x, id == 0.0 ? prel.y * sqrt(6.0) : abs(prel.x) * SQRT_2);
    vec2 PosWxy = vec2(hex.x, hex.y * HS) + PRELuw;
    float z = (hex.y) / SQRT_3D2;
    float PosWz = id == 0.0 ? z : z + SQRT_3 * prel.y - abs(prel.x);
    
    float shadowSize = distance(PosWxy, vec2(ballSTpos.x, SQRT_2 * 0.5 + HS * offset.y));

    float ballWHeight = (ballSTpos.y - SQRT_3D6) / SQRT_3D2 - PosWz;
    float ballSize = smoothstep(0.0, 2.0, ballWHeight * ballWHeight) * BALL_RADIUS * 0.5 + BALL_RADIUS;
    float attenRatio = 0.4 * smoothstep(0.0, 4.5, ballWHeight);
    float penumbraRatio = 0.6 * smoothstep(0.0, 0.7, ballWHeight);
    col *= smoothstep(ballSize * (1.0 - penumbraRatio), ballSize * (1.0 + penumbraRatio), shadowSize) * (SHADOW_DARKNESS - attenRatio) + (1.0 - SHADOW_DARKNESS + attenRatio);
                
    // Draw ball according to its mask around position
    vec3 skyGI = vec3(max(ballCoords.y, 0.0));
    vec3 fromGridGI = (max(ballCoords.x, 0.0) * cols[1] + max(-ballCoords.x, 0.0) * cols[2] + max(-ballCoords.y, 0.0) * cols[0]);
    vec3 ballGI = skyGI + 1.1 * fromGridGI * (1.1 - ballLoacalPos.y / MAX_BALL_ST_HEIGHT);
    vec3 ballColor = ballGI + 1.1 * BALL_COLOR;
    col = mix(col, ballColor * ballEdge, ballMask);


    fragColor = vec4(col, 1.0);
}