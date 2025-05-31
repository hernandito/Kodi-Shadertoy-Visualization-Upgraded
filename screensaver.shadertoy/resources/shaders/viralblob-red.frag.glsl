/*by mu6k, Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.*/

#define occlusion_enabled
#define occlusion_quality 4
//#define occlusion_preview

#define noise_use_smoothstep

// 🌈 COLOR DEFINITIONS
#define light_color vec3(1.265,0.46,0.69)       // ← Light tint (pinkish)
#define light_direction normalize(vec3(.2,1.0,-0.2))
#define light_speed_modifier 0.20

#define object_color vec3(9.1,0.1,0.1)     // ← Object base color (bright red)
#define object_count 7
#define object_speed_modifier .8

#define render_steps 33

// 🔆 SPECULAR HIGHLIGHT INTENSITY (Reflection brightness)
#define specular_strength 1.1                   // ← Reduce this to soften blue reflections (try 0.6)


// 🧪 UTILITY FUNCTIONS
float hash(float x) {
    return fract(sin(x*.0127863)*17143.321);
}
float hash(vec2 x) {
    return fract(cos(dot(x.xy,vec2(2.31,53.21))*124.123)*412.0); 
}
vec3 cc(vec3 color, float factor,float factor2) {
    float w = color.x+color.y+color.z;
    return mix(color,vec3(w)*factor,w*factor2);
}
float hashmix(float x0, float x1, float interp) {
    x0 = hash(x0);
    x1 = hash(x1);
    #ifdef noise_use_smoothstep
    interp = smoothstep(0.0,1.0,interp);
    #endif
    return mix(x0,x1,interp);
}
float noise(float p) {
    float pm = mod(p,1.0);
    float pd = p-pm;
    return hashmix(pd,pd+1.0,pm);
}
vec3 rotate_y(vec3 v, float angle) {
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        ca, .0, -sa,
        .0, 1.0, .0,
        sa, .0, ca);
}
vec3 rotate_x(vec3 v, float angle) {
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        1.0, .0, .0,
        .0, ca, -sa,
        .0, sa, ca);
}
float max3(float a, float b, float c) {
    return max(a,max(b,c));
}

// 🔘 OBJECT POSITIONS ARRAY
vec3 bpos[object_count];

// 🧱 DISTANCE FIELD (SDF)
float dist(vec3 p) {
    float d = 1920.0;
    float nd;
    for (int i = 0; i < object_count; i++) {
        vec3 np = p + bpos[i];
        float shape0 = max3(abs(np.x),abs(np.y),abs(np.z)) - 1.0;
        float shape1 = length(np) - 1.0;
        nd = shape0 + (shape1 - shape0)*2.0;
        d = mix(d, nd, smoothstep(-1.0, 1.0, d - nd));
    }
    return d;
}

// 📐 NORMAL ESTIMATION FROM DISTANCE FIELD
vec3 normal(vec3 p, float e) {
    float d = dist(p);
    return normalize(vec3(
        dist(p+vec3(e,0,0))-d,
        dist(p+vec3(0,e,0))-d,
        dist(p+vec3(0,0,e))-d));
}

vec3 light = light_direction;

// 🌌 BACKGROUND FUNCTION — generates sky color based on direction
vec3 background(vec3 d) {
    float y = d.y;
    float t = clamp(y * 0.23 + 0.5, 0.0, 1.0);  // [-1, 1] → [0, 1]

    // Color settings
    vec3 zenithColor = vec3(0.08, 0.15, 0.35);     // Darker sky overhead
    vec3 horizonColor = vec3(0.4, 0.90, 1.1);      // Brighter blue near horizon
    vec3 sunColor = vec3(1.0);                     // White sun

    // Sun disk at zenith
    vec3 sunDir = vec3(0.0, 1.0, 0.0);             // Straight up
    float sunRadius = 0.1;                         // Increase for visibility
    float dToSun = distance(d, sunDir);
    float sunIntensity = smoothstep(sunRadius, sunRadius * 0.5, dToSun); // softer edge

    // Composite zenith + sun
    vec3 zenithWithSun = mix(zenithColor, sunColor, sunIntensity);

    // Interpolate from zenith to horizon (top to edge)
    float f = smoothstep(0.0, 1.0, pow(1.0 - t, 1.5));
    vec3 skyTop = mix(horizonColor, zenithWithSun, f);

    // Final blend depending on view angle
    return mix(horizonColor, skyTop, smoothstep(0.0, 1.0, t));
}


// 🔅 OCCLUSION SIMULATION
float occlusion(vec3 p, vec3 d) {
    float occ = 1.0;
    p = p + d;
    for (int i = 0; i < occlusion_quality; i++) {
        float dd = dist(p);
        p += d * dd;
        occ = min(occ, dd);
    }
    return max(.0, occ);
}

// 💡 OBJECT LIGHTING AND MATERIAL COLOR
vec3 object_material(vec3 p, vec3 d) {
    vec3 color = normalize(object_color * light_color); // base reflectivity
    vec3 n = normal(p, 0.1);
    vec3 r = reflect(d, n); // reflected view vector
    
    float reflectance = dot(d, r)*.5+.5;
    reflectance = pow(reflectance, 2.0);
    float diffuse = dot(light, n)*.5+.5;
    diffuse = max(.0, diffuse);

    #ifdef occlusion_enabled
        float oa = occlusion(p, n)*.4+.6;
        float od = occlusion(p, light)*.95+.05;
        float os = occlusion(p, r)*.95+.05;
    #else
        float oa = 1.0;
        float ob = 1.0;
        float oc = 1.0;
    #endif

    #ifndef occlusion_preview
        color = 
        color * oa * .5 +                             // ambient (base color)
        color * diffuse * od * .7 +                   // diffuse (light hit)
        background(r) * os * reflectance * .7 * specular_strength; // ✨ specular (mirror reflection from sky)
    #else
        color = vec3((oa + od + os)*.3); // just show occlusion if previewing
    #endif
    
    return color;
}

// 🎛️ CAMERA TUNING
#define offset1 4.7
#define offset2 4.6

// 🎬 MAIN RENDER LOOP (restored original camera orientation)
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy - 0.5;
    uv.x *= iResolution.x / iResolution.y;

    // 🖱️ CAMERA CONTROL VIA MOUSE
    vec3 mouse = vec3(iMouse.xy / iResolution.xy - 0.5, iMouse.z - .5);

    // 🌀 OBJECT MOTION OVER TIME
    float t = iTime * .5 * object_speed_modifier + 2.0;
    for (int i = 0; i < object_count; i++) {
        bpos[i] = 1.3 * vec3(
            sin(t * 0.967 + float(i) * 42.0),
            sin(t * .423 + float(i) * 152.0),
            sin(t * .76321 + float(i)));
    }

    // ✅ RESTORED CAMERA ORIENTATION
    vec3 ro = vec3(0.0, 0.0, -4.0);
    vec3 rd = normalize(vec3(uv, 0.5));
    
    float mx = mouse.x * 9.0 + offset2;
    float my = mouse.y * 9.0 + offset1;

    ro = rotate_y(rotate_x(ro, my), mx);
    rd = rotate_y(rotate_x(rd, my), mx);

    vec3 p = ro;
    vec3 d = rd;

    // 🌟 RAYMARCHING LOOP
    float dd;
    vec3 color;
    for (int i = 0; i < render_steps; i++) {
        dd = dist(p);
        p += d * dd * .7;
        if (dd < .04 || dd > 4.0) break;
    }

    // 🎨 SHADING BASED ON HIT OR MISS
    if (dd < 0.5)
        color = object_material(p, d);   // ← includes specular highlight from background
    else
        color = background(d);           // ← just sky color

    // 🌈 FINAL COLOR POSTPROCESSING
    color *= .85;
    color = mix(color, color * color, 0.3);         // boost saturation
    color -= hash(color.xy + uv.xy) * .02;          // tiny noise
    color -= length(uv) * .13;                      // vignette
    color = cc(color, .5, .6);                      // color correction

    fragColor = vec4(color, 1.0);
}
