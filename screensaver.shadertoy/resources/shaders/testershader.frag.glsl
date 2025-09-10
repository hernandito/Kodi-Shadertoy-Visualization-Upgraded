/* 
 * zephyr mann
 * 2014
 */

float pWid = 120.;
float pHei = 100.;

float getDepth(vec2 uv) {
    float x = (uv.x - (iResolution.x*0.5)) / iResolution.x;
	float y = (uv.y - (iResolution.y*0.5)) / iResolution.x;
    
    float offX = sin(iTime * 1.) * 0.2;
    float offY = cos(iTime * 0.666) * 0.2;
    
    float d = floor(abs(y*2. + offY + sin((x+iTime*0.25)*10.) * 0.25) * 20.) * 0.05;
    d = 1. - d;
    d = 1. - (d*d*d*d);
    
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float maxStep = 30.;
    float d = 0.;
    
    vec2 uv = fragCoord.xy;
    
    for(int count = 0; count < 100; count++) {
        if(uv.x < pWid)
          break;
        
        float d = getDepth(uv);
        //d = 1.;
        
        uv.x -= pWid - (d * maxStep);
    }
    
    float x = mod(uv.x + iTime*1., pWid) / pWid;
    float y = mod(uv.y + iTime*4., pHei) / pHei;
    vec3 rgb = texture( iChannel0, vec2(x,y), -100.0 ).yxz;
    
	fragColor = vec4(rgb,1.0);
    
    // view depth map
    if(false)
    	fragColor = vec4(vec3(getDepth(fragCoord.xy)),1.0);
        
    
    // add some guide dots
    float dotWid = min(iResolution.y * 0.01, 5.0);
    uv.x = (fragCoord.x - (iResolution.x*0.5));
    uv.y = (fragCoord.y - (iResolution.y*0.5));
    
    if(distance(uv, vec2(maxStep*1.5,0.0)) < dotWid || distance(uv, vec2(-maxStep*1.5,0.0)) < dotWid)
        fragColor = vec4(0.0);
}