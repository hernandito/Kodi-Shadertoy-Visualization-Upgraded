// Robust Tanh Approximation Function (included as per directive, though not explicitly used for tanh() in this shader)
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float PRECISION = 0.001;
const float EPSILON = 0.00005;
const float ESCAPEDISTANCE = 4.0;

// --- GLOBAL PARAMETERS ---
#define BRIGHTNESS 0.9    // Brightness adjustment (1.0 = neutral)
#define CONTRAST 1.50     // Contrast adjustment (1.0 = neutral)
#define SATURATION 1.0    // Saturation adjustment (1.0 = neutral)
#define SCREEN_SCALE 1.20  // Scale factor for zooming the effect (e.g., 0.5 for zoom in, 2.0 for zoom out)
#define WHITE_TINT vec3(1.0, 1.0, 1.0) // RGB color for the white tint (e.g., vec3(1.0, 0.9, 0.8) for warm white)
#define WHITE_TINT_STRENGTH 0.0 // How strongly to apply the tint (0.0 for no tint, 1.0 for full tint)
#define ANIMATION_SPEED 0.20 // Controls the overall animation speed (1.0 = normal speed)
#define DITHER_STRENGTH 0.005 // Strength of the dither effect (e.g., 0.005 for subtle dither)

struct Surface {
    float sd;
    vec3 col;
    vec3 spec;
    float rough;
};

vec3 juliaFractal(vec2 z, vec2 c) {
    const float maxIter = 32.0;
    float iter = 0.0;
    float smoothVal = 0.0;

    for(float i = 0.0; i < maxIter; i++) {
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;

        if(dot(z, z) > ESCAPEDISTANCE) {
            // Ensure log2 argument is robust
            smoothVal = i - log2(max(log2(max(dot(z, z), 1e-6)), 1e-6)) + 4.0;
            iter = i;
            break;
        }
        iter = i;
    }

    if(iter < maxIter-1.0) {
        float t = smoothVal / max(maxIter, 1e-6); // Robust division
        vec3 color = 0.5 + 0.45 * cos(2.5 + t * 8.0 + vec3(0.2, 0.5, 0.8));
        return pow(color, vec3(1.3));
    }
    return vec3(0.08, 0.1, 0.25);
}

Surface sdSphere(vec3 p, float r, vec3 offset, vec3 col) {
    p = (p - offset);
    float d = length(p) - r;
    return Surface(d, col, vec3(1.0), 0.2);
}

Surface sdFractalPlane(vec3 p, vec2 c) {
    float d = p.y;
    vec2 uv = p.xz * 0.2;
    vec3 fractalCol = juliaFractal(uv, c);

    const float axisWidth = 0.008;
    const float glowWidth = 0.02;
    const float axisRange = 15.0;

    float distX = abs(p.z);
    float axisX = smoothstep(axisWidth + glowWidth, axisWidth, distX) *
                  smoothstep(-axisRange, axisRange, abs(p.x));

    float distZ = abs(p.x);
    float axisZ = smoothstep(axisWidth + glowWidth, axisWidth, distZ) *
                  smoothstep(-axisRange, axisRange, abs(p.z));

    float distOrigin = length(p.xz);
    float origin = smoothstep(axisWidth * 1.5 + glowWidth, axisWidth * 1.5, distOrigin);

    float axisMask = clamp(axisX + axisZ + origin, 0.0, 1.0);
    vec3 axisCol = vec3(1.0);

    vec3 envColor = mix(vec3(0.08, 0.1, 0.25), fractalCol, 0.7);
    vec3 finalAxisCol = mix(envColor * 1.2, axisCol, 0.8);

    fractalCol = mix(fractalCol, finalAxisCol, 1.0 - exp(-6.0 * axisMask));

    return Surface(d, fractalCol, vec3(0.3), 0.7);
}

Surface sdStereoSphere(vec3 p, vec3 center, float r, vec2 c) {
    vec3 rel = p - center;
    float d = length(rel) - r;

    vec3 norm = normalize(rel);
    // Robust division for u and v
    float u = norm.x / max(1.0 - norm.y, 1e-6);
    float v = norm.z / max(1.0 - norm.y, 1e-6);
    vec2 st = vec2(u, v) * 0.65;

    vec3 fractalCol = juliaFractal(st, c);
    return Surface(d, fractalCol, vec3(1.0), 0.1);
}

Surface scene(vec3 p) {
    // Explicitly initialize c
    // Note: iTime is now multiplied by ANIMATION_SPEED
    vec2 c = vec2(-0.70176, -0.3842 * sin(iTime * 0.5 * ANIMATION_SPEED));

    if (iMouse.z > 0.1) {
        // Explicitly initialize mouseUV
        vec2 mouseUV = (2.0 * iMouse.xy - iResolution.xy) / max(min(iResolution.y, iResolution.x), 1e-6); // Robust division
        c = mouseUV;
    }

    Surface co = sdFractalPlane(p, c);
    Surface stereoSphere = sdStereoSphere(p, vec3(0, 1.6, 0), 1.6, c);
    if(stereoSphere.sd < co.sd) co = stereoSphere;

    return co;
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1, -1) * EPSILON;
    return normalize(
      e.xyy * scene(p + e.xyy).sd +
      e.yyx * scene(p + e.yyx).sd +
      e.yxy * scene(p + e.yxy).sd +
      e.xxx * scene(p + e.xxx).sd);
}

float softShadow(vec3 ro, vec3 rd, float mint, float tmax) {
  float res = 1.0;
  float t = mint;

  for(int i = 0; i < 16; i++) {
    float h = scene(ro + rd * t).sd;
    res = min(res, 8.0*h/max(t, 1e-6)); // Robust division
    t += clamp(h, 0.02, 0.10);
    if(h < 0.001 || t > tmax) break;
  }

  return clamp(res, 0.0, 1.0);
}

mat3 camera(vec3 cameraPos, vec3 lookAtPoint) {
    vec3 cd = normalize(lookAtPoint - cameraPos);
    vec3 cr = normalize(cross(vec3(0, 1, 0), cd));
    vec3 cu = normalize(cross(cd, cr));
    return mat3(-cr, cu, -cd);
}

Surface rayMarch(vec3 ro, vec3 rd) {
  float depth = MIN_DIST;
  Surface co; // Explicitly initialize co

  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
    vec3 p = ro + depth * rd;
    co = scene(p);
    depth += co.sd;
    if (abs(co.sd) < PRECISION || depth > MAX_DIST) break;
  }

  co.sd = depth;
  return co;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Explicitly initialize uv and bg
    vec2 uv = vec2(0.0);
    vec3 bg = vec3(0.05, 0.08, 0.12);

    // Apply screen scale for zooming
    uv = (fragCoord - 0.5 * iResolution.xy) / max(iResolution.y, 1e-6); // Robust division
    uv /= SCREEN_SCALE;

    vec3 lookAt = vec3(0, 1.5, 0);
    float camDist = 5.0;
    // Apply ANIMATION_SPEED to time-dependent angle
    float angle = iTime * 0.2 * ANIMATION_SPEED;
    vec3 ro = vec3(camDist * cos(angle), 4.0, camDist * sin(angle));
    mat3 camMat = camera(ro, lookAt);
    vec3 rd = camMat * normalize(vec3(uv, -1));

    // Raymarching
    Surface co = rayMarch(ro, rd);
    vec3 col; // Explicitly initialize col

    if (co.sd > MAX_DIST - 1.0) {
        col = bg;
    } else {
        vec3 pos = ro + rd * co.sd;
        vec3 normal = calcNormal(pos);

        vec3 lightPos = vec3(0.0, 8.0, 0.0);
        vec3 lightDir = normalize(lightPos - pos);

        float dif = clamp(dot(normal, lightDir), 0.0, 1.0);
        float amb = 0.2;

        float sh = softShadow(pos + normal * 0.01, lightDir, 0.02, 10.0);

        vec3 ref = reflect(-lightDir, normal);
        float spec = pow(clamp(dot(ref, -rd), 0.0, 1.0), 32.0) * co.spec.r;

        col = co.col * (dif * sh + amb) + spec * vec3(1.0);

        col = mix(col, bg, 1.0 - exp(-0.0002 * co.sd * co.sd));
    }

    // Gamma correction from original shader
    col = pow(col, vec3(1.0/2.2));

    // --- BCS ADJUSTMENT ---
    vec3 finalColor = col; // Start with the processed color
    float luminance = dot(finalColor, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), finalColor, SATURATION);
    vec3 contrasted = (saturated - 0.5) * CONTRAST + 0.5;
    finalColor = clamp(contrasted + (BRIGHTNESS - 1.0), 0.0, 1.0);

    // --- Apply White Tint ---
    // Mix the final color with the WHITE_TINT based on its luminance and the strength parameter.
    // This applies the tint more strongly to brighter areas.
    finalColor = mix(finalColor, WHITE_TINT, luminance * WHITE_TINT_STRENGTH);

    // --- Apply Dither Effect ---
    // A simple ordered dither pattern based on screen coordinates.
    // This helps break up color banding in smooth gradients.
    float dither = mod(floor(fragCoord.x) + floor(fragCoord.y), 2.0) * 2.0 - 1.0;
    finalColor += dither * DITHER_STRENGTH;

    fragColor = vec4(finalColor, 1.0);
}
