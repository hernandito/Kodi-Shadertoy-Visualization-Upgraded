precision highp float;

void mainImage(out vec4 c, vec2 u) {
    vec3 p;
    float z = 1.0, d, s;
    c = vec4(0.0); // Initialize output color

    // Reduce iteration count for performance on lower-end devices
    for (float i = 0.0; i < 60.0; i++) {
        // Initialize ray marching starting point
        p = z * normalize(vec3(u + u + vec2(0.0, iResolution.x / 1.066), 0.0) - vec3(iResolution.x, iResolution.y, iResolution.y));

        // Rotate image by 30 degrees
        p.xy = vec2(p.x * 0.866 - p.y * 0.5, p.x * 0.5 + p.y * 0.866); // cos(π/6) and sin(π/6)

        // Reflect symmetry
        float a = 0.5236; // π/6
        for (float j = 0.0; j < 6.0; j++) {
            vec2 n = vec2(cos(j * a), sin(j * a));
            float D = dot(p.xy, n);
            if (D < 0.0) p.xy -= 2.0 * D * n;
        }

        // Space folding with reduced complexity
        for (d = 5.0; d < 100.0; d += d) {
            for (int j = 0; j < 2; j++) {
                p = abs(abs(p + 0.1) - 0.2);
                if (p.y > p.x) p.yx = p.xy;
                if (p.y - p.z < 0.0) p.yz = p.zy;
            }

            // Simplified turbulence
            p += 0.6 * sin(p.yzx * d - 0.2 * iTime + 2.0) / d;
        }

        z += d = 0.005 + max(s = 0.3 - abs(p.y), -s * 0.2) / 4.0;
        c += (cos(s / 0.07 + p.x + 0.5 * 2.4 - vec4(0.0, 1.0, 2.0, 3.0) - 3.0) + 1.5) * exp(s / 0.1) / d / 20000.0;
    }

    // Gamma correction
    c = pow(c, vec4(3.3));
}