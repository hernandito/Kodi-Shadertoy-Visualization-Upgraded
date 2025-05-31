// Created by inigo quilez - iq/2015
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/

// Based on Flyguy's "Ring Teister" https://www.shadertoy.com/view/Xt23z3. I didn't write
// this effect since around 1999. Only now it's antialiased, motion blurred, texture
// filtered and high resolution. Uncomment line 40 to see the columns.

// -----------------------------------------------------------------------------
// ADJUSTABLE PARAMETERS
// Adjust these values to fine-tune the shader's appearance and animation.
// -----------------------------------------------------------------------------

// === Animation Speed Control ===
// Adjust this value to control the overall speed of the animation.
// Increase for faster animation (e.g., 2.0), decrease for slower animation (e.g., 0.5).
const float animationSpeed = 0.20; // EDIT THIS VALUE. Default: 1.0 (normal speed)

// === BCS Parameters ===
// Brightness: -1.0 to 1.0 (0.0 = no change, positive brightens, negative darkens)
const float post_brightness = -0.015; // EDIT THIS VALUE. Default: no change
// Contrast: 0.0 to 2.0 (1.0 = no change, higher increases contrast, lower reduces)
const float post_contrast = 1.00;   // EDIT THIS VALUE. Default: no change
// Saturation: 0.0 to 2.0 (1.0 = no change, 0.0 = grayscale, higher increases saturation)
const float post_saturation = 1.1; // EDIT THIS VALUE. Default: no change

// === Suggested Adjustments for BCS ===
// - If the image looks washed out on your TV:
//   - post_brightness = 0.2 (slight brightening)
//   - post_contrast = 1.2 (increase contrast)
//   - post_saturation = 1.3 (boost colors)
// - If the image is too dark:
//   - post_brightness = 0.3 to 0.5 (brighten more)
// - If colors are too muted:
//   - post_saturation = 1.5 (more vibrant colors)

// === Global Rotation Control ===
// enableRotation: 1.0 to enable rotation, 0.0 to disable.
const float enableRotation = 1.0; // EDIT THIS VALUE. Default: 0.0 (disabled)
// rotationSpeed: Controls how fast the entire effect rotates around the center.
// Increase for faster rotation, decrease for slower. Can be negative for opposite direction.
const float rotationSpeed = 0.03; // EDIT THIS VALUE. Default: 0.1

// -----------------------------------------------------------------------------
// END ADJUSTABLE PARAMETERS
// -----------------------------------------------------------------------------


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

vec4 segment( float x0, float x1, vec2 uv, float id, float time, float f )
{
    float u = (uv.x - x0)/(x1 - x0);
    float v =-1.0*(id+0.5)*time+2.0*uv.y/3.141593 + f*2.0;
    float w = (x1 - x0);

    vec3 col = texture( iChannel0, vec2(u,v) ).xyz;
    col += 0.3*sin( 2.0*f + 2.0*id + vec3(0.0,1.0,2.0) );

    //col *= mix( 1.0, smoothstep(-0.95,-0.94, sin(8.0*6.2831*v + 3.0*u + 2.0*f)), smoothstep(0.4,0.5,sin(f*13.0)) );
    col *= mix( 1.0, smoothstep(-0.8,-0.7, sin(80.0*v)*sin(20.0*u) ), smoothstep(0.4,0.5,sin(f*17.0)) );

    col *= smoothstep( 0.01, 0.03, 0.5-abs(u-0.5) );

    // lighting
    col *= vec3(0.0,0.1,0.3) + w*vec3(1.1,0.7,0.4);
    col *= mix(1.0-u,1.0,w*w*w*0.45);

    float edge = 1.0-smoothstep( 0.5,0.5+0.02/w, abs(u-0.5) );
    return vec4(applyBCS(col),  edge * step(x0,x1) ); // Applied BCS to the segment color
}

const int numSamples = 6;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalize fragment coordinates to -1 to 1 range, centered
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y; // Use y for aspect ratio correction

    // Apply global rotation if enabled
    if (enableRotation > 0.5) { // Check if enableRotation is effectively true
        float angle = iTime * rotationSpeed;
        float cosA = cos(angle);
        float sinA = sin(angle);
        mat2 rotationMatrix = mat2(cosA, -sinA, sinA, cosA);
        uv = rotationMatrix * uv;
    }

    uv *= 5.0;

    vec2 st = vec2( length(uv), atan(uv.y, uv.x) );
    st = uv;  // uncomment to see the effect in cartersian coordinates

    float id = floor((st.x)/2.0);

    vec3 tot = vec3(0.0);
    for( int j=0; j<numSamples; j++ )
    {
        float h = float(j)/float(numSamples);
        // Apply animationSpeed here
        float time = iTime * animationSpeed + h*(1.0/30.0);

        // Background color: A constant medium grey: vec3(0.2)
        // This color is then slightly darkened based on the 'x' component of the screen-space coordinates (st.x).
        // It's not a traditional gradient, but rather a base color with a positional darkening effect.
        vec3 col = vec3(0.01)*(1.0-0.08*st.x);

        vec2 uvr = vec2( mod( st.x, 2.0 ) - 1.0, st.y );

        float a = uvr.y + (id+0.5) * 1.0*time + 0.2*sin(3.0*uvr.y)*sin(2.0*time);
        float r = 0.9;

        float x0 = r*sin(a);
        for(int i=0; i<5; i++ )
        {
            float f = float(i+1)/5.0;
            float x1 = r*sin(a + 6.2831*f );

            vec4 seg = segment(x0, x1, uvr, id, time, f );
            col = mix( col, seg.rgb, seg.a );

            x0 = x1;
        }
        col *= (1.6-0.1*st.x);
        tot += col;
    }

    tot = tot / float(numSamples);

    fragColor = vec4( applyBCS(tot), 1.0); // Applied BCS to the final color
}
