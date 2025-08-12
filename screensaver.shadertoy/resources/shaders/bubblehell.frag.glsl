// key toggles
// M: mode 1 or 2
// A: anti-aliasing

precision mediump float; // Required for GLSL ES 1.00 compatibility

// --- Screen Scaling Parameter ---
// Adjust this value to zoom in or out.
// 1.0 = original view.
// > 1.0 = zoom out (e.g., 2.0 for 2x wider view).
// < 1.0 = zoom in (e.g., 0.5 for 2x closer view).
#define VIEW_SCALE 0.75 // Starting with 1.5 for a slightly wider view

// Custom round function for GLSL ES 1.00 compatibility
float custom_round(float x) {
    return sign(x) * floor(abs(x) + 0.5);
}

// Fixed KT to use standard texture2D for keyboard input on Shadertoy
// iChannel0 usually holds the keyboard texture (256x1 pixels).
// 'i' is the key code (0-255). We sample at the center of the pixel.
// User MUST set iChannel0 to 'Keyboard' in Shadertoy's Input tab.
#define KT(i) texture2D(iChannel0, vec2((float(i) + 0.5) / 256.0, 0.5)).x

// RT macro: 'a' will be a float (m.x or m.y) passed directly.
// Ensure all literal constants are floats (e.g., 0.0 instead of 0).
#define RT(a) mat2(cos((a)*1.571+vec4(0.0,-1.571,1.571,0.0)))

// Fixed H macro: 'radians' applied to float components of vec3.
// Ensure all literal constants are floats.
#define H(a) (cos(radians(vec3(90.0, 30.0, -30.0))-((a)*6.2832)) * 0.5 + 0.5)

void mainImage( out vec4 RGBA, in vec2 XY )
{
    // --- Shadertoy Uniforms ---
    // Use iMouse for mouse input (Shadertoy's convention)
    vec2 m = iMouse.xy / iResolution.xy * 4.0 - 2.0; // mouse coords
    
    // Use iTime for time (Shadertoy's convention)
    float t = iTime/45.0 + 0.001; 

    // Explicit Variable Initialization
    float aa = 2.0 - KT(65); // anti-aliasing: key A (2.0 if not pressed, 1.0 if pressed)
    float d = 0.0; // step dist for raymarch
    float s = 0.0; // smoothstep result

    vec2 o = vec2(0.0); // offset for aa loop
    vec3 bg = vec3(0.0); // background accumulator
    vec3 ro = vec3(0.5, 0.0, t); // camera (ray origin)
    vec3 rd = vec3(0.0); // 3d uv (ray direction)
    vec3 l = vec3(0.0); // light/spot calculation
    vec3 c = vec3(0.0); // color calculation

    // If mouse button not pressed, rotate with time (use iMouse.z for Shadertoy)
    if (iMouse.z < 1.0) m = vec2(-cos(t)*0.4+0.4) + vec2(0.0, 0.1); 
    
    // Initialize km after iMouse and KT are defined.
    bool km = KT(77) > 0.0; // switch mode: key M

    // Pass m.y and m.x to RT macro as single float values
    mat2 pitch = RT(m.y); 
    mat2 yaw   = RT(m.x);

    // Anti-aliasing loop: Loop count determined by `aa` (1 or 4 iterations)
    for (int k = 0; k < int(aa*aa); k++) 
    {
        // Fixing '%' operator: use mod(float, float) and floor for integer division behavior
        o = vec2(mod(float(k), 2.0), floor(float(k) / 2.0)) / aa; 
        
        // --- Apply VIEW_SCALE here for zoom effect ---
        // Divide the normalized screen coordinates by VIEW_SCALE to zoom out.
        rd = normalize(vec3((XY - 0.5 * iResolution.xy + o) / (iResolution.y * VIEW_SCALE), 1.0)); 
        
        rd.yz *= pitch;
        rd.xz *= yaw;
        
        d = 0.0; // Reset step dist for each raymarch
        
        for (int i = 0; i < 100; i++)
        {
            vec3 p = ro + rd * d; // position along ray
            
            // Apply custom_round component-wise to vec3 'p' for calculations
            float p_y_rounded = custom_round(p.y);
            
            if (km) p.xz += p_y_rounded * t;      // mode 2
            else    p.z  += sqrt(p_y_rounded * t * t * 2.0); // mode 1
            
            // Apply custom_round component-wise for the 'length' calculation
            s = smoothstep(0.23, 0.27, length(p - vec3(custom_round(p.x), custom_round(p.y), custom_round(p.z))) ); // sphere grid
            
            if (s < 0.001) break;
            d += s;
        }
        
        l = 1.0 - vec3( length(rd.yz), length(rd.xz), length(rd.xy) ); // spots at xyz
        c = vec3(d * 0.013); // objects
        c += vec3(0.9, 0.5, 0.2) - min(1.0 - l.x, 1.0 - l.z); // firey glow
        c.b += l.x * 0.5 + l.y * 1.5; // x & y tint
        
        if (km) c = c.gbr;   // change color with mode
        c = max(c, 0.5 - H(d)); // rainbow fringe (H macro is fine now)
        
        bg += c; // add to bg
    }
    
    bg /= (aa * aa); // fix brightness after aa pass
    bg *= sqrt(bg) * 0.8; // contrast
    
    // Final output. RGBA is the out variable name for this shader.
    RGBA = vec4(bg, 1.0);
}