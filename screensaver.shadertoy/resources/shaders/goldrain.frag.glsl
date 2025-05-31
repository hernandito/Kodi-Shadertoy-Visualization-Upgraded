// === Animation Speed Control ===
const float GLOBAL_SPEED = 1.75; // 🔧 Increase this to speed up animation, decrease to slow down

// === Utility Functions ===

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float glyphShape(vec2 cellCoord, float time) {
    float t = floor(time * 0.5); // Slower time scale for glyphs
    return rand(cellCoord + t);
}

// Updated renderLayer to use GLOBAL_SPEED
vec4 renderLayer(vec2 fragCoord, float columnDivisor, float speedMultiplier, float brightnessScale) {
    vec2 resolution = iResolution.xy;
    vec2 uv = fragCoord / resolution;

    float columns = resolution.x / columnDivisor;
    float cellWidth = resolution.x / columns;
    float cellHeight = cellWidth;

    vec2 gridUV = vec2(floor(fragCoord.x / cellWidth), floor(fragCoord.y / cellHeight));

    float columnSeed = rand(vec2(gridUV.x, 0.0));
    float speed = mix(4.0, 10.0, columnSeed) * speedMultiplier;
    float timeOffset = columnSeed * 100.0;

    // 🔄 Apply global speed multiplier here
    float dropY = resolution.y - mod(iTime * GLOBAL_SPEED * speed + timeOffset, resolution.y);

    float distFromHead = fragCoord.y - dropY;

    float headHeight = mix(2.0, 5.0, rand(vec2(gridUV.x, 42.0)));
    float trailLength = mix(100.0, 500.0, rand(vec2(gridUV.x, 88.0)));

    float wrapDist = fragCoord.y + (resolution.y - dropY);
    distFromHead = (fragCoord.y >= dropY) ? distFromHead : wrapDist;

    float brightness = 0.0;
    float fade = 0.0;

    float hueShift = rand(vec2(gridUV.x, 1337.0));
    vec3 mediumBlue = vec3(0.902, 0.682, 0.106);
    vec3 yellowishOrange = vec3(0.902, 0.361, 0.106);
    vec3 dropColor = mix(mediumBlue, yellowishOrange, hueShift);

    if (distFromHead > 0.0 && distFromHead < trailLength) {
        fade = pow(1.0 - distFromHead / trailLength, 2.0);
        dropColor = mix(dropColor, vec3(1.0), fade * fade);
        brightness = fade;
    }

    if (abs(distFromHead) < headHeight) {
        float headFade = 1.0 - abs(distFromHead) / headHeight;
        dropColor = mix(dropColor, vec3(1.0), headFade);
        brightness = 1.0;
    }

    float glyph = glyphShape(gridUV, iTime * GLOBAL_SPEED); // 🔄 Global speed for glyphs too
    brightness *= mix(0.9, 1.0, glyph);

    return vec4(dropColor * brightness * brightnessScale, fade);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 finalColor = vec4(0.0);

    finalColor += renderLayer(fragCoord, 3.0, 2.0, 0.25);   // Bottom layer
    finalColor += renderLayer(fragCoord, 6.0, 1.5, 0.5);    // Second layer
    finalColor += renderLayer(fragCoord, 9.0, 1.25, 0.75);  // Third layer
    finalColor += renderLayer(fragCoord, 12.0, 1.0, 1.0);   // Top layer

    fragColor = finalColor;
}
