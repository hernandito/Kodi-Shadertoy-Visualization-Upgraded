#define T iTime*.5
#define PI 3.141596
#define S smoothstep

mat2 rotate(float a){
  float s = sin(a);
  float c = cos(a);
  return mat2(c,-s,s,c);
}

// knighty  https://www.shadertoy.com/view/XlX3zB
vec3 fold(vec3 p) {
	vec3 nc = vec3(-.5, -.809017, .309017);
	for (int i = 0; i < 5; i++) {
		p.xy = abs(p.xy);
		p -= 2.*min(0., dot(p, nc))*nc;
	}
	return p - vec3(0, 0, 1.275);
}

vec4 map(vec3 p) {
  vec3 q = p;
  q.xz *= rotate(T*.2);
  q.yz *= rotate(T*.2);

  q = fold(q)-vec3(2.);
  q += cos(q.zxy*3.+T)/1.3;   // xor's turbulence twist ring
  q = fold(q)-vec3(2.);      // let's add more fold,  LoL

  float d = length(vec2(length(q.xy)-2., q.z))-.2;
  vec3 col = sin(vec3(3,2,1)+dot(p,p)*.1+T)*.5+.5;
  return vec4(col, d);
}

// https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0);
    const float eps = 0.0005;
    return normalize( 
            e.xyy*map( pos + e.xyy*eps ).w + 
					  e.yyx*map( pos + e.yyx*eps ).w + 
					  e.yxy*map( pos + e.yxy*eps ).w + 
					  e.xxx*map( pos + e.xxx*eps ).w );
}

float rayMarch(vec3 ro, vec3 rd, float zMin, float zMax){
  float z = zMin;
  for(float i=0.;i<100.;i++){
    vec3 p = ro + rd * z;
    float d = map(p).w;
    d *= .5;
    if(d<1e-3 || z>zMax) break;
    z += d;
  }

  return z;
}


void mainImage(out vec4 O, in vec2 I){
  vec2 R = iResolution.xy;
  vec2 uv = (I*2.-R)/R.y;

  O.rgb *= 0.;
  O.a = 1.;

  vec3 ro = vec3(0.,0.,-13.);
  if(iMouse.z>0.){
      ro.z = -4.;
  }

  vec3 rd = normalize(vec3(uv, 1.));

  float zMax = 50.;

  float z = rayMarch(ro, rd, 0.1, zMax);

  vec3 col = vec3(0);
  if(z<zMax) {
    vec3 p = ro + rd * z;
    vec3 nor = calcNormal(p);
    vec3 objColor = map(p).rgb;

    vec3 l_dir = normalize(vec3(4,4,-4)-p);
    float diff = max(0., dot(l_dir, nor));

    // float spe = pow(max(0., dot(reflect(-l_dir, nor), -rd)), 5.);
    float spe = pow(max(0., dot(normalize(l_dir-rd), nor)), 30.);

    col = (.5+diff+spe)*objColor;
  }

  //col *= exp(-1e-4*z*z*z);
  col = pow(col, vec3(.5));
  O.rgb = col;

}