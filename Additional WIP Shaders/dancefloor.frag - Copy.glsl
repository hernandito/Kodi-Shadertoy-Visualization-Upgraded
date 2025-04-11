#define M_2PI 6.28318530718
vec2 polar(vec2 dPoint)
{
    return vec2(sqrt(dPoint.x * dPoint.x + dPoint.y * dPoint.y), atan(dPoint.y, dPoint.x));
}

float rand(vec2 co)
{
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

vec2 decart(vec2 pPoint)
{
    return vec2(pPoint.x * cos(pPoint.y), pPoint.x * sin(pPoint.y));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 screen = iResolution.xy;
    vec2 center = screen / 2.0;
    vec2 frag = fragCoord.xy - center;
    vec2 fragPolar = polar(frag);
    float lenCenter = length(center);
    
	const float bandPass = 720.0;
    const float angleDisp = M_2PI / (bandPass + 1.0);
    
    const float particlesCount = 4300.0;
    const float particleLifetime = 20.0;
    const float particleMaxSize = 7.5;
    float particleMaxSizeNorm = particleMaxSize / lenCenter;
    
    float globTime = iTime / particleLifetime;
    float timeDelta = bandPass;
    
    const float polarRadiusClip = 0.01;
    const float polarRadiusMax = 0.75;
    float polarRadiusDelta = polarRadiusMax - polarRadiusClip; 
    
    float presence = 0.0;
    vec2 pPoint;
    
    for (float i = 0.0; i < particlesCount; i += 1.0)
    {
        float phase = i / particlesCount;
        
        float localTime = globTime + timeDelta * (2.0 * phase - 1.0) + phase;
        float particleTime = fract(localTime);
        float spaceTransform = pow(particleTime, 8.0);
        
        pPoint.x = lenCenter * ((polarRadiusClip + polarRadiusDelta * phase) + spaceTransform);
        
        // +30 FPS :)
        if (abs(pPoint.x - fragPolar.x) > particleMaxSize) continue;
        
        pPoint.y = floor(particleTime + bandPass * rand(vec2(floor(localTime), 1))) * angleDisp;
        
        vec2 dPoint = decart(pPoint);        
        float particleSize = particleMaxSize * spaceTransform;
        float localPresence = particleSize * (1.0 - clamp(length(dPoint - frag), 0.0, 1.0));
        presence += localPresence;
    }
    presence = clamp(presence, 0.0, 1.0);
    fragColor = vec4(presence, presence, presence, 1.0);
}