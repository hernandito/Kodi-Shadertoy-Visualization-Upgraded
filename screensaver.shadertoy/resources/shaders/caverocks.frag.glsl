/*
    Abstract Plane
    --------------

    Performing 2nd order distance checks on randomized 3D tiles to add some pronounced 
    surfacing to a warped plane... Verbose description aside, it's a pretty simple process. :)

    I put this example together some time ago, but couldn't afford a reflective pass, so 
    forgot about it. Anyway, I was looking at XT95's really nice "UI" example - plus a 
    couple of my own - and realized that a little bit of environment mapping would work 
    nicely. I'm using a less sophisticated environment mapping function than XT95's, but 
    it produces the desired effect. 
    
    By the way, XT95's is really worth taking a look at. It gives off a vibe of surrounding 
    area lights. I tested it on other surfaces and was pretty pleased with the results. The 
    link is below.

    As for the geometry itself, it's just a variation of 3D repetitive tiling. I colored in
    some of the regions - Greyscale with a splash of color is on page five of the "Tired Old 
    Cliche Design" handbook. :) However, I also to wanted to show that it's possible to 
    identify certain regions within the tile in a similar way to which it is done with regular 
    Voronoi.    

    Other examples:
    
    // Excellent environment mapping example.
    UI easy to integrate - XT95    
    https://www.shadertoy.com/view/ldKSDm

    // As abstact terrain shaders go, this is my favorite. :)
    Somewhere in 1993 - nimitz
    https://www.shadertoy.com/view/Md2XDD
*/

// Animation speed control
#define ANIMATION_SPEED 0.10  // Range: 0.0 to any positive value (1.0 = default speed)
#define FAR 40.

// 2x2 matrix rotation. Note the absence of "cos." It's there, but in disguise, and comes courtesy
// of Fabrice Neyret's "ouside the box" thinking. :)
mat2 rot2(float a) { vec2 v = sin(vec2(1.570796, 0) - a); return mat2(v, -v.y, v.x); }

float drawObject(in vec3 p) {
    p = abs(fract(p) - 0.5);
    return dot(p, vec3(0.5));
}

float cellTile(in vec3 p) {
    p /= 5.5;
    vec4 v, d;
    d.x = drawObject(p - vec3(0.81, 0.62, 0.53));
    p.xy = vec2(p.y - p.x, p.y + p.x) * 0.7071;
    d.y = drawObject(p - vec3(0.39, 0.2, 0.11));
    p.yz = vec2(p.z - p.y, p.z + p.y) * 0.7071;
    d.z = drawObject(p - vec3(0.62, 0.24, 0.06));
    p.xz = vec2(p.z - p.x, p.z + p.x) * 0.7071;
    d.w = drawObject(p - vec3(0.2, 0.82, 0.64));

    v.xy = min(d.xz, d.yw), v.z = min(max(d.x, d.y), max(d.z, d.w)), v.w = max(v.x, v.y);
    d.x = min(v.z, v.w) - min(v.x, v.y); // Maximum minus second order, for that beveled Voronoi look. Range [0, 1].

    return d.x * 2.66; // Normalize... roughly.  texBump
}

vec3 cellTileColor(in vec3 p) {
    int cellID = 0;
    p /= 5.5;
    vec3 d = vec3(0.75); // Set the maximum.

    d.z = drawObject(p - vec3(0.81, 0.62, 0.53)); if (d.z < d.x) cellID = 1;
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);

    p.xy = vec2(p.y - p.x, p.y + p.x) * 0.7071;
    d.z = drawObject(p - vec3(0.39, 0.2, 0.11)); if (d.z < d.x) cellID = 2;
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);

    p.yz = vec2(p.z - p.y, p.z + p.y) * 0.7071;
    d.z = drawObject(p - vec3(0.62, 0.24, 0.06)); if (d.z < d.x) cellID = 3;
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);

    p.xz = vec2(p.z - p.x, p.z + p.x) * 0.7071;
    d.z = drawObject(p - vec3(0.2, 0.82, 0.64)); if (d.z < d.x) cellID = 4;
    d.y = max(d.x, min(d.y, d.z)); d.x = min(d.x, d.z);

    vec3 col = vec3(0.25);
    if (cellID == 3) col = vec3(1, 0.05, 0.15);

    return col;
}

float map(vec3 p) {
    float n = (0.5 - cellTile(p)) * 1.5;
    return p.y + dot(sin(p / 2. + cos(p.yzx / 2. + 3.14159 / 2.)), vec3(0.5)) + n;
}

float trace(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 96; i++) {
        float d = map(ro + rd * t);
        if (abs(d) < 0.0025 * (t * 0.125 + 1.) || t > FAR) break;
        t += d * 0.7; // Using more accuracy, in the first pass.
    }
    return min(t, FAR);
}

vec3 getNormal(in vec3 p) {
    const vec2 e = vec2(0.005, 0);
    return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy), map(p + e.yyx) - map(p - e.yyx)));
}

float calculateAO(in vec3 pos, in vec3 nor) {
    float sca = 2.0, occ = 0.0;
    for (int i = 0; i < 5; i++) {
        float hr = 0.01 + float(i) * 0.5 / 4.0;
        float dd = map(nor * hr + pos);
        occ += (hr - dd) * sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0.0, 1.0);
}

vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n) {
    n = max((abs(n) - 0.2) * 7., 0.001);
    n /= (n.x + n.y + n.z);
    return (texture(tex, p.yz) * n.x + texture(tex, p.zx) * n.y + texture(tex, p.xy) * n.z).xyz;
}

vec3 texBump(sampler2D tx, in vec3 p, in vec3 n, float bf) {
    const vec2 e = vec2(0.002, 0);
    mat3 m = mat3(tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    vec3 g = vec3(0.299, 0.587, 0.114) * m;
    g = (g - dot(tex3D(tx, p, n), vec3(0.299, 0.587, 0.114))) / e.x; g -= n * dot(n, g);
    return normalize(n + g * bf);
}

float curve(in vec3 p, in float w) {
    vec2 e = vec2(-1., 1.) * w;
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    return 0.125 / (w * w) * (t1 + t2 + t3 + t4 - 4. * map(p));
}

vec3 envMap(vec3 p) {
    float c = cellTile(p * 6.);
    c = smoothstep(0.2, 1., c);
    return vec3(pow(c, 8.), c * c, c);
}

vec2 path(in float z) { float s = sin(z / 36.) * cos(z / 18.); return vec2(s * 16., 0.); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
    vec3 lk = vec3(0, 3.5, iTime * 6. * ANIMATION_SPEED);  // "Look At" position scaled by animation speed
    vec3 ro = lk + vec3(0, 0.25, -0.25);
    vec3 lp = ro + vec3(0, 0.75, 2);
    vec3 lp2 = ro + vec3(0, 0.75, 9);
    lk.xy += path(lk.z);
    ro.xy += path(ro.z);
    lp.xy += path(lp.z);
    lp2.xy += path(lp2.z);

    float FOV = 1.57;
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x));
    vec3 up = cross(fwd, rgt);
    vec3 rd = normalize(fwd + FOV * uv.x * rgt + FOV * uv.y * up);
    rd.xy *= rot2(path(lk.z).x / 64. * ANIMATION_SPEED); // Rotation speed scaled by animation speed

    float t = trace(ro, rd);
    vec3 sceneCol = vec3(0.);
    if (t < FAR) {
        vec3 sp = ro + rd * t;
        vec3 sn = getNormal(sp);
        const float tSize0 = 1. / 2.;
        sn = texBump(iChannel0, sp * tSize0, sn, 0.0); // Reduced from 0.01 to 0.005
        vec3 texCol = tex3D(iChannel0, sp * tSize0, sn);
        float ao = calculateAO(sp, sn);
        vec3 ld = lp - sp;
        vec3 ld2 = lp2 - sp;
        float lDist = max(length(ld), 0.001);
        float lDist2 = max(length(ld2), 0.001);
        ld /= lDist;
        ld2 /= lDist2;
        float atten = 1. / (1. + lDist * lDist * 0.025);
        float atten2 = 1. / (1. + lDist2 * lDist2 * 0.025);
        float ambience = 0.1;
        float diff = max(dot(sn, ld), 0.0);
        float diff2 = max(dot(sn, ld2), 0.0);
        float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.0), 8.);
        float spec2 = pow(max(dot(reflect(-ld2, sn), -rd), 0.0), 8.);
        float crv = clamp(curve(sp, 0.125) * 0.5 + 0.5, 0.0, 1.);
        float fre = pow(clamp(dot(sn, rd) + 1., 0., 1.), 1.);
        float shading = crv * 0.5 + 0.5;
        shading *= smoothstep(-0.1, 0.15, cellTile(sp));
        vec3 env = envMap(reflect(rd, sn)) * 0.5;
        vec3 rCol = cellTileColor(sp) * dot(texCol, vec3(0.299, 0.587, 0.114));
        sceneCol += (rCol * (diff + ambience) + vec3(0.8, 0.95, 1) * spec * 1.5 + env) * atten;
        sceneCol += (rCol * (diff2 + ambience) + vec3(0.8, 0.95, 1) * spec2 * 1.5 + env) * atten2;
        sceneCol *= shading * ao;
    }
    sceneCol = mix(sceneCol, vec3(0.0, 0.003, 0.01), smoothstep(0.0, FAR - 5., t));
    fragColor = vec4(sqrt(clamp(sceneCol, 0., 1.)), 1.0);
}