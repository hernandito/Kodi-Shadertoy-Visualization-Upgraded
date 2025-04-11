/**
	Parallax Stars
	shader by @hugoaboud
	
	License: GPL-3.0
**/

/**
	Properties
**/

// Background Gradient
vec4 _TopColor = vec4(0,0,0,1);
vec4 _BottomColor = vec4(0.,0.,0,1);

// Star colors
vec4 _Star1Color = vec4(1,0.94,0.72,0.7);
vec4 _Star2Color = vec4(0.18,0.03,0.41,0.7);
vec4 _Star3Color = vec4(0.63,0.50,0.81,0.7);

// Star grid
float _Grid = 30.0;
float _Size = 0.15;

// Parallax Speed
vec2 _Speed = vec2(0, 3);

/**
	Utilities
**/

// Generates a random 2D vector from another 2D vector
// seed must be a large number
// output range: ([0..1[,[0..1[)
vec2 randVector(in vec2 vec, in float seed)
{
    return vec2(fract(sin(vec.x*999.9+vec.y)*seed),fract(sin(vec.y*999.9+vec.x)*seed));
}

/**
	Star shader
**/

// Draw star grid
void drawStars(inout vec4 fragColor, in vec4 color, in vec2 uv, in float grid, in float size, in vec2 speed, in float seed)
{
    uv += iTime * speed;
    
    // Split UV into local grid
    vec2 local = mod(uv,grid)/grid;
    
    // Random vector for each grid cell
    vec2 randv = randVector(floor(uv/grid), seed)-0.5;
    float len = length(randv);
    
    // If center + random vector lies inside cell
    // Draw circle
    if (len < 0.5) {
        // Draw circle on local grid
        float radius = 1.0-distance(local, vec2(0.5,0.5)+randv)/(size*(0.5-len));
        if (radius > 0.0) fragColor += color*radius;
    }
}

/**
	Main frag shader
**/

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{    
    // Background
    fragColor = mix(_TopColor, _BottomColor, fragCoord.y/iResolution.y);
    
    // Stars
    drawStars(fragColor, _Star1Color, fragCoord, _Grid, _Size, _Speed, 123456.789);
   	drawStars(fragColor, _Star2Color, fragCoord, _Grid*2.0/3.0, _Size, _Speed/1.2, 345678.912);
    drawStars(fragColor, _Star3Color, fragCoord, _Grid/2.0, _Size*3.0/4.0, _Speed/1.6, 567891.234);
}