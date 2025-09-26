// Shadertoy uniforms: iTime, iResolution
// Kodi compatible version with no uniforms

// ---------------- USER PARAMETERS ----------------
// Adjusts the field of view. Smaller values "zoom in," larger values "zoom out."
#define FOV 1.950 

// --- COLOR SELECTION ---
// Choose a color palette (0, 1, 2)
// 0: Green (Default)
// 1: Red/Orange
// 2: Blue/Cyan
#define COLOR_PALETTE_INDEX 1

// --- ORBIT PARAMETERS ---
// X-axis radius of the orbit ellipse. (Default: 6.0)
#define ORBIT_RADIUS_X 5.0
// Z-axis radius of the orbit ellipse. (Default: 4.0)
#define ORBIT_RADIUS_Z 3.50
// Controls how fast the ellipse itself rotates around the center. 
// Speed is defined as rotation angle (radians) per second. (Default: 1/60th of a rotation per second)
#define ORBIT_ROTATION_SPEED (22.0 / 60.0) 
// -------------------------------------------------
// --- BCS PARAMETERS ---
// Adjusts overall brightness (0.0 is no change, positive brightens, negative darkens)
#define BRIGHTNESS -0.15
// Adjusts contrast (1.0 is no change, > 1.0 increases contrast, < 1.0 decreases)
#define CONTRAST 1.30
// Adjusts saturation (1.0 is no change, > 1.0 increases saturation, 0.0 is grayscale)
#define SATURATION 0.50
// ----------------------

// --- DEFINED COLOR PALETTES ---
// Palette 0: Green (Original)
#define COLOR_P0_AMBIENT vec3(0.0, 0.7, 0.0)
#define COLOR_P0_DIFFUSE vec3(0.7, 0.5, 0.0)

// Palette 1: Red/Orange
#define COLOR_P1_AMBIENT vec3(0.7, 0.10, 0.0)
#define COLOR_P1_DIFFUSE vec3(1.50, 0.6, 0.1)

// Palette 2: Blue/Cyan
#define COLOR_P2_AMBIENT vec3(1.0, 0.6, 0.0)
#define COLOR_P2_DIFFUSE vec3(0.0, 0.8, 1.0)
// ------------------------------

struct Surface{
    vec3 col;
    float d;
};

mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

// Rotation matrix around the Y axis.
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

// Rotation matrix around the Z axis.
mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}


Surface sdSpher(vec3 p,float r,vec3 offset,vec3 col){
    return Surface(col,length(p-offset)-r);
}

Surface sdFloor(float p,vec3 col,float v){
    return Surface(col,p+v);
}

Surface sdBox( vec3 p, vec3 b, vec3 offset, vec3 col,mat3 tr)
{
    p = (p - offset)*tr;
    vec3 q = abs(p) - b;
    float d = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
    return Surface(col, d);
}


Surface sceleSurface(Surface Surface1,Surface Surface2){
    if(Surface1.d>Surface2.d)
        return Surface2;
    else
        return Surface1;
}

Surface mixcolor(Surface Surface1, Surface Surface2) {
    float k = 3.; // 减小 k 值以控制平滑范围
    float h = clamp(0.5 + 0.5 * (Surface1.d - Surface2.d) / k, 0., 1.);
    float sud = mix(Surface1.d, Surface2.d, h) - k * h * (1. - h); // 修正符号
    vec3 suc = mix(Surface1.col, Surface2.col, h); // 颜色无需修正项
    return Surface(suc, sud);
}

Surface sdScene(vec3 p){
    // Two fixed spheres (original)
    // The surface color is not used here for the spheres, but kept for structure.
    Surface sdSpher1=sdSpher(p,1.,vec3(-2.,0.,0.),vec3(1.,1.,0.));
    Surface sdSpher2=sdSpher(p,1.,vec3(2.,0.,0.),vec3(1.,0.,0.));
    
    // Calculate the elliptical orbit position based on time
    float orbital_speed = iTime / 12.0; // Fixed orbit speed around the ellipse (one full orbit every 4 seconds)
    
    float orbital_x = ORBIT_RADIUS_X * sin(orbital_speed); 
    float orbital_z = ORBIT_RADIUS_Z * cos(orbital_speed);
    vec3 circular_pos = vec3(orbital_x, 0., orbital_z);
    
    // Apply slow rotation of the entire elliptical path
    float rotation_angle = iTime * ORBIT_ROTATION_SPEED;
    mat3 slow_rotation = rotateY(rotation_angle);
    vec3 orbiterPos = circular_pos * slow_rotation;

    // The orbiting sphere is now on an elliptical path that slowly rotates
    Surface sdSphereOrbiter = sdSpher(p, 1.0, orbiterPos, vec3(0.,0.,1.));
    
    // Floor setup (kept from original to maintain structure)
    vec3 floorColor=vec3(mod(floor(p.x)+floor(p.z),2.));
    Surface sdFloor1=sdFloor(p.y,floorColor,3.);
    
    Surface sc=sceleSurface(sdSpher1,sdSpher2);
    sc=mixcolor(sdSphereOrbiter,sc);
    sc=sceleSurface(sdFloor1,sc);
    
    return sc;
}

// Function moved up to ensure it is defined before use
vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005; // epsilon
    return normalize(
        e.xyy * sdScene(p + e.xyy).d +
        e.yyx * sdScene(p + e.yyx).d +
        e.yxy * sdScene(p + e.yxy).d +
        e.xxx * sdScene(p + e.xxx).d);
}

Surface rayMraching(vec3 ro,vec3 rd){
    float depth=0.;
    Surface co;
    for(int i=0;i<=255;i++){
        vec3 p=ro+rd*depth;
        co=sdScene(p);
        depth+=co.d;
        if(co.d<=0.001||depth>=100.)
            break;
    }
    co.d=depth;
    return co;
}

vec3 phong(vec3 lightDir, vec3 normal, vec3 rd) {
    // Determine the color based on the selected palette index
    vec3 ambient_color;
    vec3 diffuse_color;

    // Use if/else if structure because GLSL does not support switch/case on non-constant indices
    if (COLOR_PALETTE_INDEX == 0) {
        ambient_color = COLOR_P0_AMBIENT;
        diffuse_color = COLOR_P0_DIFFUSE;
    } else if (COLOR_PALETTE_INDEX == 1) {
        ambient_color = COLOR_P1_AMBIENT;
        diffuse_color = COLOR_P1_DIFFUSE;
    } else { // Fallback to Palette 2 or any other index
        ambient_color = COLOR_P2_AMBIENT;
        diffuse_color = COLOR_P2_DIFFUSE; // <-- FIXED: Was diffense_color
    }

    // ambient iTime
    float k_a = 0.6;
    vec3 ambient = k_a * ambient_color;

    // diffuse
    float k_d = 0.5;
    float dotLN = clamp(dot(lightDir, normal), 0., 1.);
    vec3 diffuse = k_d * dotLN * diffuse_color;

    // specular
    float k_s = 0.6;
    float dotRV = clamp(dot(reflect(lightDir, normal), -rd), 0., 1.);
    vec3 i_s = vec3(1, 1, 1);
    float alpha = 10.;
    vec3 specular = k_s * pow(dotRV, alpha) * i_s;

    return ambient + diffuse + specular;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy; // <0,1>
    uv -= 0.5;
    uv.x *= iResolution.x/iResolution.y; // fix aspect ratio
    uv /= FOV;
    //uv=ceil(uv*100.)/100.;
    vec3 ro=vec3(0,10,10);
    vec3 rd=normalize(vec3(uv,-1.))*rotateX(5.5);
    Surface d=rayMraching(ro,rd);
    vec3 col;
    if(d.d>=100.){
        col=vec3(1.);
    }
    else{
        vec3 p = ro + rd * d.d; // point on surface found by ray marching
        vec3 normal = calcNormal(p); // surface normal

        // light #1
        vec3 lightPosition1 = vec3(-8, -6, -5);
        vec3 lightDirection1 = normalize(lightPosition1 - p);
        float lightIntensity1 = 0.6;

        // light #2
        vec3 lightPosition2 = vec3(1, 1, 1);
        vec3 lightDirection2 = normalize(lightPosition2 - p);
        float lightIntensity2 = 0.7;

        // final color determined by the phong lighting model, which now uses the selected palette
        col = lightIntensity1 * phong(lightDirection1, normal, rd);
        col += lightIntensity2 * phong(lightDirection2, normal , rd);
    }
    
    // --- Apply Brightness, Contrast, and Saturation (BCS) Post-Process ---

    // 1. Contrast: Adjust values around the 0.5 midpoint
    col = (col - 0.5) * CONTRAST + 0.5;

    // 2. Brightness: Simple offset
    col += BRIGHTNESS;

    // 3. Saturation: Mix with grayscale
    // Standard luminance weights for converting RGB to grayscale
    float luminance = dot(col, vec3(0.2126, 0.7152, 0.0722));
    vec3 lum_color = vec3(luminance); 

    // Mix between grayscale and original color based on SATURATION
    col = mix(lum_color, col, SATURATION);
    
    // Clamp the final color to ensure valid [0, 1] range
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col,1.0);
}
