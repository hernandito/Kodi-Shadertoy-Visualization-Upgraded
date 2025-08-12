#define FAR 20.

// === BCS Parameters ===
// Brightness: -1.0 to 1.0 (0.0 = no change, positive brightens, negative darkens) fragColor
// Contrast: 0.0 to 2.0 (1.0 = no change, higher increases contrast, lower reduces)
// Saturation: 0.0 to 2.0 (1.0 = no change, 0.0 = grayscale, higher increases saturation)
const float post_brightness = -0.03; // Default: slight darkening
const float post_contrast = 1.02;   // Default: slight contrast increase
const float post_saturation = 1.0; // Default: no change

// === Apply BCS Adjustments to a vec3 Color ===
vec3 applyBCS(vec3 col) {
    // Apply brightness
    col = clamp(col + post_brightness, 0.0, 1.0);

    // Apply contrast
    col = clamp((col - 0.5) * post_contrast + 0.5, 0.0, 1.0);

    // Apply saturation
    vec3 grayscale = vec3(dot(col, vec3(0.299, 0.587, 0.114))); // Luminance
    col = mix(grayscale, col, post_saturation);

    return col;
}

mat2 rot2(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}

vec3 rotObj(vec3 p){
    p.yz*=rot2(iTime*.02);
    p.zx*=rot2(iTime*.05);
    return p;    
}

const float PHI=(1.+sqrt(5.))/2.;
const float A=PHI/sqrt(1.+PHI*PHI);
const float B=1./sqrt(1.+PHI*PHI);
const float J=(PHI-1.)/2.;
const float K=PHI/2.;
const mat3 R0=mat3(.5,-K,J,K,J,-.5,J,.5,K);
const mat3 R1=mat3(K,J,-.5,J,.5,K,.5,-K,J);
const mat3 R2=mat3(-J,-.5,K,.5,-K,-J,K,J,.5);

#define size 1.25
const vec3 v0=vec3(0,A,B)*size;
const vec3 v1=vec3(B,0,A)*size;
const vec3 v2=vec3(-B,0,A)*size;
const vec3 cent=((v0+v1+v2)/3.)*1.06;

vec3 opIcosahedronWithPolarity(in vec3 p){
    vec3 pol=sign(p);
    p=R0*abs(p);
    pol*=sign(p);
    p=R1*abs(p);
    pol*=sign(p);
    p=R2*abs(p);
    pol*=sign(p);
    vec3 ret=abs(p);
    return ret*vec3(pol.x*pol.y*pol.z,1,1);
}   

mat3 basis(in vec3 n){
    float a=1./(1.+n.z);
    float b=-n.x*n.y*a;
    return mat3(1.-n.x*n.x*a,b,n.x,b,1.-n.y*n.y*a,n.y,-n.x,-n.y,n.z);
                
}
 
float sdCapsule(vec3 p,vec3 a,vec3 b,float r,float lf){
    b-=a;
    float l=length(b);
    p=basis(normalize(b))*(p-a-b*.5);
    p=abs(p);
    return max(max(p.y*.866025+p.x*.5,p.x)-r,p.z-l*lf);
}
    
vec4 objID;

float dist(vec3 p,float r){
    return length(p)-r;
}

float map(in vec3 p){
    float pln=-p.z+6.;
    p=rotObj(p);
    p=opIcosahedronWithPolarity(p);
    const vec3 flip=vec3(-1,1,1);
    const float lw=.02;
    float lf=.45;
    const vec3 hd=vec3(0,0,.08);
    float d=1e5,d2=1e5,d3=1e5;
    vec3 a=mix(v0,v1,.425*.5);
    vec3 b=mix(mix(v0,v2,.5),cent,.375);
    vec3 mid=mix(a,b,.5);
    d=min(d,sdCapsule(p,a,mid-hd,lw,lf));
    d=min(d,sdCapsule(p,mid-hd,b,lw,lf));
    d=min(d,sdCapsule(p,flip*a,flip*mid+hd,lw,lf));
    d=min(d,sdCapsule(p,flip*mid+hd,flip*b,lw,lf));
    vec3 a2=mix(v0,v1,.575*.5);
    vec3 b2=mix(mix(v0,v2,.5),cent,.625);
    vec3 mid2=mix(a2,b2,.5);
    d=min(d,sdCapsule(p,a2,mid2-hd,lw,lf));
    d=min(d,sdCapsule(p,mid2-hd,b2,lw,lf));
    d=min(d,sdCapsule(p,flip*a2,flip*mid2+hd,lw,lf));
    d=min(d,sdCapsule(p,flip*mid2+hd,flip*b2,lw,lf)); 
    const float lw2=.035;
    lf=1.;
    d2=min(d2,sdCapsule(abs(p),a,a2,lw2,lf));
    d2=min(d2,sdCapsule(abs(p),flip*b,flip*b2,lw2,lf));
    const float jw=.02;
    d3=min(d3,dist(mid-hd-p,jw));
    d3=min(d3,dist(mid2-hd-p,jw));  
    d3=min(d3,dist(flip*mid+hd-p,jw));    
    d3=min(d3,dist(flip*mid2+hd-p,jw));  
    objID=vec4(d,d2,d3,pln);
    return min(min(d,d2),min(d3,pln));
}

vec3 calcNormal(vec3 p,inout float edge,inout float crv,float t){ 
    vec2 e=vec2(2.5/mix(400.,iResolution.y,.5),0);
    float d1=map(p+e.xyy),d2=map(p-e.xyy);
    float d3=map(p+e.yxy),d4=map(p-e.yxy);
    float d5=map(p+e.yyx),d6=map(p-e.yyx);
    float d=map(p)*2.;
    edge=abs(d1+d2-d)+abs(d3+d4-d)+abs(d5+d6-d);
    edge=smoothstep(0.,1.,sqrt(edge/e.x*2.));
    e=vec2(.001,0);
    d1=map(p+e.xyy),d2=map(p-e.xyy);
    d3=map(p+e.yxy),d4=map(p-e.yxy);
    d5=map(p+e.yyx),d6=map(p-e.yyx);
    return normalize(vec3(d1-d2,d3-d4,d5-d6));
}

float trace(in vec3 ro,in vec3 rd){
    float t=0.,d;
    for(int i=0;i<64;i++){
        d=map(ro+rd*t);
        if(abs(d)<.001*(1.+t*.05)||t>FAR)break;
        t+=d;
    }
    return min(t,FAR);
}

float hash(float n){return fract(cos(n)*45758.5453);}

float calculateAO(in vec3 p,in vec3 n,float maxDist){
    float ao=0.,l;
    const float nbIte=6.;
    for(float i=1.;i<nbIte+.5;i++){
        l=(i+hash(i))*.5/nbIte*maxDist;
        ao+=(l-map(p+n*l))/(1.+l);
    }
    return clamp(1.-ao/nbIte,0.,1.);
}

float softShadow(in vec3 ro,in vec3 rd,float t,in float end,float k){
    float shade=1.;
    const int maxIterationsShad=24;
    float dist=.001*(1.+t*.1);
    float stepDist=end/float(maxIterationsShad);
    for(int i=0;i<maxIterationsShad;i++){
        float h=map(ro+rd*dist);
        shade=min(shade,k*h/dist);
        dist+=clamp(h,0.01,0.25);
        if(abs(h)<0.0001||dist>end)break;
    }
    return min(max(shade,0.)+0.1,1.);
}

void mainImage(out vec4 fragColor,in vec2 fragCoord){
    vec2 p=(fragCoord-iResolution.xy*.5)/iResolution.y;
    vec3 rd=normalize(vec3(p,1.));
    vec3 ro=vec3(0.,0.,-3.);
    vec3 lp=ro+vec3(0.25,2,0);
    float t=trace(ro,rd);
    float svObjID=objID.x<objID.y&&objID.x<objID.z&&objID.x<objID.w?0.:objID.y<objID.z&&objID.y<objID.w?1.:objID.z<objID.w?2.:3.;
    vec3 col=vec3(0);
    if(t<FAR){
        vec3 pos=ro+rd*t;
        float edge=0.,crv=1.;
        vec3 nor=calcNormal(pos,edge,crv,t);
        vec3 li=lp-pos;
        float lDist=max(length(li),.001);
        li/=lDist;
        float atten=1.5/(1.+lDist*.05+lDist*lDist*0.01);
        float shd=softShadow(pos+nor*.0015,li,t,lDist,8.);
        float ao=calculateAO(pos,nor,4.);
        float diff=max(dot(li,nor),.0);
        float spec=pow(max(dot(reflect(-li,nor),-rd),0.),16.);
        diff=pow(diff,4.)*2.;
        float Schlick=pow(1.-max(dot(rd,normalize(rd+li)),0.),5.);
        float fre2=mix(.5,1.,Schlick);
        col=vec3(.6);
        if(svObjID==1.){col=vec3(1,.55,.2);col=mix(col,col.yxz,rd.y*.5);}
        if(svObjID==3.){col=vec3(1,.55,.2).zyx/7.;col=mix(col,col.yxz,rd.y*.1+.1);col*=clamp(sin((pos.x-pos.y)*iResolution.y/8.)*2.+1.5,0.,1.)*.5+.5;}
        col*=diff+.25;
        if(svObjID==3.)col+=vec3(1,.6,.2).zyx*spec*.25;
        else col+=vec3(.5,.75,1.)*spec*2.;
        col*=1.-edge*.7;
        col*=atten*shd*ao;
    }
    col = applyBCS(col);
    fragColor=vec4(sqrt(clamp(col,0.,1.)),1.);
}