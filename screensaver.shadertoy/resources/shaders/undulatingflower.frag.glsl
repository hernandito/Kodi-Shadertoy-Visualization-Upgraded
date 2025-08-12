#define T iTime
#define PI 3.141596
#define S smoothstep

precision mediump float; // Ensure medium precision for GLSL ES 1.00

// General purpose small epsilon for numerical stability
const float TINY_EPSILON = 1e-6; 

// New Post-Processing Parameters for BCS
#define BRIGHTNESS_POST 1.20     // Adjusts overall brightness (1.0 for neutral)
#define SATURATION_POST 1.0     // Adjusts color intensity (1.0 for neutral, 0.0 for grayscale)
#define POST_CONTRAST 1.2       // Adjusts contrast (1.0 for neutral, >1.0 for more contrast)

// New: Overall Animation Speed Control
#define ANIMATION_SPEED 0.20     // Controls the speed of all animations (1.0 for original speed)


// The Robust Tanh Conversion Method: tanh_approx functions
// This provides a numerical approximation for tanh suitable for GLSL ES 1.00.
// It also includes a small EPSILON to prevent division by zero, making it robust.

// Overload for vec4 input
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), TINY_EPSILON));
}

// Overload for vec3 input
vec3 tanh_approx(vec3 x) {
    return x / (1.0 + max(abs(x), TINY_EPSILON));
}


mat2 rotate(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// Knighty's folding function
vec3 fold(vec3 p) {
    vec3 nc = vec3(-0.465, -0.809017, 0.309017); // Explicitly initialized
    for (int i = 0; i < 5; i++) { // Loop counter explicitly int
        p.xy = abs(p.xy);
        p -= 2.0 * min(0.0, dot(p, nc)) * nc;
    }
    return p - vec3(0.0, 0.0, 1.275);
}

// Signed distance function + procedural color
vec4 map(vec3 p) {

    vec3 q = p; // Explicitly initialized
    q.zy *= rotate(iTime * ANIMATION_SPEED * 0.5); // Uses animatedTime
    q.yz *= rotate(iTime * ANIMATION_SPEED * 0.2); // Uses animatedTime

    q = fold(q) - vec3(2.0);
    q += cos(q.zxy * 3.0 + iTime * ANIMATION_SPEED) * 0.5; // Turbulence (uses animatedTime)
    q = fold(q) - vec3(2.0);             // More folding

    vec3 k = q / vec3(1.5, 1.2, 1.2); // axis scaling
    float d = (abs(k.x) + abs(k.y) + abs(k.z)) - 2.0; // Explicitly initialized
    vec3 col = sin(vec3(3.0, 2.0, 1.0) + dot(p, p) * 0.1 + iTime * ANIMATION_SPEED) * 0.5 + 0.5; // Uses animatedTime
    return vec4(clamp(col, 0.0, 1.0), d);
}

// Approximate surface normal using SDF sampling
vec3 calcNormal(vec3 pos) {
    vec2 e = vec2(1.0, -1.0); // Explicitly initialized
    const float eps = 0.0005;
    return normalize(
        e.xyy * map(pos + e.xyy * eps).w +
        e.yyx * map(pos + e.yyx * eps).w +
        e.yxy * map(pos + e.yxy * eps).w +
        e.xxx * map(pos + e.xxx * eps).w
    );
}

// Raymarching loop
float rayMarch(vec3 ro, vec3 rd, float zMin, float zMax) {
    float z = zMin; // Already initialized
    for (float i = 0.0; i < 300.0; i++) { // Changed 3e2 to 300.0, explicit float initialization
        vec3 p_loop = ro + rd * z; // Explicitly initialized
        float d_loop = map(p_loop).w * 0.2 + 0.0001; // Explicitly initialized
        if (d_loop < TINY_EPSILON || z > zMax) break; // Using TINY_EPSILON for robustness
        z += d_loop;
    }
    return z;
}

float shadow(vec3 ro, vec3 rd) {
    float res = 0.5; // Explicitly initialized
    float t = 0.005; // Explicitly initialized
    for (int i = 0; i < 32; i++) { // Loop counter explicitly int
        float h = map(ro + rd * t).w; // Explicitly initialized
        if (h < TINY_EPSILON) return 0.0; // early shadow hit, using TINY_EPSILON
        res = min(res, 10.0 * h / max(t, TINY_EPSILON)); // softly decay shadow, robustness for t
        t += clamp(h, 0.02, 0.2);
        if (t > 20.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

// Main image function
void mainImage(out vec4 O, in vec2 I) {
    vec2 R = iResolution.xy; // Explicitly initialized
    // Added robustness for R.y division
    vec2 uv = (I * 2.0 - R) / max(R.y, TINY_EPSILON); // Explicitly initialized

    O.rgb = vec3(0.0); // Explicitly initialized
    O.a = 1.0; // Explicitly initialized

    vec3 ro = vec3(0.0, 0.0, -13.0); // Explicitly initialized
    if (iMouse.z > 0.0) {
        ro.z = -4.0;
    }

    vec3 rd = normalize(vec3(uv, 1.0)); // Explicitly initialized
    float zMax = 50.0; // Explicitly initialized
    float z = rayMarch(ro, rd, 0.1, zMax); // Explicitly initialized

    if (z < zMax) {
        vec3 p = ro + rd * z; // Explicitly initialized
        vec4 res = map(p); // Explicitly initialized
        
        vec3 nor = calcNormal(p); // Explicitly initialized

        vec3 lightDir = normalize(vec3(4.0, 4.0, -4.0) - p); // Explicitly initialized
        float diff = max(0.0, dot(lightDir, nor)); // Explicitly initialized
        
        float spe = pow(max(0.0, dot(normalize(lightDir - rd), nor)), 30.0); // Explicitly initialized
        float sh = shadow(p, lightDir); // Explicitly initialized
        vec3 col = vec3(0.0); // Explicitly initialized
        
        // Loop for accumulating color (changed from i++ to i++)
        for (float i=0.0; i < 100.0; i++){ // Explicitly initialized loop counter
            vec3 objColor = res.rgb*0.5+vec3(cos(z*0.3+iTime*ANIMATION_SPEED*0.5)*2.0,0.0,0.3-sin(i*0.005))*2.0; // Uses animatedTime
            col += (0.30 + diff + spe) * objColor;
        }
        
        // Clamp col to non-negative values before tanh and pow
        col = max(col, vec3(0.0));

        // Tone mapping + gamma correction
        // Replaced tanh() with tanh_approx() and added robustness for division.
        col = pow(tanh_approx(col * col / max(15000.0, TINY_EPSILON)), vec3(0.4545));

        O.rgb = col;
    }

    // Apply BCS post-processing
    // Brightness
    O.rgb *= BRIGHTNESS_POST;
    // Saturation (mix between grayscale and original color)
    O.rgb = mix(vec3(dot(O.rgb, vec3(0.2126, 0.7152, 0.0722))), O.rgb, SATURATION_POST);
    // Contrast (adjust around 0.5 gray level)
    O.rgb = (O.rgb - 0.5) * POST_CONTRAST + 0.5;
}
