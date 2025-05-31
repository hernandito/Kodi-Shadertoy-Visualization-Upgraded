/*
	Perspex Web Lattice (Modified - Animation Speed, Cell Size, and Lattice Fill)
	-------------------
	
	Modified to slow down animation, increase the number of visible lattice cells (reduce cell size),
	scale down border outlines/shadows/specular highlights proportionally, and further darken the lattice fill
	while reducing iChannel0 visibility more.
	Original: https://www.shadertoy.com/view/Mld3Rn
*/

#define FAR 2.

int id = 0; // Object ID - Red perspex: 0; Black lattice: 1.

// Animation speed multiplier (adjust this value to slow down or speed up: < 1.0 slows down, > 1.0 speeds up)
float animation_speed = 0.2;

// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){
   
    n = max((abs(n) - .2), .001);
    n /= (n.x + n.y + n.z ); // Roughly normalized.
    
	p = (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
    
    return p*p;
}

// Compact, self-contained version of IQ's 3D value noise function.
float n3D(vec3 p){
    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

// vec2 to vec2 hash.
vec2 hash22(vec2 p) { 
    float n = sin(dot(p, vec2(41, 289)));
    p = fract(vec2(262144, 32768)*n); 
    return sin(p*6.2831853 + iTime*animation_speed)*.45 + .5; 
}

// 2D 2nd-order Voronoi.
float Voronoi(in vec2 p){
    
	vec2 g = floor(p), o; p -= g;
	
	vec3 d = vec3(1);
    
	for(int y = -1; y <= 1; y++){
		for(int x = -1; x <= 1; x++){
            
			o = vec2(x, y);
            o += hash22(g + o) - p;
            
			d.z = dot(o, o);
            d.y = max(d.x, min(d.y, d.z));
            d.x = min(d.x, d.z); 
                       
		}
	}
	
    return max(d.y/1.2 - d.x*1., 0.)/1.2;
}

// The height map values (increased scale to show more cells).
float heightMap(vec3 p){
    
    id = 0;
    float c = Voronoi(p.xy*6.); // Increased from 4.0 to 8.0 to reduce cell size (more cells)
    
    if (c<.07) {c = smoothstep(0.7, 1., 1.-c)*.2; id = 1; }

    return c;
}

float m(vec3 p){
   
    float h = heightMap(p);
    
    return 1. - p.z - h*.1;
}

vec3 nr(vec3 p, inout float edge) { 
	
    vec2 e = vec2(.00525, 0); // Reduced from .005 to .0025 (scaled by 0.5) to match smaller cell size

    float d1 = m(p + e.xyy), d2 = m(p - e.xyy);
    float d3 = m(p + e.yxy), d4 = m(p - e.yxy);
    float d5 = m(p + e.yyx), d6 = m(p - e.yyx);
    float d = m(p)*2.;
     
    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
	
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

vec3 eMap(vec3 rd, vec3 sn){
    
    vec3 sRd = rd;
    rd.xy -= iTime*animation_speed*.25;
    rd *= 3.;
    
    float c = n3D(rd)*.57 + n3D(rd*2.)*.28 + n3D(rd*4.)*.15;
    c = smoothstep(0.5, 1., c);
    
    vec3 col = vec3(min(c*1.5, 1.), pow(c, 2.5), pow(c, 12.)).zyx;
    
    return mix(col, col.yzx, sRd*.25+.25); 
}

void mainImage(out vec4 c, vec2 u){

    vec3 r = normalize(vec3(u - iResolution.xy*.5, iResolution.y)), 
         o = vec3(0), l = o + vec3(0, 0, -1);
   
    vec2 a = sin(vec2(1.570796, 0) + iTime*animation_speed/8.);
    r.xy = mat2(a, -a.y, a.x) * r.xy;

    float d, t = 0.;
    
    for(int i=0; i<32;i++){
        
        d = m(o + r*t);
        if(abs(d)<0.001 || t>FAR) break;
        t += d*.7;

    }
    
    t = min(t, FAR);
    c = vec4(0);
    float edge = 0.;
    
    if(t<FAR){
    
        vec3 p = o + r*t, n = nr(p, edge);
        l -= p;
        d = max(length(l), 0.001);
        l /= d;

        float hm = heightMap(p);
        vec3 tx = tex3D(iChannel0, (p*2. + hm*.2), n);

        c.xyz = vec3(1.)*(hm*.8 + .2);
        // Apply texture influence differently for red perspex cells and lattice
        if (id == 0) {
            c.xyz *= vec3(1.5)*tx; // Original texture influence for red perspex cells
        } else {
            c.xyz *= vec3(0.3)*tx; // Further reduced from 0.5 to 0.3 for less iChannel0 visibility
        }
        
        c.x = dot(c.xyz, vec3(.299, .587, .114));
        if (id==0) c.xyz *= vec3(min(c.x*1.5, 1.), pow(c.x, 5.), pow(c.x, 24.))*2.;
        else c.xyz *= .03; // Further darkened the lattice fill (from .05 to .03)
        
        float df = max(dot(l, n), 0.);
        float sp = pow(max(dot(reflect(-l, n), -r), 0.), 64.);
        
        if(id == 1) sp *= sp;
        
        c.xyz = c.xyz*(df + .75) + vec3(1, .97, .92)*sp + vec3(.5, .7, 1)*pow(sp, 64.);
        
        vec3 em = eMap(reflect(r, n), n);
        if(id == 1) em *= .5;
        c.xyz += em;
        
        c.xyz *= 1. - edge*.8;
        c.xyz *= 1./(1. + d*d*.125);
    }
    
    c = vec4(sqrt(clamp(c.xyz, 0., 1.)), 1.);
}