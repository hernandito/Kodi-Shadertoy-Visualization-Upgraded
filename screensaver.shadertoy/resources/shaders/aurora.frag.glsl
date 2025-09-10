#define PI 3.1415926

// Adjustable BCS parameters (Brightness, Contrast, Saturation)
#define BRIGHTNESS 1.20 // Default brightness (current setting)
#define CONTRAST 2.5   // Default contrast (current setting)
#define SATURATION 1.0 // Default saturation (current setting)
#define ANIM_SPEED .05 // Default animation speed (current setting)

mat2 rot(float a){ return mat2(cos(a),-sin(a),sin(a),cos(a)); }

vec4 tanh_approx(vec4 x) { 
    const float EPSILON = 1e-6; 
    return x / (1.0 + max(abs(x), EPSILON)); 
}

//-------------------------
// Lensflare 部分（精简：删除了自动旋转和鼠标中心）
float noise(float t)
{
    return texture(iChannel0,vec2(t, 0.0) / iChannelResolution[0].xy).x;
}
float noise(vec2 t)
{
    return texture(iChannel0,t / iChannelResolution[0].xy).x;
}

vec3 lensflare(vec2 uv,vec2 pos)
{
    vec2 main = uv-pos;
    vec2 uvd = uv*(length(uv));
    
    float ang = atan(main.y, main.x);
    float dist=length(main); dist = pow(dist,.1);
    float n = noise(vec2(ang*16.0,dist*32.0));   // 去掉 iTime
    
    float f0 = 1.0/(length(uv-pos)*16.0+1.0);
    f0 = f0+f0*(sin((ang + n*2.0)*1.0)*.1+dist*.1+.8);

    float f2  = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),.0)*0.025;
    float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),.0)*0.023;
    float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),.0)*0.021;
    
    vec2 uvx = mix(uv,uvd,-0.5);
    
    float f4  = max(0.01-pow(length(uvx+0.4*pos),2.4),.0)*6.0;
    float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4),.0)*5.0;
    float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*3.0;
    
    uvx = mix(uv,uvd,-.4);
    
    float f5  = max(0.01-pow(length(uvx+0.2*pos),5.5),.0)*2.0;
    float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5),.0)*2.0;
    float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5),.0)*2.0;
    
    uvx = mix(uv,uvd,-0.5);
    
    float f6  = max(0.01-pow(length(uvx-0.3*pos),1.6),.0)*6.0;
    float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6),.0)*3.0;
    float f63 = max(0.01-pow(length(uvx-0.35*pos),1.6),.0)*5.0;
    
    vec3 c = vec3(.0);
    c.r+=f2+f4+f5+f6; c.g+=f22+f42+f52+f62; c.b+=f23+f43+f53+f63;
    c+=vec3(f0);
    
    return c;
}

vec3 cc(vec3 color, float factor,float factor2) // color modifier
{
    float w = color.x+color.y+color.z;
    return mix(color,vec3(w)*factor,w*factor2);
}

// BCS adjustment function
vec3 adjustBCS(vec3 color, float brightness, float contrast, float saturation)
{
    // Brightness
    color *= brightness;
    
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    
    // Saturation
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(gray), color, saturation);
    
    return clamp(color, 0.0, 1.0);
}
//-------------------------

void mainImage(out vec4 o, vec2 u) {
    o = vec4(0.0);
    float t = iTime*10.0*ANIM_SPEED; // Apply animation speed
    vec4 colortint=vec4(1,0,1,0);
    vec3 res = iResolution;    
    
    // scale coords
    u = (u+u-res.xy)/res.y;
    
    // cinema bars
    if (abs(u.y) > .8) { o = vec4(0); return; }
    
    //-------------------------
    // 鼠标旋转相机
    vec2 mouse = iMouse.xy / res.xy;
    float yaw   = (mouse.x-0.5) * 6.2831;
    float pitch = (mouse.y-0.5) * 3.1415;

    vec3 rd = normalize(vec3(u, 1.0));
    rd.yz = rd.yz * rot(pitch);
    rd.xz = rd.xz * rot(yaw);

    vec3 ro = vec3(0.0, 0.0, -t*0.5*3.0); 
    
    float d = 0.0;
    float e = 0.0;
    float e2 = 0.0;
    float s = 0.0;
    float i_val = 0.0;
    float a_val = 0.0;
    vec3 p = vec3(0.0);
    
    while(i_val < 128.0) {
        p = ro + rd * d;
        
        float sint1 = sin(sin(t*.2)+t*.4);
        float sint2 = sin(sin(t*.5)+t*.2);
        vec3 center1 = vec3(sint1 * 2.0, 1.0 + sint2 * 2.0, 10.0 + ro.z);
        e = length(p - center1) - .1;
        vec3 center2 = vec3(center1.xy, -10.0 + ro.z);
        e2 = length(p - center2) - .1;
        e = (e + e2) * 0.75;
        p.xy *= mat2(cos(.1*t + p.z/16. + vec4(0,33,11,0)));
        s = 4.0 - abs(p.y);
        
        a_val = .42;
        while(a_val < 16.0) {
            p += cos(.4*t + p.yzx) * .3;
            vec3 temp_sin_arg = .1*t + p * a_val;
            vec3 temp_sin = sin(temp_sin_arg);
            float temp_dot = dot(temp_sin, vec3(0.18));
            s -= abs(temp_dot) / max(a_val, 1e-6);
            a_val += a_val;
        }
        
        e = max(.8*e, .01);
        s = min(.01 + .4 * abs(s), e);
        d += s;
        vec4 temp_cos = cos(.1 * p.z * vec4(3.0,1.0,PI/2.0,0.0));
        vec4 temp_add = (1.0 + colortint * temp_cos) / max((s + e*2.0), 1e-6);
        o += temp_add;
        
        i_val += 1.0;
    }
    
    // tonemap
    u += (u.yx*.9+.3-vec2(-1.,.5));
    float temp_denom = max(dot(u,u), 1e-6);
    vec4 temp = o / 6.0 / temp_denom;
    o = tanh_approx(temp);

    //-------------------------
    // Lensflare (固定以 rd.xy 为中心)
    vec3 flare = lensflare(rd.xy, vec2(0.0,0.0));
    flare = cc(flare*1.0, .5*0.1, .1);
    o.rgb += flare * 1.0;
    
    // Apply BCS adjustments
    o.rgb = adjustBCS(o.rgb, BRIGHTNESS, CONTRAST, SATURATION);
}