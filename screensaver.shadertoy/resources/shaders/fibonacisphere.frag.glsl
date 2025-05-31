// The MIT License
// Copyright © 2015 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// --- User Adjustable Parameters ---

// Palette Selection: Choose the color palette (1 to 5)
// 1: Red (default colors, no change)
// 2: Green (hue shift +67 degrees)
// 3: Blue (hue shift -150 degrees)
// 4: Tan (hue shift +31 degrees)
// 5: Greyscale (saturation set to 0)
#define PALETTE 2

// ZOOM_FACTOR: Adjust this value to change the apparent distance from the sphere.
// A higher value (e.g., 2.0, 3.0) will "zoom out", making the sphere appear smaller and further away.
// A value of 1.0 is the original view.
#define ZOOM_FACTOR 0.6

// SPHERE_ANIMATION_SPEED: Controls the speed of the sphere's surface pattern animation.
// A smaller value (e.g., 0.5) will make the animation cycle slower, increasing its duration.
// Default is 1.0.
#define SPHERE_ANIMATION_SPEED 0.25

// SPHERE_ANIMATION_TRANSITION_RANGE: Controls the width of the smoothstep transition for the sphere's surface pattern.
// A larger value (e.g., 0.5) will make the transition smoother and longer.
// Default is 0.2 (matching the original -0.1 to 0.1 range).
#define SPHERE_ANIMATION_TRANSITION_RANGE -0.15

// SPHERE_ROTATION_SPEED: Controls the speed at which the camera orbits the sphere,
// giving the illusion of the sphere rotating.
// A smaller value (e.g., 0.1) will slow down the rotation.
// The original speed was 0.5.
#define SPHERE_ROTATION_SPEED 0.3

// AO_STRENGTH: Controls the strength/darkness of the ambient occlusion (AO) shadow.
// A value of 1.0 maintains the default strength.
// Values greater than 1.0 will make shadows darker.
// Values less than 1.0 (but greater than 0.0) will make shadows lighter.
#define AO_STRENGTH 1.075

// --- Helper Functions for Hue/Saturation Adjustments ---

// RGB to HSV conversion
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Hue shift function (hue in degrees, -180 to 180)
vec3 shiftHue(vec3 col, float hueDegrees) {
    vec3 hsv = rgb2hsv(col);
    hsv.x += hueDegrees / 360.0; // Convert degrees to [0,1] range
    hsv.x = fract(hsv.x); // Wrap hue around
    return hsv2rgb(hsv);
}

// Spherical Fibonnacci points, as described by Benjamin Keinert, Matthias Innmann,
// Michael Sanger and Marc Stamminger in their paper
// https://dl.acm.org/doi/10.1145/2816795.2818131

// Manual round function for Kodi
float manualRound(float x) {
    return floor(x + 0.5);
}

vec2 inverseSF(vec3 p) {
    const float kTau = 6.28318530718;
    const float kPhi = (1.0+sqrt(5.0))/2.0;
    const float kNum = 150.0;

    float k = max(2.0, floor(log2(kNum*kTau*0.5*sqrt(5.0)*(1.0-p.z*p.z))/log2(kPhi+1.0)));
    float Fk = pow(kPhi, k)/sqrt(5.0);
    vec2 F = vec2(manualRound(Fk), manualRound(Fk*kPhi)); // |Fk|, |Fk+1|

    vec2 ka = 2.0*F/kNum;
    vec2 kb = kTau*(fract((F+1.0)*kPhi)-(kPhi-1.0));

    mat2 iB = mat2(ka.y, -ka.x, kb.y, -kb.x) / (ka.y*kb.x - ka.x*kb.y);
    vec2 c = floor(iB*vec2(atan(p.y,p.x),p.z-1.0+1.0/kNum));

    float d = 8.0;
    float j = 0.0;
    for(int s=0; s<4; s++) {
        vec2 uv = vec2(float(int(s) - (int(s) / 2) * 2), float(int(s) / 2));
        float id = clamp(dot(F, uv+c), 0.0, kNum-1.0); // all quantities are integers

        float phi = kTau*fract(id*kPhi);
        float cosTheta = 1.0 - (2.0*id+1.0)/kNum;
        float sinTheta = sqrt(1.0-cosTheta*cosTheta);

        vec3 q = vec3(cos(phi)*sinTheta, sin(phi)*sinTheta, cosTheta);
        float tmp = dot(q-p, q-p);
        if(tmp < d) {
            d = tmp;
            j = id;
        }
    }
    return vec2(j, sqrt(d));
}

// iq code starts here

float hash1(float n) { return fract(sin(n)*158.5453123); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Apply ZOOM_FACTOR here to scale the normalized fragment coordinates.
    // Dividing by ZOOM_FACTOR effectively "zooms out".
    vec2 p = (-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y / ZOOM_FACTOR;

    // Camera movement
    // Now using SPHERE_ROTATION_SPEED to control the camera's orbital speed
    float an = SPHERE_ROTATION_SPEED * iTime;
    vec3 ro = vec3(2.5*cos(an), 1.0, 2.5*sin(an));
    vec3 ta = vec3(0.0, 1.0, 0.0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0,1.0,0.0)));
    vec3 vv = normalize(cross(uu, ww));
    vec3 rd = normalize(p.x*uu + p.y*vv + 1.5*ww); // rd now uses the zoomed 'p'

    // Sphere center (original, unscaled values)
    vec3 sc = vec3(0.0, 1.0, 0.0);

    vec3 col = vec3(1.0);

    // Raytrace
    float tmin = 10000.0;
    vec3 nor = vec3(0.0);
    float occ = 1.0;
    vec3 pos = vec3(0.0);

    // Raytrace-plane (original AO calculation)
    float h = (0.0-ro.y)/rd.y;
    if(h > 0.0) {
        tmin = h;
        nor = vec3(0.0, 1.0, 0.0);
        pos = ro + h*rd;
        vec3 di = sc - pos;
        float l = length(di);
        // Reverted to original AO calculation as scene elements are no longer scaled
        occ = 1.0 - dot(nor, di/l)*1.0*1.0/(l*l);
        col = vec3(1.0);
    }

    // Raytrace-sphere (original radius)
    vec3 ce = ro - sc;
    float b = dot(rd, ce);
    // Reverted to original sphere radius of 1.0
    float c = dot(ce, ce) - 1.0;
    h = b*b - c;
    if(h > 0.0) {
        h = -b - sqrt(h);
        if(h < tmin) {
            tmin = h;
            nor = normalize(ro + h*rd - sc);
            occ = 0.5 + 0.5*nor.y;
        }

        vec2 fi = inverseSF(nor);
        col = 0.5 + 0.5*sin(hash1(fi.x*13.0)*3.0 + 1.0 + vec3(0.0, 1.0, 1.0));
        col *= smoothstep(0.02, 0.03, fi.y);

        // Calculate the animation value based on SPHERE_ANIMATION_SPEED
        float animValue = sin(iTime * SPHERE_ANIMATION_SPEED);
        // Apply the smoothstep transition using SPHERE_ANIMATION_TRANSITION_RANGE
        float transition = smoothstep(-SPHERE_ANIMATION_TRANSITION_RANGE / 2.0, SPHERE_ANIMATION_TRANSITION_RANGE / 2.0, animValue);

        col *= mix(1.0, 1.0 - smoothstep(0.12, 0.125, fi.y), transition);
        col *= 1.0 + 0.1*sin(250.0*fi.y);
        col *= 1.5;
    }

    // Apply AO_STRENGTH to the calculated ambient occlusion
    // This clamps the final 'occ' value between 0.0 and 1.0 to prevent artifacts.
    occ = clamp(1.0 - (1.0 - occ) * AO_STRENGTH, 0.0, 1.0);

    if(tmin < 100.0) {
        pos = ro + tmin*rd;
        col *= occ; // Apply the adjusted ambient occlusion
        col = mix(col, vec3(1.0), 1.0-exp(-0.003*tmin*tmin));
    }

    col = sqrt(col);

    // --- Apply Color Palette Adjustments in Postprocessing ---
    #if PALETTE == 1
        // Palette 1: Red (default, no change)
        col = col;
    #elif PALETTE == 2
        // Palette 2: Green (hue shift +67 degrees)
        col = shiftHue(col, 67.0);
    #elif PALETTE == 3
        // Palette 3: Blue (hue shift -150 degrees)
        col = shiftHue(col, -150.0);
    #elif PALETTE == 4
        // Palette 4: Tan (hue shift +31 degrees)
        col = shiftHue(col, 31.0);
    #elif PALETTE == 5
        // Palette 5: Greyscale (saturation set to 0)
        vec3 hsv = rgb2hsv(col);
        hsv.y = 0.0; // Set saturation to 0
        col = hsv2rgb(hsv);
    #else
        // Default to Palette 1 if PALETTE is not set correctly
        col = col;
    #endif

    fragColor = vec4(col, 1.0);
}