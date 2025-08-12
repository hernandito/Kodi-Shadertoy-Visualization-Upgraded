precision mediump float; // Set default precision for floats

const float PI  = 3.14159265359;

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float smin(float a, float b, float k){
    float f = clamp(0.5 + 0.5 * ((a - b) / k), 0.0, 1.0); // Explicitly 0.0f, 1.0f
    return (1.0 - f) * a + f  * b - f * (1.0 - f) * k; // Explicitly 1.0f
}

float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

float time = 0.0; // Initialized global time
bool lightingPass = false; // Initialized global lightingPass

vec4 leaf(vec3 p, vec2 uv) {
    float thick = clamp(uv.y, 0.7, 1.0); // Explicitly 0.7f, 1.0f
    thick = 1.0; // Explicitly 1.0f
    float th = thick * 0.16; // Explicitly 0.16f
    pR(p.xz, -uv.x);
    float width = mix(0.5, 0.1, min(uv.y, 1.0)); // Explicitly 0.5f, 0.1f, 1.0f
    width = 0.75 / max(uv.y, 1e-6); // Robust division, Explicitly 0.75f
    width *= thick;
    vec3 n = normalize(vec3(1.0,0.0,width)); // Explicitly 1.0f, 0.0f
    float d = -dot(p, n);
    d = max(d, dot(p, n * vec3(1.0,1.0,-1.0))); // Explicitly 1.0f, 1.0f, -1.0f
    float len = mix(PI / 1.2, PI / 2.0, pow(uv.y/2.9, 2.0)); // Explicitly 1.2f, 2.0f, 2.9f, 2.0f
    len = max(len, 0.0); // Explicitly 0.0f
    pR(p.yz, PI / 2.0 - len); // Explicitly 2.0f
    d = smax(d, p.y, thick);
    d = smax(d, abs(length(p) - uv.y) - thick * th, th);
    vec2 uuv = vec2(
        atan(p.y, p.z) / max(-len, 1e-6), // Robust division
        p.x
        );
    vec3 col = mix(vec3(0.0), vec3(0.5,1.0,0.7) * 0.05, 1.0-smoothstep(0.0, 0.5, uuv.x)); // Explicitly 0.0f, 0.5f, 1.0f, 0.7f, 0.05f, 1.0f, 0.0f, 0.5f
    col += vec3(0.06,0.0,0.03) * max(1.0 - uv.y / 2.0, 0.0); // Explicitly 0.06f, 0.0f, 0.03f, 1.0f, 2.0f, 0.0f
    col = mix(col, col * 0.2, 1.0-smoothstep(0.0, 0.2, uuv.x)); // Explicitly 0.2f, 1.0f, 0.0f, 0.2f
    return vec4(d, col);
}


vec4 opU(vec4 a, vec4 b) {
    return a.x < b.x ? a : b;
}

vec4 bloom(vec3 p) {

    float bound = length(p - vec3(0.0,-1.2,0.0)) - 3.3; // Explicitly 0.0f, -1.2f, 0.0f, 3.3f
    bound = max(bound, p.y - 1.1); // Explicitly 1.1f
    if (bound > 0.01 && ! lightingPass) { // Explicitly 0.01f
        return vec4(bound, 0.0, 0.0, 0.0); // Explicitly 0.0f
    }

    vec2 cc = vec2(5.0, 8.0); // Explicitly 5.0f, 8.0f
    if (iMouse.z > 0.0) { // Explicitly 0.0f
        cc = floor(iMouse.xy / max(iResolution.xy, 1e-6) * 10.0); // Robust division, Explicitly 10.0f
    }
    float aa = atan(cc.x / max(cc.y, 1e-6)); // Robust division
    float r = (PI*2.0) / max(sqrt(cc.x*cc.x + cc.y*cc.y), 1e-6); // Robust division, Explicitly 2.0f
    mat2 rot = mat2(cos(aa), -sin(aa), sin(aa), cos(aa));
    
    vec2 offset = vec2(1.0, 2.0) * time * r * rot; // Explicitly 1.0f, 2.0f
    
    vec2 uv = vec2(
        atan(p.x, p.z),
        length(p)
    );

    uv -= offset;

    uv = rot * uv;
    vec2 cell = floor(uv / max(r, 1e-6) + 0.5); // Replaced round with floor(x + 0.5), Robust division

    vec4 d = vec4(1e12, vec3(0.0)); // Explicitly 0.0f

    // Replaced multiple opU calls with nested loops
    for(float i = -2.0; i <= 1.0; i += 1.0){ // Explicitly -2.0f, 1.0f, 1.0f
       for(float j = -2.0; j <= 1.0; j += 1.0) // Explicitly -2.0f, 1.0f, 1.0f
       {
            d = opU(d, leaf(p, ((cell + vec2(i, j)) * rot * r) + offset));
       }
    }

    return d;
}

vec4 map(vec3 p) {
    return bloom(p);
}

vec3 calcNormal(vec3 pos){
    float eps = 0.0005; // Explicitly 0.0005f
    vec2 e = vec2(1.0,-1.0) * 0.5773; // Explicitly 1.0f, -1.0f, 0.5773f
    return normalize(
        e.xyy * map(pos + e.xyy * eps).x + 
        e.yyx * map(pos + e.yyx * eps).x + 
        e.yxy * map(pos + e.yxy * eps).x + 
        e.xxx * map(pos + e.xxx * eps).x
    );
}

// https://www.shadertoy.com/view/lsKcDD
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0; // Explicitly 1.0f
    float t = mint; // Explicitly initialized
    float ph = 1e10; // Explicitly initialized
    
    for( int i=0; i<64; i++ ) // Explicitly 64
    {
        float h = map( ro + rd*t ).x; // Explicitly initialized
        res = min( res, 10.0*h/max(t, 1e-6) ); // Robust division, Explicitly 10.0f
        t += h;
        if( res < 0.0001 || t > tmax ) break; // Explicitly 0.0001f
        
    }
    return clamp( res, 0.0, 1.0 ); // Explicitly 0.0f, 1.0f
}

// https://www.shadertoy.com/view/Xds3zN
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0; // Explicitly 0.0f
    float sca = 1.0; // Explicitly 1.0f
    for( int i=0; i<5; i++ ) // Explicitly 5
    {
        float hr = 0.01 + 0.12*float(i)/4.0; // Explicitly 0.01f, 0.12f, 4.0f
        vec3 aopos = nor * hr + pos; // Explicitly initialized
        float dd = map( aopos ).x; // Explicitly initialized
        occ += -(dd-hr)*sca;
        sca *= 0.95; // Explicitly 0.95f
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ); // Explicitly 1.0f, 3.0f, 0.0f, 1.0f
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro ); // Explicitly initialized
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) ); // Explicitly 0.0f
    vec3 vv = normalize( cross(uu,ww)); // Explicitly initialized
    return mat3( uu, vv, ww );
}

#define AA 1 // Hardcoded AA to 1

// --- POST-PROCESSING DEFINES (BCS) ---
#define BRIGHTNESS 1.1    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.4      // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.30    // Saturation adjustment (1.0 = neutral)

// --- ANIMATION PARAMETERS ---
#define ANIMATION_SPEED 0.20 // Global animation speed multiplier (1.0 = normal speed)

// --- COLOR PARAMETERS ---
#define BACKGROUND_PLANE_COLOR vec3(0.435, 0.62, 0.51) // Color of the background plane

// --- VIGNETTE PARAMETERS ---
#define VIGNETTE_INTENSITY 25.0 // Intensity of vignette
#define VIGNETTE_POWER 0.60     // Falloff curve of vignette
#define DITHER_STRENGTH 0.05    // Strength of dithering (0.0 to 1.0)

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    vec3 col_final; // Renamed col to col_final to avoid conflict
    vec3 tot = vec3(0.0); // Explicitly 0.0f

    float mTime = mod(iTime * ANIMATION_SPEED / 2.0, 1.0); // Explicitly 2.0f, 1.0f, apply animation speed
    time = mTime; // Global time variable

    vec2 o = vec2(0.0); // Explicitly 0.0f

    // With AA hardcoded to 1, the loop is effectively unrolled.
    // pixel coordinates
    o = vec2(0.0, 0.0); // For AA = 1, o is always (0,0)
    // time coordinate (motion blurred, shutter=0.5)
    // float d_time = 0.5*sin(fragCoord.x*147.0)*sin(fragCoord.y*131.0); // Not needed for AA=1
    // time = mTime - 0.1*(1.0/24.0)*(float(0)+d_time)/max(float(1*1-1), 1e-6); // Simplified for AA=1
    // For AA=1, the time calculation simplifies as there's only one sample
    // and the motion blur part becomes effectively zero if AA is 1.
    // time = mTime; // Already set above

    lightingPass = false;

    vec2 p_coord = (-iResolution.xy + 2.0*(fragCoord+o))/max(iResolution.y, 1e-6); // Renamed p to p_coord, Robust division, Explicitly 2.0f

    vec3 camPos = vec3(0.5, 7.4, -8.7) * 0.9; // Explicitly 0.5f, 7.4f, -8.7f, 0.9f
    mat3 camMat = calcLookAtMatrix( camPos, vec3(0.0,-1.4,0.0), -0.5); // Explicitly 0.0f, -1.4f, 0.0f, -0.5f
    vec3 rd = normalize( camMat * vec3(p_coord.xy,2.8) ); // Explicitly 2.8f

    vec3 pos = camPos; // Explicitly initialized
    float rayLength = 0.0; // Explicitly 0.0f
    float dist = 0.0; // Explicitly 0.0f
    bool bg = false; // Explicitly initialized
    vec4 res; // Explicitly initialized

    for (int i = 0; i < 100; i++) { // Explicitly 100
        rayLength += dist;
        pos = camPos + rd * rayLength;
        res = map(pos);
        dist = res.x;

        if (abs(dist) < 0.001) { // Explicitly 0.001f
            break;
        }
        
        if (rayLength > 16.0) { // Explicitly 16.0f
            bg = true;
            break;
        }
    }

    // Initial background color setup (only the last one is effective in the original code)
    col_final = BACKGROUND_PLANE_COLOR * 0.05; // Use the new define and original multiplier
    
    if ( ! bg) {
        
        lightingPass = true;
        
        vec3 nor = calcNormal(pos); // Explicitly initialized
        float occ = calcAO( pos, nor ); // Explicitly initialized
        vec3  lig = normalize( vec3(-0.2, 1.5, 0.3) ); // Explicitly -0.2f, 1.5f, 0.3f
        vec3  lba = normalize( vec3(0.5, -1.0, -0.5) ); // Explicitly 0.5f, -1.0f, -0.5f
        vec3  hal = normalize( lig - rd ); // Explicitly initialized
        float amb = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 )); // Explicitly 0.5f, 0.0f, 1.0f
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 ); // Explicitly 0.0f, 1.0f
        float bac = clamp( dot( nor, lba ), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0); // Explicitly 0.0f, 1.0f, 1.0f, 0.0f, 1.0f
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 ); // Explicitly 1.0f, 0.0f, 1.0f, 2.0f

        occ = mix(1.0, occ, 0.8); // Explicitly 1.0f, 0.8f
        
        dif *= softshadow( pos, lig, 0.001, 0.9 ); // Explicitly 0.001f, 0.9f

        float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)* // Explicitly 0.0f, 1.0f, 16.0f
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 )); // Explicitly 0.04f, 0.96f, 1.0f, 0.0f, 1.0f, 5.0f

        vec3 lin = vec3(0.0); // Explicitly 0.0f
        lin += 2.80*dif*vec3(1.30,1.00,0.70); // Explicitly 2.80f, 1.30f, 1.00f, 0.70f
        lin += 0.55*amb*vec3(0.40,0.60,1.15)*occ; // Explicitly 0.55f, 0.40f, 0.60f, 1.15f
        lin += 1.55*bac*vec3(0.25,0.25,0.25)*occ*vec3(2.0,0.0,1.0); // Explicitly 1.55f, 0.25f, 0.25f, 0.25f, 2.0f, 0.0f, 1.0f
        lin += 0.25*fre*vec3(1.00,1.00,1.00)*occ; // Explicitly 0.25f, 1.00f, 1.00f, 1.00f

        col_final = res.yzw;
        col_final = col_final*lin;
        col_final += 5.00*spe*vec3(1.10,0.90,0.70); // Explicitly 5.00f, 1.10f, 0.90f, 0.70f

        //col_final = nor * 0.5 + 0.5; // Explicitly 0.5f, 0.5f
        //col_final = max(dot(vec3(0.1,1.0,-0.2), nor), 0.0) * vec3(0.2); // Explicitly 0.1f, 1.0f, -0.2f, 0.0f, 0.2f
    }

    tot = col_final; // Simplified for AA = 1

    col_final = tot;
    col_final *= 1.3; // Explicitly 1.3f
    col_final = pow( col_final, vec3(0.4545) ); // Explicitly 0.4545f

    // --- Apply Vignette effect ---
    vec2 vignette_uv = fragCoord.xy / iResolution.xy; // Use fragCoord and iResolution
    vignette_uv *= 1.0 - vignette_uv.yx; // Transform UV for vignette
    float vig = vignette_uv.x * vignette_uv.y * VIGNETTE_INTENSITY;
    vig = pow(vig, VIGNETTE_POWER);

    // Apply dithering to reduce banding
    int x = int(mod(fragCoord.x, 2.0));
    int y = int(mod(fragCoord.y, 2.0));
    float dither = 0.0;
    if (x == 0 && y == 0) dither = 0.25 * DITHER_STRENGTH;
    else if (x == 1 && y == 0) dither = 0.75 * DITHER_STRENGTH;
    else if (x == 0 && y == 1) dither = 0.75 * DITHER_STRENGTH;
    else if (x == 1 && y == 1) dither = 0.25 * DITHER_STRENGTH;
    vig = clamp(vig + dither, 0.0, 1.0);

    col_final *= vig; // Apply vignette by multiplying the color

    // --- Apply BCS adjustments ---
    vec3 finalColor = col_final;
    // Brightness
    finalColor += (BRIGHTNESS - 1.0);

    // Contrast
    finalColor = (finalColor - 0.5) * CONTRAST + 0.5;

    // Saturation
    float luminance = dot(finalColor, vec3(0.2126, 0.7152, 0.0722)); // Standard Rec. 709 luminance
    vec3 grayscale = vec3(luminance);
    finalColor = mix(grayscale, finalColor, SATURATION);

    finalColor = clamp(finalColor, 0.0, 1.0); // Clamp final color to [0, 1] range

    fragColor = vec4(finalColor,1.0); // Explicitly 1.0f
}
