#define TRIANGLE_PATTERN

// Render green grass on the terrain. Uncommented leaves dry terrain.
#define GRASS

// -----------------------------------------------------------------------------
// ADJUSTABLE PARAMETERS
// Adjust these values to fine-tune the shader's appearance and animation.
// -----------------------------------------------------------------------------

// === Animation Speed Control ===
// Adjust this value to control the overall speed of the animation.
// Increase for faster animation (e.g., 2.0), decrease for slower animation (e.g., 0.5).
const float animationSpeed = 0.30; // EDIT THIS VALUE. Default: 1.0 (normal speed)

// === BCS Parameters ===
const float post_brightness = -0.150; // Default: no change
const float post_contrast = 1.0;   // Default: no change
const float post_saturation = 1.2; // Default: no change

// === Suggested Adjustments for BCS ===
// - If the image looks washed out on your TV:
//   - post_brightness = 0.2 (slight brightening)
//   - post_contrast = 1.2 (increase contrast)
//   - post_saturation = 1.3 (boost colors)
// - If the image is too dark:
//   - post_brightness = 0.3 to 0.5 (brighten more)
// - If colors are too muted:
//   - post_saturation = 1.5 (more vibrant colors)

// -----------------------------------------------------------------------------
// END ADJUSTABLE PARAMETERS
// -----------------------------------------------------------------------------


// Standard 2D rotation formula.
mat2 rot2(in float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Standard vec2 to float hash - Based on IQ's original.
float hash21(vec2 p) { return fract(sin(dot(p, vec2(141.13, 289.97))) * 43758.5453); }

// vec2 to vec2 hash.
vec2 hash22(vec2 p) {
    float n = sin(dot(p, vec2(41, 289)));
    p = fract(vec2(262144, 32768) * n);
    // Apply animationSpeed to iTime here
    return sin(p * 6.2831853 + iTime * animationSpeed);
}

// Based on IQ's gradient noise formula.
float n2D3G(in vec2 p) {
    vec2 i = floor(p); p -= i;
    vec4 v;
    v.x = dot(hash22(i), p);
    v.y = dot(hash22(i + vec2(1, 0)), p - vec2(1, 0));
    v.z = dot(hash22(i + vec2(0, 1)), p - vec2(0, 1));
    v.w = dot(hash22(i + 1.), p - 1.);
#if 1
    // Quintic interpolation.
    p = p * p * p * (p * (p * 6. - 15.) + 10.);
#else
    // Cubic interpolation.
    p = p * p * (3. - 2. * p);
#endif
    return mix(mix(v.x, v.y, p.x), mix(v.z, v.w, p.x), p.y);
}

// The isofunction. Just a single noise function, but it can be more elaborate.
float isoFunction(in vec2 p) { return n2D3G(p / 4. + .07); }

// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 a, vec2 b) {
    b = a - b;
    float h = clamp(dot(a, b) / dot(b, b), 0., 1.);
    return length(a - b * h);
}

// Based on IQ's signed distance to the segment joining "a" and "b".
float distEdge(vec2 a, vec2 b) {
    return dot((a + b) * 0.5, normalize((b - a).yx * vec2(-1, 1)));
}

// Interpolating along the edge connecting vertices v1 and v2 with respect to the isovalue.
vec2 inter(in vec2 p1, in vec2 p2, float v1, float v2, float isovalue) {
    return mix(p1, p2, (isovalue - v1) / (v2 - v1) * 0.75 + 0.25 / 2.);
}

// Isoline function.
int isoLine(vec3 n3, vec2 ip0, vec2 ip1, vec2 ip2, float isovalue, float i,
            inout vec2 p0, inout vec2 p1) {
    p0 = vec2(1e5); p1 = vec2(1e5);
    int iTh = 0;
    if (n3.x > isovalue) iTh += 4;
    if (n3.y > isovalue) iTh += 2;
    if (n3.z > isovalue) iTh += 1;
    if (iTh == 1 || iTh == 6) {
        p0 = inter(ip1, ip2, n3.y, n3.z, isovalue);
        p1 = inter(ip2, ip0, n3.z, n3.x, isovalue);
    } else if (iTh == 2 || iTh == 5) {
        p0 = inter(ip0, ip1, n3.x, n3.y, isovalue);
        p1 = inter(ip1, ip2, n3.y, n3.z, isovalue);
    } else if (iTh == 3 || iTh == 4) {
        p0 = inter(ip0, ip1, n3.x, n3.y, isovalue);
        p1 = inter(ip2, ip0, n3.z, n3.x, isovalue);
    }
    if (iTh >= 4 && iTh <= 6) { vec2 tmp = p0; p0 = p1; p1 = tmp; }
    if (i == 0.) { vec2 tmp = p0; p0 = p1; p1 = tmp; }
    return iTh;
}

// === Apply BCS Adjustments to a vec3 Color ===
vec3 applyBCS(vec3 col) {
    // Apply brightness
    col = clamp(col + post_brightness, 0.0, 1.0);

    // Apply contrast
    col = clamp((col - 0.5) * post_contrast + 0.5, 0.0, 1.0);

    // Apply saturation
    vec3 grayscale = vec3(dot(col, vec3(0.299, 0.587, 0.114))); // Luminance
    col = mix(grayscale, col, post_saturation);

    return col;
}


vec3 simplexContour(vec2 p) {
    const float gSc = 8.0;
    p *= gSc;
    vec2 oP = p;
    p += vec2(n2D3G(p * 3.5), n2D3G(p * 3.5 + 7.3)) * 0.015;
    vec2 s = floor(p + (p.x + p.y) * 0.36602540378);
    p -= s - (s.x + s.y) * 0.211324865;
    float i = p.x < p.y ? 1.0 : 0.0;
    vec2 ioffs = vec2(1.0 - i, i);
    vec2 ip0 = vec2(0), ip1 = ioffs - 0.2113248654, ip2 = vec2(0.577350269);
    vec2 ctr = (ip0 + ip1 + ip2) / 3.0;
    ip0 -= ctr; ip1 -= ctr; ip2 -= ctr; p -= ctr;
    vec3 n3;
    n3.x = isoFunction(s);
    n3.y = isoFunction(s + ioffs);
    n3.z = isoFunction(s + 1.0);
    float d = 1e5, d2 = 1e5, d3 = 1e5, d4 = 1e5, d5 = 1e5;
    float isovalue = 0.0;
    vec2 p0, p1;
    int iTh = isoLine(n3, ip0, ip1, ip2, isovalue, i, p0, p1);
    d = min(d, distEdge(p - p0, p - p1));
    if (iTh == 7) {
        d = 0.0;
    }
    d3 = min(d3, distLine((p - p0), (p - p1)));
    d4 = min(d4, min(length(p - p0), length(p - p1)));
    float tri = min(min(distLine(p - ip0, p - ip1), distLine(p - ip1, p - ip2)),
                     distLine(p - ip2, p - ip0));
    d5 = min(d5, tri);
    d5 = min(d5, length(p) - 0.02);
#ifdef TRIANGULATE_CONTOURS
    vec2 oldP0 = p0;
    vec2 oldP1 = p1;
    float td = (iTh > 0 && iTh < 7) ? 1.0 : 0.0;
    if (iTh == 3 || iTh == 5 || iTh == 6) {
        vec2 pt = p0;
        if (i == 1.0) pt = p1;
        d5 = min(d5, distLine((p - pt), (p - ip0)));
        d5 = min(d5, distLine((p - pt), (p - ip1)));
        d5 = min(d5, distLine((p - pt), (p - ip2)));
    }
#endif
    isovalue = -0.15;
    int iTh2 = isoLine(n3, ip0, ip1, ip2, isovalue, i, p0, p1);
    d2 = min(d2, distEdge(p - p0, p - p1));
    float oldD2 = d2;
    if (iTh2 == 7) d2 = 0.0;
    if (iTh == 7) d2 = 1e5;
    d2 = max(d2, -d);
    d3 = min(d3, distLine((p - p0), (p - p1)));
    d4 = min(d4, min(length(p - p0), length(p - p1)));
    d4 -= 0.075;
    d3 -= 0.0075; // Reduced from 0.0125
#ifdef TRIANGULATE_CONTOURS
    float td2 = (iTh2 > 0 && iTh2 < 7) ? 1.0 : 0.0;
    if (td == 1.0 && td2 == 1.0) {
        d5 = min(d5, distLine(p - p0, p - oldP0));
        d5 = min(d5, distLine(p - p0, p - oldP1));
        d5 = min(d5, distLine(p - p1, p - oldP1));
        if (oldD2 > 0.0) {
            vec2 pt = p0;
            if (i == 1.0) pt = p1;
            d5 = min(d5, distLine(p - pt, p - ip0));
            d5 = min(d5, distLine(p - pt, p - ip1));
            d5 = min(d5, distLine(p - pt, p - ip2));
        }
    } else if (td == 1.0 && td2 == 0.0) {
        vec2 pt = oldP0;
        if (i == 1.0) pt = oldP1;
        d5 = min(d5, distLine(p - pt, p - ip0));
        d5 = min(d5, distLine(p - pt, p - ip1));
        d5 = min(d5, distLine(p - pt, p - ip2));
    } else if (td == 0.0 && td2 == 1.0) {
        vec2 pt = p0;
        if (i == 1.0) pt = p1;
        d5 = min(d5, distLine(p - pt, p - ip0));
        d5 = min(d5, distLine(p - pt, p - ip1));
        d5 = min(d5, distLine(p - pt, p - ip2));
    }
#endif
    d /= gSc;
    d2 /= gSc;
    d3 /= gSc;
    d4 /= gSc;
    d5 /= gSc;
    vec3 col = vec3(1, 0.85, 0.6);
    float sf = 0.0025; // Reduced from 0.004
    if (d > 0.0 && d2 > 0.0) col = vec3(1, 1.8, 3) * 0.45;
    if (d > 0.0) col = mix(col, vec3(1, 1.85, 3) * 0.3, (1.0 - smoothstep(0.0, sf, d2 - 0.007))); // Reduced from 0.012
    col = mix(col, vec3(1.1, 0.85, 0.6), (1.0 - smoothstep(0.0, sf, d2)));
    col = mix(col, vec3(1.5, 0.9, 0.6) * 0.6, (1.0 - smoothstep(0.0, sf, d - 0.012)));
#ifdef GRASS
    col = mix(col, vec3(1, 0.8, 0.6) * vec3(0.7, 1.0, 0.75) * 0.95, (1.0 - smoothstep(0.0, sf, d)));
#else
    col = mix(col, vec3(1, 0.82, 0.6) * 0.95, (1.0 - smoothstep(0.0, sf, d)));
#endif
    if (d2 > 0.0) col *= (abs(dot(n3, vec3(1))) * 1.25 + 1.25) / 2.0;
    else col *= max(2.0 - (dot(n3, vec3(1)) + 1.45) / 1.25, 0.0);
#ifdef TRIANGLE_PATTERN
    float pat = abs(fract(tri * 12.5 + 0.4) - 0.5) * 2.0;
    col *= pat * 0.425 + 0.75;
#endif
    col = mix(col, vec3(0), (1.0 - smoothstep(0.0, sf, d5)) * 0.95);
    col = mix(col, vec3(0), (1.0 - smoothstep(0.0, sf, d3)));
    col = mix(col, vec3(0), (1.0 - smoothstep(0.0, sf, d4)));
    col = mix(col, vec3(1), (1.0 - smoothstep(0.0, sf, d4 + 0.0025))); // Reduced from 0.005
    vec2 q = oP * 1.5;
    col = min(col, 1.0);
    float gr = sqrt(dot(col, vec3(0.299, 0.587, 0.114))) * 1.25;
    float ns = (n2D3G(q * 4.0 * vec2(1.0 / 3.0, 3.0)) * 0.64 + n2D3G(q * 8.0 * vec2(1.0 / 3.0, 3.0)) * 0.34) * 0.5 + 0.5;
    ns = gr - ns;
    q *= rot2(3.14159 / 3.0);
    float ns2 = (n2D3G(q * 4.0 * vec2(1.0 / 3.0, 3.0)) * 0.64 + n2D3G(q * 8.0 * vec2(1.0 / 3.0, 3.0)) * 0.34) * 0.5 + 0.5;
    ns2 = gr - ns2;
    ns = smoothstep(0.0, 1.0, min(ns, ns2));
    col = mix(col, col * (ns + 0.35), 0.4);

    // Apply BCS adjustments using the provided function
    col = applyBCS(col);

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - iResolution.xy * 0.5) / min(650.0, iResolution.y);
    // Apply animation speed to iTime
    vec2 p = rot2(3.14159 / 12.0) * uv + vec2(0.8660254, 0.5) * (iTime * animationSpeed) / 16.0;
    vec3 col = simplexContour(p);
    uv = fragCoord / iResolution.xy;
    col *= pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.0625) + 0.1;
    fragColor = vec4(sqrt(max(col, 0.0)), 1.0);
}
