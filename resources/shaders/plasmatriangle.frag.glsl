/*

    You guys draw a LOT of pixels, with very few code.
    
    I did the exact opposite ^^'
    
    I heavily commented, for myself, and for newbies enthousiasts like me who appreciate readable code 
    and who want to understand the intent behind.
        
*/
#define speed .75
#define time iTime * speed
#define wheelRadius 0.11
#define amplitude 0.3
#define wheelsDist .35

// If you want to read the code below, NAIVE_MODE is here to show you why my first attempts were wrong ^^'
// Set it to 1 to switch to simple wheels positionning
#define NAIVE_MODE 0


/*

    TOOLS FUNCTIONS
        
*/

// Classical rotation matrix
mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

// sdf segment function by iq <3
float udSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 ba = b-a;
    vec2 pa = p-a;
    float h =clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length(pa-h*ba);
}



/*

    COORDINATES CALCULATION FUNCTIONS
        
*/

// Calculates the y of the hill given the x absciss
float hillY(float x) {
    float t = x + time;

    return amplitude                                            // base amplitude 
           * sin(t*1.5) * 0.75 + sin(t*2.) * 0.45 + sin(t*3.) * 0.25 // modulations over x and time
           - 0.2;                                                 // adjustement on y axis
}

// Calculates coords of a wheel at point x
vec2 wheelCenter(float wheelX) {

    // Base Y is the naive approach : heigth of the hill at x + wheel's radius
    float baseY = hillY(wheelX)+wheelRadius;
    
    if (NAIVE_MODE == 1)
        return vec2(wheelX, baseY);
    
    float fixedY = baseY;

    for (float a = -3.14159; a <= 0.; a += 0.26179) {
        float hillAtX = hillY(wheelX + cos(a) * wheelRadius);
        float dy = sin(a) * wheelRadius + fixedY;

        if (dy < hillAtX)
            fixedY += hillAtX - dy;
        
    }

    return vec2(wheelX, fixedY);
}

vec2 followingWheelCenter(vec2 leadWheelCenter) {
    float targetDist = wheelsDist;
    vec2 currentCenter = leadWheelCenter - normalize(leadWheelCenter - vec2(leadWheelCenter.x - targetDist, hillY(leadWheelCenter.x - targetDist))) * targetDist;
    
    for(int i = 0; i < 10; ++i) {
        vec2 hillCenter = wheelCenter(currentCenter.x);
        float dist = length(hillCenter - leadWheelCenter);
        
        if (abs(dist - targetDist) < 0.0001) {
            return hillCenter;
        }
        
        currentCenter += normalize(leadWheelCenter - hillCenter) * (dist - targetDist);
    }
    
    return wheelCenter(currentCenter.x);
}

/*
    "DRAWING" FUNCTIONS
*/

float drawWheel(vec2 uv, vec2 center, float radius, float tireThickness) {
    float distToWheel = length(uv - center);
    float rim = radius * (1. - tireThickness);
    float wheelIntensity = smoothstep(radius, radius - 0.0025, distToWheel) - smoothstep(rim, rim - 0.0025, distToWheel);
    return wheelIntensity;
}

float drawSegment(vec2 p, vec2 a, vec2 b, float thickness) {
    return smoothstep(thickness, thickness - .001, udSegment(p, a, b));
}

float drawHill(vec2 pos) {
    float lineWidth = 0.01;
    float sinusY = hillY(pos.x);
    float distToCurve = abs(pos.y - sinusY);
    return smoothstep(lineWidth, 0.0, distToCurve);
}

float drawBike(vec2 pos) {
    vec2 w1c = wheelCenter(.1);
    vec2 w2c = followingWheelCenter(w1c);

    float render = drawWheel(pos, w1c, wheelRadius, .25);
    render += drawWheel(pos, w2c, wheelRadius, .25);
    
    // Fill the inside of the wheels with 50% transparent green
    float wheelFill1 = smoothstep(wheelRadius - 0.0125, 0.0, length(pos - w1c));
    float wheelFill2 = smoothstep(wheelRadius - 0.0125, 0.0, length(pos - w2c));

    vec2 hdir = w1c - w2c;
    vec2 fp1 = w2c;
    vec2 fp2 = fp1 + hdir * .48 * rot(-.15);
    float renderSeg = drawSegment(pos, fp1, fp2, .01);
    render = max(render,renderSeg);
    vec2 fp3 = fp1 + hdir * .5 * rot(1.1);
    renderSeg = drawSegment(pos, fp1, fp3, .01);
    render = max(render,renderSeg);
    vec2 vdir = fp3 - fp2;
    vec2 fp4 = fp2 + vdir * 1.2;
    renderSeg = drawSegment(pos, fp2, fp4, .01);
    render = max(render,renderSeg);
    renderSeg = drawSegment(pos, fp4 - hdir * .1, fp4 + hdir * .1, .01);
    render = max(render,renderSeg);
    vec2 fp5 = w1c;
    vec2 fp6 = fp5 + vdir * 1.1;
    renderSeg = drawSegment(pos, fp5, fp6, .01);
    render = max(render,renderSeg);
    vec2 fp7 = fp3 + hdir *.56;
    renderSeg = drawSegment(pos, fp3, fp7, .01);
    render = max(render,renderSeg);
    renderSeg = drawSegment(pos, fp2, fp7 - vdir * .05, .01);
    render = max(render,renderSeg);
    vec2 oDir = fp3 - fp1;
    vec2 fp8 = fp6 + oDir * .2;
    renderSeg = drawSegment(pos, fp6, fp8, .008);
    render = max(render,renderSeg);
    renderSeg = drawSegment(pos, fp8, fp8 - hdir * .2, .008);
    render = max(render,renderSeg);
    
    return max(render, wheelFill1 + wheelFill2);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 pos = (2. * fragCoord - iResolution.xy) / iResolution.y;
    float bike = drawBike(pos);
    float hill = drawHill(pos);

    // Combine colors: Green bike and Yellow hill
    fragColor = vec4(
        0.0, bike * 0.5, 0.0, 1.0
    ) + vec4(
        hill, hill * 0.8, 0.0, 1.0
    );
}