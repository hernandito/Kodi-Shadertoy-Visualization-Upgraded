// Mellow riff on ZnW's Voronoi Wave, https://www.shadertoy.com/view/3lfyDB
//
const int POINTS = 16; // Point rows are determined like N / 10, from bottom to up
const float WAVE_OFFSET = 12000.0;
const float SPEED = 1.0 / 12.0;
const float COLOR_SPEED = 1.0 / 4.0;
const float BRIGHTNESS = 1.2;

void voronoi(vec2 uv, inout vec3 col)
{
    vec3 voronoi = vec3(0.0);
    float time = (iTime + WAVE_OFFSET)*SPEED; // Vary time offset to affect wave pattern
    float bestDistance = 999.0;		
    float lastBestDistance = bestDistance;	// Used for Bloom & Outline
    for (int i = 0; i < POINTS; i++)		// Is there a proper GPU implementation of voronoi out somewhere?
    {
        float fi = float(i);
        vec2 p = vec2(mod(fi, 1.0) * 0.1 + sin(fi),
                      -0.05 + 0.15 * float(i / 10) + cos(fi + time * cos(uv.x * 0.025)));
        float d = distance(uv, p);
        if (d < bestDistance)
        {
            lastBestDistance = bestDistance;
            bestDistance = d;
            
            // Two colored gradients for voronoi color variation
            voronoi.x = p.x;
            voronoi.yz = vec2(p.x * 0.4 + p.y, p.y) * vec2(0.9, 0.87);
        }
    }
    col *= 0.68 + 0.19 * voronoi;	// Mix voronoi effect and default shadertoy gradient
    col += smoothstep(0.99, 1.05, 1.0 - abs(bestDistance - lastBestDistance)) * 0.9;			// Outline
    col += smoothstep(0.95, 1.01, 1.0 - abs(bestDistance - lastBestDistance)) * 0.1 * col;		// Outline fade border
    col += (voronoi) * 0.1 * smoothstep(0.5, 1.0, 1.0 - abs(bestDistance - lastBestDistance));	// Bloom
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(iTime*COLOR_SPEED+uv.xyx+vec3(0,2,4));
    
    // Effect looks nice on this uv scaling
    voronoi(uv * 4.0 - 1.0, col); 

    // Output to screen
    fragColor = vec4(col,1.0)*BRIGHTNESS;
}