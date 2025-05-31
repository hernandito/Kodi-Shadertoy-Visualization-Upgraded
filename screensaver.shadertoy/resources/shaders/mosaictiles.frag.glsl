// v1.2


#define t iTime*2.

#define SIZE 30.


#define col1 vec3(193.,41.,46.)/255.

#define col2 vec3(241.,211.,2.)/255.


// NEW PARAMETERS FOR BOUNDARY LINES

// Thickness of the boundary line. Smaller values make thinner lines.

#define LINE_THICKNESS 0.085 // Adjust this value (e.g., 0.001 for very thin, 0.01 for thicker)

// Color of the boundary line.

#define LINE_COLOR vec3(0.0, 0.0, 0.0) // Black color for the line


vec2 ran(vec2 uv) {

    uv *= vec2(dot(uv,vec2(127.1,311.7)),dot(uv,vec2(227.1,521.7)) );

    return 1.0-fract(tan(cos(uv)*123.6)*3533.3)*fract(tan(cos(uv)*123.6)*3533.3);

}


vec2 pt(vec2 id) {

    return sin(t*(ran(id+.5)-0.5)+ran(id-20.1)*8.0)*0.5;

}



void mainImage( out vec4 fragColor, in vec2 fragCoord )

{

    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.x;

    vec2 off = iTime/vec2(50.,30.);

    uv += off;

    uv *= SIZE;

    

    vec2 gv = fract(uv)-.5;

    vec2 id = floor(uv);

    

    float mindist = 1e9;        // Distance to the closest point

    float second_mindist = 1e9; // Distance to the second closest point

    vec2 vorv;                  // Vector to the closest point's cell center

    // vec2 second_vorv;        // Not strictly needed for boundary drawing, but good for understanding


    for(float i=-1.;i<=1.;i++) {

        for(float j=-1.;j<=1.;j++) {

            vec2 offv = vec2(i,j);

            // Calculate the distance from the current fragment to the potential Voronoi point

            // (gv is the fractional part, pt(id+offv) is the random offset, offv is the cell offset)

            float dist = length(gv+pt(id+offv)-offv);

            

            // Check if this is the closest point found so far

            if(dist < mindist){

                second_mindist = mindist; // The previous closest is now the second closest

                mindist = dist;           // Update the closest distance

                vorv = (id+pt(id+offv)+offv)/SIZE-off; // Update the vector to the closest cell center

            } else if (dist < second_mindist) {

                // If not the closest, but closer than the current second closest

                second_mindist = dist; // Update the second closest distance

            }

        }

    }

    

    vec3 col = mix(col1,col2,clamp(vorv.x*2.2+vorv.y,-1.,1.)*0.5+0.5);

    

    // Calculate the boundary line.

    // The difference between the second_mindist and mindist is very small near the boundary.

    // We use smoothstep to create a sharp transition for the line.

    float boundary = smoothstep(LINE_THICKNESS, 0.0, second_mindist - mindist);

    

    // Mix the main color with the line color based on the boundary detection

    col = mix(col, LINE_COLOR, boundary);

    

    fragColor = vec4(col,1.0);

} 