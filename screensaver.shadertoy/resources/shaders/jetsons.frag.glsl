/*
    Planet and Moon Shader with Circular Orbit and Star Masking
*/

// Constants
#define ANIMATION_SPEED_FACTOR 10.0
#define PLANET_L_RADIUS .90
#define PLANET_L_POS vec2(-0.7, 0.05)
#define PLANET_L_ATMOSPHERE_THICKNESS 0.12
#define PLANET_L_ATMOSPHERE_DENSITY 2.0
#define PLANET_L_OUTER_GLOW_FACTOR 0.15
#define PLANET_L_CRESCENT_SOFTNESS 0.03
#define PLANET_L_DARK_SIDE_BRIGHTNESS 0.018
#define PLANET_L_ORBIT_SPEED 0.002
#define MOON_S_RADIUS 0.16
#define MOON_S_POS_OFFSET vec2(0.675, -0.6) // Controls the radius of the moon's orbit around the planet (0.9, -0.8)
#define MOON_S_ATMOSPHERE_THICKNESS 0.025
#define MOON_S_ATMOSPHERE_DENSITY 2.5
#define MOON_S_OUTER_GLOW_FACTOR 0.1
#define MOON_S_CRESCENT_SOFTNESS 0.02
#define MOON_S_SURFACE_NOISE_SCALE 12.0
#define MOON_S_SURFACE_NOISE_STRENGTH 0.5
#define MOON_S_DARK_SIDE_BRIGHTNESS 0.035
#define MOON_S_ORBIT_SPEED 0.015
#define STAR_FIELD_DENSITY 6.0
#define STAR_TWINKLE_SPEED 5.10
#define STAR_BRIGHT_BLINK_FACTOR .5
#define STAR_BASE_BRIGHTNESS_MULT 18.0
#define STAR_BRIGHTNESS_POWER 13.0
#define STAR_GLOW_RADIUS_MULT 5.0
#define STAR_COLOR_VARIATION 0.45
#define HAZE_NOISE_SCALE 0.7
#define HAZE_EVOLUTION_SPEED 0.01
#define HAZE_INTENSITY 0.55
#define HAZE_VERTICAL_FALLOFF 0.65
#define LIGHT_DIR normalize(vec3(0.7, 0.1, 0.5))

const vec3 COLOR_DEEP_SPACE = vec3(0.0, 0.0, 0.0);
const vec3 COLOR_PLANET_L_ATMOSPHERE_RIM = vec3(0.95, 0.65, 0.7);
const vec3 COLOR_PLANET_L_ATMOSPHERE_INNER = vec3(0.55, 0.35, 0.45);
const vec3 COLOR_PLANET_L_SURFACE_DARK = vec3(0.02, 0.02, 0.04);
const vec3 COLOR_PLANET_L_OUTER_GLOW = vec3(0.6, 0.3, 0.4);
const vec3 COLOR_MOON_S_ATMOSPHERE_RIM = vec3(1.0, 0.75, 0.85);
const vec3 COLOR_MOON_S_ATMOSPHERE_INNER = vec3(0.65, 0.45, 0.6);
const vec3 COLOR_MOON_S_SURFACE_BASE = vec3(0.45, 0.4, 0.5);
const vec3 COLOR_MOON_S_SURFACE_DARK = vec3(0.05, 0.04, 0.06);
const vec3 COLOR_MOON_S_OUTER_GLOW = vec3(0.7, 0.4, 0.5);
const vec3 COLOR_HAZE_TOP = vec3(0.0, 0., 0.);
const vec3 COLOR_HAZE_BOTTOM = vec3(0.0, 0.0, 0.0);

float hash11(float p) { p = fract(p * .1031); p *= p + 33.33; p *= p + p; return fract(p); }
vec2 hash22(vec2 p) { return vec2(hash11(p.x + p.y * 57.0), hash11(p.x * 13.0 - p.y)); }

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float v00 = hash11(dot(i + vec2(0.0, 0.0), vec2(1.0, 57.0)));
    float v10 = hash11(dot(i + vec2(1.0, 0.0), vec2(1.0, 57.0)));
    float v01 = hash11(dot(i + vec2(0.0, 1.0), vec2(1.0, 57.0)));
    float v11 = hash11(dot(i + vec2(1.0, 1.0), vec2(1.0, 57.0)));
    return mix(mix(v00, v10, f.x), mix(v01, v11, f.x), f.y);
}

float fbm(vec2 p, int octaves, float persistence, float lacunarity) {
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;
    float maxValue = 0.0;
    for (int i = 0; i < octaves; i++) {
        total += noise(p * frequency) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return total / maxValue;
}

mat2 rot2D(float angle) {
    float s = sin(angle); float c = cos(angle);
    return mat2(c, -s, s, c);
}

vec2 raySphere(vec3 ro, vec3 rd, vec3 s_pos, float s_rad) {
    vec3 oc = ro - s_pos;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - s_rad * s_rad;
    float h = b * b - c;
    if (h < 0.0) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b - h, -b + h);
}

vec3 renderCelestialBody(
    vec2 uv_planet_space, float obj_radius_apparent, vec3 base_color, vec3 dark_side_color, float dark_side_brightness,
    vec3 atmo_rim_color, vec3 atmo_inner_color, float atmo_thick_abs, float atmo_density,
    float crescent_softness, float surface_noise_scale, float surface_noise_strength,
    float obj_time, float aspect, vec3 outer_glow_color, float outer_glow_factor
) {
    vec3 col = vec3(0.0);
    float dist_from_center = length(uv_planet_space);

    if (dist_from_center < obj_radius_apparent + atmo_thick_abs * 1.8 + outer_glow_factor * obj_radius_apparent * 0.5) {
        vec3 ro = vec3(uv_planet_space.x, uv_planet_space.y, 2.0);
        vec3 rd = vec3(0.0, 0.0, -1.0);

        vec2 isect = raySphere(ro, rd, vec3(0.0, 0.0, 0.0), obj_radius_apparent);

        if (isect.x > 0.0) {
            vec3 hit_pos_local = ro + rd * isect.x;
            vec3 normal = normalize(hit_pos_local);
            vec3 sphere_uvw = normal;
            sphere_uvw.yz *= rot2D(obj_time * 0.1);
            float surface_noise = 0.0;
            if(surface_noise_strength > 0.0){
                surface_noise = fbm(sphere_uvw.xy * surface_noise_scale, 3, 0.5, 2.0);
                surface_noise += fbm(sphere_uvw.yz * surface_noise_scale * 0.8, 3, 0.5, 2.0);
                surface_noise = surface_noise * 0.5 - 0.25;
            }
            // Further enhance the noise contrast
            vec3 surface_color = base_color;
            if (surface_noise_strength > 0.0) {
                // Increase the noise contrast and strength
                float noise_contrast = (surface_noise * 2.5 - 1.25) * surface_noise_strength * 1.2; // Increased scaling and strength
                noise_contrast = clamp(noise_contrast, -0.6, 0.6); // Slightly wider range to allow more pronounced effects
                surface_color = mix(base_color, base_color * (1.0 + noise_contrast), 1.1); // Higher mix factor for more pronounced noise
            }

            float NdotL = max(0.0, dot(normal, LIGHT_DIR));
            float light_intensity = smoothstep(0.0, crescent_softness, NdotL);
            
            col = mix(dark_side_color * dark_side_brightness, surface_color * (0.5 + NdotL*0.9) , light_intensity); // Slightly increase the bright side intensity

            float fresnel = pow(1.0 - abs(dot(rd, normal)), atmo_density / aspect);
            vec3 atmo_color_base = mix(atmo_inner_color, atmo_rim_color, fresnel);
            
            float lit_edge_boost = smoothstep(0.0, 0.15, NdotL) * (1.0-smoothstep(0.1, 0.3, NdotL));
            float atmo_strength = (fresnel + lit_edge_boost * 1.0) * (NdotL * 0.8 + 0.2);
            float atmo_falloff = 1.0 - smoothstep(obj_radius_apparent, obj_radius_apparent + atmo_thick_abs, dist_from_center);
            vec3 atmo_final_color = atmo_color_base * clamp(atmo_strength * atmo_falloff * 2.5, 0.0, 1.0);
            col = mix(col, atmo_final_color, clamp(atmo_strength * atmo_falloff * 3.0,0.0,1.0) );
            col = max(col, atmo_final_color * 0.7);
        } else if (dist_from_center < obj_radius_apparent + atmo_thick_abs) {
             vec3 normal_approx = normalize(vec3(uv_planet_space, sqrt(max(0.0, (obj_radius_apparent+atmo_thick_abs)*(obj_radius_apparent+atmo_thick_abs) - dist_from_center*dist_from_center )) ));
             float fresnel = pow(1.0 - abs(dot(rd, normal_approx)), atmo_density / aspect * 1.5);
             vec3 atmo_color_base = mix(atmo_inner_color, atmo_rim_color, fresnel);
             float atmo_strength = fresnel * 1.0;
             col = mix(vec3(0.0), atmo_color_base, clamp(atmo_strength * (1.0-smoothstep(obj_radius_apparent*0.95, obj_radius_apparent + atmo_thick_abs, dist_from_center)), 0.0,1.0));
        }

        float outer_glow_start_radius = obj_radius_apparent + atmo_thick_abs * 0.5;
        float outer_glow_end_radius = obj_radius_apparent + atmo_thick_abs + obj_radius_apparent * outer_glow_factor;
        float outer_glow_mask = smoothstep(outer_glow_end_radius, outer_glow_start_radius, dist_from_center);
        col += outer_glow_color * outer_glow_mask * 0.5;
    }
    return col;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float time = iTime * ANIMATION_SPEED_FACTOR;
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float aspect = iResolution.x / iResolution.y;

    vec2 haze_uv = uv * HAZE_NOISE_SCALE + vec2(0.0, time * HAZE_EVOLUTION_SPEED);
    float haze_fbm = fbm(haze_uv, 4, 0.5, 2.0);
    haze_fbm = (haze_fbm * 0.5 + 0.5);
    
    float vertical_gradient = pow(smoothstep(-1.0, 1.0, uv.y * 0.8 + 0.4), HAZE_VERTICAL_FALLOFF);
    vec3 haze_color = mix(COLOR_HAZE_TOP, COLOR_HAZE_BOTTOM, vertical_gradient);
    haze_color *= (0.6 + haze_fbm * 0.4) * HAZE_INTENSITY;
    
    vec3 finalColor = COLOR_DEEP_SPACE + haze_color;
    vec2 starUvBase = uv * STAR_FIELD_DENSITY;
    vec3 starColorAccumulator = vec3(0.0);

    // Calculate distances to planet and moon for masking
    float planet_L_z = 0.0;
    float moon_S_z = -0.1;

    vec2 planetL_finalPos = PLANET_L_POS + vec2(cos(time * PLANET_L_ORBIT_SPEED), sin(time*PLANET_L_ORBIT_SPEED*0.7))*0.01;
    float planet_L_apparent_radius = PLANET_L_RADIUS / (2.0 - planet_L_z);
    float planet_L_atmo_abs = PLANET_L_ATMOSPHERE_THICKNESS * planet_L_apparent_radius;
    float dist_to_planet = length(uv - planetL_finalPos) - (planet_L_apparent_radius + planet_L_atmo_abs);

    // Modified section to ensure circular orbit around the planet
    vec2 moonS_orbit_center = planetL_finalPos; // Same center as the planet
    vec2 moonS_finalPos = moonS_orbit_center + MOON_S_POS_OFFSET * rot2D(time * MOON_S_ORBIT_SPEED);
    // End of modified section
    float moon_S_apparent_radius = MOON_S_RADIUS / (2.0 - moon_S_z);
    float moon_S_atmo_abs = MOON_S_ATMOSPHERE_THICKNESS * moon_S_apparent_radius;
    float dist_to_moon = length(uv - moonS_finalPos) - (moon_S_apparent_radius + moon_S_atmo_abs);

    // Render stars only where not overlapped by planet or moon
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 starGridId = floor(starUvBase) + vec2(x, y);
            float starExistenceSeed = hash11(dot(starGridId, vec2(12.9898, 78.233)));
            if (starExistenceSeed < 0.25) continue;

            vec2 offsetInCell = hash22(starGridId) * 0.8 + 0.1;
            vec2 starPosScreen = (starGridId + offsetInCell) / STAR_FIELD_DENSITY;
            float distToStar = length(uv - starPosScreen) * STAR_FIELD_DENSITY;
            float brightnessSeed = hash11(dot(starGridId, vec2(31.642, 47.137)));
            float starBrightness = pow(brightnessSeed, STAR_BRIGHTNESS_POWER);
            float starSize = mix(0.007, 0.035, starBrightness);
            float twinkleVal = sin(time * STAR_TWINKLE_SPEED * (1.0 + brightnessSeed*2.0) + dot(starGridId, vec2(3.1,7.8)) * 10.0);
            float blinkMod = (0.6 + 0.4 * twinkleVal);
            if (brightnessSeed > 0.7) {
                blinkMod = 0.4 + pow(twinkleVal * 0.5 + 0.5, 8.0) * STAR_BRIGHT_BLINK_FACTOR;
            }
            float starIntensityFalloff = smoothstep(starSize * 1.5, 0.0, distToStar) * blinkMod;

            // Mask stars if they are behind the planet or moon
            if (dist_to_planet > 0.0 && dist_to_moon > 0.0) {
                float colorSeed = hash11(dot(starGridId, vec2(8.123, 2.456)));
                vec3 baseStarColor = vec3(1.0);
                if (STAR_COLOR_VARIATION > 0.0) {
                    if (colorSeed < 0.5 * STAR_COLOR_VARIATION) baseStarColor = vec3(0.8, 0.85, 1.0);
                }
                vec3 currentStarCol = baseStarColor * starIntensityFalloff * starBrightness * STAR_BASE_BRIGHTNESS_MULT;

                float glowFalloff = smoothstep(starSize * STAR_GLOW_RADIUS_MULT, starSize*0.5, distToStar);
                currentStarCol += baseStarColor * glowFalloff * starBrightness * STAR_BASE_BRIGHTNESS_MULT * 0.2 * blinkMod;
                
                starColorAccumulator += currentStarCol;
            }
        }
    }
    finalColor += starColorAccumulator;

    // Render planet and moon   MOON_S_POS_OFFSET
    vec3 planetLCompositeColor = vec3(0.0);
    vec3 moonSCompositeColor = vec3(0.0);

    vec2 uv_for_planetL = uv - planetL_finalPos;
    planetLCompositeColor = renderCelestialBody(uv_for_planetL, planet_L_apparent_radius, vec3(0.0), COLOR_PLANET_L_SURFACE_DARK, PLANET_L_DARK_SIDE_BRIGHTNESS,
                                         COLOR_PLANET_L_ATMOSPHERE_RIM, COLOR_PLANET_L_ATMOSPHERE_INNER, planet_L_atmo_abs, PLANET_L_ATMOSPHERE_DENSITY,
                                         PLANET_L_CRESCENT_SOFTNESS, 0.0, 0.0,
                                         time, aspect, COLOR_PLANET_L_OUTER_GLOW, PLANET_L_OUTER_GLOW_FACTOR);
    
    vec2 uv_for_moonS = uv - moonS_finalPos;
    moonSCompositeColor = renderCelestialBody(uv_for_moonS, moon_S_apparent_radius, COLOR_MOON_S_SURFACE_BASE, COLOR_MOON_S_SURFACE_DARK, MOON_S_DARK_SIDE_BRIGHTNESS,
                                       COLOR_MOON_S_ATMOSPHERE_RIM, COLOR_MOON_S_ATMOSPHERE_INNER, moon_S_atmo_abs, MOON_S_ATMOSPHERE_DENSITY,
                                       MOON_S_CRESCENT_SOFTNESS, MOON_S_SURFACE_NOISE_SCALE, MOON_S_SURFACE_NOISE_STRENGTH,
                                       time * 2.5, aspect, COLOR_MOON_S_OUTER_GLOW, MOON_S_OUTER_GLOW_FACTOR);

    finalColor = finalColor + planetLCompositeColor * 0.8;
    finalColor = finalColor + moonSCompositeColor;

    finalColor = pow(finalColor, vec3(0.92));
    finalColor = clamp(finalColor, 0.0, 1.0);

    fragColor = vec4(finalColor, 1.0);
}