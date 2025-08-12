#ifdef GL_ES
precision mediump float;
#endif

// Robust Tanh Approximation
const float EPSILON = 1e-6; // A small epsilon to prevent division by zero or very small numbers
vec4 tanh_approx(vec4 x) {
    return x / (1.0 + max(abs(x), EPSILON));
}

// --- Custom GLSL ES 1.00 Compatible Functions ---
// Custom round function for GLSL ES 1.00
float custom_round(float x) {
    return floor(x + 0.5);
}

// Custom round function for vec3 (added for compatibility)
vec3 custom_round(vec3 x) {
    return floor(x + 0.5);
}

// --- Common Tab Utilities ---
const float PI = 3.14159265359;
const float TAU = PI * 2.0;

// "Function Smoothing Explained!" The Art of Code iTime
// https://www.youtube.com/watch?v=YJ4iyff7zbk
float smin(float a, float b, float k){
    float h = max(0.0, min(1.0, (b-a)/max(k, EPSILON) + 0.5)); // Robust division
    float m = h * (1.0 - h) * k;
    return h * a + (1.0 - h) * b - m * 0.5;
}

float smax(float a, float b, float k){
    return smin(a, b, -k);
}

float sabs(float x, float k) {
    float a = (0.5 / max(k, EPSILON)) * x * x + k * 0.5; // Robust division
    float b = abs(x);
    return b < k ? a : b;
}

vec3 pow_mix(vec3 colA, vec3 colB, float h){
    float baseg = 4.0;
    float f = pow(sabs(h-0.5, 0.5)*2.0, 0.4545);
    vec3 gamma = (vec3(baseg)-f*(baseg-1.0))*2.2+2.2;
    colA = pow(colA, 1.0/max(gamma, EPSILON)); // Robust division
    colB = pow(colB, 1.0/max(gamma, EPSILON)); // Robust division
    return pow(mix(colA, colB, h), gamma*f);
}

// "hash11()" - "hash44()"
// by David Hoskins
// https://www.shadertoy.com/view/4djSRW
float hash11(float p){
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
float hash13(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash21(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}
vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

// Custom rotation function for vec2 (used in camera)
void R(inout vec2 p, float a) {
    p = cos(a) * p + sin(a) * vec2(p.y, -p.x);
}

// Binary Union for vec4 (distance, color) - selects the closer object's properties
vec4 bUni(vec4 a, vec4 b){
    return a.x < b.x ? a : b;
}

// from iq
// https://iquilezles.org/articles/distfunctions/
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// Reverted linearstep back to macro for Kodi compatibility
#define linearstep(edge0, edge1, x) min(max((x - edge0) / max((edge1 - edge0), EPSILON), 0.0), 1.0)


// --- Image Tab Code ---

#define DIST_MIN 0.0001
#define DIST_MAX 8.0
#define COL_AMB (vec3(0.486,0.867,0.996)*(1.0/PI)*2.0)
#define COL_L0 vec3(1.000,0.965,0.898)
#define COL_FLR vec3(0.792,0.769,0.780)*(1.0/PI)
#define COL_S1 vec3(0.75)*(1.0/PI)
#define COL_S2 vec3(0.031,0.741,0.020)*(1.0/PI)
#define COL_S3 vec3(0.435,0.827,0.290)*(1.0/PI)
#define COL_S4 vec3(0.545,0.302,1.000)*(1.0/PI)

// --- FOV Adjustment Parameter ---
// FOV_ADJUSTMENT: Adjusts the Field of View (FOV).
// A higher value will "zoom in" (narrower FOV).
// A lower value will "zoom out" (wider FOV).
// Default: 1.0 (original FOV)
#define FOV_ADJUSTMENT 1.10
// --------------------------------

// --- Horizon Tilt Parameter ---
// HORIZON_TILT_DEGREES: Tilts the horizon line by rotating the camera's view.
// Value in degrees (e.g., 1.5 for a subtle tilt).
#define HORIZON_TILT_DEGREES 1.75
// ------------------------------

// from blackle
// https://www.shadertoy.com/view/Wl3fD2
float nonZeroSign(float x) {
    return x < 0.0 ? -1.0 : 1.0;
}
vec3 neighbor_cell(vec3 p, float cellsize) {
    vec3 ap = abs(p);
    vec3 off = vec3(0.0);
    if (ap.x >= max(ap.z, ap.y)) off = vec3(nonZeroSign(p.x), 0.0, 0.0);
    if (ap.y >= max(ap.z, ap.x)) off = vec3(0.0, nonZeroSign(p.y), 0.0);
    if (ap.z >= max(ap.x, ap.y)) off = vec3(0.0, 0.0, nonZeroSign(p.z));
    return p - off * cellsize;
}

float bUniSink(float a, float b, float r, float n) {
  vec2 p = vec2(a, b);
  float rad = r * sqrt(2.0) / (2.0 + sqrt(2.0));
  p.x -= sqrt(2.0) / 2.0 * r;
  p.x += rad * sqrt(2.0);
  p.y -= rad;
  float d = length(p + vec2(0.0, n)) - rad;
  d = min(d, a);
  return d;
}

float grid_spheres(vec3 p){
    
    vec3 ip = custom_round(p/0.65); // Changed round() to custom_round()
    ip = clamp(ip, vec3(-1.0), vec3(1.0));
    p -= ip*0.65;
    return length(p)-0.2;
}

float vox_map(vec3 p, float cellsize){
    
    float anim_dist = 25.854;
    // metaball
    float vd = DIST_MAX;
    for(int i=0; i<8; i++){
        float u_time = iTime * 0.25 + 1.0 + float(i);
        vd = smin(length(p+vec3(sin(u_time*1.0), sin(u_time*1.0*2.5)*1.5,cos(u_time*1.0))*0.025*anim_dist)-0.025*(9.0+sin(float(i*4)*4.0)), vd, 1.5);
    }
        
    // avoid the spheres
    float sd = grid_spheres(p);
    vd = bUniSink(vd, sd-0.025, 0.283, 0.0);
    
    return vd;
}
vec3 g_vox = vec3(0.0);
bool is_primary = true;
float tsubu(vec3 p){

    float cellsize = 0.015;

    vec3 vox = custom_round(p/cellsize); // Changed round() to custom_round()
    if(is_primary) g_vox = vox;
    
    vec3 fp = p;
    fp -= vox * cellsize;

    vec2 hs = hash22((vox.xz * (vox.y + 100.0) + 2.0));

    float vd = vox_map(p, cellsize);
    
    float ivd = vox_map(vox * cellsize, cellsize);

    bool is_empty = hs.x > 0.3 + sin(iTime) * 0.05;
    is_empty = is_empty || ivd > 0.0;

    float r = cellsize * 0.25;
    r = cellsize * ((0.5 + 0.5 * hs.y) * 0.4 + 0.1);

    vec3 off = vec3(hs * 2.0 - 1.0, (hs.x * hs.y + 0.5) - 1.0) * (cellsize * 0.4 - r);

    float fd = abs(vd + cellsize) + DIST_MIN * 2.0;
    bool is_box = false;
#define BOX
    // current cell
    if(!is_empty){
        if(is_box)
            fd = min(sdBox(fp+off, vec3(r-cellsize*0.1))-cellsize*0.1, fd);
        else
            fd = min(length(fp+off)-r, fd);
    }
    

#if 0
    fd = min(abs(length(fp)-cellsize*0.5)+DIST_MIN*2.0, fd);
#elif 0
    fd = min(abs(sdBox(fp, vec3(cellsize*0.5-DIST_MIN*1.0)))+DIST_MIN*16.0, fd);
#else
    // neighbor distance
    vec3 np = neighbor_cell(fp, cellsize);
    float nd;
    if(is_box)
        nd = sdBox(np, vec3(cellsize*0.5))+DIST_MIN*2.0;
    else
        nd = length(np)-cellsize*0.5+DIST_MIN*2.0;
    nd = abs(nd)+DIST_MIN*16.0;
    fd = min(fd, nd);
#endif

    fd = max(fd, vd-cellsize*0.5);
    return fd;

}

vec4 map(vec3 p){
    float d = DIST_MAX;
    vec4 res = vec4(tsubu(p), COL_S2);
    res = bUni(vec4(grid_spheres(p), COL_S1), res);
    return res;
}

vec3 ro = vec3(0.0);
vec3 rd = vec3(0.0);
vec4 intersect(vec3 ro_in, vec3 rd_in){
    float d = 1.0;
    vec3  m = vec3(0.0);
    for (int i = 0; i < 400; i++){
        vec4 res = map(ro_in + d * rd_in);
        m = res.yzw;
        if(res.x < DIST_MIN) break;
        d += res.x;
        if (d >= DIST_MAX) break;
    }
    return vec4(d,m);
}

vec3 normal(vec3 p){
    // Copy from iq shader.
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    // Rewritten bitwise operations for GLSL ES 1.00 compatibility
    for( int i=0; i<4; i++ ){
        vec3 e_val;
        if (i == 0) e_val = vec3(0.5773, -0.5773, -0.5773);
        else if (i == 1) e_val = vec3(-0.5773, -0.5773, 0.5773);
        else if (i == 2) e_val = vec3(-0.5773, 0.5773, -0.5773);
        else /* i == 3 */ e_val = vec3(0.5773, 0.5773, 0.5773);

        n += e_val * map(p + 0.0005 * e_val).x;
    }
    return normalize(n);
}

// borrowed from here:
// https://www.shadertoy.com/view/lsKcDD
float calcSoftshadow( in vec3 ro_in, in vec3 rd_in, in float mint, in float tmax, in float w)
{
    float res = 1.0;
    float t = mint;
    float ph = 1e10; // big, such that y = 0 on the first iteration
    
    for( int i=0; i<200; i++ )
    {
        float h = map( ro_in + rd_in*t ).x;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, d/(w*max(0.0,t-y)) );
        ph = h;
        
        t += h;
        
        if( abs(res)<0.001 || t>tmax ) break;
        
    }
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}


// "Multi Level AO" by iY0Yi
// https://www.shadertoy.com/view/fsBfDR
float aoSeed = 0.0;
const float MAX_SAMP = 24.0;
float ao(vec3 p, vec3 n, float sphereRadius) {
    float ao_val = 0.0;
    for(float i = 0.0; i <= MAX_SAMP; i++) {
        vec2 rnd = hash21((i + 1.0) + aoSeed);

        float scale = (i + 1.0)/MAX_SAMP;
        scale = mix(0.0, 1.0, pow(scale, 0.5));

        rnd.x = (rnd.x * 2.0 - 1.0) * PI * 0.5;
        rnd.y = (rnd.y * 2.0 - 1.0) * PI;
        vec3 rd_ao = normalize(n + hash21(i + 2.0 + aoSeed).xyx);
        rd_ao.xy *= mat2(cos(rnd.x), sin(rnd.x), -sin(rnd.x), cos(rnd.x));
        rd_ao.xz *= mat2(cos(rnd.y), sin(rnd.y), -sin(rnd.y), cos(rnd.y));

        rd_ao *= sign(dot(rd_ao, n));

        float raylen = sphereRadius * scale;
        vec3 rndp = p + normalize(n + rd_ao) * raylen;
        float res = map(rndp).x;
        ao_val += res;
        aoSeed+=123.57;
    }
    return ao_val/MAX_SAMP;
}

// https://hanecci.hatenadiary.org/entry/20130505/p2
// http://www.project-asura.com/program/d3d11/d3d11_006.html
float normalizedBlinnPhong(float shininess, vec3 n, vec3 vd, vec3 ld){
    float norm_factor = (shininess+1.0) / (2.0*PI);
    vec3 h  = normalize(-vd+ld);
    return pow(max(0.0, dot(h, n)), shininess) * norm_factor;
}
vec3 render(vec2 uv){

    // ray march
    vec4 res = intersect(ro, rd);
    is_primary = false;
    
    vec3 pos = ro + res.x * rd;
    vec3 m = res.yzw;
    vec3 col = COL_AMB;
    if (res.x<DIST_MAX){
        vec3 n = normal(pos);

        vec3 ldir = normalize(vec3(-0.5, 0.85, -0.5));
        
        // diffuse
        float diff = max(0.0, dot(n, ldir))*(1.0/PI);
        float indr = (dot(n, -ldir)*0.5+0.5)*(1.0/PI);
        
        // specular
        float rgh = (distance(m, COL_S2)<0.05) ? 0.005 : 0.0003;
        float spec = normalizedBlinnPhong(1.0/max(rgh, EPSILON), n, rd, ldir);
        
        // ao
        float a = linearstep(0.0, 1.0, ao(pos, n+(hash33(pos*vec3(123.45,321.532,753.213)))*0.25, 0.2));
        
        // shadow
        float off = (length(m-COL_S2)<0.1) ? 0.00025 : 0.0001;
        float sdw = calcSoftshadow( pos+n*off, ldir, 0.01, 5.0, 0.001);
        
        // composite
        col = diff*sdw*12.0*vec3(1.000,0.965,0.761);
        a = mix(1.0, a, 0.980);
        col += mix(COL_AMB,vec3(1.0),0.25)*4.0*a;
        
        bool is_tsubu = length(m-COL_S2)<0.1;
        if(!is_tsubu)
        {
            // fake bounce light ;)
            // this works in 2 materials scene only.
            float d_tsubu = tsubu(pos);
            col += mix(COL_AMB, COL_S3, 0.9) * 1.0 * pow(smoothstep(0.5,0.1,d_tsubu),2.0)*smoothstep(0.3,0.0,a) * (indr*0.5+0.5);
            col += mix(COL_AMB, COL_S2, 0.9) * 2.0 * indr*pow(smoothstep(0.5,0.1,d_tsubu),2.0)*smoothstep(0.3,0.0,a) * (indr*0.5+0.5);
        }
        col *= m + (is_tsubu ? hash33(g_vox)*0.025 : vec3(0.0));
        col += spec * 3.0 * sdw;

        // fog
        col = mix(col, COL_AMB, min(1.0, pow(length(pos-ro)/7.5, 8.0)));
    }
    return col;
}

// "Physically-based SDF" by romainguy:
//https://www.shadertoy.com/view/XlKSDR
vec3 ACESFilm(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x * (a * x + b))/max((x * (c * x + d) + e), EPSILON); // Robust division
}

void camera(vec2 uv) {
    float pY = 0.25;
    float cL = 4.0;
    vec3 focus = vec3(0.0);
    float fov = 0.4 * FOV_ADJUSTMENT; // Apply FOV_ADJUSTMENT here
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 pos = vec3(0.0, 0.0, -1.0) * cL;
    R(pos.xz, iTime*.2*0.5);
    
    if(iMouse.z > 0.5) {
        pos = vec3(
            -sin(iMouse.x/iResolution.x * PI*2.0 + PI * 0.5),
            sin(iMouse.y/iResolution.y * PI * 2.0),
            -cos(iMouse.x/iResolution.x * PI*2.0 + PI * 0.5)
            ) * cL;
        R(pos.xz, PI);
    }
    
    // Apply horizon tilt here
    float tilt_radians = HORIZON_TILT_DEGREES * (PI / 180.0);
    R(uv, tilt_radians);

    vec3 dir = normalize(focus - pos);
    vec3 target = pos - dir;
    vec3 cw = normalize(target - pos);
    vec3 cu = normalize(cross(cw, up));
    vec3 cv = normalize(cross(cu, cw));
    mat3 camMat = mat3(cu, cv, cw);
    rd = normalize(camMat * normalize(vec3(sin(fov) * uv.x, sin(fov) * uv.y, -cos(fov))));
    ro = pos;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv = (uv*2.0-1.0)*iResolution.y/max(iResolution.x, EPSILON); // Robust division
    uv.x *= iResolution.x / max(iResolution.y, EPSILON); // Robust division
    camera(uv);
    vec3 col = render(uv);
    col *= smoothstep(1.5, 0.65, length(uv));
    
    col = ACESFilm(col);
    
    col = mix(col, smoothstep(0.0, 1.0,col), 0.25);

    fragColor = vec4(pow(col,vec3(0.4545)),1.0);
}
