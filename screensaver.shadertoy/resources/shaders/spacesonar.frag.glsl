float lineSDF(vec2 uv, vec2 pointA, vec2 pointB) {
    vec2 pa = uv - pointA;
    vec2 ba = pointB - pointA;
    
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    return length(pa - h * ba);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalized pixel coordinates (from -0.5 to 0.5)
    vec2 uv = fragCoord / iResolution.xy - 0.5;
    uv.x *= iResolution.x / iResolution.y;
    
    // colors
    vec3 black = vec3(0.);
    vec3 white = vec3(1.);
    vec3 blue = vec3(0.65, 0.85, 1.0);
    vec3 orange = vec3(0.9, 0.6, 0.3);
    vec3 magenta = vec3(0.9, 0.0, 1.0);
    vec3 yellow = vec3(1.0, 1.0, 0.0);
    
    // === Animate the white bar up and down ===
    float speed = 0.25; // adjust speed here
    float amplitude = 0.3; // how high it moves up/down
    
    float offsetY = sin(iTime * speed) * amplitude;
    
    // === Move the center of the white bar to the left edge ===
    // The original length of the white bar is 0.6 units (from -0.3 to 0.3)
    // To align the center with the left edge, we move the bar to -0.3
    vec2 pointA = vec2(-1.0, offsetY);  // Move the center to the left edge
    vec2 pointB = vec2(-0.6, offsetY);  // Keep the same length (0.6 units)

    vec3 col = vec3(0.);
    
    float distanceToLine = lineSDF(uv, pointA, pointB);
    
    col = distanceToLine < 0. ? blue : orange;
    
    // adding waves
    float waveSpeed = 6.0;
    float waveSize = 400.0;
    col = col * 0.8 + col * 0.2 * sin(distanceToLine * waveSize - waveSpeed * iTime);
    
    // adding light
    float lineSize = 7.0; // control the width of the white bar and glow
    col = mix(white, col, lineSize * abs(distanceToLine));
    
    // Output to screen
    fragColor = vec4(col, 1.0);
}
