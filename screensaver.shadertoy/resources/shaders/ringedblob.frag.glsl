// A robust approximation of the tanh function for older GLSL versions
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6;
    return x / (1.0 + max(abs(x), EPSILON));
}

// Post-processing parameters for Brightness, Contrast, and Saturation
// Adjust these values to change the look of the final output.
#define BRIGHTNESS -0.05      // Range: -1.0 to 1.0 (0.0 is default)
#define CONTRAST   1.30      // Range: 0.0 to 2.0 (1.0 is default)
#define SATURATION 1.4      // Range: 0.0 to 2.0 (1.0 is default)

// Function to apply Brightness, Contrast, and Saturation adjustments
vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color += brightness;
    
    // Apply contrast
    color = (color - 0.5) * contrast + 0.5;
    
    // Apply saturation
    vec3 gray = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
    color = mix(gray, color, saturation);
    
    return color;
}

vec3 hue(vec3 col, float hue) {
    return mix(vec3(dot(vec3(0.333), col)), col, cos(hue)) + cross(vec3(0.577), col) * sin(hue);
}

float hash12(vec2 p) {
    vec3 p3 = abs(fract(p.xyx / 0.1031));
    p3 += dot(p3, p3.yzx + 33.33);
    return abs(fract((p3.x + p3.y) * p3.z));
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = p - i;
    f *= f * (3.0 - 2.0 * f);
    float res = mix(
        mix(hash12(i), hash12(i + vec2(1, 0)), f.x),
        mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1)), f.x), f.y);
    return res;      
}

vec3 aces(vec3 x) {
  return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    // Explicitly initialize all variables
    float R = 0.7;
    vec2 uv = vec2(0.0);
    float l = 0.0;
    vec4 dd = vec4(0.0);
    float f = 0.0;
    float t = iTime * 0.3;
    float n1 = 0.0;
    float n2 = 0.0;
    vec3 rc = vec3(0.0);
    float w = 0.0;
    float d = 0.0;
    float r = 0.0;
    float gr = 0.0;
    vec3 c1 = vec3(0.0);
    vec3 v = vec3(0.0);
    float d2 = 0.0;
    float d3 = 0.0;
    float g = 0.0;
    float r2 = 0.0;
    vec2 suv = vec2(0.0);
    float str = 0.0;
    float cut = 0.0;
    vec3 c2 = vec3(0.0);
    float s = 0.0;
    vec3 c = vec3(0.0);

    uv = (fragCoord.xy * 2.0 - iResolution.xy) / iResolution.y;
    l = length(uv);
    dd = vec4(dFdx(uv), dFdy(uv));
    f = sqrt(max(dot(dd.xy, dd.xy), dot(dd.zw, dd.zw))) * 1.5;
    
    n1 = noise(uv * 2.0 + t) * 0.7 + noise(uv * 3.0 - t) * 0.3;
    n2 = noise(uv * 1.5 + 3.19 - t) * 0.7 + noise(uv * 3.0 - 9.61 + t) * 0.3;
    
    w = 0.03;
    d = abs(l - 1.17 * R);
    r = min(1.0, w / max(sqrt(d), 1e-6) * 3.0);
    gr = clamp(1.0 - d / max(w * 0.3, 1e-6), 0.0, 1.0);
    c1 = vec3(0, r*r*n2*n1, r);
    c1 = max(hue(c1, -sin(cos(uv.y * 3.0 + t * 8.0) + uv.x * 2.0 + t * 5.0) * 0.4), 0.0);
    rc += c1 * c1;
    
    v = max(hue(vec3(0, 1, 1), 0.9+sin(cos(uv.y * 3.0 + t * 8.0) + uv.x * 2.0 + t * 5.0) * 0.4), 0.0);
    
    d2 = l - R + (n2 - R) * 0.1;
    d3 = abs(d2);
    w = 0.09 * pow(abs(n1 - 0.1), 0.7);
    g = mix(smoothstep(-w, w, d2), smoothstep(w, -w, d2), smoothstep(0.1, 0.3, n1));
    r2 = clamp((w - d3) / max(f, 1e-6), 0.0, 1.0) * 3.0 * sqrt(g);
    suv = vec2(smoothstep(0.0, w, d3), abs(atan(uv.y, uv.x) / 1.57));
    str = smoothstep(0.0, 1.0, noise(suv.xy * vec2(4)))*0.5+0.5;
    cut = 0.5+0.5*smoothstep(-1.0, 1.0, sin((suv.y + (suv.x + str) * 0.1) * 2.0 - t * 2.0 + n1 - n2));
    r2 *= min(str*str, 0.5 * 0.5 + cut);
    c2 = vec3(n1 * n2 * 0.5, 0.9 * (1.0 - n1) * (1.0 - n2), 1) / max(1.0 - g * 0.5, 1e-6);
    rc = rc * (1.0 - min(r2, 1.0)) + r2 * c2;
    rc += 3.0 * cut * c2 * (1.0 - r2) * pow(smoothstep(0.13, -1.0, d3) / max(0.1 + d3, 1e-6), 2.0);
    
    // todo (orb): fix max color clipping
    d3 = l - R + (n1 - R + 4.0) * 0.1;
    r2 = smoothstep(0.0, -f, d3);
    c2 = vec3(n1 * n2 * 0.5, 0.9 * (1.0 - n1) * (1.0 - n2), 1);
    c2 = mix(vec3(0.0, 0.0, 0.04 / max(0.1 + d3*d3, 1e-6)), c2, smoothstep(0.15, -0.2, d3));
    c2 = c2 * (1.0 + smoothstep(0.1, -0.15, d3));
    rc = rc * (1.0 - min(r2, 1.0)) + r2 * c2;
    rc += 3.0 * c2 * (1.0 - r2) * pow(smoothstep(0.23, -1.5, d3) / max(0.2 + d3, 1e-6), 2.0);
    
    n1 = noise(uv * 2.0 + t - 3.19) * 0.7 + noise(uv * 3.0 - t + 22.13) * 0.3;
    n2 = noise(uv * 1.5 + 13.19 - t) * 0.7 + noise(uv * 3.0 - 19.61 + t) * 0.3;
    
    d2 = l - R + (n1 - R + 0.9) * 0.1;
    d3 = abs(d2);
    w = 0.09 * pow(abs(n1 - 0.1), 0.7);
    g = mix(smoothstep(-w, w, d2), smoothstep(w, -w, d2), smoothstep(0.1, 0.3, n1));
    r2 = clamp((w - d3) / max(f, 1e-6), 0.0, 1.0) * 3.0 * sqrt(g);
    suv = vec2(smoothstep(0.0, w, d3), abs(atan(uv.y, uv.x) / 1.57));
    str = smoothstep(0.0, 1.0, noise(suv.xy * vec2(4)))*0.5+0.5;
    cut = smoothstep(-1.0, 1.0, sin((suv.y + (suv.x + str) * 0.1) * 2.0 - t * 2.0 + n1 - n2));
    r2 *= min(str*str, 0.5+0.5*cut);
    c2 = vec3(n1 * n2 * 0.5, 0.9 * (1.0 - n1) * (1.0 - n2), 1) / max(1.0 - g * 0.5, 1e-6);
    rc = rc * (1.0 - min(r2, 1.0)) + r2 * c2;
    rc += 3.0 * cut * c2 * (1.0 - r2) * pow(smoothstep(0.13, -1.0, d3) / max(0.1 + d3, 1e-6), 2.0);
    
    n1 = noise(uv * 2.0 + t - 43.19) * 0.7 + noise(uv * 3.0 - t + 42.13) * 0.3;
    n2 = noise(uv * 1.5 + 8.19 - t) * 0.7 + noise(uv * 3.0 - 29.61 + t) * 0.3;
    
    d2 = l - R + (n1 - R - 0.75) * 0.1;
    d3 = abs(d2);
    w = 0.09 * pow(abs(n1 - 0.1), 0.7);
    g = mix(smoothstep(-w, w, d2), smoothstep(w, -w, d2), smoothstep(0.1, 0.3, n1));
    r2 = clamp((w - d3) / max(f, 1e-6), 0.0, 1.0) * 3.0 * sqrt(g);
    suv = vec2(smoothstep(0.0, w, d3), abs(atan(uv.y, uv.x) / 1.57));
    str = smoothstep(0.0, 1.0, noise(suv.xy * vec2(4)))*0.5+0.5;
    cut = smoothstep(-1.0, 1.0, sin((suv.y + (suv.x + str) * 0.1) * 2.0 - t * 2.0 + n1 - n2));
    r2 *= min(str*str, 0.5+0.5*cut);
    c2 = vec3(n1 * n2 * 0.5, 0.9 * (1.0 - n1) * (1.0 - n2), 1) / max(1.0 - g * 0.5, 1e-6);
    rc = rc * (1.0 - min(r2, 1.0)) + r2 * c2;
    rc += 3.0 * cut * c2 * (1.0 - r2) * pow(smoothstep(0.13, -1.0, d3) / max(0.1 + d3, 1e-6), 2.0);
    
    s = max(0.0, l - 0.8);
    rc = mix(rc, rc.bgr, smoothstep(-0.5 - s, 0.5 + s, n1 - n2 - uv.x + uv.y));
    rc = clamp(rc, 0.0, 1.0);
    
    c = pow(rc, vec3(0.45));
    
    // Apply the BCS adjustments to the final color
    c = applyBCS(c, BRIGHTNESS, CONTRAST, SATURATION);
    
    fragColor = vec4(c, 1);
}