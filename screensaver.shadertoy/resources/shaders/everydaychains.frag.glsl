// Day 49!
// A bit of work with modeling, animation, effects.iTime

# define res iResolution.xy

mat2 rotMat(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

// iquilezles.org/articles/distfunctions2d
float sdEllipse( in vec2 p, in vec2 ab )
{
    p = abs(p); if( p.x > p.y ) {p=p.yx;ab=ab.yx;}
    float l = ab.y*ab.y - ab.x*ab.x;
    float m = ab.x*p.x/l;      float m2 = m*m; 
    float n = ab.y*p.y/l;      float n2 = n*n; 
    float c = (m2+n2-1.0)/3.0; float c3 = c*c*c;
    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;
    float co;
    if( d<0.0 )
    {
        float h = acos(q/c3)/3.0;
        float s = cos(h);
        float t = sin(h)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
        float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
    }
    vec2 r = ab * vec2(co, sqrt(1.0-co*co));
    return length(r-p) * sign(p.y-r.y);
}

float sdChain(vec2 p, out int id) {
    vec2 q = p;
    vec2 b = vec2(0.3, 0.25);
    
    p.x = mod(p.x, b.x * 2.0) - b.x;
    float d1 = abs(sdEllipse(p, b - 0.1)) - 0.02;
    
    p = q - vec2(b.x, 0.0);

    p.x = mod(p.x, b.x * 2.0) - b.x;   
    float d2 = abs(sdEllipse(p, b - 0.1)) - 0.02;
    
    d1 = max(d1, -d2 + 0.01);
    
    float d = d1;
    id = 0;
    
    if(d2 < d) { d = d2; id = 1; }
    
    return d;
}

float map(vec2 p, out int id) {
    vec2 q = p;
    
    float d0 = 1e+10;
    
    float a = 1.0;
    float b = 6.0;
    
    for(int i = 0; i < 4; i++) {  
        q = p;
        
        if(d0 - 0.02 <= 0.0) break;
        int nId;
        
        float t = 0.8;
        p.y += sin(p.x) * 0.3;

        p = vec2(p.x * a, mod(p.y * a, t) - t * 0.5);
        float d = sdChain(p, nId);
        p = q;
        
        d0 = d;
        id = nId;
        
        a *= 2.0;
        b += cos(float(i + 1)) * float(i);
        mat2 rot = rotMat(b);
        p += vec2(iTime*.1, 0.0) * rot / float(i + 1) * 0.2;
        p *= rot;
    }
    
    return d0;
}

float map(vec2 p) {
    int i; return map(p, i);
}

vec2 getNormal(in vec2 p) {
    const float eps = 0.0001;
    float dx = map(p + vec2(eps, 0.0)) - map(p - vec2(eps, 0.0));
    float dy = map(p + vec2(0.0, eps)) - map(p - vec2(0.0, eps));
    return normalize(vec2(dx, dy));
}

void mainImage( out vec4 O, in vec2 I )
{
    vec2 p = 2.0 * (I - 0.5 * res) / res.y * rotMat(cos(iTime*.1 * 0.2) * 2.0);
    p -= vec2(iTime*.1, 0.0);
    
    // Coloring.
    // Trying to get one bit of a different object to cut into the previous.
    int id0;
    int id1;
    int id2;

    float d = map(p, id0);

    vec2 normal = getNormal(p);
    float d2 = map(p + normal * 0.005, id1);
    float d3 = map(p - normal * 0.005, id2);
    
    float t = 1.0 - smoothstep(0.0, 3.0 / res.y, d);
    
    float edge = 1.0;
    if(id0 != id1 || id0 != id2) {
        edge = smoothstep(0.0, 3.0 / res.y, d2 - d);
    }

    vec3 col;
    col = vec3(0.9, 0.9, 0.9) * t * edge + vec3(0.0, 0.2, 0.3) * (1.0 - t) * edge;

    O = vec4(col, 1.0);
}