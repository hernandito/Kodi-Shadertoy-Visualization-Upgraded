/*
    MIT License
    Copyright 2025 @EwanC

    Adapted for Kodi (GLSL ES 1.0 / GLSL 1.00)
*/

// --- USER PARAMETERS ---
#define ANIMATION_SPEED 0.30 
#define BRIGHTNESS 1.00
#define CONTRAST   1.00
#define SATURATION 1.00
#define SHOW_FALLING_LEAVES 0.00 // 1.0 = On, 0.0 = Off
#define FOREST_FLOOR_SPEED_FACTOR 0.025 // Controls the speed of ground elements moving forward (0.50 was default)
// -----------------------

#define SS(a, b, t) smoothstep(a, b, t)

struct ray {
    vec3 o; // origin / camera
    vec3 d; // direction
};

// Robust Brightness/Contrast/Saturation function
vec3 applyBCS(vec3 color, float brightness, float contrast, float saturation) {
    color += brightness - 1.0;
    color = (color - 0.5) * contrast + 0.5;
    
    // Using a standard luminance formula for saturation
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    color = mix(grayscale, color, saturation);
    
    return color;
}


ray getRay(vec2 uv, vec3 camPos, vec3 lookAt, float zoom) {
    ray a;
    a.o = camPos;
    
    // Explicit initialization for robustness
    vec3 f = normalize(lookAt - camPos); // camera forwards vector
    vec3 r = cross(vec3(0.0, 1.0, 0.0), f); // camera right vector
    vec3 u = cross(f, r);                  // camera up vector
    vec3 c = a.o + f * zoom;             // center of screen

    vec3 i = c + uv.x * r + uv.y * u; // intersection of ray with screen
    a.d = normalize(i - a.o);         // ray direction

    return a;
}

vec3 closestPoint(ray r, vec3 p) {
    return r.o + max(0.0, dot(p - r.o, r.d)) * r.d;
}

float distRay(ray r, vec3 p) { 
    return length(p - closestPoint(r, p)); 
}

float bokeh(ray r, vec3 p, float size, float blur) {
    // distance from point to ray
    float dist = distRay(r, p);

    // We want points to become more faint when further away, rather than
    // smaller. Multiply to account for size reduction.
    size *= length(p);

    // Smoothstep and mix for nicer effect
    float mask = SS(size, size * (1.0 - blur), dist);
    mask *= mix(0.7, 1.0, SS(size * 0.8, size, dist));
    return mask;
}

// Pseudo-random number generator
vec4 noise(float t) {
    return fract(sin(t * vec4(123.0, 1024.0, 3456.0, 9564.0)) *
                 vec4(6547.0, 345.0, 8799.0, 1564.0));
}

// Fixed: Replaced array constructor and % operator with GLSL ES 1.0 compatible code
vec3 getAutumnColor(float t) {
    const int N = 6;
    
    // Use mod() instead of % operator
    int idx = int(mod(t * 10.0, float(N)));
    
    // Use conditional structure instead of unsupported array constructor/lookup
    vec3 col = vec3(0.0);
    
    if (idx == 0)      col = vec3(96.0 / 255.0, 60.0 / 255.0, 20.0 / 255.0);    // brown
    else if (idx == 1) col = vec3(156.0 / 255.0, 39.0 / 255.0, 6.0 / 255.0);    // red
    else if (idx == 2) col = vec3(212.0 / 255.0, 91.0 / 255.0, 18.0 / 255.0);  // orange
    else if (idx == 3) col = vec3(243.0 / 255.0, 188.0 / 255.0, 46.0 / 255.0); // yellow
    else if (idx == 4) col = vec3(95.0 / 255.0, 34.0 / 255.0, 38.0 / 255.0);    // brown
    else /* idx == 5 */ col = vec3(0.2, 0.9, 0.5);                              // green
    
    return col;
}

vec3 fallingLeaves(ray r, float t_scaled) {
    float s = 1.0 / 30.0;
    vec3 c = vec3(0.0); // color accumulator
    
    // Explicitly initialize loop variables
    float ti = 0.0;
    vec4 n = vec4(0.0);
    float x = 0.0;
    float fallSpeed = 100.0;
    float base = -14.0;
    float y = 0.0;
    float z = 0.0;
    vec3 p = vec3(0.0);
    float size = 0.0;
    float mask = 0.0;
    float fade = 0.0;
    vec3 col = vec3(0.0);


    for (float i = 0.0; i < 1.0; i += s) {
        ti = fract(t_scaled + i); // Use scaled time

        n = noise(i * 2.0);
        x = mix(-20.0, 20.0, n.x);
        x += sin(t_scaled * 20.0 * n.y); // wind sway (Use scaled time)
        
        y = base + (fallSpeed - (ti * fallSpeed));
        z = 50.0;
        p = vec3(x, y, z);

        size = mix(0.01, 0.03, n.w);
        mask = bokeh(r, p, size, 0.1);

        // multiply by ti to fade into distance linearly
        // further multiplication gives a curve of fade
        fade = ti * ti * ti;

        col = getAutumnColor(n.z);
        c += mask * fade * col;
    }

    return c;
}

vec3 foliage(ray r, float t_scaled) {
    float s = 1.0 / 500.0;
    vec3 c = vec3(0.0); // color accumulator
    
    // Explicitly initialize loop variables
    vec4 n = vec4(0.0);
    float x = 0.0;
    float y = 0.0;
    float z = 0.0;
    vec3 p = vec3(0.0);
    float size = 0.0;
    float mask = 0.0;
    vec3 col = vec3(0.0);
    float fade = 0.0;

    for (float i = 0.0; i < 1.0; i += s) {
        n = noise(i);

        x = mix(-20.0, 20.0, n.x);
        x += sin(t_scaled * 2.0 * n.y); // wind sway (Use scaled time)

        y = mix(-5.0, 10.0, n.y);
        z = mix(30.0, 50.0, n.z);
        p = vec3(x, y, z);

        size = mix(0.01, 0.03, n.w);
        mask = bokeh(r, p, size, 0.5);

        col = getAutumnColor(n.z);
        fade = mix(0.5, 0.3, n.w);
        c += mask * col * fade;
    }
    return c;
}

vec3 forestFloor(ray r, float t_scaled) {
    float s = 1.0 / 500.0;
    vec3 c = vec3(0.0); // color accumulator
    
    // Explicitly initialize loop variables
    vec4 n = vec4(0.0);
    float x = 0.0;
    float y = 0.0;
    float ti = 0.0;
    float z = 0.0;
    vec3 p = vec3(0.0);
    float size = 0.0;
    float mask = 0.0;
    vec3 col = vec3(0.0);
    float fade = 0.0;

    for (float i = 0.0; i < 1.0; i += s) {
        n = noise(i);

        x = mix(-20.0, 20.0, n.x);
        y = mix(-15.0, -5.0, n.y);

        // attenuate time using the new control variable to slow down walking effect
        ti = fract(t_scaled * FOREST_FLOOR_SPEED_FACTOR + i); // Use scaled time and floor factor
        z = 50.0 - (ti * 50.0);
        p = vec3(x, y, z);

        size = mix(0.01, 0.03, n.w);
        mask = bokeh(r, p, size, 0.5);

        col = vec3(0.423, 0.2863, 0.227); // brown color
        fade = mix(0.5, 0.3, n.w);
        c += mask * col * fade;
    }
    return c;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord / iResolution.xy; // <0, 1>
    uv -= 0.5;                               // <-0.5, 0.5>
    uv.x *= iResolution.x / iResolution.y; // Fix aspect ration.

    // Explicitly initialize
    vec2 m = iMouse.xy / iResolution.xy;
    
    // Apply speed control
    float t_scaled = iTime * ANIMATION_SPEED;
    float t = t_scaled * 0.1 + m.x;

    // Setup ray from camera to lookat
    vec3 camPos = vec3(0.0, 0.0, 0.0); // camera position
    vec3 lookAt = vec3(0.0, 0.0, 1.0); // camera directed at lookAt

    ray r = getRay(uv, camPos, lookAt, 2.0); // Camera setup

    // Base background goes top to bottom: blue -> green -> brown.
    vec3 col = mix(vec3(0.10, 0.20, 0.05), vec3(0.52, 0.80, 0.92), uv.y);
    col += smoothstep(0.1, -0.5, uv.y) * vec3(0.423, 0.2863, 0.227);

    // Bokeh effects (passing the scaled time to functions)
    col += foliage(r, t_scaled);
    
    // Conditional toggle for falling leaves
    col += fallingLeaves(r, t_scaled) * SHOW_FALLING_LEAVES;
    
    // Use the new, slower speed factor for the floor
    col += forestFloor(r, t_scaled);

    // Apply Brightness, Contrast, Saturation (BCS) adjustment
    col = applyBCS(col, BRIGHTNESS, CONTRAST, SATURATION);

    fragColor = vec4(col, 1.0);
}
