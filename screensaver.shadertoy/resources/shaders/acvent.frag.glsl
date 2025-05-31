/*
    "Corridor" by @XorDev

    https://x.com/XorDev/status/1923882930834751520
*/

// --- OpenGL ES 1.0 Compatible tanh approximation ---
vec4 tanh_approx(vec4 x) {
    // Approximation of tanh(x) = x / (1 + |x|)
    return x / (1.0 + abs(x)); // Use 1.0 for clarity
}

// --- Post-processing functions for better output control ---
vec4 saturate(vec4 color, float sat) {
    // Adjusts color saturation
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(mix(vec3(lum), color.rgb, sat), color.a);
}

vec4 applyPostProcessing(vec4 color, float brightness, float contrast, float saturation) {
    // Applies brightness, contrast, and saturation adjustments
    color.rgb = (color.rgb - 0.5) * contrast + 0.5; // Use 0.5 for clarity
    color.rgb *= brightness;
    return saturate(color, saturation);
}


// --- Post-processing Parameters ---
// Adjust these values to fine-tune the final image appearance
float brightness = 1.6; // Increase for brighter image, decrease for darker
float contrast = 1.10;   // Increase for more contrast, decrease for less
float saturation = 1.0; // Increase for more saturated colors, decrease for less
// ------------------------------------

// --- Animation Speed Parameter ---
// Adjust this value to control the speed of the effect
// Increase for faster animation, decrease for slower
float animation_speed = 0.30; // Adjust this value for animation speed
// ---------------------------------


void mainImage(out vec4 O, vec2 I)
{
    //Time for scrolling
    // Use the animation_speed parameter to control the time
    float t = iTime * animation_speed;

    //Raymarch iterator
    float i;

    //Raymarch step distance
    float d;

    //Raymarch depth
    float z = 0.0; // Initialize raymarch depth

    //Clear fragColor
    O = vec4(0.0); // Explicitly initialize output color to 0.0

    // Raymarch loop (standardized structure)
    // Raymarch 30 steps
    for(i = 0.0; i < 30.0; i += 1.0) // Converted to standard for loop
    {
        //Compute ray direction
        vec3 r = normalize(vec3(I+I,0.0)-iResolution.xyy); // Use 0.0 for clarity

        //Raymarch sample position
        vec3 p = z*r;

        //Raytraced wall coordinates
        vec3 w = abs(r);

        //Compute distance to walls
        w /= max(w.x,w.y);

        //Scroll forward
        w.z += t;
        p.z -= t;

        //Shift camera
        vec3 r_shifted = ++p; // Store the shifted p in a temporary variable

        //Step forward
        // Calculate step distance 'd' first
        d = length(
            //Reflected coordinates
            (p.xy=abs(mod(p.xy-2.0,4.0)-2.0))-1.0 // Use 2.0, 4.0, 1.0 for clarity
            //Line position
            +cos(p.z/vec2(3.1,2.0))) + // Use 2.0 for clarity
            //Reflection fall off
            0.1 * length(p-r_shifted) * // Use 0.1 for clarity and the shifted variable
            //Reflectivity blocks
            exp(dot(cos(ceil(w/0.3)),sin(w/0.6).yzx)); // Use 0.3, 0.6 for clarity

        // Accumulate raymarch depth
        z += d; // Accumulate depth after calculating step distance

        //Add coloring
        // Scale down the color accumulation to prevent overexposure
        // Further decreased scaling factor to significantly increase brightness
        O.rgb += (cos(p)+1.4) / (d * z * 5.0); // Decreased scaling factor from 20.0 to 5.0

        // Optional: Add a break condition if ray goes too far
        // if (z > 100.0) break; // Example break condition
    }

    //Tanh tonemapping
    // Replaced tanh with tanh_approx and adjusted the divisor
    // Further decreased divisor for tanh_approx to make tone mapping much less aggressive (much brighter)
    O = tanh_approx(O/10.0); // Decreased divisor from 50.0 to 10.0

    // --- Apply Post-processing ---
    O = applyPostProcessing(O, brightness, contrast, saturation);
    // -----------------------------

    // Final clamp to ensure valid output range
    O = clamp(O, 0.0, 1.0); // Use 0.0, 1.0 for clarity
}
