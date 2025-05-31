/*
    "Waveform" by @XorDev
*/

// --- OpenGL ES 1.0 Compatible tanh approximation ---
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + abs(x));
}

// --- Post-processing functions for better output control ---
vec4 saturate(vec4 color, float sat) {
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    color.rgb *= brightness;
    return saturate(color, saturation);
}

// --- Editable Parameters ---
#define WAVEFORM_AMPLITUDE 2.60        // Height/amplitude of waveform peaks (increase for higher, decrease for lower)
#define WAVEFORM_COLOR_SATURATION 0.80  // Saturation of waveform color (1.0 for full color, 0.0 for grayscale)
#define LIGHT_FALLOFF_FACTOR 0.01      // How quickly the trailing light fades (increase for faster falloff, decrease for slower)
#define WAVEFORM_LINE_GLOW 0.05        // Intensity of the waveform line glow (increase for more glow, decrease for less)
#define FLOOR_REFLECTIVITY 0.1         // Reflectivity of the floor (0.0 for no reflection, 1.0 for full reflection)
#define BRIGHTNESS 0.80                // Overall brightness (increase for brighter, decrease for darker)
#define CONTRAST 1.30                  // Overall contrast (increase for more contrast, decrease for less)
#define SATURATION 1.0                 // Overall saturation (increase for more color, decrease for less)
#define ANIMATION_SPEED .5            // Overall animation speed (increase for faster, decrease for slower)
// ------------------------------------

void mainImage(out vec4 O, vec2 I)
{
    float i; // Raymarch loop iterator
    float d; // Raymarch step distance
    float z = 0.0; // Raymarch depth
    float r_reflect; // Reflection coordinate

    O = vec4(0.0);

    for(i = 0.0; i < 90.0; i += 1.0)
    {
        vec3 p = z * normalize(vec3(I+I,0.0) - iResolution.xyy);
        vec3 p_shifted = ++p;
        r_reflect = max(-p_shifted.y, 0.0);

        p.y += r_reflect + r_reflect;

        float sine_wave_y = 0.0;
        for(float inner_d = 1.0; inner_d < 30.0; inner_d += inner_d)
        {
            sine_wave_y += cos(p * inner_d + 2.0 * iTime * cos(inner_d) * ANIMATION_SPEED + z).x / (inner_d * 2.0);
        }
        p.y += sine_wave_y * WAVEFORM_AMPLITUDE;

        float d_temp = p.z + 3.0;
        d = (0.1 * r_reflect / (1.0 + r_reflect) + abs(p.y - 1.0) / (1.0 + r_reflect + r_reflect + r_reflect * r_reflect) + max(d_temp, -d_temp * 0.1)) / 8.0;

        z += d;

        // Adjusted phase offsets for warmer amber, orange, yellow palette
        vec3 waveform_color = (cos(z * 0.5 + iTime * ANIMATION_SPEED + vec4(0.0, 1.0, 2.0, 0.5)) + 1.3).rgb;
        float lum = dot(waveform_color, vec3(0.299, 0.587, 0.114));
        waveform_color = mix(vec3(lum), waveform_color, WAVEFORM_COLOR_SATURATION);

        float reflection_factor = r_reflect > 0.0 ? FLOOR_REFLECTIVITY : 1.0;
        waveform_color *= reflection_factor;

        O.rgb += waveform_color * WAVEFORM_LINE_GLOW / (d * pow(z, LIGHT_FALLOFF_FACTOR) * 5.0);
    }

    O = tanh_approx(O/30.0);
    O = applyPostProcessing(O, BRIGHTNESS, CONTRAST, SATURATION);
    O = clamp(O, 0.0, 1.0);
}

/*

// --- Editable Parameters ---
#define WAVEFORM_AMPLITUDE 2.60        // Height/amplitude of waveform peaks (increase for higher, decrease for lower)
#define WAVEFORM_COLOR_SATURATION .70  // Saturation of waveform color (1.0 for full color, 0.0 for grayscale)
#define LIGHT_FALLOFF_FACTOR 0.01      // How quickly the trailing light fades (increase for faster falloff, decrease for slower)
#define WAVEFORM_LINE_GLOW 0.05        // Intensity of the waveform line glow (increase for more glow, decrease for less)
#define FLOOR_REFLECTIVITY 0.1         // Reflectivity of the floor (0.0 for no reflection, 1.0 for full reflection)
#define BRIGHTNESS 1.10                // Overall brightness (increase for brighter, decrease for darker)
#define CONTRAST 1.10                  // Overall contrast (increase for more contrast, decrease for less)
#define SATURATION 1.0     

*/