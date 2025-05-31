// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

// This shader computes the distance to the Mandelbrot Set for every pixel, and colorizes
// it accordingly.
// 
// Z -> Z²+c, Z0 = 0. 
// therefore Z' -> 2·Z·Z' + 1
//
// The Hubbard-Douady potential G(c) is G(c) = log Z/2^n
// G'(c) = Z'/Z/2^n
//
// So the distance is |G(c)|/|G'(c)| = |Z|·log|Z|/|Z'|
//
// More info here: https://iquilezles.org/articles/distancefractals

// --- Parameters ---

const float speed = 0.5583; // Overall speed of the cycle (lower is slower)
//   - Adjusted to make each cycle ~120 seconds (67.0 / 120.0 ≈ 0.5583)

const float zoomInDuration = 60.0; // Duration of zoom-in phase (seconds)
const float zoomOutDuration = 15.0; // Duration of zoom-out phase (seconds)
const float pauseDuration = 1.0; // Duration of pause at zoomed-in position (seconds)
const float easeFactor = 1.0; // Controls the steepness of the easing curve (higher = more gradual easing)

const float totalCycleDuration = zoomInDuration + pauseDuration + zoomOutDuration;

// Foreground color options
const vec3 creamColor = vec3(1.0, 0.95, 0.85); // Default cream color
const vec3 colorOption1 = vec3(0.9, 0.6, 0.3);  // Placeholder: Warm orange
const vec3 colorOption2 = vec3(0.7, 0.8, 1.0);  // Placeholder: Soft blue
const vec3 colorOption3 = vec3(0.682, 0.831, 0.718);  // Placeholder: Muted purple

// Color selection parameter (0: creamColor, 1: colorOption1, 2: colorOption2, 3: colorOption3)
const int foregroundColorChoice = 0;

// Background color and falloff options
const vec3 backgroundColor0 = vec3(0.0, 0.0, 0.0);  // Dark brown, pairs with creamColor
const float falloffEdge0 = 0.90;                     // Default falloff edge for milky effect
const vec3 backgroundColor1 = vec3(0.05, 0.05, 0.1); // Dark navy, cooler tone
const float falloffEdge1 = 0.85;                     // Slightly tighter falloff for contrast
const vec3 backgroundColor2 = vec3(0.1, 0.0, 0.05);  // Dark maroon, warm tone
const float falloffEdge2 = 0.80;                     // Tighter falloff for deeper effect
const vec3 backgroundColor3 = vec3(0.149, 0.067, 0); // Dark teal, balanced tone
const float falloffEdge3 = 0.95;                     // Wider falloff for softer transition

// Background selection parameter (0: backgroundColor0, 1: backgroundColor1, 2: backgroundColor2, 3: backgroundColor3)
const int backgroundColorChoice = 0;

// Rotation parameters
const bool rotateClockwise = false; // true for clockwise, false for counterclockwise
const float rotationPeriod = 600.0; // Time for a full 360-degree rotation (seconds, 10 minutes)

// Destination selection parameter
// 0: Ouhrificel (original), 1: Coral Plant, 2: Tensetickles, 3: Anouss Louginus
const int destinationChoice = 3;

// Destination-specific parameters
vec2 center;
float zoomedOutLevel;
float zoomedInLevel;
bool useOriginalColoring;
bool enableRotation;

// --- Color Selection Functions ---

vec3 getForegroundColor() {
    if(foregroundColorChoice == 0) return creamColor;
    else if(foregroundColorChoice == 1) return colorOption1;
    else if(foregroundColorChoice == 2) return colorOption2;
    else return colorOption3;
}

vec3 getBackgroundColor() {
    if(backgroundColorChoice == 0) return backgroundColor0;
    else if(backgroundColorChoice == 1) return backgroundColor1;
    else if(backgroundColorChoice == 2) return backgroundColor2;
    else return backgroundColor3;
}

float getFalloffEdge() {
    if(backgroundColorChoice == 0) return falloffEdge0;
    else if(backgroundColorChoice == 1) return falloffEdge1;
    else if(backgroundColorChoice == 2) return falloffEdge2;
    else return falloffEdge3;
}

// --- Destination Parameters ---

void setDestinationParameters() {
    if(destinationChoice == 0) { // Ouhrificel (original)
        center = vec2(-0.05, 0.6805);
        zoomedOutLevel = 0.003;
        zoomedInLevel = 0.0001;
        useOriginalColoring = false;
        enableRotation = true;
    } else if(destinationChoice == 1) { // Coral Plant
        center = vec2(0.36648964576699, 0.13828377882577);
        zoomedOutLevel = 0.0006800529632;
        zoomedInLevel = 0.0001; // Placeholder, adjust after preview
        useOriginalColoring = true; // Placeholder, adjust after preview
        enableRotation = true; // Placeholder, adjust after preview
    } else if(destinationChoice == 2) { // Tensetickles
        center = vec2(-0.74742557293875, -0.08293501860172);
        zoomedOutLevel = 0.0028935604; // Scaled up to avoid pixelation
        zoomedInLevel = 0.000096452013; // Adjusted to maintain zoom ratio
        useOriginalColoring = true; // Placeholder, adjust after preview
        enableRotation = true; // Placeholder, adjust after preview
    } else if(destinationChoice == 3) { // Anouss Louginus
        center = vec2(0.30681517181794, 0.03041678220566);
        zoomedOutLevel = 0.0018981084; // Scaled up to avoid pixelation
        zoomedInLevel = 0.00006327028; // Adjusted to maintain zoom ratio
        useOriginalColoring = true; // Placeholder, adjust after preview
        enableRotation = true; // Placeholder, adjust after preview
    }
}

// --- Mandelbrot Distance Function ---

float distanceToMandelbrot(in vec2 c) {
    #if 1
    {
        float c2 = dot(c, c);
        // skip computation inside M1 - https://iquilezles.org/articles/mset1bulb
        if( 256.0*c2*c2 - 96.0*c2 + 32.0*c.x - 3.0 < 0.0 ) return 0.0;
        // skip computation inside M2 - https://iquilezles.org/articles/mset2bulb
        if( 16.0*(c2 + 2.0*c.x + 1.0) - 1.0 < 0.0 ) return 0.0;
    }
    #endif

    // iterate
    float di = 1.0;
    vec2 z = vec2(0.0);
    float m2 = 0.0;
    vec2 dz = vec2(0.0);
    for(int i = 0; i < 300; i++) {
        if(m2 > 1024.0) { di = 0.0; break; }

        // Z' -> 2·Z·Z' + 1
        dz = 2.0 * vec2(z.x * dz.x - z.y * dz.y, z.x * dz.y + z.y * dz.x) + vec2(1.0, 0.0);
        
        // Z -> Z² + c
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        
        m2 = dot(z, z);
    }

    // distance
    // d(c) = |Z|·log|Z|/|Z'|
    float d = 0.5 * sqrt(dot(z, z) / dot(dz, dz)) * log(dot(z, z));
    if(di > 0.5) d = 0.0;
    
    return d;
}

// --- Main Shader ---

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Set destination-specific parameters
    setDestinationParameters();

    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // Animation timing for zoom
    float scaledTime = iTime * speed;
    float phaseTime = mod(scaledTime, totalCycleDuration);

    // Determine the current phase and compute tz (zoom factor)
    float tz;
    if(phaseTime < zoomInDuration) {
        // Zoom-in phase (single smooth motion)
        float t = phaseTime / zoomInDuration;
        tz = smoothstep(0.0, 1.0, t * easeFactor) / smoothstep(0.0, 1.0, easeFactor);
    } else if(phaseTime < zoomInDuration + pauseDuration) {
        // Pause at zoomed-in position
        tz = 1.0;
    } else {
        // Zoom-out phase (single smooth motion)
        float t = (phaseTime - (zoomInDuration + pauseDuration)) / zoomOutDuration;
        tz = 1.0 - smoothstep(0.0, 1.0, t * easeFactor) / smoothstep(0.0, 1.0, easeFactor);
    }

    // Interpolate zoom level logarithmically to ensure constant perceived speed
    float zoo = exp(mix(log(zoomedOutLevel), log(zoomedInLevel), tz));

    // Rotation: Rotate around the destination point
    float angle = enableRotation ? (iTime * 2.0 * 3.14159265359 / rotationPeriod) : 0.0;
    if(rotateClockwise) angle = -angle; // Reverse direction for clockwise rotation
    float cosA = cos(angle);
    float sinA = sin(angle);
    // Translate to origin, rotate, translate back
    vec2 translatedP = p - center;
    vec2 rotatedP = vec2(
        translatedP.x * cosA - translatedP.y * sinA,
        translatedP.x * sinA + translatedP.y * cosA
    );
    p = rotatedP + center;

    // Compute Mandelbrot coordinate with rotated position
    vec2 c = center + p * zoo;

    // Distance to Mandelbrot
    float d = distanceToMandelbrot(c);
    
    // Select coloring method based on useOriginalColoring
    if(useOriginalColoring) {
        // Original coloring (sharper, more noise)
        d = clamp(pow(4.0 * d / zoo, 0.2), 0.0, 1.0);
    } else {
        // Noise-reduced coloring (smoother, your latest tweaks)
        d = d / zoo; // Normalize distance by zoom level
        d = pow(d * 4.0, 0.25); // Exponent 0.25
        d = smoothstep(0.0, getFalloffEdge(), d); // Apply smoothstep with selected falloff edge
        d = clamp(d, 0.0, 1.0);
    }
    
    // Apply selected colors
    vec3 col = mix(getBackgroundColor(), getForegroundColor(), d);
    
    fragColor = vec4(col, 1.0);
}