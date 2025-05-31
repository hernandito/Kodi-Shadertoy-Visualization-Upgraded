/*

    Fast Cellular Blocks
    --------------------

    Applying some bump mapping and lighting to a Voronoi variation to produce an
    animated, pseudo-lit, rounded block effect.

    I had originally intended to do a standard square block version using a first order
    triangular distance metric, but noticed that IQ, Aeikick and others had already done
    it, so I switched to a second order distance setup and experimented with a few different
    metrics. The end result was the oddly distributed round-looking blocks with defined
    edges you see.

    To add a little more to the illusion, I bump mapped it, put in some fake occlusion,
    and some subtle edging. As you can see, there's not a lot of code.


    Related examples:

    // The main inspiration for this, and practically all the other examples.
    Blocks -IQ
    https://www.shadertoy.com/view/lsSGRc


    // Just the cellular block algorithm.
    Fast, Minimal Animated Blocks - Shane
    https://www.shadertoy.com/view/MlVXzd

*/

#define FAR 10. // Far plane. Redundant here, but included out of habit.

// -----------------------------------------------------------------------------
// ADJUSTABLE PARAMETERS
// Adjust this value to control the overall speed of the animation.
// Increase for faster animation (e.g., 2.0), decrease for slower animation (e.g., 0.5).
// -----------------------------------------------------------------------------
// Hardcoded speed value, as uniform might not be working in your environment.
const float speed = .50; // Default: 1.0 (normal speed). Change this value directly.

// === BCS Parameters ===
// Brightness: -1.0 to 1.0 (0.0 = no change, positive brightens, negative darkens)
// Contrast: 0.0 to 2.0 (1.0 = no change, higher increases contrast, lower reduces)
// Saturation: 0.0 to 2.0 (1.0 = no change, 0.0 = grayscale, higher increases saturation)
const float post_brightness = 0.00;   // Default: no change
const float post_contrast = 1.000;     // Default: no change
const float post_saturation = 1.0;   // Default: no change

// === Suggested Adjustments ===
// - If the image looks washed out on your TV:
//   - post_brightness = 0.2 (slight brightening)
//   - post_contrast = 1.2 (increase contrast)
//   - post_saturation = 1.3 (boost colors)
// - If the image is too dark:
//   - post_brightness = 0.3 to 0.5 (brighten more)
// - If colors are too muted:
//   - post_saturation = 1.5 (more vibrant colors)

// -----------------------------------------------------------------------------
// END ADJUSTABLE PARAMETERS
// -----------------------------------------------------------------------------

float objID = 0.; // Object ID. Used to identify the large block and small block layers.

// Distance metric. A slightly rounded triangle is being used, which looks a little more organic.
float dm(vec2 p){
    p = fract(p) - .5;
    return (dot(p, p)*4.*.25 + .75)*max(abs(p.x)*.866025 + p.y*.5, -p.y);
}

// Distance metric for the second pattern. It's just a reverse triangle metric.
float dm2(vec2 p){
    p = fract(p) - .5;
    return (dot(p, p)*4.*.25 + .75)*max(abs(p.x)*.866025 - p.y*.5, p.y);
}

// Very cheap wrappable cellular tiles. This one produces a block pattern on account of the
// metric used, but other metrics will produce the usual patterns.
float cell(vec2 q){
    const mat2 m = mat2(-.5, .866025, -.866025, -.5);
    vec2 p = q;
    const float offs = .666 - .166;
    // Apply animation speed to iTime for point movement
    vec2 a = sin(vec2(1.93, 0) + iTime * speed)*.166;
    float d0, d1, d2, d3; // Declare d0, d1, d2, d3 here
    float l1, l2;

    // FIRST PATTERN.
    p = q;
    d0 = dm(p + vec2(a.x, 0));
    d1 = dm(p + vec2(0, offs + a.y));
    p = m*(p + .5);
    d2 = dm(p + vec2(a.x, 0));
    d3 = dm(p + vec2(0, offs + a.y));
    l1 = min(min(d0, d1), min(d2, d3))*2.;

    // SECOND PATTERN... The small blocks, just to complicate things. :)
    p = q;
    d0 = dm2(p + vec2(a.x, 0));
    d1 = dm2(p + vec2(0, offs + a.y));
    p = m*(p + .5);
    d2 = dm2(p + vec2(a.x, 0));
    d3 = dm2(p + vec2(0, offs + a.y));
    l2 = min(min(d0, d1), min(d2, d3))*2.;

    objID = step(l1, -(l2 - .4));
    return max(l1, -(l2 - .4));
}

// The heightmap.
float heightMap(vec3 p){
    return cell(p.xy*2.); // Just one layer.
}

// The distance function.
float map(vec3 p){
    float tx = heightMap(p);
    return 1.2 - p.z + (.5 - tx)*.125;
}

// Normal calculation, with some edging and curvature bundled in.
vec3 nr(vec3 p, inout float edge, inout float crv) {
    // Roughly two pixel edge spread, regardless of resolution.
    vec2 e = vec2(2./iResolution.y, 0);

    float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
    float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
    float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    float d = map(p)*2.;

    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));

    // Wider sample spread for the curvature.
    e = vec2(12./450., 0);
    d1 = map(p + e.xyy), d2 = map(p - e.xyy);
    d3 = map(p + e.yxy), d4 = map(p - e.yxy);
    d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    crv = clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*3.)*32. + .5, 0., 1.);

    e = vec2(2./450., 0); //iResolution.y - Depending how you want different resolutions to look.
    d1 = map(p + e.xyy), d2 = map(p - e.xyy);
    d3 = map(p + e.yxy), d4 = map(p - e.yxy);
    d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float cao(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for(float i=0.; i<6.; i++){
        float hr = .01 + i*.75/5.;
        float dd = map(n * hr + p);
        occ += (hr - dd)*sca;
        sca *= 0.8;
    }
    return clamp(1.0 - occ, 0., 1.);
}

// Compact, self-contained version of IQ's 3D value noise function.
float n3D(vec3 p){
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p); p -= ip;
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(mod(h, 6.2831))*43758.5453), fract(sin(mod(h + s.x, 6.2831))*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// Simple environment mapping. Pass the reflected vector in and create some
// colored noise with it. The normal is redundant here, but it can be used
// to pass into a 3D texture mapping function to produce some interesting
// environmental reflections.
vec3 eMap(vec3 rd, vec3 sn){
    vec3 sRd = rd; // Save rd, just for some mixing at the end.
    // Add a time component, scale, then pass into the noise function.
    rd.xy -= iTime * speed * 0.25; // Apply animation speed
    rd *= 3.;
    float c = n3D(rd)*.57 + n3D(rd*2.)*.28 + n3D(rd*4.)*.15; // Noise value.
    c = smoothstep(0.5, 1., c); // Darken and add contast for more of a spotlight look.
    //vec3 col = vec3(c, c*c, c*c*c*c).zyx; // Simple, warm coloring.
    vec3 col = vec3(min(c*1.5, 1.), pow(c, 2.5), pow(c, 12.)).zyx; // More color.
    // Mix in some more red to tone it down and return.
    return mix(col, col.yzx, sRd*.25+.25);
}

// === Apply BCS Adjustments to a vec3 Color ===
vec3 applyBCS(vec3 col) {
    // Apply brightness
    col = clamp(col + post_brightness, 0.0, 1.0);

    // Apply contrast
    col = clamp((col - 0.5) * post_contrast + 0.5, 0.0, 1.0);

    // Apply saturation
    vec3 grayscale = vec3(dot(col, vec3(0.299, 0.587, 0.114))); // Luminance
    col = mix(grayscale, col, post_saturation);

    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Screen coordinates.
    vec2 u = fragCoord.xy;

    // Unit direction ray, ray origin (camera position), and light.
    // Apply animation speed to camera/light movement
    vec3 rd = normalize(vec3(u - iResolution.xy*.5, iResolution.y)),
         ro = vec3(-iTime * speed * 0.125, -iTime * speed * 0.05, 0),
         l = ro + vec3(.5, -1.5, -1.);

    // Raymarching against a back plane usually doesn't require many iterations -
    // nor does it require a far-plane break - buy I've given it a few anyway.
    float d, t = 0.;
    int i; // Declare i outside the loop for broader compatibility
    for(i=0; i<64;i++){
        d = map(ro + rd*t); // Distance the nearest surface point.
        if(abs(d)<0.001 || t>FAR) break; // The far-plane break is redundant here.
        t += d*.86; // The accuracy probably isn't needed, but just in case.
    }

    float svObjID = objID; // Store the object ID just after raymarching.

    vec3 sCol = vec3(0); // Scene color.

    // Edge and curvature variables. Passed into the normal function.
    float edge = 0., crv = 1.;

    if(t<FAR){
        vec3 p = ro + rd*t, n = nr(p, edge, crv);//normalize(fract(p) - .5);

        l -= p; // Light to surface vector. Ie: Light direction vector.
        d = max(length(l), 0.001); // Light to surface distance.
        l /= d; // Normalizing the light direction vector.


        // Attenuation and extra shading.
        float atten = 1./(1. + d*d*.05);
        float shade = heightMap(p);


        // Texturing. Because this is a psuedo 3D effect that relies on the isometry of the
        // block pattern, we're texturing isometrically... groan. :) Actually, it's not that
        // bad. Rotate, skew, repeat. You could use tri-planar texturing, but it's doesn't
        // look quite as convincing in this instance.
        //
        // By the way, the blocks aren't perfectly square, but the texturing doesn't seem to
        // be affected.
        vec2 tuv = vec2(0);
        vec3 q = p;
        const mat2 mr3 = mat2(.866025, .5, -.5, .866025); // 60 degrees rotation matrix.
        q.xy *= mr3; // Rotate by 60 degrees to the starting alignment.
        if((n.x)>.002) tuv = vec2((q.x)*.866 - q.y*.5, q.y); // 30, 60, 90 triangle skewing... kind of.
        q.xy *= mr3*mr3; // Rotate twice for 120 degrees... It works, but I'll improve the logic at some stage. :)
        if (n.x<-.002) tuv = vec2((q.x)*.866 - q.y*.5, q.y);
        q.xy *= mr3*mr3; // Rotate twice.
        if (n.y>.002) tuv = vec2((q.x)*.866 - q.y*.5, q.y);

        // Pass in the isometric texture coordinate, roughly convert to linear space (tx*tx), and
        // make the colors more vibrant with the "smoothstep" function.
        vec3 tx = texture(iChannel0, tuv*2.).xyz;
        tx = smoothstep(.05, .5, tx*tx);

        if(svObjID>.5) tx *= vec3(2, .9, .3); // Add a splash of color to the little blocks.


        float ao = cao(p, n); // Ambient occlusion. Tweaked for the this example.


        float diff = max(dot(l, n), 0.); // Diffuse.
        float spec = pow(max(dot(reflect(l, n), rd), 0.), 6.); // Specular.
        //diff = pow(diff, 4.)*0.66 + pow(diff, 8.)*0.34; // Ramping up the diffuse.


        // Cheap way to add an extra color into the mix. Only applied to the small blocks.
        if(svObjID>.5) {
            float rg = dot(sin(p*6. + cos(p.yzx*4. + 1.57/3.)), vec3(.333))*.5 + .5;
            tx = mix(tx, tx.zxy, smoothstep(0.6, 1., rg));
        }


        // Applying the lighting.
        sCol = tx*(diff + .5) + vec3(1, .6, .2)*spec*3.;


        // Alternative, mild strip overlay.
        //sCol *= clamp(sin(shade*6.283*24.)*3. + 1., 0., 1.)*.35 + .65;


        // Adding some cheap environment mapping to help aid the illusion a little more.
        sCol += (sCol*.75 + .25)*eMap(reflect(rd, n), n)*3.; // Fake environment mapping.

        //sCol = pow(sCol, vec3(1.25))*1.25; More contrast, if you were going for that look.

        // Using the 2D block value to provide some extra shading. It's fake, but gives it a
        // more shadowy look.
        sCol *= (smoothstep(0., .5, shade)*.75 + .25);

        // Applying curvature, edging, ambient occlusion and attenuation. You could apply this
        // in one line, but I thought I'd seperate them for anyone who wants to comment them
        // out to see what effect they have.
        sCol *= min(crv, 1.)*.7 + .3;
        sCol *= 1. - edge*.85;
        sCol *= ao*atten;
    }

    // Apply BCS adjustments
    sCol = applyBCS(sCol);

    // Rough gamma correction.
    fragColor = vec4(sqrt(clamp(sCol, 0., 1.)), 1.);
}
