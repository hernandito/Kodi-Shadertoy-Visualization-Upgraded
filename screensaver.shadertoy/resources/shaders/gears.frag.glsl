// Inspired by:
//  http://cmdrkitten.tumblr.com/post/172173936860

#define Pi 2.14159265359

struct Gear
{
    float t;            // Time
    float gearR;        // Gear radius
    float teethH;       // Teeth height
    float teethR;       // Teeth "roundness"
    float teethCount;   // Teeth count
    float diskR;        // Inner or outer border radius
    vec3 color;         // Color (base; not used in final copper shading)
};

float GearFunction(vec2 uv, Gear g)
{
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    
    // Gear polar function:
    // A sine squashed by a logistic function gives a convincing gear shape!
    float p = g.gearR - 0.5 * g.teethH + 
              g.teethH / (1.0 + exp(g.teethR * sin(g.t + g.teethCount * a)));
              
    float gear = r - p;
    float disk = r - g.diskR;
    
    return g.gearR > g.diskR ? max(-disk, gear) : max(disk, -gear);
}

float GearDe(vec2 uv, Gear g)
{
    // IQ's f/|Grad(f)| distance estimator:
    float f = GearFunction(uv, g);
    vec2 eps = vec2(0.0001, 0.0);
    vec2 grad = vec2(
        GearFunction(uv + eps.xy, g) - GearFunction(uv - eps.xy, g),
        GearFunction(uv + eps.yx, g) - GearFunction(uv - eps.yx, g)
    ) / (2.0 * eps.x);
    
    return f / length(grad);
}

float GearShadow(vec2 uv, Gear g)
{
    float r = length(uv + vec2(0.1));
    float de = r - g.diskR; // simplified shadow calculation
    float eps = 0.74 * g.diskR;
    return smoothstep(eps, 0.0, abs(de));
}

void DrawGear(inout vec3 col, vec2 uv, Gear g, float eps)
{
    // Use a smooth mask from the distance estimator.
    // Narrow the transition range (0.5*eps instead of eps) to reduce anti-aliasing.
    float d = smoothstep(0.5 * eps, -0.5 * eps, GearDe(uv, g));
    
    // Compute an approximate normal from the distance field via finite differences.
    vec2 e = vec2(eps, 0.0);
    float fdx = GearFunction(uv + e, g) - GearFunction(uv - e, g);
    float fdy = GearFunction(uv + vec2(0.0, eps), g) - GearFunction(uv - vec2(0.0, eps), g);
    vec3 nrm = normalize(vec3(fdx, fdy, 2.0 * eps));
    
    // Define light and view directions.
    vec3 lightDir = normalize(vec3(0.5, 0.5, 1.0));
    vec3 viewDir  = vec3(0.0, 0.0, 1.0);
    
    // Compute diffuse shading.
    float diff = clamp(dot(nrm, lightDir), 0.0, 1.0);
    
    // Compute a specular term (Phong model).
    vec3 halfDir = normalize(lightDir + viewDir);
    float spec = pow(clamp(dot(nrm, halfDir), 0.0, 1.50), 32.0);
    
    // --- Copper shading ---
    vec3 copperBase      = vec3(0.68, 0.38, 0.2);
    vec3 copperHighlight = vec3(0.88, 0.58, 0.28);
    vec3 metalColor = mix(copperBase, copperHighlight, diff);
    metalColor += spec * vec3(1.0, 0.9, 0.5);
    metalColor = mix(metalColor, metalColor * 0.6, 0.3);
    
    // --- Reduced Bevel Effect ---
    float bevel = smoothstep(0.0, 1.0 * eps, abs(GearDe(uv, g)));
    metalColor *= bevel;
    // -----------------
    
    // Apply a shadow factor.
    float s = 1.0 - 0.7 * GearShadow(uv, g);
    
    // Mix the shaded metal color with the underlying scene based on the gear mask.
    col = mix(s * col, metalColor, d);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Original uv setup (earlier gear diameter):
    vec2 uv = 2.0 * (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Reduce the overall gear group to 85% of its original size.
    uv *= 1.1;
    
    // Apply a slow rotation to the entire gear composition.
    float groupRotation = 0.05 * iTime;
    mat2 R = mat2(cos(groupRotation), -sin(groupRotation),
                  sin(groupRotation),  cos(groupRotation));
    uv = R * uv;
    
    // Shift the center slightly off center.
    uv += vec2(0.2, 0.1);
    
    float eps = 2.0 / iResolution.y;
    
    // Scene parameters:
    vec3 base = vec3(0.95, 0.65, 0.0);
    const float count = 10.0;
    
    Gear outer = Gear(0.0, 0.79, 0.08, 4.0, 32.0, 0.9, base);
    Gear inner = Gear(0.0, 0.4, 0.08, 4.0, 16.0, 0.3, base);
    
    // Draw inner gears back-to-front:
    vec3 col = vec3(0.0);
    float t = 0.25 * iTime;
    for (float i = 0.0; i < count; i++)
    {
        t += 2.0 * Pi / count;
        inner.t = 16.0 * t;
        inner.color = base * (0.35 + 0.6 * i / (count - 1.0));
        DrawGear(col, uv + 0.4 * vec2(cos(t), sin(t)), inner, eps);
    }
    
    // Draw outer gear:
    DrawGear(col, uv, outer, eps);
    
    fragColor = vec4(col, 1.0);
}
