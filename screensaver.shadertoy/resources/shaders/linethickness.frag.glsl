// User-configurable parameters
// Adjust these values to control the rotation and axis offset.
#define ROTATION_SPEED 0.005       // Rotation speed. Use a negative value for counter-clockwise, positive for clockwise.
#define AXIS_OFFSET_X  20.0        // Shift the center of rotation horizontally.
#define AXIS_OFFSET_Y  30.0        // Shift the center of rotation vertically.
#define MIN_BRIGHTNESS 0.05        // Controls the brightness of the most distant lines.
#define MAX_BRIGHTNESS 1.0         // Controls the brightness of the closest lines.
#define LINE_COLOR vec3(2.00, 0.50, 0.0) // The RGB color of the lines.
#define FILL_ALPHA 0.045             // Transparency of the fill color (0.0 = fully transparent, 1.0 = fully opaque).

#define R iResolution
#define T iTime*.2
#define M iMouse

mat2 r(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}
float h(vec2 a){return fract(sin(dot(a,vec2(27.609,57.583)))*43758.5453);}

void mainImage(out vec4 O,in vec2 F){
    vec3 C=vec3(0);
    vec2 uv=(2.*F-R.xy)/max(R.x,R.y);

    // Get the center of rotation and translate the UVs
    vec2 center = (R.xy / 2.0 + vec2(AXIS_OFFSET_X, AXIS_OFFSET_Y)) / max(R.x, R.y);
    uv -= center;

    // Apply the rotation
    float angle = ROTATION_SPEED * iTime;
    uv = r(angle) * uv;
    
    // Translate the UVs back
    uv += center;

    // The rest of the original shader logic
    vec2 vv=F/max(R.x,R.y),mv=M.z>0.?M.xy/max(R.x,R.y):.5*R.xy/max(R.x,R.y)+.3*vec2(cos(T),sin(T));
    float fz=.04+.035*sin(T*1.5),lv=.25-clamp(length(vv-mv)-fz,0.,.245),dv=length(vv-mv)-.15,s=14.;
    uv+=vec2(.01,.03)*T;
    vec2 id=floor(uv*s),q=fract(uv*s)-.5;
    float rnd=h(id);
    if(rnd>.5)q.x=-q.x;
    vec2 p=length(q-.5)<length(q+.5)?q-.5:q+.5;
    float d=abs(length(p)-.5)-lv;
    if(fract(rnd*43.32)>.5){
        if(fract(rnd*57.41)>.55)q*=r(1.57);
        float t1=abs(length(q.x))-lv,t2=abs(length(q.y))-lv;
        d=min(max(t1,.02-t2),t2);
    }
    float g=max(d,dv),px=fwidth(mv.x);

    // Calculate the fill color
    vec3 fillColor = mix(vec3(0), LINE_COLOR, smoothstep(.05+px,-px,g) * FILL_ALPHA);
    
    // Calculate the line color
    vec3 lineColor = LINE_COLOR * clamp(lv*3.25, MIN_BRIGHTNESS, MAX_BRIGHTNESS);
    px=fwidth(uv.x*s);
    lineColor = mix(vec3(0), lineColor, smoothstep(px,-px,abs(d)-.02));

    // Combine the fill and line colors
    C = max(fillColor, lineColor);
    
    O=vec4(pow(C,vec3(.4545)),1);
}
