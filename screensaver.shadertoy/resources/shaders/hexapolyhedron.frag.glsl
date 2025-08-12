// 3d version of Shane's https://www.shadertoy.com/view/3ctXz8 :-p
// z axis horizontal, y axis vertical, x axis = depth

#define rot(a)        mat2(cos(a+vec4(0,33,11,0)))            // rotation
#define C(a)          max(a.x, max(a.y, a.z))                 // cube

float map(vec3 q) {
    q *= 0.9;

    q.xy *= rot(0.314);  
    q.yz *= rot(-0.523); 
    q.xz *= rot(0.628);  
    q.yx *= rot(0.785);

    vec3 a = abs(q), A = a.yzx, b; 
    float h = C(a) - 1.0;

    h = max(h, 0.08 + C(-max(a,A)));                          
    h = max(h, C((a+A))*0.7 - 0.9);

    b = (a - A) * 0.7;    
    return max(h, 0.1 - min( length(vec2(b.x, q.z)),           
                       min( length(vec2(b.y, q.x)),
                            length(vec2(b.z, q.y))
                        )));
}

// Kodi automatically calls this function: mainImage(o, gl_FragCoord.xy)
void mainImage(out vec4 O, vec2 u) {
    vec3 R = iResolution;
    vec3 P = vec3(0.0, 0.0, 10.0), q;
    vec3 D = normalize(vec3(u - 0.5 * R.xy, -R.y));
    vec3 M = (iMouse.z > 0.0) ? iMouse.xyz / R - 0.5 : vec3(0.05,0.07,0.0) * cos(0.3 * iTime*.3 + vec3(0,11,0)) + vec3(0.3,0,0);
    vec2 H = 2.0 * vec2(0.83, 1.0);
    float h = 9.0, y = H.x;

    // Initialize output to white, so shading math works normally
    O = vec4(1.0);

    for (; O.a > 0.0 && h > 0.001; O -= 0.003) {
        q = P;
        q.yz *= rot(6.0 * M.y);
        q.xz *= rot(6.0 * M.x);
        q += floor(q.y / y) * vec3(-0.5, 0.0, 1.0);
        q.yz = mod(q.yz, H) - H / 2.0;
        h = map(q);
        h = min(h, map(q - sign(q.y) * vec3(0.5, y, floor(q.y / y + step(0.0, q.y)) * sign(q.z))));

        P += 0.3 * h * D;
    }

    // Original shading math
    O *= O * O * O * 1.4;
    O = pow(O, vec4(1.0, 4.0, 16.0, 1.0));

    // Texture line commented out
    // vec2 texCoord = q.xy * 0.5;
    // O *= 0.9 + 0.1 * texture2D(iChannel0, texCoord).rrrr;

    // Background color (orange-yellow)
    vec3 bgColor = vec3(0.8, 0.576, 0.09);

    // Clamp very bright pixels (white gaps) to background color
    float brightness = max(max(O.r, O.g), O.b);
    float isBright = step(0.95, brightness);
    O.rgb = mix(O.rgb, bgColor, isBright);

    // --- Vignette effect ---

    // Normalize pixel coords 0..1
    vec2 uv = u / R.xy;

    // Transform UV for vignette shape
    uv *= 1.0 - uv.yx;

    float vignetteIntensity = 25.0;
    float vignettePower = 0.60;

    float vig = uv.x * uv.y * vignetteIntensity;
    vig = pow(vig, vignettePower);

    // Dithering to reduce banding
    float xMod = mod(u.x, 2.0);
    float yMod = mod(u.y, 2.0);
    float dither = 0.0;
    if (xMod < 0.5 && yMod < 0.5) dither = 0.25 * 0.05;
    else if (xMod >= 0.5 && yMod < 0.5) dither = 0.75 * 0.05;
    else if (xMod < 0.5 && yMod >= 0.5) dither = 0.75 * 0.05;
    else if (xMod >= 0.5 && yMod >= 0.5) dither = 0.25 * 0.05;

    vig = clamp(vig + dither, 0.0, 1.0);

    // Apply vignette (multiply the color)
    O.rgb *= vig;
}
