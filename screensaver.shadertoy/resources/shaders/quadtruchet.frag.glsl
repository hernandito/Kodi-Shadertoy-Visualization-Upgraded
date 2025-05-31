// Colored setting: White: 0, Spectrum: 1, Pink: 2.
#define COLOR 1

// Showing the different tile layers stacked on top of one another.
//#define STACKED_TILES

// This option produces art deco looking patterns.
//#define INCLUDE_LINE_TILES

// NEW PARAMETERS CONTROLLED BY #DEFINE
// Adjust this value to control the animation speed of the internal patterns.
// 1.0 is normal speed, 0.5 is half speed, 2.0 is double speed.
#define ANIMATION_SPEED 8.0

// Adjust this value to control the overall screen scale of the effect.
// 5.0 is the original scale, higher values make the effect smaller (more visible).
#define SCREEN_SCALE 7.0

// Adjust this value to control the speed at which the entire effect moves and rotates.
// 1.0 is normal speed, 0.5 is half speed, 2.0 is double speed.
#define GLOBAL_ANIMATION_SPEED 0.20

// Brightness adjustment: 0.0 is black, 1.0 is normal, >1.0 is brighter.
#define BRIGHTNESS 1.0
// Contrast adjustment: 0.0 is grey, 1.0 is normal, >1.0 is higher contrast.
#define CONTRAST 1.20
// Saturation adjustment: 0.0 is grayscale, 1.0 is normal, >1.0 is more saturated.
#define SATURATION 1.70


// vec2 to vec2 hash.
vec2 hash22(vec2 p) {
    float n = sin(dot(p, vec2(57, 27)));
    return fract(vec2(262144, 32768)*n);
}

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Function to adjust brightness, contrast, and saturation
vec3 adjustBCS(vec3 color, float brightness, float contrast, float saturation) {
    // Apply brightness
    color *= brightness;

    // Apply contrast
    vec3 avgColor = vec3(0.2126*color.r + 0.7152*color.g + 0.0722*color.b);
    color = mix(avgColor, color, contrast);

    // Apply saturation
    vec3 grayColor = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
    color = mix(grayColor, color, saturation);

    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    // Screen coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;

    // Apply screen scale parameter here. Increasing SCREEN_SCALE will make the effect smaller.
    vec2 oP = uv * SCREEN_SCALE;

    // These transformations define the overall geometry movement.
    // Now controlled by GLOBAL_ANIMATION_SPEED.
    float globalTime = iTime * GLOBAL_ANIMATION_SPEED;
    oP *= r2(sin(globalTime/8.)*3.14159/8.);
    oP -= vec2(cos(globalTime/8.)*0., -globalTime);

    vec4 d = vec4(1e5), d2 = vec4(1e5), grid = vec4(1e5);

    float dim = 1.;

    for(int k=0; k<3; k++){
        vec2 ip = floor(oP*dim);

        for(int j=-1; j<=1; j++){
            for(int i=-1; i<=1; i++){

                vec2 rndIJ = hash22(ip + vec2(i, j));

                vec2 rndIJ2 = hash22(floor((ip + vec2(i, j))/2.));
                vec2 rndIJ4 = hash22(floor((ip + vec2(i, j))/4.));

                // Manually define rndTh.y values for each k, replacing the const array.
                float rndTh_y_k0 = 0.35;
                float rndTh_y_k1 = 0.7;
                float rndTh_y_k2 = 1.0;

                // If the previous large tile has been rendered, continue.
                if(k==1 && rndIJ2.y < rndTh_y_k0) continue;
                // If any of the two previous larger tiles have been rendered, continue.
                if(k==2 && (rndIJ2.y < rndTh_y_k1 || rndIJ4.y < rndTh_y_k0)) continue;

                // Determine the current rndTh.y and rndTh.x values based on k
                float current_rndTh_y;
                float current_rndTh_x = 0.5; // All rndTh.x values are 0.5 in the original code

                if (k == 0) current_rndTh_y = rndTh_y_k0;
                else if (k == 1) current_rndTh_y = rndTh_y_k1;
                else current_rndTh_y = rndTh_y_k2; // k == 2

                if(rndIJ.y < current_rndTh_y){
                    vec2 p = oP - (ip + .5 + vec2(i, j))/dim;

                    float square = max(abs(p.x), abs(p.y)) - .5/dim;

                    const float lwg = .01;
                    float gr = abs(square) - lwg/2.;
                    grid.x = min(grid.x, gr);

                    if(rndIJ.x < current_rndTh_x) p.xy = p.yx;
                    if(fract(rndIJ.x*57.543 + .37) < current_rndTh_x) p.x = -p.x;

                    vec2 p2 = abs(vec2(p.y - p.x, p.x + p.y)*.7071) - vec2(.5, .5)*.7071/dim;
                    float c3 = length(p2) - .5/3./dim;

                    float c, c2;

                    c = abs(length(p - vec2(-.5, .5)/dim) - .5/dim) - .5/3./dim;

                    if(fract(rndIJ.x*157.763 + .49)>.35){
                        c2 = abs(length(p - vec2(.5, -.5)/dim) - .5/dim) - .5/3./dim;
                    }
                    else{
                        c2 = length(p -  vec2(.5, 0)/dim) - .5/3./dim;
                        c2 = min(c2, length(p -  vec2(0, -.5)/dim) - .5/3./dim);
                    }

                    #ifdef INCLUDE_LINE_TILES
                        if(fract(rndIJ.x*113.467 + .51)<.35){
                            c = abs(p.x) - .5/3./dim;
                        }
                        if(fract(rndIJ.x*123.853 + .49)<.35){
                            c2 = abs(p.y) - .5/3./dim;
                        }
                    #endif

                    float truchet = min(c, c2);

                    #ifdef INCLUDE_LINE_TILES
                        float lne = abs(c - .5/12./4.) - .5/12./4.;
                        truchet = max(truchet, -lne);
                    #endif

                    c = min(c3, max(square, truchet));
                    d[k] = min(d[k], c);

                    p = abs(p) - .5/dim;
                    float l = length(p);
                    c = min(l - 1./3./dim, square);
                    d2[k] = min(d2[k], c);

                    grid.y = min(grid.y, l - .5/8./sqrt(dim));
                    grid.z = min(grid.z, l);
                    grid.w = dim;
                }
            }
        }
        dim *= 2.;
    }

    vec3 col = vec3(.25);

    // This variable scales the iTime for internal pattern animations using ANIMATION_SPEED.
    float animatedTime = iTime * ANIMATION_SPEED;

    // pat3 does not use iTime directly, its animation is tied to oP's geometry.
    float pat3 = clamp(sin((oP.x - oP.y)*6.283*iResolution.y/24.)*1. + .9, 0., 1.)*.25 + .75;

    float fo = 5./iResolution.y;

    vec3 pCol2 = vec3(.125);
    vec3 pCol1 = vec3(1);

    #if COLOR == 1
    pCol1 = vec3(.7, 1.4, .4);
    #elif COLOR == 2
    pCol1 = mix(vec3(1, .1, .2), vec3(1, .1, .5), uv.y*.5 + .5);
    pCol2 = vec3(.1, .02, .06);
    #endif

    #ifdef STACKED_TILES
        float pw = .02;
        d -= pw/2.;
        d2 -= pw/2.;

        for (int k=0; k<3; k++){
            col = mix(col, vec3(0), (1. - smoothstep(0., fo*5., d2[k]))*.35);
            col = mix(col, vec3(0), 1. - smoothstep(0., fo, d2[k]));
            col = mix(col, pCol2, 1. - smoothstep(0., fo, d2[k] + pw));

            col = mix(col, vec3(0), (1. - smoothstep(0., fo*5., d[k]))*.35);
            col = mix(col, vec3(0), 1. - smoothstep(0., fo, d[k]));
            col = mix(col, pCol1, 1. - smoothstep(0., fo, d[k] + pw));

            vec3 temp = pCol1; pCol1 = pCol2; pCol2 = temp;
        }
        col *= pat3;
    #else
        d.x = max(d2.x, -d.x);
        d.x = min(max(d.x, -d2.y), d.y);
        d.x = max(min(d.x, d2.z), -d.z);

        // These patterns now include the animatedTime for controllable animation.
        float pat = clamp(-sin(d.x*6.283*20. + animatedTime) - .0, 0., 1.);
        float pat2 = clamp(sin(d.x*6.283*16. + animatedTime)*1. + .9, 0., 1.)*.3 + .7;
        float sh = clamp(.75 + d.x*2., 0., 1.);

        #if COLOR == 1
            col *= pat;

            d.x = -(d.x + .03);

            col = mix(col, vec3(0), (1. - smoothstep(0., fo*5., d.x)));
            col = mix(col, vec3(0), 1. - smoothstep(0., fo, d.x));
            col = mix(col, vec3(.8, 1.2, .6), 1. - smoothstep(0., fo*2., d.x + .02));
            col = mix(col, vec3(0), 1. - smoothstep(0., fo*2., d.x + .03));
            col = mix(col, vec3(.7, 1.4, .4)*pat2, 1. - smoothstep(0., fo*2., d.x + .05));

            col *= sh;
        #else
            col = pCol1;

            col = mix(col, vec3(0), (1. - smoothstep(0., fo*5., d.x))*.35);
            col = mix(col, vec3(0), 1. - smoothstep(0., fo, d.x));
            col = mix(col, pCol2, 1. - smoothstep(0., fo, d.x + .02));

            col *= pat3;
        #endif
    #endif

    // Mild spotlight.
    col *= max(1.15 - length(uv)*.5, 0.);

    if(iMouse.z>0.){
        vec3 vCol1 = vec3(.8, 1, .7);
        vec3 vCol2 = vec3(1, .7, .4);

        #if COLOR == 2
        vCol1 = vCol1.zxy;
        vCol2 = vCol2.zyx;
        #endif

        vec3 bg = col;
        col = mix(col, vec3(0), (1. - smoothstep(0., .02, grid.x - .02))*.7);
        col = mix(col, vCol1 + bg/2., 1. - smoothstep(0., .01, grid.x));

        fo = 10./iResolution.y/sqrt(grid.w);
        col = mix(col, vec3(0), (1. - smoothstep(0., fo*3., grid.y - .02))*.5);
        col = mix(col, vec3(0), 1. - smoothstep(0., fo, grid.y - .02));
        col = mix(col, vCol2, 1. - smoothstep(0., fo, grid.y));
        col = mix(col, vec3(0), 1. - smoothstep(0., fo, grid.z - .02/sqrt(grid.w)));
    }

    // Apply Brightness, Contrast, and Saturation
    col = adjustBCS(col, BRIGHTNESS, CONTRAST, SATURATION);

    #if COLOR == 1
    col = mix(col, col.yxz, uv.y*.75 + .5);
    col = mix(col, col.zxy, uv.x*.7 + .5);
    #endif

    // Rough gamma correction, and output to the screen.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}
