// Author: bitless
// Title: another triangular voronoi 
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders" and inspiration 
// Thanks to Inigo Quiles for his amazing articles
// "Smooth Voronoi"  https://iquilezles.org/articles/smoothvoronoi


vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float sm_vr (in vec2 st) {
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);

    float c = 0.;
    for (int j=-1; j<=1; j++ ) {
        for (int i=-1; i<=1; i++ ) {
            vec2 neighbor = vec2(float(i),float(j));
            vec2 point = random2(i_st + neighbor);
            point = 0.5 + 0.5*sin(iTime + 6.2831*point);
            vec2 diff = neighbor + point - f_st;
            float dist = length(diff)+(sin(iTime*length(random2(i_st + neighbor)))*0.25+0.25);
            c +=  exp( -16.*dist );
        }
    }
    return -(1.0/16.)*log(c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 st = fragCoord.xy/iResolution.xy;
    st.x *= iResolution.x/iResolution.y;
    vec3 color = vec3(0.388, 0.337, 0.161);

    // Scale
    st *= 7.;

    float c=0.;
    for (float i = 3.;i >= 0.; i--)   {
        float vr = sm_vr(st*pow(2.,i)+vec2(sin(iTime)+iTime,0.));
        vr = smoothstep(0.,1.5,vr*(sin(iTime+i)+4.25)*0.25);
        c = mix(c,vr,1.0-smoothstep(0.4,0.5,vr));
        c = (c + 0.325)*(1.-i*0.25);

    }
    color = vec3(0.494, 0.569, 0.541)*(c);
//    color = vec3(0.769, 0.106, 0.106)*(c);
//    color = vec3(0.443, 0.612, 0.435)*(c);
//    color = vec3(0.769, 0.106, 0.106)*(c);


    fragColor = vec4(color,1.0);
}