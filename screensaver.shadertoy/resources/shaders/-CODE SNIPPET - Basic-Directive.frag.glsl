I have a BRAND NEW Shadertoy shader that I want to make compatible with Kodi's Shadertoy addon. For reference, Kodi only supports OpenGL ES v.1.0. It does NOT support uniform statements or #version statements either. It also does not support gl_FragColor, but it does support fragColor and o=. The below code does NOT work in Kodi. I am pasting the new Shader code along with the Kodi log below:


I have a new Shadertoy shader that I want to make compatible with Kodi's Shadertoy addon. Kodi only supports OpenGL ES v.1.0. It does NOT support uniform statements or #version statements either. It also does not support gl_FragColor, but it does support fragColor and o=. The below code DOES work in Kodi. I am pasting the new Shader code below. 

I am pasting below the code for a Shadertoy shader that I want to use with the Shadertoy Kodi addon. This code works properly in Kodi.



I want to make the following adjustments to the below code.

Add #define parameters to adjust BCS in post.

Add #define parameters to control overall animation spped

Add #define parameter to adjust the effects FOV.


BRAND NEW SHADER CODE:



KODI LOG:

