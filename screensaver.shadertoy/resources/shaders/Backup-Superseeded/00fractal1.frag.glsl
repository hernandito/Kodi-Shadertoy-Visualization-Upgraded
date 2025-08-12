
/*
   Different distance estimations from:http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/

 * z = r*(sin(theta)cos(phi) + i cos(theta) + j sin(theta)sin(phi)
 * zn+1 = zn^8 +c
 * z^8 = r^8 * (sin(8*theta)*cos(8*phi) + i cos(8*theta) + j sin(8*theta)*sin(8*theta)
 * zn+1' = 8 * zn^7 * zn' + 1


*/

float stime, ctime;
bool is_julia = true;
vec3 julia = vec3(-0.6,-0.8,0.7);

vec3 gradient;

#define EPS 0.0001

void ry(inout vec3 p, float a){  
    float c,s;vec3 q=p;  
    c = cos(a); s = sin(a);  
    p.x = c * q.x + s * q.z;  
    p.z = -s * q.x + c * q.z; 
}  

void rx(inout vec3 p, float a){  
    float c,s;vec3 q=p;  
    c = cos(a); s = sin(a);  
    p.y = c * q.y - s * q.z;  
    p.z = s * q.y + c * q.z; 
}  

vec3 hash3(float n){
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(43758.5453123, 22578.1459123, 19642.3490423));
}

float hash(vec2 p){
    float h=dot(p,vec2(127.1, 311.7));
    return -1.0+2.0*fract(sin(h)*43758.5453123);
}

float noise(vec2 p){
   vec2 i=floor(p);
   vec2 f=fract(p);
   vec2 u=f*f*(3.0-2.0*f);
   return mix(mix(hash(i+vec2(0.0,0.0)), hash(i+vec2(1.0,0.0)), u.x),
              mix(hash(i+vec2(0.0,1.0)), hash(i+vec2(1.0,1.0)), u.x),
              u.y);
}
	
float plane(vec3 p, float y) { return distance(p, vec3(p.x, y, p.z)); }

vec3 bulb_power(vec3 z, float power) {
    float r = length(z);

    float theta = acos(z.y / r) * power;
    float phi = atan(z.z, z.x) * power;

    return pow(r, power) * vec3(sin(theta)*cos(phi), cos(theta), sin(theta)*sin(phi));
}


/* method 1: the potential gradient approximation -------------------------------------------*/ 
// use gradient.
float _sinh(float x) {
    return 0.5 * (exp(x) - exp(-x));
}

vec3 potential(vec3 p) {
    vec3 z = p;
    float power = 8.0;
    float t0 = 1.0;
    float r;
    float iter = 0.0;
	vec3 c = p;
	if(is_julia)
		c = julia;
	julia.y = stime;
	julia.x = ctime;

    for(int i = 1; i < 8; ++i) {
        z = bulb_power(z, power) + c;
        r = length(z);
		ry(z, stime);
        // orbit trap to mimic ao
        t0 = min(t0, r);

        if(r > 2.0) {
            iter = float(i);
            break;
        }
    }
    return vec3(log(r) / pow(power, iter), t0, 0.0);
}

vec3 mb_p(vec3 p) {
    vec3 pt = potential(p);
    if(pt.x == 0.0) return vec3(0.0);
    vec3 e=vec3(EPS,0.0,0.0); 
    gradient = (vec3(potential(p+e.xyy).x, 
                potential(p+e.yxy).x, 
                potential(p+e.yyx).x) 
            - pt.x) / e.x; 
    return vec3((0.5 / exp(pt.x)) * _sinh(pt.x) / length(gradient), pt.y, pt.z); /* syntopia method */
    /*return vec3((0.5 * pt.x) / length(gradient), pt.y, pt.z);*/  /* quilez method */
}
/* the potential gradient approximation -------------------------------------------*/ 




/* method 2: the scalar distance estimator------------------------------------------------*/
/* the normal is calculated by central difference */
vec3 mb_s(vec3 p) {
    /*p.xyz=p.xzy;*/
    vec3 z = p;
    float power = 8.0;
    float r, theta, phi;
    float dr = 1.0;
	vec3 c = p;
	if(is_julia)
		c = julia;
    float t0 = 1.0;
	julia.y = stime;
	julia.x = ctime;
	julia.z = 0.5*cos(stime);

    for(int i = 0; i < 7; ++i) {
        r = length(z);
        if(r > 2.0) continue;

        dr = pow(r, power - 1.0) * dr * power + 1.0; 

        theta = acos(z.y / r) * power;
        phi = atan(z.z, z.x) * power;
        r = pow(r, power);
        z = r * vec3(sin(theta)*cos(phi), cos(theta), sin(theta)*sin(phi)) + c;
        ry(z, stime);

        // the Positive-z variation
        /*theta = atan(z.y, z.x) * power;*/
        /*phi = asin(z.z/ r) * power;*/
        /*r = pow(r, power);*/
        /*z = r * vec3(cos(theta)*cos(phi), sin(theta)*cos(phi), sin(phi)) + p;*/
        t0 = min(t0, length(z));
    }
    return vec3(0.5 * log(r) * r / dr, t0, 0.0);
}
/* the scalar distance estimator------------------------------------------------*/




/* method 3: the escape length approximation -------------------------------------------*/ 
/* reffered to as Makin/Buddhi 4-point Delta-DE formula */
int last = 0; // global to ensure evaluating the escape length at the same iteration each time
vec3 escape_length(vec3 p) {
    vec3 z = p;
    float power = 8.0, r;
    float t0 = 1.0;
	vec3 c = p;
	if(is_julia)
		c = julia;

    for(int i = 1; i < 8; ++i) {
        z = bulb_power(z, power) + c;
        r = length(z);
        t0 = min(t0, r);
        
        if ((r > 2.0 && last == 0) || (i == last))
        {
            last = i;
            return vec3(r, t0, 0.0);
        }
    }
    return vec3(length(z), 0.0, 0.0);
}

vec3 mb_e(vec3 p) {
    last = 0;
    vec3 el = escape_length(p);
    if(el.x * el.x < 2.0) return vec3(0.0);
    vec3 e=vec3(EPS,0.0,0.0); 
    gradient = (vec3(escape_length(p+e.xyy).x, escape_length(p+e.yxy).x, escape_length(p+e.yyx).x) - el.x) / e.x; 
    return vec3(0.5 * el.x * log(el.x) / length(gradient), el.y, el.z); 
}
/* the escape length approximation -------------------------------------------*/ 


vec3 f(vec3 p){ 
    vec2 uv=p.xz*1.0;
	float noi = noise(uv);
	noi = 0.5 + 0.5 * noi;
  
   float a=plane(vec3(p.x, p.y + noi * 0.2, p.z), -0.71);
	
	
	//ry(p, stime * 0.5);
	p.yz = p.zy;
    
	//p.x = mod(p.x, 3.0) - 1.5;
	p.y = mod(p.y, 2.0) - 1.0;
	//p.xz = mod(p.xz, 8.0) - 4.0;
	
	//p.yz = -p.zy;
    vec3 b = mb_s(p);
	vec3 res = vec3(a, 0.8, 1.0);
	if(a > b.x)
		res = b;
	return res;

}


float softshadow(vec3 ro, vec3 rd, float k ){ 
    float akuma=1.0,h=0.0; 
    float t = 0.01;
    for(int i=0; i < 32; ++i){ 
        h=f(ro+rd*t).x; 
        if(h<0.001)return 0.02; 
        akuma=min(akuma, k*h/t); 
        t+=clamp(h,0.01,2.0); 
    } 
    return akuma; 
} 
vec3 nor(vec3 p){ 
    vec3 e=vec3(EPS,0.0,0.0); 
    return normalize(vec3(f(p+e.xyy).x-f(p-e.xyy).x, 
                f(p+e.yxy).x-f(p-e.yxy).x, 
                f(p+e.yyx).x-f(p-e.yyx).x)); 
} 


vec3 intersect( in vec3 ro, in vec3 rd )
{
    float t = 0.0;
    vec3 res = vec3(-1.0);
    vec3 h = vec3(1.0);
    for( int i=0; i<196; i++ )
    {
		// To avoid compiler bug
        if( h.x<0.0006 || t>20.0 ) {
           
        }
		else{
        	h = f(ro + rd*t);
        	res = vec3(t,h.yz);
        	t += h.x;  // marching
		}
    }
    if( t>20.0 ) res=vec3(-1.0);
    return res;
}

vec3 lighting(in vec3 p, in vec3 n, in vec3 rd, in float ao) {
	vec3 l1_pos = normalize(vec3(0.0, 0.8, 1.8)) * 11.0;
	vec3 l1_dir = normalize(l1_pos - p);
    vec3 l1_col = vec3(1.37, 0.99, 0.79);
	
    vec3 l2_dir = normalize(vec3(0.0, -0.8, -1.8));
    vec3 l2_col = vec3(1.19, 0.99, 1.0); 
    
    float shadow = softshadow(p, l1_dir, 10.0 );

    float dif1 = max(0.0, dot(n, l1_col));
    float dif2 = max(0.0, dot(n, l2_col));
    float bac1 = max(0.3 + 0.7 * dot(vec3(-l1_dir.x, -1.0, -l1_dir.z), n), 0.0);
    float bac2 = max(0.2 + 0.8 * dot(vec3(-l2_dir.x, -1.0, -l2_dir.z), n), 0.0);
    float spe = max(0.0, pow(clamp(dot(l1_dir, reflect(rd, n)), 0.0, 1.0), 10.0)); 

    vec3 col = 2.3 * l1_col * dif1 * shadow;
    col += 1.4 * l2_col * dif2 * ao;
    col += 0.7 * bac1 * l1_col * ao;
    col += 0.7 * bac2 * l2_col * ao; 
    col += 6.0 * spe * vec3(1.0, 0.84313, 0.0); 
    
	ao = pow(clamp(ao, 0.0, 1.0), 2.55);
	vec3 tc0 = 0.5 + 0.5 * sin(3.0 + 3.7 * ao + vec3(1.4, 0.0, 0.0));
	vec3 tc1 = 0.5 + 0.5 * sin(3.0 + 3.9 * ao + vec3(1.0, 0.84313, 0.0));
	col *= 0.2 * tc0 * tc1;
	
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{ 
    vec2 q=fragCoord.xy/iResolution.xy; 
    vec2 uv = -1.0 + 2.0*q; 
    uv.x*=iResolution.x/iResolution.y; 
    // camera
    stime=sin(iTime*0.01); 
    ctime=cos(iTime*0.01); 

    vec3 ta=vec3(0.0,0.3-0.3*ctime,-4.0); 
	//vec3 ta = vec3(0.0);
    vec3 ro = vec3(5.0 * stime, 2.0, 1.0 * ctime);

    vec3 cf = normalize(ta-ro); 
    vec3 cs = normalize(cross(cf,vec3(0.0,1.0,0.0))); 
    vec3 cu = normalize(cross(cs,cf)); 
    vec3 rd = normalize(uv.x*cs + uv.y*cu + 7.8*cf);  // transform from view to world

    vec3 bg = vec3(0.0, 0.0, 0.0);

    float halo=clamp(dot(normalize(vec3(-ro.x, -ro.y, -ro.z)), rd), 0.0, 1.0); 
    vec3 col=bg+vec3(0.3, 0.0, 0.0) * pow(halo,9.0); 


    float t=0.0;
    vec3 p=ro; 
    float normal_back_step = 1.0;


    vec3 res = intersect(ro, rd);
	float ao = res.y;
	
    if(res.x > 0.5){
        p = ro + res.x * rd;
        vec3 n=nor(p);   // for mb_s
		//vec3 n = normalize(gradient);  // for mb_p and mb_e
       	col = lighting(p, n, rd, ao);
        col=mix(col,bg, 1.0-exp(-0.01*res.x*res.x)); 
    }

    // post
    col=pow(clamp(col,0.0,1.0),vec3(0.45)); 
    col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
    col=mix(col, vec3(dot(col, vec3(0.33))), -0.5);  // satuation
    col*=0.5+0.5*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
    fragColor=vec4(col.x,col.y,col.z,1.0); 
}
