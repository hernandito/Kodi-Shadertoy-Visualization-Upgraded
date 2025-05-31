/*by mu6k, Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.*/

#define occlusion_enabled
#define occlusion_quality 3
//#define occlusion_preview

#define noise_use_smoothstep

// COLOR DEFINITIONS
#define light_color vec3(1.265, 0.46, 0.69)       // Light tint (pinkish)
#define light_direction normalize(vec3(.2, 1.0, -0.2))
#define light_speed_modifier 0.20

#define object_color vec3(.3, 0.8, 0.127)         // Object base color (greenish)
#define object_count 3                             // Reduced for performance
#define object_speed_modifier .8

#define render_steps 25                            // Reduced for performance

// MATERIAL PROPERTIES (Adjustable Parameters)
const float specular_strength = 0.3;              // Specular highlight intensity
const float specular_weight = 0.7;                 // Weight of specular term
const float specular_sharpness = 2.0;              // Sharpness of specular highlight
const float specular_occlusion_offset = 0.1;       // Minimum brightness of specular in occluded areas

const float ambient_factor = 0.8;                  // Ambient light factor (middle ground)
const float ambient_occlusion_offset = 0.85;       // Minimum brightness in occluded areas (ambient)
const float diffuse_contrast = 0.3;                // Diffuse contrast
const float diffuse_base = 0.75;                   // Base diffuse brightness (middle ground)
const float diffuse_occlusion_offset = 0.25;       // Minimum brightness in occluded lit areas (diffuse)

// UTILITY FUNCTIONS
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
    return v*mat3(ca, .0, -sa, .0, 1.0, .0, sa, .0, ca);
}
vec3 rotate_x(vec3 v, float angle) {
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(1.0, .0, .0, .0, ca, -sa, .0, sa, ca);
}
float max3(float a, float b, float c) {
    return max(a,max(b,c));
}

// OBJECT POSITIONS ARRAY
vec3 bpos[object_count];

// DISTANCE FIELD (SDF)
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

// NORMAL ESTIMATION FROM DISTANCE FIELD
vec3 normal(vec3 p, float e) {
    float d = dist(p);
    return normalize(vec3(
        dist(p+vec3(e,0,0))-d,
        dist(p+vec3(0,e,0))-d,
        dist(p+vec3(0,0,e))-d));
}

vec3 light = light_direction;

// BACKGROUND FUNCTION — generates sky color based on direction
vec3 background(vec3 d) {
    float y = d.y;
    float t = clamp(y * 0.23 + 0.5, 0.0, 1.0);  // [-1, 1] → [0, 1]

    vec3 zenithColor = vec3(0.08, 0.15, 0.35);     // Darker sky overhead
    vec3 horizonColor = vec3(0.4, 0.90, 1.1);      // Brighter blue near horizon
    vec3 sunColor = vec3(1.0);                     // White sun

    vec3 sunDir = vec3(0.0, 1.0, 0.0);             // Straight up
    float sunRadius = 0.1;                         // Increase for visibility
    float dToSun = distance(d, sunDir);
    float sunIntensity = smoothstep(sunRadius, sunRadius * 0.5, dToSun);

    vec3 zenithWithSun = mix(zenithColor, sunColor, sunIntensity);
    float f = smoothstep(0.0, 1.0, pow(1.0 - t, 1.5));
    vec3 skyTop = mix(horizonColor, zenithWithSun, f);
    return mix(horizonColor, skyTop, smoothstep(0.0, 1.0, t));
}

// OCCLUSION SIMULATION
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

// OBJECT LIGHTING AND MATERIAL COLOR
vec3 object_material(vec3 p, vec3 d) {
    vec3 color = normalize(object_color * light_color); // base reflectivity
    vec3 n = normal(p, 0.1);
    vec3 r = reflect(d, n); // reflected view vector
    
    float reflectance = dot(d, r)*.5+.5;
    reflectance = pow(reflectance, specular_sharpness);
    float diffuse = dot(light, n)*diffuse_contrast+diffuse_base;
    diffuse = max(.0, diffuse);

    #ifdef occlusion_enabled
        float oa = occlusion(p, n)*.4+ambient_occlusion_offset;
        float od = occlusion(p, light)*.95+diffuse_occlusion_offset;
        float os = occlusion(p, r)*.55+specular_occlusion_offset;
    #else
        float oa = 1.0;
        float od = 1.0;
        float os = 1.0;
    #endif

    #ifndef occlusion_preview
        color = 
        color * oa * ambient_factor +                 // ambient (base color)
        color * diffuse * od * .7 +                   // diffuse (light hit)
        background(r) * os * reflectance * specular_weight * specular_strength; // specular
    #else
        color = vec3((oa + od + os)*.3); // just show occlusion if previewing
    #endif
    
    return color;
}

// FLY PARAMETERS
// FLY PARAMETERS
const bool enable_blobs = false;                  // Disable blobs to focus on fly animation
const float fly_appear_time = 1.0;                // Time (in seconds) before the fly appears
const vec2 fly_start_pos = vec2(-0.7, -0.3);      // Starting position (left edge, lower quadrant)
const float fly_scale = 5.0;                       // Scale factor for the fly texture
const float fly_size = 0.1;                        // Bounding box size for rendering the fly
const float walk_duration_min = 3.0;              // Minimum duration of a walking phase
const float walk_duration_max = 5.0;              // Maximum duration of a walking phase
const float stop_duration_min = 2.0;              // Minimum duration of a pause
const float stop_duration_max = 4.0;              // Maximum duration of a pause
const float walk_distance_min = 0.05;             // Minimum distance the fly walks
const float walk_distance_max = 0.2;              // Maximum distance the fly walks
const float wiggle_speed = 70.0;                  // Speed of the wiggling motion during walking (your adjustment)
const float wiggle_amplitude = 0.006;             // Amplitude of the wiggling motion (~0.34 degrees, within 0.25 to 0.5 degrees)
const vec2 rotation_pivot = vec2(0.6, 0.5);       // Adjusted pivot point (slightly more toward the head, assuming head is on the right)
// CAMERA TUNING
#define offset1 4.7
#define offset2 4.6






// MAIN RENDER LOOP
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy - 0.5;
    uv.x *= iResolution.x / iResolution.y;

    vec3 mouse = vec3(iMouse.xy / iResolution.xy - 0.5, iMouse.z - .5);

    float t = iTime * .5 * object_speed_modifier + 2.0;

    // Update blob positions (only if enabled)
    if (enable_blobs) {
        for (int i = 0; i < object_count; i++) {
            bpos[i] = 1.3 * vec3(
                sin(t * 0.967 + float(i) * 42.0),
                sin(t * .423 + float(i) * 152.0),
                sin(t * .76321 + float(i)));
        }
    }

    vec3 ro = vec3(0.0, 0.0, -4.0);
    vec3 rd = normalize(vec3(uv, 0.5));
    
    float mx = mouse.x * 9.0 + offset2;
    float my = mouse.y * 9.0 + offset1;

    ro = rotate_y(rotate_x(ro, my), mx);
    rd = rotate_y(rotate_x(rd, my), mx);

    vec3 p = ro;
    vec3 d = rd;

    float dd;
    vec3 color;

    // Render blobs only if enabled; otherwise, use background
    if (enable_blobs) {
        for (int i = 0; i < render_steps; i++) {
            dd = dist(p);
            p += d * dd * .7;
            if (dd < .04 || dd > 4.0) break;
        }

        if (dd < 0.5)
            color = object_material(p, d);
        else
            color = background(d);
    } else {
        color = background(d);
    }

    // Fly Animation
    if (iTime >= fly_appear_time) {
        float fly_time = iTime - fly_appear_time;
        vec2 fly_pos = fly_start_pos;
        float fly_angle = 0.0; // Initial angle (head points right)

        // State machine: Track walk-pause-rotate-reset cycle
        float cycle_start_time = 0.0;
        float seed = 0.0;
        bool is_first_walk = true;
        vec2 walk_direction = vec2(1.0, 0.0); // Initial direction (right)
        float walk_distance = 0.0;
        bool is_walking = false;
        float cycle_time = 0.0;
        vec2 target_pos = fly_start_pos; // Target position for the current walk
        float last_angle = fly_angle; // Track the angle at the end of the walk

        // Compute position and angle up to the current cycle
        while (cycle_start_time < fly_time) {
            float walk_duration = mix(walk_duration_min, walk_duration_max, hash(seed + 789.0));
            float stop_duration = mix(stop_duration_min, stop_duration_max, hash(seed));
            float total_cycle_duration = walk_duration + stop_duration;

            if (cycle_start_time + total_cycle_duration >= fly_time) {
                cycle_time = fly_time - cycle_start_time;
                is_walking = cycle_time < walk_duration;
                break;
            }

            // Complete the walk phase
            walk_distance = mix(walk_distance_min, walk_distance_max, hash(seed + 456.0));
            float angle = is_first_walk ? hash(seed + 123.0) * 1.5708 : hash(seed + 123.0) * 6.28318;
            walk_direction = vec2(cos(angle), sin(angle));

            // Compute target position from the edge
            target_pos = fly_start_pos + walk_direction * walk_distance;
            if (target_pos.x < -0.7 || target_pos.x > 0.7 || target_pos.y < -0.5 || target_pos.y > 0.5) {
                vec2 to_center = normalize(vec2(0.0) - fly_start_pos);
                float redirect_angle = atan(to_center.y, to_center.x) + (hash(seed + 999.0) - 0.5) * 1.5708;
                walk_direction = vec2(cos(redirect_angle), sin(redirect_angle));
                target_pos = fly_start_pos + walk_direction * walk_distance;
            }

            fly_pos = target_pos; // Fly reaches the target position
            last_angle = atan(walk_direction.y, walk_direction.x);

            // Reset to edge for the next cycle
            fly_pos = fly_start_pos;

            cycle_start_time += total_cycle_duration;
            seed += 1.0;
            if (is_first_walk) is_first_walk = false;
        }

        // Current cycle
        float walk_duration = mix(walk_duration_min, walk_duration_max, hash(seed + 789.0));
        float stop_duration = mix(stop_duration_min, stop_duration_max, hash(seed));
        walk_distance = mix(walk_distance_min, walk_distance_max, hash(seed + 456.0));
        float angle = is_first_walk ? hash(seed + 123.0) * 1.5708 : hash(seed + 123.0) * 6.28318;
        walk_direction = vec2(cos(angle), sin(angle));

        // Compute target position for the current walk
        target_pos = fly_start_pos + walk_direction * walk_distance;
        if (target_pos.x < -0.7 || target_pos.x > 0.7 || target_pos.y < -0.5 || target_pos.y > 0.5) {
            vec2 to_center = normalize(vec2(0.0) - fly_start_pos);
            float redirect_angle = atan(to_center.y, to_center.x) + (hash(fly_time + 999.0) - 0.5) * 1.5708;
            walk_direction = vec2(cos(redirect_angle), sin(redirect_angle));
            target_pos = fly_start_pos + walk_direction * walk_distance;
        }

        if (is_walking) {
            // Walking phase: Smoothly interpolate from edge to target
            float t = clamp(cycle_time / walk_duration, 0.0, 1.0);
            fly_pos = mix(fly_start_pos, target_pos, t);
            fly_angle = atan(walk_direction.y, walk_direction.x);

            // Add wiggle during walking
            float wiggle_time = cycle_time * wiggle_speed;
            fly_angle += sin(wiggle_time) * wiggle_amplitude;
            last_angle = fly_angle; // Update last_angle for the pausing phase
        } else {
            // Pausing phase: Hold position at the destination
            fly_pos = target_pos;
            fly_angle = last_angle; // Hold the angle from the end of the walk
        }

        // Compute texture coordinates for the fly
        vec2 fly_uv = (uv - fly_pos) * fly_scale;
        vec4 fly_color = vec4(0.0); // Default to transparent

        // Ensure fly is rendered within its bounding box
        if (abs(fly_uv.x) < fly_size && abs(fly_uv.y) < fly_size) {
            // Normalize fly_uv to [0, 1] range for texture sampling
            fly_uv = (fly_uv / fly_size) * 0.5 + 0.5; // Map [-fly_size, fly_size] to [0, 1]

            // Center the UVs around the rotation pivot (between head and body)
            fly_uv -= rotation_pivot;
            mat2 rot = mat2(cos(fly_angle), -sin(fly_angle), sin(fly_angle), cos(fly_angle));
            fly_uv = rot * fly_uv;
            fly_uv += rotation_pivot; // Shift back to align with texture space

            // Clamp UV coordinates to prevent flashing
            fly_uv = clamp(fly_uv, 0.0, 1.0);

            fly_color = texture2D(iChannel0, fly_uv); // Use fly-static.png
        }

        // Overlay fly on background with alpha blending
        color = mix(color, fly_color.rgb, fly_color.a);
    }

    color *= .85;
    color = mix(color, color * color, 0.3);
    color -= hash(color.xy + uv.xy) * .02;
    color -= length(uv) * .13;
    color = cc(color, .5, .6);

    fragColor = vec4(color, 1.0);
}

