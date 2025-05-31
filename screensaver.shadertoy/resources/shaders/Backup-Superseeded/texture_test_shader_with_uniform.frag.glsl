/*
         Simple Shader to Test iChannel0 Texture Loading with Explicit Uniform
     */
     #ifdef GL_ES
     precision mediump float;
     #endif

     uniform sampler2D iChannel0; // Explicitly declare the uniform

     void mainImage(out vec4 fragColor, in vec2 fragCoord)
     {
         vec2 uv = fragCoord / iResolution.xy;
         // Directly output the texture from iChannel0
         vec4 texColor = texture(iChannel0, uv);
         // If texture loads, you'll see the texture; if not, you'll see black
         fragColor = texColor;
     }