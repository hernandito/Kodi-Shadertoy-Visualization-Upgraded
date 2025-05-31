void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.0*fragCoord.xy - iResolution.xy) / iResolution.y;

    // --- Scale Parameter ---
    float scale = 0.70; // Adjust to make the effect smaller (values > 1) or larger (values < 1)
    uv /= scale;
    // -----------------------

    // --- Rotation Parameters ---
    float rotationSpeed = 0.07; // Adjust for rotation speed
    vec2 rotationAxis = vec2(-0.10, 0.1); // Adjust for the axis of rotation (normalized screen space, centered at 0,0)
    // -------------------------

    float angle = iTime * rotationSpeed;
    float cosA = cos(angle);
    float sinA = sin(angle);
    mat2 rotationMatrix = mat2(cosA, -sinA, sinA, cosA);

    // Offset UV by the rotation axis, rotate, and then offset back
    vec2 rotatedUV = uv - rotationAxis;
    rotatedUV = rotationMatrix * rotatedUV;
    rotatedUV += rotationAxis;

    vec2 mouse = 1.5*(2.0*iMouse.xy - iResolution.xy) / iResolution.y;
    vec2 offset = vec2(cos(iTime/2.0)*mouse.x,sin(iTime/2.0)*mouse.y);;
    vec3 light_color = vec3(0.9, 0.65, 0.5);
    float light = 0.1 / distance(normalize(rotatedUV), rotatedUV);
    if(length(rotatedUV) < 1.0){
        light *= 0.1 / distance(normalize(rotatedUV-offset), rotatedUV-offset);
    }
    vec3 final_color = light * light_color;

    // Scale down the color to prevent pure white
    final_color *= 0.8; // Adjust this value to control the max brightness

    fragColor = vec4(final_color, 1.0);
}