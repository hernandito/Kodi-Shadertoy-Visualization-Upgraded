// --- GLSL Version and Precision Directives for Kodi Compatibility (GLSL ES 1.0) ---
precision highp float;
precision highp int;
precision lowp sampler2D;

// Define a small epsilon for numerical stability in divisions.
const float EPSILON = 1e-6; // 0.000001

// The Robust Tanh Conversion Method: tanh_approx function
// Ensures numerical stability for tanh, especially near zero.
// Expects a vec4 input for consistency with common use cases, takes .x for scalar results.
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

#define T iTime // Using iTime as per user preference for web animation
#define PI 3.141596
#define S smoothstep

// Helper function for standard 2D rotation matrix.
// Fixes the non-standard `rot` macro from the original code.
mat2 rotate(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

// Helper function for 3D rotation around Y-axis.
// Moved from a macro to a proper function definition to ensure correct usage.
vec3 rotY(vec3 v, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec3(c * v.x + s * v.z, v.y, -s * v.x + c * v.z);
}

// https://iquilezles.org/articles/distfunctions/
float sdBoxFrame( vec3 p, vec3 b, float e )
{
    p = abs(p) - b;
    vec3 q = abs(p + e) - e;
    return min(min(
        length(max(vec3(p.x,q.y,q.z),0.0)) + min(max(p.x,max(q.y,q.z)),0.0),
        length(max(vec3(q.x,p.y,q.z),0.0)) + min(max(q.x,max(p.y,q.z)),0.0)),
        length(max(vec3(q.x,q.y,p.z),0.0)) + min(max(q.x,max(q.y,p.z)),0.0));
}
// https://iquilezles.org/articles/distfunctions/
float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    float d = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
    return abs(d) + 0.1;
}

// Helper macros (from original shader) - ensured float literals and robustness.
#define smin(d1, d2, k) (mix(d2, d1, clamp(0.5 + 0.5 * ((d2) - (d1)) / max((k), EPSILON), 0.0, 1.0)) - (k) * clamp(0.5 + 0.5 * ((d2) - (d1)) / max((k), EPSILON), 0.0, 1.0) * (1.0 - clamp(0.5 + 0.5 * ((d2) - (d1)) / max((k), EPSILON), 0.0, 1.0)))
#define ssub(d1, d2, k) (mix(d2, -(d1), clamp(0.5 - 0.5 * ((d2) + (d1)) / max((k), EPSILON), 0.0, 1.0)) + (k) * clamp(0.5 - 0.5 * ((d2) + (d1)) / max((k), EPSILON), 0.0, 1.0) * (1.0 - clamp(0.5 - 0.5 * ((d2) + (d1)) / max((k), EPSILON), 0.0, 1.0)))
#define sphereSDF(spherePos, radius, rayPos) (length((spherePos) - (rayPos)) - (radius))
#define planeSDF(planeHeight, rayPos) ((rayPos).y - (planeHeight))
#define saturate(x) clamp((x), 0.0, 1.0)
#define remap(v, inMin, inMax, outMin, outMax) (((v) - (inMin)) / ((inMax) - (inMin) + EPSILON) * ((outMax) - (outMin)) + (outMin)) // Added EPSILON
#define repeatRay(p, cellSize) (mod((p) + 0.5 * (cellSize), (cellSize)) - 0.5 * (cellSize))
#define cellIndex(pos, size) (floor(((pos) + 0.5 * (size)) / (size)))


// Structs (explicitly initialized in functions).
struct RayResult {
    vec3 position;
    vec3 normal;
    float depth;
    float shadow;
    int stepCount;
    bool isSurface;
};

struct ColorResult {
    RayResult ray;
    vec3 color;
};

// --- CAMERA AND LIGHT SETTINGS ---
const float FOV = 90.0; // Fixed: FOV was undeclared. Defined as const float.
// CAMERA_POSITION now a function due to dynamic nature (iTime, iMouse).
vec3 getCameraPosition(float time, vec2 mouse) {
    // Replaced tanh() with tanh_approx() and ensured vec4 conversion for float input.
    return rotY(vec3(-5.0, 3.0 + sin(time) * 0.2, 2.0 + cos(time) * 0.2), (mouse.x / iResolution.x) * 6.2831853 + time * 0.1);
}
// CAMERA_FORWARD is dynamically calculated in getCameraRayDirection or mainImage.

const vec3 SUN_DIRECTION = normalize(vec3(1.0, -1.0, 1.0)); // Constant as it's a fixed direction.
const float SUN_OPACITY = 0.5;

// --- RAY SETTINGS (Converted to constants) ---
const float RENDER_DISTANCE = 50.0;
const int MAX_STEPS = 200;
const float MIN_HIT_DISTANCE = 0.01;
const float SMOOTHING = 3.0; // Unused in this shader, but kept for completeness.
const int REFLECTION_DEPTH = 2;
const float REFLECTION_OPACITY = 0.0;
const int ANTI_ALIASING = 1;


// Main SDF function for the scene.
float sceneSDF(vec3 position){
    vec3 tiling = vec3(4.0, 0.0, 4.0); // Ensure float literals.
    vec3 cell = cellIndex(position, tiling);
    // Explicitly initialized 0.0 for sphereSDF.
    return smin(
        sphereSDF(vec3(0.0, 0.5 + sin(cell.x + T), 0.0), 1.0, repeatRay(position, tiling)),
        planeSDF(0.0, position),
        1.0 // Ensure float literal.
    );
}

vec3 getCameraRayDirection(vec2 uv, vec3 camera_forward_vector) {
    float aspect = iResolution.x / iResolution.y; // Explicitly initialize aspect.
    float halfFOV = radians(FOV) / 2.0; // Explicitly initialize halfFOV.
    
    vec2 screenCoord = uv * 2.0 - 1.0; // Explicitly initialize screenCoord, float literals.
    screenCoord.x *= aspect;
    
    vec2 offsets = screenCoord * tan(halfFOV); // Explicitly initialize offsets.
    
    vec3 rayRight = cross(camera_forward_vector, vec3(0.0, 1.0, 0.0)); // Explicitly initialize rayRight, float literals.
    vec3 rayUp = cross(rayRight, camera_forward_vector); // Explicitly initialize rayUp.
    
    return normalize(camera_forward_vector + rayRight * offsets.x + rayUp * offsets.y);
}

vec3 getNormal(vec3 p) {
    float eps = 0.001; // Explicitly initialized.
    vec2 h = vec2(eps, 0.0); // Explicitly initialized, float literal.
    return normalize(vec3(
        sceneSDF(p + h.xyy) - sceneSDF(p - h.xyy),
        sceneSDF(p + h.yxy) - sceneSDF(p - h.yxy),
        sceneSDF(p + h.yyx) - sceneSDF(p - h.yyx)
    ));
}

RayResult raymarch(vec3 startPosition, vec3 direction){
    RayResult result;
    // Explicitly initialize all members of RayResult struct.
    result.position = startPosition;
    result.normal = vec3(0.0); // Default normal
    result.depth = 0.0;
    result.shadow = 1000.0;
    result.stepCount = 0;
    result.isSurface = false;

    for(result.stepCount = 0; result.stepCount < MAX_STEPS; result.stepCount++){
        float distanceToSurface = sceneSDF(result.position); // Explicitly initialized.
        result.depth += distanceToSurface;
        result.position = startPosition + direction * result.depth;
        // Ensure division robustness.
        result.shadow = min(result.shadow, 8.0 * distanceToSurface / max(result.depth, EPSILON)); // float literal
        result.isSurface = distanceToSurface < MIN_HIT_DISTANCE;
        if(result.isSurface) {
            result.normal = getNormal(result.position);
        }
        if(result.isSurface || result.depth > RENDER_DISTANCE) {
            break;
        }
    }
    return result;
}

ColorResult getColor(vec3 position, vec3 direction){
    ColorResult colorResult;
    // Explicitly initialize struct members.
    colorResult.ray = raymarch(position, direction);
    colorResult.color = vec3(0.851, 0.82, 0.667); // Default color.
    
    //Shadow Calculation
    if(colorResult.ray.isSurface){
        // Ensure explicit initialization of sunResult members.
        RayResult sunResult;
        sunResult.position = colorResult.ray.position; // Base for shadow ray
        sunResult.normal = vec3(0.0);
        sunResult.depth = 0.0;
        sunResult.shadow = 1000.0;
        sunResult.stepCount = 0;
        sunResult.isSurface = false;

        // Perform shadow raymarch.
        sunResult = raymarch(colorResult.ray.position - SUN_DIRECTION * (RENDER_DISTANCE - 2.0), SUN_DIRECTION);
        
        //Hard Shadow
        // Explicit float literals, ensure robustness.
        float shadowMask = 1.0 - saturate(length(sunResult.position - colorResult.ray.position));
        
        //Soft Shadows (commented out in original, kept as is)
        //shadowMask *= sunResult.shadow;
        
        //Sun Opacity
        // Explicit float literals.
        colorResult.color *= remap(shadowMask, 0.0, 1.0, SUN_OPACITY, 1.0);
        
        //Sun Reflections (commented out in original, kept as is)
        //colorResult.color += pow(saturate(-dot(SUN_DIRECTION, colorResult.ray.normal)), 100.0);
    }
    
    //Camera Fresnel
    // Explicit float literals.
    colorResult.color *= pow(saturate(-dot(direction, colorResult.ray.normal)), saturate(colorResult.ray.depth * 0.005));
    
    //Fog
    // Explicit float literals, ensure robustness.
    float fog = pow(colorResult.ray.depth / max(RENDER_DISTANCE, EPSILON), 1.0);
    colorResult.color = saturate(mix(colorResult.color, vec3(0.42, 0.682, 0.788), fog)); // float literal
    
    return colorResult;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Explicitly initialize inputCameraPosition.
    vec3 inputCameraPosition = getCameraPosition(T, iMouse.xy); // Use getCameraPosition function.
    fragColor = vec4(0.0); // Explicitly initialize output color.

    // Calculate CAMERA_FORWARD here as it depends on inputCameraPosition.
    vec3 cameraForward = normalize(-inputCameraPosition);

    // Anti-aliasing loops.
    for(int x = 0; x < ANTI_ALIASING; x++){ // Explicitly initialized loop variable.
        for(int y = 0; y < ANTI_ALIASING; y++){ // Explicitly initialized loop variable.
            // Explicitly initialize uv, float literals, robustness.
            vec2 uv = fragCoord / iResolution.xy + vec2(x,y) / float(ANTI_ALIASING) / 1000.0;
            // Get camera ray direction.
            vec3 cameraDirection = getCameraRayDirection(uv, cameraForward); // Pass cameraForward.
            vec4 baseColor = vec4(1.0); // Explicitly initialize.

            // Primary Color and Reflection Loop.
            vec3 currentCameraPosition = inputCameraPosition; // Explicitly initialize.
            vec3 currentCameraDirection = cameraDirection; // Explicitly initialize.

            for(int reflection_i = 0; reflection_i < REFLECTION_DEPTH; reflection_i++) { // Renamed loop variable.
                // Use currentCameraPosition and currentCameraDirection for reflections.
                ColorResult result = getColor(currentCameraPosition, currentCameraDirection);
                // Explicit float literals for mix weights.
                baseColor = vec4(mix(baseColor.xyz, result.color, reflection_i == 0 ? 1.0 : REFLECTION_OPACITY), 1.0);
                currentCameraPosition = result.ray.position;
                currentCameraDirection = result.ray.normal; // Normal is the new direction for reflection.
            }
            fragColor += baseColor;
        }
    }
    // Final division for anti-aliasing.
    fragColor /= float(ANTI_ALIASING * ANTI_ALIASING);
}
