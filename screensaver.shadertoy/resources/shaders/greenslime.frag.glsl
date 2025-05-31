/* THE ORIGINAL COLOR
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv =  (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
   
    for(float i = 1.0; i < 9.0; i++){
    uv.y += i * 0.1 / i * 
      sin(uv.x * i * i + iTime * 0.5) * sin(uv.y * i * i + iTime * 0.5);
  }
    
   vec3 col;
   col.r  = uv.y - 0.0;
   col.g = uv.y + 0.2;
   col.b = uv.y + 0.9;
    
    fragColor = vec4(col,1.0);
}


    /* Option 1 - extra dark blood (more horror)
    col.r = y + 0.5;
    col.g = y - 0.3;
    col.b = y - 0.35;
    
    // Option 2 - heavy crimson, less black
    col.r = y + 0.55;
    col.g = y - 0.15;
    col.b = y - 0.2;
	*/

/*   bLOOD TO BLACK.

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = (1.15 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
   
    for(float i = .6; i < 9.0; i++){
        uv.y += i * 0.1 / i * 
                sin(uv.x * i * i + iTime * 0.5) * sin(uv.y * i * i + iTime * 0.5);
    }
    
    vec3 col;
    col.r = uv.y + 0.5;   // Boost red strongly
    col.g = uv.y - 0.00;  // Suppress green slightly
    col.b = uv.y - 0.1;   // Suppress blue more

    fragColor = vec4(col, 1.30);
}

/* 
#a00000


#260000
*/

/*   Green Slime        */

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = (1.2 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
   
    for(float i = 2.15; i < 7.150; i++){
        uv.y += i * 0.1 / i * 
                sin(uv.x * i * i + iTime * 0.5) * sin(uv.y * i * i + iTime * 0.5);
    }
    
    vec3 col;
    col.r = uv.y + 0.443;   // Boost red strongly
    col.g = uv.y + 0.502;  // Suppress green slightly
    col.b = uv.y - 0.324;   // Suppress blue more

    fragColor = vec4(col, 1.0);
}



/*Love this one... gold to copper

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
   
    for(float i = .6; i < 9.0; i++){
        uv.y += i * 0.1 / i * 
                sin(uv.x * i * i + iTime * 0.5) * sin(uv.y * i * i + iTime * 0.5);
    }
    
    vec3 col;
    col.r = uv.y + 0.5;   // Boost red strongly
    col.g = uv.y - 0.00;  // Suppress green slightly
    col.b = uv.y - 0.3;   // Suppress blue more

    fragColor = vec4(col, 1.30);
}

*/