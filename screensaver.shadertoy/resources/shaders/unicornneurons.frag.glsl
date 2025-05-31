float map(vec3 p) {
    vec3 n = vec3(0.0, 1.0, 0.0);
    float k1 = 1.9;
    float k2 = (sin(p.x * k1) + sin(p.z * k1)) * 0.8;
    float k3 = (sin(p.y * k1) + sin(p.z * k1)) * 0.8;
    float w1 = 4.0 - dot(abs(p), normalize(n)) + k2;
    float w2 = 4.0 - dot(abs(p), normalize(n.yzx)) + k3;
    float s1 = length(mod(p.xy + vec2(sin((p.z + p.x) * 2.0) * 0.3, cos((p.z + p.x) * 1.0) * 0.5), 2.0) - 1.0) - 0.2;
    float s2 = length(mod(0.5 + p.yz + vec2(sin((p.z + p.x) * 2.0) * 0.3, cos((p.z + p.x) * 1.0) * 0.3), 2.0) - 1.0) - 0.2;
    return min(w1, min(w2, min(s1, s2)));
}

vec2 rot(vec2 p, float a) {
    float ca = cos(a);
    float sa = sin(a);
    return vec2(
        p.x * ca - p.y * sa,
        p.x * sa + p.y * ca
    );
}

vec3 calcNormal(vec3 pos) {
    float eps = 0.01;
    float dx = map(vec3(pos.x + eps, pos.y, pos.z)) - map(vec3(pos.x - eps, pos.y, pos.z));
    float dy = map(vec3(pos.x, pos.y + eps, pos.z)) - map(vec3(pos.x, pos.y - eps, pos.z));
    float dz = map(vec3(pos.x, pos.y, pos.z + eps)) - map(vec3(pos.x, pos.y, pos.z - eps));
    float len = sqrt(dx * dx + dy * dy + dz * dz);
    if (len < 0.001) len = 0.001; // Avoid division by zero
    return vec3(dx / len, dy / len, dz / len);
}

float calcAO(vec3 pos) {
    float ao = 0.0;
    float h = 0.02; // Sample distance
    float intensity = 1.95; // AO strength

    // Sample 3 fixed directions
    float d1 = map(pos + vec3(0.1, 0.0, 0.0)) * h;
    float d2 = map(pos + vec3(0.0, 0.1, 0.0)) * h;
    float d3 = map(pos + vec3(0.0, 0.0, 0.1)) * h;

    ao = ao + (h - d1) * intensity;
    ao = ao + (h - d2) * intensity;
    ao = ao + (h - d3) * intensity;

    float aoResult = 1.0 - ao;
    if (aoResult < 0.0) aoResult = 0.0;
    if (aoResult > 1.0) aoResult = 1.0;
    return aoResult;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // User-editable parameters for brightness, contrast, and saturation
    float brightness = -0.1; // Adjusts overall brightness: -1.0 to 1.0 (0.0 = neutral)
                              // Increase to 0.0 to make brighter, decrease to -0.3 to make darker
    float contrast = 1.1;    // Adjusts contrast: 0.0 to 2.0 (1.0 = neutral)
                              // Increase to 2.0 to make more contrasted, decrease to 1.0 to reduce contrast
    float saturation = 1.2;  // Adjusts saturation: 0.0 to 2.0 (1.0 = neutral)
                              // Increase to 1.5 to make colors more vibrant, decrease to 0.5 to desaturate

    float time = iTime * 0.10;
    vec2 uv = (fragCoord.xy / iResolution.xy) * 2.0 - 1.0;
    uv.x = uv.x * (iResolution.x / iResolution.y);

    vec3 dir = normalize(vec3(uv * 1.6, 1.0));
    dir.xz = rot(dir.xz, time * 0.23);
    dir = dir.yzx;
    dir.xz = rot(dir.xz, time * 0.2);
    dir = dir.yzx;
    vec3 pos = vec3(0.0, 0.0, time);
    vec3 col = vec3(0.0);
    float t = 0.0;
    float tt = 0.0;

    for (int i = 0; i < 100; i = i + 1) {
        tt = map(pos + dir * t);
        if (tt < 0.001) break;
        t = t + tt * 0.45;
    }

    vec3 ip = pos + dir * t;
    col = vec3(t * 0.1);
    col = sqrt(col);

    // Apply ambient occlusion
    float ao = calcAO(ip);
    col = col * ao;

    // Compute final color as vec4 to match fragColor's type
    fragColor = vec4(0.05 * t + abs(dir) * col + max(0.0, map(ip - 0.1) - tt), 1.0);

    // Apply brightness
    fragColor = fragColor + brightness;
    if (fragColor.x < 0.0) fragColor.x = 0.0;
    if (fragColor.y < 0.0) fragColor.y = 0.0;
    if (fragColor.z < 0.0) fragColor.z = 0.0;
    if (fragColor.x > 1.0) fragColor.x = 1.0;
    if (fragColor.y > 1.0) fragColor.y = 1.0;
    if (fragColor.z > 1.0) fragColor.z = 1.0;

    // Apply contrast
    fragColor = (fragColor - 0.5) * contrast + 0.5;
    if (fragColor.x < 0.0) fragColor.x = 0.0;
    if (fragColor.y < 0.0) fragColor.y = 0.0;
    if (fragColor.z < 0.0) fragColor.z = 0.0;
    if (fragColor.x > 1.0) fragColor.x = 1.0;
    if (fragColor.y > 1.0) fragColor.y = 1.0;
    if (fragColor.z > 1.0) fragColor.z = 1.0;

    // Apply saturation
    float luminance = 0.299 * fragColor.x + 0.587 * fragColor.y + 0.114 * fragColor.z;
    float satComplement = 1.0 - saturation;
    fragColor.x = satComplement * luminance + saturation * fragColor.x;
    fragColor.y = satComplement * luminance + saturation * fragColor.y;
    fragColor.z = satComplement * luminance + saturation * fragColor.z;
    if (fragColor.x < 0.0) fragColor.x = 0.0;
    if (fragColor.y < 0.0) fragColor.y = 0.0;
    if (fragColor.z < 0.0) fragColor.z = 0.0;
    if (fragColor.x > 1.0) fragColor.x = 1.0;
    if (fragColor.y > 1.0) fragColor.y = 1.0;
    if (fragColor.z > 1.0) fragColor.z = 1.0;

    fragColor.a = 1.0 / (t * t * t * t);
}