float g_threshold = 0.99;
vec3 g_SkyColor = vec3(0.067, 0.078, 0.188); // Original night sky color
vec3 g_StarColor = vec3(0.9, 0.9, 0.9);

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
    vec3 s = floor(p + dot(p, vec3(F3)));
    vec3 x = p - s + dot(s, vec3(G3));
    vec3 e = step(vec3(0.0), x - x.yzx);
    vec3 i1 = e*(1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy*(1.0 - e);
    vec3 x1 = x - i1 + G3;
    vec3 x2 = x - i2 + 2.0*G3;
    vec3 x3 = x - 1.0 + 3.0*G3;
    vec4 w, d;
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);
    w = max(0.6 - w, 0.0);
    d.x = dot(random3(s), x);
    d.y = dot(random3(s + i1), x1);
    d.z = dot(random3(s + i2), x2);
    d.w = dot(random3(s + 1.0), x3);
    w *= w;
    w *= w;
    d *= w;
    return dot(d, vec4(52.0));
}

float Pseudo3dNoise(vec3 pos) {
    float hash = 0.0;
    pos = fract(pos);
    hash += sin(pos.x * 15.234) + exp(pos.x);
    hash += cos(pos.y * 965.235) + exp(pos.y);
    hash += cos(pos.z * 35.5) + exp(pos.z);
    return fract(3854.2345 * hash);
}

float Pseudo2dNoise(vec2 pos) {
    float hash = 0.0;
    hash += sin(pos.x * 15.234) + exp(pos.x);
    hash += cos(pos.y * 965.235) + exp(pos.y);    
    return fract(3854.2345 * hash);
}

float getStar(vec3 pos, float threshold) {
    float c = Pseudo2dNoise(pos.xy);
    if(c < threshold) return 0.0;
    return c;
}

// Moon texture and glow function
void getMoon(vec2 uv, vec2 moonCenter, float moonRadius, float aspect, out float moonValue, out float glowValue, out float moonAlpha) {
    vec2 adjustedUV = uv;
    adjustedUV.x *= aspect;
    moonCenter.x *= aspect;
    float dist = length(adjustedUV - moonCenter);
    float moon = 1.0 - smoothstep(moonRadius - 0.00002, moonRadius, dist);
    vec2 texCoord = (adjustedUV - moonCenter) * 40.0;
    float textureNoise = simplex3d(vec3(texCoord * 0.5, 0.0)) * 0.5;
    textureNoise += simplex3d(vec3(texCoord * 2.0, 0.0)) * 0.3;
    textureNoise += Pseudo2dNoise(texCoord * 5.0) * 0.2;
    textureNoise = clamp(textureNoise, 0.0, 1.0);
    float lunarTexture = mix(0.9, 1.0, 1.0 - pow(textureNoise, 0.45));
    moonValue = moon * lunarTexture;
    moonAlpha = moon;
    const float glowStartIntensity = 0.7;
    const float glowFalloffDistance = 0.1;
    float glowStartRadius = moonRadius - 0.01;
    float glow = 0.0;
    if (dist > glowStartRadius) {
        float normalizedDist = (dist - glowStartRadius) / glowFalloffDistance;
        glow = glowStartIntensity * exp(-2.0 * normalizedDist);
    }
    glowValue = (dist <= moonRadius) ? 0.0 : glow;
}

// Function to compute eased position for one-way journey
float getEasedPosition(float t, float easeInDuration, float linearDuration, float easeOutDuration) {
    float totalDuration = easeInDuration + linearDuration + easeOutDuration;
    t = clamp(t, 0.0, totalDuration);
    
    // Ease-in phase (0 to 5s)
    if (t <= easeInDuration) {
        float normT = t / easeInDuration;
        return smoothstep(0.0, 1.0, normT) * (easeInDuration / totalDuration);
    }
    // Linear phase (5s to 65s)
    else if (t <= easeInDuration + linearDuration) {
        float linearT = (t - easeInDuration) / linearDuration;
        float easeInFraction = easeInDuration / totalDuration;
        float linearFraction = linearDuration / totalDuration;
        return easeInFraction + linearT * linearFraction;
    }
    // Ease-out phase (65s to 70s)
    else {
        float normT = (t - (easeInDuration + linearDuration)) / easeOutDuration;
        float easeInLinearFraction = (easeInDuration + linearDuration) / totalDuration;
        return easeInLinearFraction + (smoothstep(0.0, 1.0, normT) * (easeOutDuration / totalDuration));
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord/iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    
    // Background gradient with dithering to reduce banding
    vec3 baseColor = g_SkyColor * (uv.y + 0.25) / 1.25;
    float dither = simplex3d(vec3(uv * 100.0, iTime)) * 0.01; // Small noise for dithering
    vec3 col = baseColor + vec3(dither);
    
    col += getStar(vec3(uv, iTime), g_threshold) * g_StarColor * (simplex3d(vec3(uv*100.0, iTime)) + 0.4) / 1.4;
    
    // Moon animation parameters
    vec2 startPos = vec2(0.75, 0.75);
    vec2 endPos = vec2(0.5, 0.25);
    float cycleTime = 140.0; // Full cycle: forward + back
    float journeyTime = 70.0; // One-way journey time
    float easeInTime = 5.0;
    float linearTime = 60.0;
    float easeOutTime = 5.0;
    
    // Compute current time in cycle
    float time = mod(iTime, cycleTime);
    float t;
    float p;
    if (time < journeyTime) {
        // Forward journey
        t = time;
        p = getEasedPosition(t, easeInTime, linearTime, easeOutTime);
    } else {
        // Backward journey
        t = time - journeyTime;
        p = 1.0 - getEasedPosition(t, easeInTime, linearTime, easeOutTime);
    }
    vec2 moonCenter = mix(startPos, endPos, p);
    
    float moonRadius = 0.1;
    float moonValue, glowValue, moonAlpha;
    getMoon(uv, moonCenter, moonRadius, aspect, moonValue, glowValue, moonAlpha);
    
    if (moonValue > 0.0) {
        vec3 moonColor = vec3(moonValue);
        col = mix(col, moonColor, moonAlpha);
    }
    if (glowValue > 0.0) {
        vec3 glowColor = vec3(glowValue);
        col += glowColor;
    }
    
    col = clamp(col, 0.0, 1.0);
    fragColor = vec4(col, 1.0);
}