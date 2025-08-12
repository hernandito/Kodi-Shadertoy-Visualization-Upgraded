// CC0: Simpler planemarcher
// A technique I used in the past is "marching through planes". I like it.
// This version is a simplified version of my previous "framework"

// Maybe it's of use to someone

// renderPlane is the function that renders each plane, so tinkering with that
// is a good starting point

// Robust approximation for tanh(x) to avoid issues on OpenGL ES 1.0.
// This prevents division by zero if x is very small.
vec4 tanh_approx(vec4 x) {
    const float EPSILON = 1e-6; // A small constant to prevent division by zero
    return x / (1.0 + max(abs(x), EPSILON));
}

//---------------------------------------------------------------------------------------------------------------------
// Post-processing parameters for Brightness, Contrast, and Saturation (BCS)
// Adjust these values to modify the final look of the scene.
//---------------------------------------------------------------------------------------------------------------------
#define BRIGHTNESS_ADJUSTMENT 0.0 // Additive brightness adjustment (-1.0 to 1.0, 0.0 is no change)
#define CONTRAST_ADJUSTMENT   1.001 // Multiplicative contrast adjustment (0.0 for no contrast, 1.0 for original, >1.0 for more)
#define SATURATION_ADJUSTMENT 1.0 // Multiplicative saturation adjustment (0.0 for grayscale, 1.0 for original, >1.0 for more)

// Constants for the shader
const float
    // Number of planes to render in the scene
    numberOfPlanes = 12.
    // Amplitude of the sinusoidal path
    , pathAmplitude = 3.5
    ;
const vec2
    // Frequency of the sinusoidal path, higher value means more oscillations
    pathFrequency = vec2(1,sqrt(.5))/6.
    ;

//---------------------------------------------------------------------------------------------------------------------
// Utility Functions
//---------------------------------------------------------------------------------------------------------------------

// Calculates a point on the sinusoidal path based on a distance 'z' along the path
vec3 calculatePathPosition(float z) {
    // The XY coordinates are a sine wave, the Z coordinate is the distance along the path
    return vec3(pathAmplitude*sin(pathFrequency*z),z);
}

// Calculates the tangent vector of the path, which indicates the direction of travel
vec3 calculatePathTangent(float z) {
    // This is the first derivative of the path position function
    return vec3(pathAmplitude*pathFrequency*cos(pathFrequency*z),1);
}

// Calculates the curvature of the path. Used to determine the plane's rotation.
vec3 calculatePathCurvature(float z) {
    // This is the second derivative of the path position function
    return vec3(-pathAmplitude*pathFrequency*pathFrequency*sin(pathFrequency*z),0);
}

// Blends two layers (colors with alpha) together, with 'front' on top of 'back'
vec4 blendLayers(vec4 back, vec4 front) {
    // Based on: https://en.wikipedia.org/wiki/Alpha_compositing
    float alpha  = front.w + back.w*(1.-front.w);
    // Ensure robust division by alpha
    vec3  color  = (front.xyz*front.w + back.xyz*back.w*(1.0-front.w))/max(alpha, 1E-6);
    return alpha > 0. ? vec4(color, alpha) : vec4(0);
}

// Calculates a custom distance metric for a superellipse shape
// This is not a standard length, but a specialized distance function for a specific shape
float calculateSuperellipseDistance(vec2 p) {
    return pow(dot(p*=p,p),.25);
}

// Creates a 2D rotation matrix for a given angle
mat2 rotate2D(float angle) {
    float c=cos(angle),s=sin(angle);
    return mat2(c,s,-s,c);
}

// Renders a single plane and returns its color and alpha
vec4 renderPlane(vec3 intersectionPoint) {
    // Calculate the distance from the center of the plane to the intersection point
    float
        dist      = calculateSuperellipseDistance(intersectionPoint.xy*rotate2D(-2.*calculatePathCurvature(intersectionPoint.z).x))-.25
    // Calculate the anti-aliasing amount based on the screen-space width of a pixel
    , antiAlias = length(fwidth(intersectionPoint.xy))
    ;
    // Ensure robust division within the glow calculation
    float glow = 0.001 / max(pow(dot(intersectionPoint.xy,intersectionPoint.xy),2.), 1E-6);
    return vec4(
        // Mixes between a glow color (for the center) and a solid color (for the plane body)
        vec3(mix(glow, 2., smoothstep(antiAlias, -antiAlias, dist - 0.01)))
    // The alpha of the plane is determined by the distance and anti-aliasing
    , smoothstep(antiAlias,-antiAlias,-dist)
    );
}

//---------------------------------------------------------------------------------------------------------------------
// Main Shader Entry Point
//---------------------------------------------------------------------------------------------------------------------

void mainImage(out vec4 outputColor, vec2 fragmentCoordinates) {
    // Explicitly initialize variables
    float beatsPerMinute = 114.0;
    float totalTime = iTime * 0.2 * beatsPerMinute / 60.0;
    float fractionalTime = fract(totalTime);
    float beatTime = floor(totalTime) + fractionalTime;
    float pathPos = beatTime * 0.5;

    vec2 resolution = iResolution.xy;
    vec2 pixelCoordinates = (2.0 * fragmentCoordinates - resolution) / resolution.y;

    vec3 cameraPosition = calculatePathPosition(pathPos);
    vec3 cameraDirection = normalize(calculatePathPosition(pathPos + numberOfPlanes) - cameraPosition);
    vec3 pathTangent = normalize(calculatePathTangent(pathPos));
    vec3 pathRight = normalize(cross(vec3(0.0, 1.0, 0.0) - calculatePathCurvature(pathPos), pathTangent));
    vec3 pathUp = cross(pathTangent, pathRight);
    vec3 rayDirection = normalize(pixelCoordinates.x * pathRight + pixelCoordinates.y * pathUp + 2.0 * pathTangent);
    vec3 intersectionPoint = vec3(0.0); // Explicitly initialized

    vec4 planeColor = vec4(0.0); // Explicitly initialized

    // Initialize the raymarching 'z' value to start from the current camera position
    // Ensure robust division by rayDirection.z
    pathPos = fract(-pathPos) / max(rayDirection.z, 1E-6);
    outputColor = vec4(0.0); // Explicitly initialized

    // Loop through each plane to render it using alpha blending
    for(
        float planeIndex = 0.0
        ; planeIndex < numberOfPlanes
        ; ++planeIndex
    ) {
        intersectionPoint = cameraPosition + pathPos * rayDirection;
        // Offset the intersection point to center it on the path's curve
        intersectionPoint.xy -= calculatePathPosition(intersectionPoint.z).xy;
        planeColor = renderPlane(intersectionPoint);
        // Fade the planes in as they get closer to the camera
        planeColor.w *= smoothstep(numberOfPlanes, numberOfPlanes - 4.0, pathPos);
        // Blend the current plane with the accumulated scene
        outputColor = blendLayers(planeColor, outputColor);
        // Advance the ray to the next plane
        // Ensure robust division by rayDirection.z
        pathPos += 1.0 / max(rayDirection.z, 1E-6);
    }

    // Add a final beating glow effect to the scene (commented out in original)
    // planeColor  = vec4(vec3(4e-3*sqrt(1.-fractionalTime)/(1.001-dot(rayDirection,cameraDirection))),1);
    // outputColor = blendLayers(planeColor,outputColor);

    // Final color processing
    // Pre-multiply alpha
    outputColor.xyz *= outputColor.w;

    // Apply Brightness, Contrast, and Saturation adjustments
    // Brightness: Simple additive adjustment
    outputColor.xyz += BRIGHTNESS_ADJUSTMENT;

    // Contrast: Adjusts values around a midpoint (0.5 for normalized RGB)
    outputColor.xyz = (outputColor.xyz - 0.5) * CONTRAST_ADJUSTMENT + 0.5;

    // Saturation: Blend between grayscale and original color
    float luminance = dot(outputColor.xyz, vec3(0.2126, 0.7152, 0.0722)); // Standard luminance coefficients
    vec3 grayscale = vec3(luminance);
    outputColor.xyz = mix(grayscale, outputColor.xyz, SATURATION_ADJUSTMENT);

    // Tone mapping and color grading - using tanh_approx
    outputColor = sqrt(tanh_approx(outputColor));
}
