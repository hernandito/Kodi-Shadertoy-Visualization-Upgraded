
// Kodi/Shadertoy standard variables (implicitly defined):
// vec3 iResolution (viewport resolution)
// float iTime (shader playback time in seconds)
// sampler2D iChannel0 (texture sampler for channel 0) iTime

float inv(float n){
    return 1.0 - n;
}

// Helper function to safely retrieve point coordinates without using arrays
// This replaces the forbidden array declaration and dynamic indexing.
vec2 getPoint(int i) {
    // This is the array data:
    // vec2(0.5, 0.5), vec2(0.2, 0.3), vec2(0.8, 0.3), vec2(0.3, 0.8), 
    // vec2(1.0, 0.8), vec2(1.4, 0.3), vec2(1.5, 0.8)

    // Using if/else if is the most compatible way to handle constant data sets.
    if (i == 0) return vec2(0.5, 0.5);
    else if (i == 1) return vec2(0.2, 0.3);
    else if (i == 2) return vec2(0.8, 0.3);
    else if (i == 3) return vec2(0.3, 0.8);
    else if (i == 4) return vec2(1.0, 0.8);
    else if (i == 5) return vec2(1.4, 0.3);
    else if (i == 6) return vec2(1.5, 0.8);
    
    // Fallback for safety
    return vec2(0.0);
}

void mainImage( out vec4 o, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    // The constant literal 1280./720. must be converted to a float literal
    uv.x *= 1.77777777; // 1280.0 / 720.0 (aspect ratio correction)

    // Time varying pixel color
    vec3 col = vec3(uv.x, uv.y, 0.0); // Use 0.0 for float literal
    vec3 shad = vec3(0.0);
    
    // The loop iterates 7 times, replacing the dynamic array access.
    for(int i = 0; i < 7; i++){
      
      // Get point from the safe helper function
      vec2 pnt = getPoint(i);
      
      // The float() cast is necessary for GLSL ES 1.0 compatibility when mixing ints and floats
      pnt.xy += sin(iTime*.5 + float(i)) / 30.0;
      
      float f = 6.0;

      vec2 ans = vec2(uv - pnt) * f;
      // Using 1.0 for float literal
      ans *= max(0.0, 1.0 - distance(uv, pnt) * f);

      col.xy += ans;
      col.z += max(0.0, 1.0 - distance(uv, pnt) * f);
      
      float shadLen = 0.168;
      
      float dist = distance(uv, pnt);
      
      float mask = step(shadLen, dist);
      
      // Using 1.0 for float literal
      shad += clamp(pow(inv(dist), 9.0) / 1.0 * mask, 0.0, 1.0);
      
    }

    // Output to screen (using 'o' instead of 'fragColor')
    o = vec4(texture2D(iChannel0, col.xy).rgb, 1.0);
    
    // Use 'o' consistently for all final calculations
    o = vec4(pow(o.rgb, 0.5 - col.zzz + 0.5), 1.0);
    o -= vec4(shad, 1.0);
}
