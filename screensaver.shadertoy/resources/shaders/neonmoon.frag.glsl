// GLSL ES 1.00 compatibility header (usually added by Kodi, but good to note)
// #version 100
precision mediump float; // Required for GLSL ES 1.00

float intensity = 0.05; // Base intensity for overall glow
float falloff = 1.0;    // Falloff rate for glow intensity

vec3 green = vec3(0.0, 1.0, 0.5);
vec3 yellow = vec3(1.0, 0.5, 0.0);
vec3 red = vec3(1.0, 0, 0);
vec3 white = vec3(1.0);
vec3 blue = vec3(0.1, 0.25, 0.95);

// Orangish-yellow color for the star (#fcd406)
vec3 neon_yellow_star = vec3(0.9882, 0.8314, 0.0235);

float pi = 3.14159265359;

// Function for pseudo-random number based on a float input
float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    return fract(p * (p + p));
}

// --------------------------------------
// Neon Flicker Parameters
// Adjust these values to fine-tune the flicker behavior
// --------------------------------------
// 1. Subtle Humming Flicker (always present for both moon and star)
#define HUM_AMOUNT 0.05          // Intensity of subtle, rapid hum/flicker (0.0 = no hum, 0.1 = noticeable)
#define HUM_SPEED 120.0          // Speed/frequency of the subtle "humming" flicker (higher = faster)

// 2. Major Flicker Event (Concentrated Burst - ONLY FOR MOON)
// This defines when and how the moon performs its noticeable flickers.
#define EVENT_CYCLE_LENGTH 30.0  // Approx. time between major flicker events (e.g., 15.0 to 30.0 seconds).
                                 // The moon's flicker burst will start at a random point within this cycle.
#define EVENT_BURST_DURATION 1.0 // Duration of the intense flicker burst (e.g., 1.0 to 2.0 seconds).
#define BURST_FLICKER_RATE 60.0  // Speed of individual flickers WITHIN the burst (higher = faster, more choppy).
#define BURST_OFF_PROB 0.05      // Probability (0-1) of going OFF during the burst (e.g., 0.05 = 5% chance per rapid segment).
#define BURST_DIM_PROB 0.4       // Probability of going DIM during the burst (e.g., 0.4 = 40% chance, including OFF).
#define BURST_DIM_FACTOR 0.6     // Brightness when DIM during the burst (0.0 to 1.0).

// 3. Brightness BETWEEN Major Flicker Events (for Moon)
#define BRIGHTNESS_BETWEEN_EVENTS 0.88 // Base brightness of the moon when NOT in a flicker event (0.0 to 1.0, 1.0 is full bright).
                                       // Only the hum will affect it here.

// --------------------------------------
// Object Specific Parameters (Moon and Star)
// --------------------------------------
#define MOON_DISPLAY_SCALE 1.5         // Overall scale factor for the moon's rendering.
#define STAR_POS_OFFSET vec2(0.7, 0.42) // X and Y position of the star in the scene (base position relative to UV center).
#define STAR_DISPLAY_SCALE 0.35        // Overall size of the star.
#define STAR_BRIGHTNESS_ADJUST 0.5     // Adjusts the overall brightness of the yellow star to match the moon.
#define STAR_TUBE_CORE_BRIGHTNESS_MULTIPLIER 2.5 // Multiplier for the star's inner tube core brightness.

// Parameters defining the structure of the neon tube and glow.
// These are UNIVERSAL for both moon and star to ensure exact match.
#define TUBE_HALF_WIDTH 0.04           // Half-width (radius) of the neon tube.
#define TUBE_INNER_CORE_END 0.02       // Distance from center where the brightest core starts fading.
#define TUBE_OUTER_EDGE 0.03           // Distance from center where the inner tube color transitions to the 'hard edge' color.
#define GLOW_START_DIST 0.04           // Distance from center where the outer glow starts fading.
#define GLOW_END_DIST 0.05             // Distance from center where the outer glow fully fades.


// --------------------------------------
// Post-Processing: Brightness, Contrast, Saturation (BCS)
// Adjust these values to modify the final look of the shader.
// --------------------------------------
#define BRIGHTNESS_ADJ 0.50 // Adjust overall brightness (e.g., 0.5 for dimmer, 1.5 for brighter)
#define CONTRAST_ADJ 1.90   // Adjust contrast (e.g., 0.5 for lower, 1.5 for higher)
#define SATURATION_ADJ 1.10 // Adjust color saturation (e.g., 0.0 for grayscale, 1.5 for oversaturated)


// --------------------------------------
// Post-Processing Scene Control
// --------------------------------------
#define STAR_RENDER_ENABLED 1.0       // 1.0 to enable star rendering, 0.0 to disable. (ON by default)
#define SCENE_SHIFT_X 0.20             // Additional X-shift for the entire scene (moon and star together).
#define SCENE_SHIFT_Y 0.080             // Additional Y-shift for the entire scene (moon and star together).


vec2 rotate2D(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    mat2 rotMatrix = mat2(
        c, -s,
        s,  c
    );
    return rotMatrix * v;
}

float sdMoon(vec2 p, float d, float ra, float rb )
{
    p.y = abs(p.y);
    float a = (ra*ra - rb*rb + d*d)/(2.0*d);
    float b = sqrt(max(ra*ra-a*a,0.0));
    if( d*(p.x*b-p.y*a) > d*d*max(b-p.y,0.0) )
        return length(p-vec2(a,b));
    return max( (length(p        )-ra),
                -(length(p-vec2(d,0))-rb));
}

// Signed Distance Function for a line segment
// p: point to test
// a: start point of the segment
// b: end point of the segment
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - h * ba);
}

// Hardcoded star vertices as individual const vec2 for GLSL ES 1.00 compatibility
const vec2 star_vertex_0 = vec2( 0.0000, -0.9246);  // Top tip
const vec2 star_vertex_1 = vec2( 0.2467, -0.3524);  // Inner valley 1
const vec2 star_vertex_2 = vec2( 0.8671, -0.2946);  // Outer tip 1
const vec2 star_vertex_3 = vec2( 0.3992,  0.1169);  // Inner valley 2
const vec2 star_vertex_4 = vec2( 0.5359,  0.7248);  // Outer tip 2
const vec2 star_vertex_5 = vec2( 0.0000,  0.4070);  // Inner valley 3
const vec2 star_vertex_6 = vec2(-0.5359,  0.7248);  // Outer tip 3
const vec2 star_vertex_7 = vec2(-0.3992,  0.1169);  // Inner valley 4
const vec2 star_vertex_8 = vec2(-0.8671, -0.2946);  // Outer tip 4
const vec2 star_vertex_9 = vec2(-0.2467, -0.3524);   // Inner valley 5


// Helper function to get star vertex data by index for GLSL ES 1.00
vec2 getStarVertex(int index) {
    if (index == 0) return star_vertex_0;
    if (index == 1) return star_vertex_1;
    if (index == 2) return star_vertex_2;
    if (index == 3) return star_vertex_3;
    if (index == 4) return star_vertex_4;
    if (index == 5) return star_vertex_5;
    if (index == 6) return star_vertex_6;
    if (index == 7) return star_vertex_7;
    if (index == 8) return star_vertex_8;
    if (index == 9) return star_vertex_9;
    return vec2(0.0); // Should not happen
}

// Signed Distance Function for a 5-point star defined by a polyline
// p: coordinate to test (assumed to be in the star's local, unit-scaled space)
float sdStarPolyline(vec2 p) {
    float minDist = 1e10; // Initialize with a very large number
    for (int i = 0; i < 10; ++i) {
        vec2 p1 = getStarVertex(i);
        vec2 p2 = getStarVertex(int(mod(float(i + 1), 10.0))); // Use mod() function for compatibility
        minDist = min(minDist, sdSegment(p, p1, p2));
    }
    return minDist;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord/iResolution.xy; //normalized coordinates
    
    //modify uv to center-fit unit circle within landscape viewport
    uv *= 2.0;
    uv -= 1.0;
    float aspectRatio = iResolution.x/iResolution.y;
    uv.x *= aspectRatio;
    
    // --------------------------------------
    // NEW: Apply scene shift based on STAR_RENDER_ENABLED
    // --------------------------------------
    vec2 shifted_uv = uv;
    if (STAR_RENDER_ENABLED == 1.0) {
        shifted_uv += vec2(SCENE_SHIFT_X, SCENE_SHIFT_Y);
    }

    // Initialize overall color to black (background)
    vec3 col = vec3(0.0);
    
    // --------------------------------------
    // Moon Calculation (uses shifted_uv)
    // --------------------------------------
    vec3 col_moon;
    // r_moon_dist is the signed distance to the moon's shape
    // Divide by MOON_DISPLAY_SCALE to ensure TUBE_HALF_WIDTH applies consistently in UV space.
    float r_moon_dist = abs(sdMoon(rotate2D(shifted_uv * MOON_DISPLAY_SCALE, 0.8 * pi / 4.0), 0.9, 1.0, 1.0)) / MOON_DISPLAY_SCALE;
    
    if(r_moon_dist < TUBE_HALF_WIDTH) { // Moon tube (inner part)
        col_moon = mix(white * 2.0, blue * 1.5, smoothstep(TUBE_INNER_CORE_END, TUBE_OUTER_EDGE, r_moon_dist));
    } else { // Moon glow (outer part)
        col_moon = mix(blue * 1.5, intensity * blue / pow(r_moon_dist, falloff), smoothstep(GLOW_START_DIST, GLOW_END_DIST, r_moon_dist));
    }

    // --------------------------------------
    // Star Calculation (uses shifted_uv and STAR_RENDER_ENABLED toggle)
    // --------------------------------------
    vec3 col_star = vec3(0.0); // Initialize to black, so if STAR_RENDER_ENABLED is 0, it stays off.

    if (STAR_RENDER_ENABLED == 1.0) {
        // Star's position offset is applied to the shifted UV coordinates
        vec2 uv_for_star_sdf = (shifted_uv - STAR_POS_OFFSET) / STAR_DISPLAY_SCALE;
        
        // r_star_dist is the distance to the star's polyline
        float r_star_dist = sdStarPolyline(uv_for_star_sdf) * STAR_DISPLAY_SCALE; 

        if(r_star_dist < TUBE_HALF_WIDTH) { // Star tube (inner part)
            col_star = mix(neon_yellow_star * (2.0 * STAR_TUBE_CORE_BRIGHTNESS_MULTIPLIER), 
                           neon_yellow_star * 1.5, 
                           smoothstep(TUBE_INNER_CORE_END, TUBE_OUTER_EDGE, r_star_dist));
        } else { // Star glow (outer part)
            col_star = mix(neon_yellow_star * 1.5, intensity * neon_yellow_star / pow(r_star_dist, falloff), smoothstep(GLOW_START_DIST, GLOW_END_DIST, r_star_dist));
        }
        
        col_star *= STAR_BRIGHTNESS_ADJUST;
    }

    // --------------------------------------
    // Neon Flicker Effect Calculation
    // --------------------------------------
    float moon_flicker_factor = 1.0;
    float star_flicker_factor = 1.0;

    float hum_val = HUM_AMOUNT * (hash11(iTime * HUM_SPEED) - 0.5);
    moon_flicker_factor += hum_val;
    star_flicker_factor += hum_val;

    float event_cycle_time = mod(iTime, EVENT_CYCLE_LENGTH);
    float event_segment_index = floor(iTime / EVENT_CYCLE_LENGTH);
    float event_start_offset_in_cycle = hash11(event_segment_index + 0.111) * (EVENT_CYCLE_LENGTH - EVENT_BURST_DURATION);

    bool in_flicker_burst = (event_cycle_time >= event_start_offset_in_cycle) &&
                            (event_cycle_time < event_start_offset_in_cycle + EVENT_BURST_DURATION);

    if (in_flicker_burst) {
        float time_within_burst = event_cycle_time - event_start_offset_in_cycle;
        float burst_flicker_segment = floor(time_within_burst * BURST_FLICKER_RATE);
        float random_burst_val = hash11(burst_flicker_segment + 0.222);

        if (random_burst_val < BURST_OFF_PROB) {
            moon_flicker_factor *= 0.0;
        } else if (random_burst_val < BURST_DIM_PROB) {
            moon_flicker_factor *= BURST_DIM_FACTOR;
        } else {
            moon_flicker_factor *= 1.0;
        }

        float burst_fade_time = 0.1;
        if (time_within_burst < burst_fade_time) {
            moon_flicker_factor *= smoothstep(0.0, burst_fade_time, time_within_burst);
        } else if (time_within_burst > EVENT_BURST_DURATION - burst_fade_time) {
            moon_flicker_factor *= smoothstep(EVENT_BURST_DURATION, EVENT_BURST_DURATION - burst_fade_time, time_within_burst);
        }

    } else {
        moon_flicker_factor *= BRIGHTNESS_BETWEEN_EVENTS;
    }

    moon_flicker_factor = clamp(moon_flicker_factor, 0.0, 1.0);
    star_flicker_factor = clamp(star_flicker_factor, 0.0, 1.0);

    col_moon *= moon_flicker_factor;
    col_star *= star_flicker_factor;

    // --------------------------------------
    // Combine Moon and Star Colors
    // --------------------------------------
    col = col_moon + col_star;
    
    //col = col / (col + 1.0); //tone mapping
    col = pow(col, vec3(0.4545)); //gamma correction
    
    // --------------------------------------
    // Post-Processing: Brightness, Contrast, Saturation (BCS) Adjustments
    // --------------------------------------
    vec3 final_rgb = col.rgb;

    // Saturation Adjustment
    float luma = dot(final_rgb, vec3(0.2126, 0.7152, 0.0722));
    final_rgb = mix(vec3(luma), final_rgb, SATURATION_ADJ);

    // Contrast Adjustment
    final_rgb = ((final_rgb - 0.5) * CONTRAST_ADJ) + 0.5;

    // Brightness Adjustment
    final_rgb *= BRIGHTNESS_ADJ;

    fragColor = vec4(final_rgb, 1.0);
}