float circle(vec2 uv, float size){
	return smoothstep(size,size*0.93,length(uv));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y;
    uv *= 3.0;
    vec3 col = vec3(0.0);
    vec4 d = vec4(0.0);
	vec2 pos = vec2(0.0);
	float colflip = -1.0;
	float size = 0.9;
    
    //rotation
    float t = iTime;
    float s = sin(t), c = cos(t);
    mat2 rot = mat2(c,-s,s,c);
    uv *= rot;
    
    //background
    vec3 bg = vec3(0.722, 0.525, 0);
    col += bg;
    
    //outer rings
    for(int i = 0; i < 7; i ++){
		d = vec4(circle(uv+pos,size));
		d.rgb *= colflip;
		size -= 0.05;
		colflip *= -1.0;
		pos.x += 0.05;

		col = mix(col,d.rgb,d.a);
		}
    //inner rings   
    for(int k = 0; k < 7; k ++){
		d = vec4(circle(uv+pos,size));
		d.rgb *= colflip;
		size -= 0.05;
		colflip *= -1.0;
		pos.x -= 0.05;

		col = mix(col,d.rgb,d.a);
		}
    //center circle
    d = vec4(circle(uv+pos,size-0.05));
	d.rgb *= 0.0;
	col = mix(col,d.rgb,d.a);
    
    
    fragColor = vec4(col,1.0);
}