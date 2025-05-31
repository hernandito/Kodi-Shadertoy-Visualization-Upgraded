#define rot(a) mat2(cos(a+vec4(0,11,33,0)))

// Formula for creating colors
#define H(h)  (cos(h*3. + 5.*vec3(1,2,3)) * 0.6 + 0.4)

// Formula for mapping scale factor
#define M(c)  log(1. + c)

#define R iResolution

#define SPEED 0.10  // 👈 Adjust this to control animation speed

void mainImage(out vec4 O, vec2 U) {
    float wfac = 0.8, zoom = 0., cfac = 0.;
    O = vec4(0); 
    vec3 c = vec3(0);  
    vec4 rd = normalize(vec4(U - 0.5 * R.xy, 0.8 * R.y, wfac * R.y)) * 15.;

    float sc, dotp, totdist = 0., t = 2.9; 
    float fac = 1.;

    for (float i = 0.; i < 100.; i++) {
        vec4 p = vec4(rd * totdist);
        p.x -= 1.3;
        p.y -= 1.9;
        p.z += iTime * SPEED;  // 👈 Speed parameter applied here

        p.z = mod(p.z, 12.) - 6.;  

        p.xy *= rot(t * 2. + sin(t / 2.));
        p.yz *= rot(0.707 + t / 2.);
        p.xz *= rot(0.707 + t / 5.);

        sc = 1.;  
        for (float j = 0.; j < 5.; j++) {
            p = abs(p - 0.8) * 0.6;
            dotp = max(1. / dot(p, p), fac);
            sc *= dotp;
            p *= dotp - 0.2 * p;
        }

        float dist = clamp(abs(length(p - p.w) - 0.35) / (1. + sc), 1e-4, 0.008); 
        float stepsize = dist + 4e-4;
        totdist += stepsize;    

        c += 0.03 * H(M(sc)) * exp(-i * i * stepsize * stepsize * 1e2);
    }

    c = clamp(c, -100., 100.);
    c = 1. - exp(-c * c);
    c *= exp(-totdist * totdist / 2.);
    c.b *= 1.5;

    O = vec4(c, 0.0);
}
