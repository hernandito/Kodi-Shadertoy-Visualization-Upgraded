mat2 rot (float a){

    float c = cos (a);
    float s = sin(a);
    return mat2 (c,s,-s,c);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   
    vec2 uv  = (fragCoord.xy*2.-iResolution.xy)/iResolution.y;
    uv*=3.;
    float d =0.;
    for(float i = 0.; i<5.;i++){
        vec2 uv2 =uv*rot(float(i)/3.14);     
        float t =abs(2.1*uv2.y-  sin(uv2.x+iTime));
        d = mix(d,.1,t*t*.2);
     }
     d*=d;
     
     
     
      
   fragColor=  vec4 (d);
    
}