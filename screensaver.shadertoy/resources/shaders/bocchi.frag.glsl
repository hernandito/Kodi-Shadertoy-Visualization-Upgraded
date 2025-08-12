#define TMIN 0.001
#define TMAX 1024.
#define RAYMARCH_TIME 128
#define PRECISION .001

//RaymatchingParam

vec3  ro=vec3(0.,0.,-2.);
float rds=0.;
float WorldScale=1.0;
vec3 centerReset=vec3(0.,-0.2,0.);
float AutoTimeSpeed=0.250;
float OutLineWidth=0.02;
vec3  OutLineColor  =vec3(0.45);
vec3 BkColor=vec3(1.0,0.7,0.76);
vec3 SkyLightDirection=normalize(vec3(0.5,1.,-1.));

float pi=3.1415926;
//================
//CommonFunctions  iTime
//================

vec2 fixUV(vec2 c)
{
    return (-iResolution.xy+2.0*c)/min(iResolution.x,iResolution.y);
}

vec2 RotateXY(vec2 P,vec2 C,float T)
{
    float pi=3.1415926;
    return vec2((P-C).x*(cos(T*2.*pi))+(P-C).y*(sin(T*2.*pi)),(P-C).y*(cos(T*2.*pi))-(P-C).x*(sin(T*2.*pi)))+C;  
}

vec3 RotateAboutAxis(vec3 p,vec3 axis,float R)
{
    float s=sin(R);
    float c=cos(R);
    float one_minus_c=1.-c;

    vec3 Axis =normalize(axis);

    mat3 rot_mat = 
    mat3(   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
        one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
        one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
    );
    return rot_mat*p;
}
vec3 CenterResetAdd(vec3 p)
{
    return p+vec3(0.,sin(iTime*AutoTimeSpeed)*0.1,0.);
}
//----------------------------------------------

//Automatic Rot
vec2 MouseCoordinate()
    {
    return vec2((iMouse.xy/iResolution.xy)*2.-1.);
    }
vec3 WScoordinateRot(vec3 p)
{
    vec2 NC=RotateXY(p.xz,vec2(0.,0.),iTime*AutoTimeSpeed*0.07+MouseCoordinate().x);
    vec3 NC2=vec3(NC.x,p.y,NC.y);
    return vec3(RotateXY(NC2.xy,vec2(0.,0.),sin(iTime*AutoTimeSpeed*0.5)*0.03+MouseCoordinate().y*0.2).xy,NC2.z);
}

//================
//SDF Create
//================
//SDF Functions

    float sdEllipsoid( vec3 p, vec3 r )
    {
        float k0 = length(p/r);
        float k1 = length(p/(r*r));
        return k0*(k0-1.0)/k1;
    }
    float RoundCube(vec3 rp,vec3 c,vec3 size,float poon)
    {
        vec3 reco=vec3(max(abs(rp.x-c.x)-size.x,0.),
                       max(abs(rp.y-c.y)-size.y,0.),
                       max(abs(rp.z-c.z)-size.z,0.));
        return distance(reco,vec3(0.,0.,0.))-poon;
    }
    float RoundCylinder(vec3 p,vec3 c,vec2 wh,float poon)
    {
        float Cir=distance(p.xz,c.xz);
        return sqrt(pow(clamp(abs(Cir)-wh.x,0.,2000.),2.)+pow(clamp(abs(p.y-c.y)-wh.y,0.,200.),2.))-poon;
    }
    float Sphere(vec3 p ,vec3 c,float r)
    {
        return distance(p,c)-r;
    }
    float Radial(vec2 p)
    {
        return fract(atan(p.x,p.y)/pi/2.);
    }
    float Segment(vec2 P,vec2 A,vec2 B)
    {
        vec2 ba=B-A;
        vec2 pa=P-A;
        vec2 Di=vec2((dot(pa,ba))/(dot(ba,ba)),(dot(pa,ba))/(dot(ba,ba)));
        vec2 Diclamp=vec2(clamp(Di,0.,1.).x,clamp(Di,0.,1.).y);
        vec2 Coord=Diclamp*ba-pa;
        return length(Coord);
    }
    float ToRadians(float a)
    {
        float pi=3.1415926;
        return (a/360.)*2.*pi;
    }
    float Tears(vec2 p,float r,float a)
    {   
        float pi=3.1415926;
        float h=(1./cos(ToRadians(90.-a)))*r;
        vec2 trip=p-vec2(0.,h);
        float tria=(90.-a)/360.;
        float triSDF=max(RotateXY(trip.xy,vec2(0.,0.),tria).y,RotateXY(trip.xy,vec2(0.,0.),-tria).y);
    
        float p_dis=distance(p,vec2(0.,0.))-r;
        float rd_A=step(abs(0.5-fract((atan(p.x,p.y)/2./pi)+0.5)),0.25-(ToRadians(a)/2./pi));
        return mix(triSDF,p_dis,1.-rd_A);
    }

//ColorArea Attribute
    //Bocchi's body
    float BocchiBody(vec3 p)
    {
        float FootRangeSDF    =(cos(clamp((p.y+0.14)*9.8,-pi,pi))+1.)*0.15;
        float WaveFootSDF     =((sin(iTime+Radial(p.xz)*2.*pi*7.)+1.)/2.)*0.3*FootRangeSDF;
        float XYFootSize      =0.5+WaveFootSDF;

        float SDF1 = sdEllipsoid(p,vec3(XYFootSize,0.65,XYFootSize));
        float SDF2 = RoundCylinder(p,vec3(0.,0.38,0.),vec2(0.55,0.4),0.2);

        float hairWidth = 0.205;
        vec3 hairp_re = p+vec3(0.57,-0.21,0.);
        float SDF3a = Sphere(hairp_re,vec3(0.,0.,-hairWidth),0.3);
        float SDF3b = Sphere(hairp_re,vec3(0.,0., hairWidth),0.3);
        float SDF3c = Sphere(hairp_re,vec3(0.,-0.18,0.),0.38);
        float SDF3  = max(max(SDF3a,SDF3b),-SDF3c);
        return min(max(SDF1,SDF2),SDF3);
    }
    //Bocchi's true body
    float BocchiHairwear1(vec3 p)
    {
        vec3 pRot=RotateAboutAxis(p,vec3(0.5),0.7);
        float R1=RoundCube(pRot,vec3(-0.17,0.55,-0.33),vec3(0.03),0.03);
        return R1;
    }
    float BocchiHairwear2(vec3 p)
    {
        vec3 pRot=RotateAboutAxis(p,vec3(0.5),-0.9);
        float R1=RoundCube(pRot,vec3(-0.5,-0.05,0.35),vec3(0.03),0.03);
        return R1;
    }
    

//SDF Create
vec4 SDFFunction(vec3 p)
{
    vec3 p_re=WScoordinateRot(p-CenterResetAdd(centerReset));

    float BodySDF=BocchiBody(p_re);
    float Hairwear=min(BocchiHairwear1(p_re),BocchiHairwear2(p_re));
    float SDF=min(BodySDF,Hairwear);


    vec4 SDFout=vec4(p.xyz*1.,SDF);
    return SDFout;
}
//================
//3D Raymatching
//================

float rayMarch(vec3 ro,vec3 rd,float l)
{
    float t =TMIN;
    vec3 p=ro+t*rd;
    for(int i =0;i<RAYMARCH_TIME && t<TMAX;i++)
    {
        vec3 p=ro+t*rd;
        float d=SDFFunction(p).w-l;
        if(d<PRECISION)
        {
        break;
        }
        t+=d;
    }
    return t;
}
vec3 calcNormal(vec3 p)
{
    const float h=0.001;
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*SDFFunction(p+k.xyy*h).w+
                      k.yyx*SDFFunction(p+k.yyx*h).w+
                      k.yxy*SDFFunction(p+k.yxy*h).w+
                      k.xxx*SDFFunction(p+k.xxx*h).w
                    );
}
vec3 Normal(vec2 uv)
{
    ro *=WorldScale;
    vec3 V=vec3(0.);
    vec3 rd=normalize(vec3(uv,rds)*WorldScale-ro);
    float t = rayMarch(ro,rd,0.);

    if(t<TMAX)
    {
        vec3 p=ro+t*rd;
        vec3 n=calcNormal(p);
        vec3 Vector=WScoordinateRot(n);
        V=Vector;
            }
    return V;
}
vec3 Position(vec2 uv)
{
    vec3 V=vec3(0.);
    vec3 rd=normalize(vec3(uv,rds)*WorldScale-ro);
    float t = rayMarch(ro,rd,0.);

    if(t<TMAX)
    {
        vec3 p=ro+t*rd;
        vec3 n=calcNormal(p);
        vec3 AlbedoColor=WScoordinateRot(SDFFunction(p-CenterResetAdd(centerReset)).xyz);
        V=AlbedoColor;

    }
    return V;
}
vec2 CustomDepthAlpha(vec2 uv)
{
    ro *=WorldScale;
    float A=0.;
    float Target=0.;
    vec3 rd=normalize(vec3(uv,rds)*WorldScale-ro);
    float t = rayMarch(ro,rd,0.);
    
    if(t<TMAX)
    {
        vec3 p=ro+t*rd;
        vec3 n=calcNormal(p);
        //Opacity
        float Alpha=1.-(pow((-dot(vec3(0.,0.,1.),n)),2.2));
        Target = Alpha; //Opacity%
        A=1.;
    }
    return vec2(Target,A);
}
float OutLine(vec2 uv)
{
    ro *=WorldScale;
    float A=0.;
    vec3 rd=normalize(vec3(uv,rds)*WorldScale-ro);
    float t = rayMarch(ro,rd,OutLineWidth);
    if(t<TMAX)
    {
        vec3 p=ro+t*rd;
        vec3 n=calcNormal(p);
        float Alpha=1.-(pow((-dot(vec3(0.,0.,1.),n)),2.2));
        A=1.;
    }
    return A;
}

//================
//FinalSceneView
//================

//Color Render
vec3 Render(vec2 uv)
    {
    //inputs
    vec3  p             =Position(uv);
    vec3  n             =Normal(uv);
    float AlphaBlend    =CustomDepthAlpha(uv).x;
    float OpacityMask   =CustomDepthAlpha(uv).y;
    float OutLineOp     =OutLine(uv);
    
    //MainBody
    vec3 ACP= vec3(step(BocchiHairwear1(p),0.0012),
                   step(BocchiHairwear2(p),0.0012),
                   0.);
    vec3 FresnelShade =mix(vec3(1.0,0.8,0.85),vec3(1.0,0.65,0.75),1.-pow(dot(n,WScoordinateRot(vec3(0.,0.,1.))),2.0));
    vec3 MainBodyC    =ACP.x*vec3(1.,0.9,0.3)+ACP.y*vec3(0.5,0.8,1.0)
                      +(1.-ACP.x-ACP.y)*FresnelShade;
    float NPRshadeSDF =dot(n,SkyLightDirection);
    float HighLight   =step(0.98,NPRshadeSDF);
    float ToonShade   =step(0.,NPRshadeSDF);
    vec3 NPRshade    =mix(mix(MainBodyC*0.84,MainBodyC,ToonShade),vec3(1.),HighLight);
    
    //eyes
    vec3 face_p = RotateAboutAxis(p.xyz,vec3(1.,0.,0.),0.11)+vec3(0.,-0.17,0.);
    float eyesGap=0.081;
    vec3 face_Lcoord    =face_p-vec3(eyesGap,0.,0.);
    vec3 face_Rcoord    =vec3((face_p+vec3(eyesGap,0.,0.)).x*-1.,
                              (face_p+vec3(eyesGap,0.,0.)).y,
                              (face_p+vec3(eyesGap,0.,0.)).z);
    vec3 face_mirrorcoord=vec3(    mix(face_Lcoord,face_Rcoord,step(face_p.x,0.)).x,
                               abs(mix(face_Lcoord,face_Rcoord,step(face_p.x,0.)).y),
                                   mix(face_Lcoord,face_Rcoord,step(face_p.x,0.)).z);
    float eyes=step(Segment(face_mirrorcoord.xy,vec2(0.),vec2(0.12,0.061))-0.0156,0.)*step(face_p.z,0.);
    vec3 eyesColor=vec3(0.2);
    vec3 AddEyes=mix(NPRshade,eyesColor,eyes);
    
    //Tears
    float TearGap=0.25;
    float TearHeight=-0.079;
    vec3 TearCoord=mix((p+vec3(TearGap, TearHeight,0.)),
                       (p-vec3(TearGap,-TearHeight,0.))*vec3(-1.,1.,1.),
                       step(0.,p.x));
    vec3 TearCoordRot=vec3(RotateXY(TearCoord.xy,vec2(0.),-0.068),TearCoord.z);
    float GridSize = 10.0;
    vec3 TearCoordGrid=vec3(      (TearCoordRot*vec3(GridSize)).x+0.5,
                             fract(TearCoordRot*vec3(GridSize)+iTime).y,
                                  (TearCoordRot*vec3(GridSize)).z
                            );
                            
    vec3 TearCoordGrid2=vec3(     (TearCoordRot*vec3(GridSize)).x,
                                  (TearCoordRot*vec3(GridSize)).y,
                                  (TearCoordRot*vec3(GridSize)).z
                            );
    float T_RangeSize=1.0;
    float T_Range=step(abs(TearCoordGrid2.y+T_RangeSize/2.),T_RangeSize)*step(abs(TearCoordGrid2.x)-0.5,0.);
    float TearSDF=Tears(TearCoordGrid.xy-vec2(0.5,0.5),0.19,30.);
    vec2 TearShapePass=vec2(step(TearSDF,0.),step(TearSDF,0.08));
    vec3 TearShape=mix(vec3(0.1),vec3(1.),TearShapePass.x)*T_Range*step(TearCoordRot.z,0.);
    vec3 TearShapeBlend=mix(AddEyes,TearShape,TearShapePass.y*T_Range*step(TearCoordRot.z,0.));
    
    //Mouse
    vec3 MouseCoord=vec3(RotateXY(p.xy,vec2(0.,0.),0.5),p.z)+vec3(0.,0.075,0.);
    float MouseSDF=Tears(MouseCoord.xy,0.045,-12.);
    float MouseButtomHeight=0.13;
    vec2 MousePass=vec2(step(max(MouseSDF,MouseCoord.y-MouseButtomHeight),0.),step(max(MouseSDF,MouseCoord.y-MouseButtomHeight),0.015));
    vec3 MouseColor=mix(vec3(0.2),vec3(1.),MousePass.x*step(MouseCoord.z,0.));
    vec3 MouseAdd=mix(TearShapeBlend,MouseColor,MousePass.y*step(MouseCoord.z,0.));
    
    vec3 BaseColor =vec3( MouseAdd); 
    
    //BackGround
    float SpotRes=7.;
    vec2 uvb=uv+vec2(iTime*AutoTimeSpeed*0.2,0.);
    float spotMask=step(distance((fract(uvb*vec2(SpotRes*2.)),fract(uvb*vec2(SpotRes*2.))),vec2(0.5))-0.29,0.);
    float Checker=mix(step(abs(0.75-fract(uvb.x*SpotRes))-0.25,0.),
                  1.-step(abs(0.75-fract(uvb.x*SpotRes))-0.25,0.),
                  step(abs(0.75-fract(uvb.y*SpotRes))-0.25,0.))
                  ;
    float BKshape=clamp(spotMask-Checker,0.,1.);
    
    vec3 OutLined = mix(BaseColor,OutLineColor,OutLineOp-OpacityMask);
    vec3 background=mix(BkColor,vec3(1.),clamp((uv.y+1.)/2.
                                           +BKshape,0.,1.));
    vec3 SceneFinalView=mix(background,OutLined,OutLineOp);
    return SceneFinalView;
    }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fixUV(fragCoord.xy);
    
    vec3 SceneColor=Render(uv);

    fragColor=vec4(SceneColor,1.);
}