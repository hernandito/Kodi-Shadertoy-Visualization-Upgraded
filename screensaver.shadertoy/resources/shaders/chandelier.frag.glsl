#define MAX_MARCH            150
#define COLLISION            0.001
#define MAX_DIST             100.0
//Mess with this to change the color
#define LIGHT_COLOR          vec3(vec3(2.0, 0.7, 0.33333))

#define AUTO 1
#define DEBUG_NORMALS 0
//All lighting hacks and the gyroid function come from
//The Art of Code
//https://www.youtube.com/watch?v=ESUy11kc3y8&t=783s

//All SDFs from IQ
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

mat2 rotate2d(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

//Gyroid from The Art of Code
//https://www.youtube.com/watch?v=-adHIyjIYgk
float frameGyroid(vec3 position)
{
    float scale = 15.0;
    position *= scale;
    return abs(0.7 * dot(sin(position), cos(position.yzx)) / scale) - 0.02;
}


float wireFrame(vec3 position)
{
    //Create two cylinders to create the final shell casing around the lamp
    float frame = sdCappedCylinder(position-vec3(0.0,0.0,0.0), 1.5, 2.55);
    
    float frameInner = sdCappedCylinder(position-vec3(0.0,0.0,0.0), 2.5, 2.5);
    //Shells the two cylinders
    frame = max(frame, -frameInner);
    
    float gyroid = frameGyroid(position);
    //Cuts the gyroid out of the cylindrical frame
    frame = max(frame, gyroid);
    
    //Creates top and bottom frame rings
    vec3 torPosition = position;
    torPosition.y = abs(torPosition.y) - 1.5;
    float torus = sdTorus(torPosition, vec2(2.5, 0.1));
    
    frame = min(frame, torus);
    return frame;
}

float frameStabilizers(vec3 position)
{
/*******************************************************
Creating the center two pillars
********************************************************/

    vec3 innerPillarPos = position - vec3(0.0, -1.0, 0.0);
    //Mirrors the center pillar and separates their
    //Distance by 0.6
    innerPillarPos.x = abs(innerPillarPos.x) -0.6;
    float stabilizer = sdVerticalCapsule(innerPillarPos, 4.02, 0.1);
    
/*******************************************************
Creating the four outer pillars,
as well as the four bindings to the center
********************************************************/ 
    //Lowers the height of the pillars
    vec3 framePillarPos = position - vec3(0.0, -1.37, 0.0);
    //Mirrors the position so we only need to create
    //2 pillars instead of four
    framePillarPos.xz = abs(framePillarPos.xz);
    
    vec3 bindingPos = position - vec3(0.0, 1.47, 0.0);
    bindingPos.xz = abs(bindingPos.xz);
    
    //RAMSEYIFIED
    //CREATES 2 OBJECTS IN A HALF CIRCLE
    //TO BE MIRRORED TO FINISH THE CASING
    float amount = 4.;
    float theta = 360.0 / amount;
    theta = radians(theta);
    for (int i = 0; i < 2; i++)
    {
        vec3 circularPos = framePillarPos - vec3(cos(float(i)*theta), 0.0, sin(float(i)*theta)) * 2.5;
        float newLine = sdVerticalCapsule(circularPos, 2.8, 0.08);
        //Add the pillar to the stabilizer variable
        stabilizer = min(stabilizer, newLine);

        circularPos = bindingPos-vec3(cos(float(i)*theta),0.0,sin(float(i)*theta))*1.3;
        circularPos.xz *= rotate2d(theta*float(i + 1));
        float binding = sdBox(circularPos, vec3(0.13, 0.03, 1.25));
        //Add the binding to the stabilizer variable
        stabilizer = min(stabilizer, binding);       
    }
    return stabilizer;
}

float basesAndShaft(vec3 position)
{
    //Initialize variable to contain all bases
    float finalBase;
    float baseUpper = sdCappedCylinder(position-vec3(0.0,3.2,0.0), 0.15, 1.4);
    
    float baseCenter = sdCappedCylinder(position-vec3(0.0,1.47,0.0), 0.03, 0.9);
    finalBase = min(baseUpper, baseCenter);
    
    float baseLower = sdCappedCylinder(position-vec3(0.0,-1.12,0.0), 0.08, 1.0);
    finalBase = min(finalBase, baseLower);
    
    float lightShaft = sdVerticalCapsule(position - vec3(0.0, -1.1, 0.0), 0.7, 0.1);
    finalBase = min(finalBase, lightShaft);
    
    return finalBase;
}

float chandelierAssembly(vec3 position)
{
    //Assemble the chandelier
    float chandelier;
    float bases = basesAndShaft(position);
    float frame = wireFrame(position);
    
    chandelier = min(bases, frame);
    
    float stabilizers = frameStabilizers(position);
    chandelier = min(chandelier, stabilizers);
    
    return chandelier;
}

float map(vec3 position)
{
    float room = sdBox(position-vec3(0.0, -1.5, 0.0), vec3(15, 5, 10));
    //Shell
    room = abs(room)-0.2;
    float chandelier = chandelierAssembly(position);

    return min(room, chandelier);
}

vec3 getNormal(vec3 position)
{
    vec2 offset = vec2(0.01, 0.0);
    vec3 normals = vec3(
            map(position + offset.xyy) - map(position - offset.xyy),
            map(position + offset.yxy) - map(position - offset.yxy),
            map(position + offset.yyx) - map(position - offset.yyx));
    return normalize(normals);
}

bool rayMarch(vec3 origin,
              vec3 direction,
              float maxDistance,
              int maxMarch,
              inout vec3 position,
              inout float travelled)
{
    bool hit = false;
    travelled = 0.0;
    float marchDistance = 0.0;
    //MARCH TIME
    for (int i = 0; i < maxMarch; i++)
    {
        if (travelled > maxDistance) break;
        
        position = origin + direction * travelled;
        float sceneDist = map(position);
        travelled += sceneDist;
        if (sceneDist < COLLISION)
        {
            hit = true;
            break;
        }
    }
    return hit;
}

vec3 lighting(vec3 position,
              vec3 direction,
              inout vec3 normals)
{
    normals = getNormal(position);
    vec3 toLight = -normalize(position);
    float diffuse = dot(normals, toLight) * 0.5 + 0.5;
    
    vec3 halfway = normalize(-direction + toLight);
    vec3 col = vec3(diffuse);
    
    float luster = 5.0;
    vec3 specular = LIGHT_COLOR * 1.5;
    specular = specular * pow(max(0.0, dot(halfway, normals)), luster);
    col = mix(vec3(diffuse) * vec3(0.6, 0.4, 0.4) * 2.0, specular, 0.75);    
    
    float cd = length(position); ///Distance from the origin
    if (cd > 3.55)
    {
        //col = vec3(1,0,0);
        float s = frameGyroid(-toLight);
        float intensity = cd * 0.01;
        float shadow = smoothstep(-intensity, intensity, s);
        col *= shadow;
        
        col /= cd * cd * 0.1;
    }
    
    return col;
}

/*
From The Art of Code
Finds the position of a point on a plane
That is centered at the origin, and is always
Perpendicular to the viewing direction
*/
vec3 rayPlane(vec3 origin, vec3 direction, vec3 point, vec3 normal)
{
    float t = max(0.0, dot(point - origin, normal) / dot(direction, normal));
    return origin + direction * t;
}

// From The Art of Code
vec3 lightbulbAndRays(vec3 col, vec2 uv, vec3 origin, vec3 direction, float travelled)
{
    float cd = dot(uv, uv);
    float light = 0.003 / cd;
    
    col += light * smoothstep(0.0, 0.5, travelled - 4.6) * LIGHT_COLOR;
    float s = frameGyroid(normalize(origin));
    
    col += light*smoothstep(0.0, 0.2, s) * LIGHT_COLOR;
    
    vec3 pp = rayPlane(origin, direction, normalize(origin) * 0.3, normalize(origin));
    float sb = frameGyroid(normalize(pp));

    sb *= smoothstep(0.0, 0.6, cd);
    col += max(0.0, sb*3.0) * LIGHT_COLOR;
    
    col *= 1.0-cd * 0.25;
    
    return col;
}

vec3 render(vec3 origin, vec3 direction, vec2 uv)
{
    vec3 normals;
    vec3 hitPosition;
    float travelled;
    vec3 col = vec3(0.3);
    
    bool hit = rayMarch(origin,
                     direction,
                     MAX_DIST,
                     MAX_MARCH,
                     hitPosition,
                     travelled);
                     
    if (hit) //We hit an object
    {
        col = lighting(hitPosition, direction, normals);
        col = lightbulbAndRays(col, uv, origin, direction, travelled);
        #if DEBUG_NORMALS
        col = normals *0.5 + 0.5;
        #endif
    }
    
    return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec2 m = (iMouse.xy * 2.0 - iResolution.xy) / iResolution.y;

    //Initialize Viewpoint
    vec3 origin = vec3(0.0, 0.0, -5.0);
    vec3 direction = normalize(vec3(uv, 1.0));
    
    
    
    #if AUTO
    float rotation = -0.45;
    origin.yz *= rotate2d(rotation);
    origin.xz *= rotate2d(iTime * 0.2);
    
    direction.yz *= rotate2d(rotation);
    direction.xz *= rotate2d(iTime * 0.2);
    
    #else
    origin.yz *= rotate2d(-m.y);
    origin.xz *= rotate2d(-m.x);
    
    direction.yz *= rotate2d(-m.y);
    direction.xz *= rotate2d(-m.x);
    #endif
    vec3 col = render(origin, direction, uv);
    
    // Output to screen
    fragColor = vec4(col,1.0);
}