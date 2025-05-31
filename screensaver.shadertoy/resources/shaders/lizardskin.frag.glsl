#define ANIMATION_SPEED 0.30
#define GREYSCALE 0 // Set to 1 for greyscale, 0 for color
const int POINTS = 140;

void voronoi(vec2 uv, inout vec3 col)
{
    vec3 voronoi_val = vec3(0.0);
    float time = (iTime * ANIMATION_SPEED + 3000.0);
    float bestDistance = 999.0;
    float lastBestDistance = bestDistance;
    for (int i = 0; i < POINTS; i++)
    {
        float fi = float(i);
        vec2 p = vec2(mod(fi, 1.0) * 0.1 + sin(fi),
                      -0.05 + 0.15 * float(i / 10) + cos(fi + time * cos(uv.x * 0.025)));
        float d = distance(uv, p);
        if (d < bestDistance)
        {
            lastBestDistance = bestDistance;
            bestDistance = d;

            voronoi_val.x = p.x;
            voronoi_val.yz = vec2(p.x * 0.4 + p.y, p.y) * vec2(0.9, 0.87);
        }
    }
    float voronoi_mix = 0.64 + 0.29 * voronoi_val.x;
    if (GREYSCALE == 1) {
        col *= voronoi_mix;
    } else {
        col *= vec3(voronoi_mix) + 0.29 * voronoi_val.yzx; // Adjusted color mixing
    }
    col += smoothstep(0.99, 1.05, 1.0 - abs(bestDistance - lastBestDistance)) * 0.9;
    col += smoothstep(0.95, 1.05, 1.0 - abs(bestDistance - lastBestDistance)) * 0.2 * col;
    col += (voronoi_val.x) * 0.1 * smoothstep(0.5, 1.0, 1.0 - abs(bestDistance - lastBestDistance)); // Bloom based on one component
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec3 col;
    if (GREYSCALE == 1) {
        float grey = 0.5 + 0.5*cos(iTime * ANIMATION_SPEED + uv.x * 5.0 + uv.y * 3.0);
        col = vec3(grey);
    } else {
        col = 0.5 + 0.5*cos(iTime * ANIMATION_SPEED + uv.xyx+vec3(0,2,4));
    }
    voronoi(uv * 2.0 - 1.0, col);
    fragColor = vec4(col,1.0);
}