const float PI = 3.1415926535897932384626433832795;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = 2.0 * (fragCoord/iResolution.xy) - 1.0;
    
    // Parameters the Gabor function
    float lambda = 0.15;  // wavelength
    float theta = iMouse.x / iResolution.x * PI;  // orientation
    float psi = iTime*4.5;  // phase offset
    float sigma = 0.155;  // sd of Gaussian
    float gamma = 1.0;  // spatial aspect ratio
    
    // Rotation transformation
    float xp = 2.0*uv.x * cos(theta) - uv.y * sin(theta);
    float yp = 2.0*uv.x * sin(theta) + uv.y * cos(theta);
    
    // Gabor function (ref: https://en.wikipedia.org/wiki/Gabor_filter)
    float envelope = exp(-((xp*xp) + (gamma*gamma * yp*yp)) / (2.0 * sigma * sigma));
    
    float carrier = cos(3.250 * PI * xp / lambda + psi);
    float gabor = envelope * carrier;
  
    vec3 colorModulation = vec3(0.75) + vec3(0.75) * cos(0.750 * PI* xp / lambda + vec3(0, 2, 4));  
    vec3 col = 0.0 + 1.5 * gabor * colorModulation;
    // set cutoff for patch:  any pixels outside this radius are set to a uniform gray color, removing the faint waves/lines outside the central region of the patch.)
    // /float radius = 0.2;
    //if(length(uv) > radius) {
    //    col = vec3(0.5);}    
    // Output to screen: colorful Gabor patch
    fragColor = vec4(col, 1.0);
    // or just uncomment to use this plain gabor
    //fragColor = vec4(vec3(0.5 + 0.5 * gabor), 1.0);

}