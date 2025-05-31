// CC0: Twitter truchet
// Saw neat multi-level truchet on twitter: https://x.com/byt3m3chanic/status/1828407777777777777
// Thought I should try to recreate it. Adding a little red to it as in the tweet would be nice
// but now I am too tired.

// Removed explicit uniform declarations to avoid redeclaration conflicts

#define TIME        iTime*.2
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

const float wlw = 0.125/2.; // Width of background gaps

float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

vec4 truchet0(vec2 p, float lineThickness) {
  float
    d0 = abs(length(p-0.5)-0.5)-wlw*4.,
    d1 = abs(length(p+0.5)-0.5)-wlw*4.,
    d2 = abs(d0)-lineThickness*4.,
    d3 = abs(d1)-lineThickness*4.;
  return vec4(d0,d1, d2,d3);
}

void rot4(inout vec2 p, float h) {
  if (h < 1./4.) {
  } else if (h < 2./4.) {
    p = vec2(p.y, -p.x);
  } else if (h < 3./4.) {
    p *= -1.;
  } else {
    p = vec2(-p.y, p.x);
  }
}

vec4 truchet1(vec2 p, float lineThickness) {
  float
    d0 = abs(length(p-0.5)-0.5),
    d1 = abs(length(p+0.5)-0.5),
    d2 = d0-wlw*6.,
    d3 = d1-wlw*6.,
    d4 = abs(d0-wlw*4.)-wlw*2.,
    d5 = abs(d1-wlw*4.)-wlw*2.;
  d4 = abs(d4)-lineThickness*2.;
  d5 = abs(d5)-lineThickness*2.;

  return vec4(d2,d3, d4,d5);
}

vec4 truchet2(vec2 p, float lineThickness) {
  float
    d0 = abs(length(p-0.5)-0.5),
    d1 = abs(length(p+0.5)-0.5),
    d2 = d0-wlw*7.,
    d3 = d1-wlw*7.,
    d4 = abs(d0-wlw*2.)-wlw,
    d5 = abs(d1-wlw*2.)-wlw,
    d6 = abs(d0-wlw*6.)-wlw,
    d7 = abs(d1-wlw*6.)-wlw,
    d8 = min(d4, d6),
    d9 = min(d5, d7);
  d8 = abs(d8)-lineThickness;
  d9 = abs(d9)-lineThickness;

  return vec4(d2,d3, d8,d9);
}

vec3 cell0(vec3 col, vec2 p, float aa, vec3 bgColor, vec3 lineColor, float lineThickness) {
  vec2 tp = p;
  vec2 tn = floor(tp);
  tp -= tn+0.5;

  float h0 = hash(tn+123.4);
  rot4(tp, h0);

  vec4 dt = truchet0(tp, lineThickness);

  col = mix(col, bgColor, smoothstep(aa, -aa, dt.x));
  col = mix(col, lineColor, smoothstep(aa, -aa, dt.z));

  col = mix(col, bgColor, smoothstep(aa, -aa, dt.y));
  col = mix(col, lineColor, smoothstep(aa, -aa, dt.w));

  return col;
}

vec3 cell1(vec3 col, vec2 p, float aa, vec3 bgColor, vec3 lineColor, float lineThickness) {
  vec2 tp = p;
  vec2 tn = floor(tp);
  tp -= tn+0.5;

  float
    h0 = hash(tn+123.45),
    h1 = fract(8667.0*h0);

  if (h1 > 2./3.) {
    return cell0(col, 2.*p, 2.*aa, bgColor, lineColor, lineThickness);
  } else {
    rot4(tp, h0);
    vec4 dt = truchet1(tp, lineThickness);

    col = mix(col, bgColor, smoothstep(aa, -aa, dt.x));
    col = mix(col, lineColor, smoothstep(aa, -aa, dt.z));

    col = mix(col, bgColor, smoothstep(aa, -aa, dt.y));
    col = mix(col, lineColor, smoothstep(aa, -aa, dt.w));
  }

  return col;
}

vec3 cell2(vec3 col, vec2 p, float aa, vec3 bgColor, vec3 lineColor, float lineThickness) {
  vec2 tp = p;
  vec2 tn = floor(tp);
  tp -= tn+0.5;

  float
    h0 = hash(tn+123.456),
    h1 = fract(8667.0*h0);

  if (h1 > 1./3.) {
    return cell1(col, 2.*p, 2.*aa, bgColor, lineColor, lineThickness);
  } else {
    rot4(tp, h0);
    vec4 dt = truchet2(tp, lineThickness);

    col = mix(col, bgColor, smoothstep(aa, -aa, dt.x));
    col = mix(col, lineColor, smoothstep(aa, -aa, dt.z));

    col = mix(col, bgColor, smoothstep(aa, -aa, dt.y));
    col = mix(col, lineColor, smoothstep(aa, -aa, dt.w));
  }

  return col;
}

vec3 effect(vec2 p, vec3 bgColor, vec3 lineColor, float lineThickness, float rotationAngle, vec2 rotationCenter) {
  float angle = rotationAngle;
  vec2 rotatedP = p - rotationCenter;
  rotatedP = rotatedP * ROT(angle);
  rotatedP += rotationCenter;

  vec3 col = bgColor;
  float aa = sqrt(2.)/RESOLUTION.y;

  float iz = 2.;
  vec2 tp = rotatedP;

  const float per = 10.;
  float a = TIME/per+100.;
  tp += (per*0.25)*sin(vec2(sqrt(0.5), 1.)*a);

  tp *= iz;
  float taa = aa*iz;

  col = cell2(col, tp, taa, bgColor, lineColor, lineThickness);

  return col;
}

// --- 3D Cube Parameters ---
float cubeSize = 0.25;
vec3 cubeColor = vec3(0.7, 0.05, 0.05);
float cubeRotationSpeed = 0.3;
vec3 cubePosition = vec3(0.0, 0.0, 0.0);
float cubeRoundness = 0.05;
float cubeGlossLevel = 64.0;
vec3 cubeSpecularColor = vec3(1.0, 0.9, 0.8);

// --- Light Parameters ---
vec3 light1Offset = vec3(-0.7, 1.2, -0.7);
vec3 light1Color = vec3(1.0, 0.8, 0.6);
float light1Intensity = 1.5;
vec3 light2Offset = vec3(0.7, 1.2, -0.7);
vec3 light2Color = vec3(0.9, 0.7, 0.5);
float light2Intensity = 1.0;

// --- Faux Shadow Parameters ---
float fauxShadowRadius = 0.11;
float fauxShadowSoftness = 0.05;
float fauxShadowStrength = 1.0;
float fauxShadowTransparency = 0.1;
float fauxShadowOffsetX = 0.02;
float fauxShadowOffsetY = -0.05;

// Signed Distance Function for a rounded box
float sdRoundedBox(vec3 p, vec3 b, float r) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

// Raymarch function for the cube
float raymarchCube(vec3 ro, vec3 rd, float maxDist, float currentCubeRotationAngle, vec3 cubePos, float size, float roundness) {
    float t = 0.0;
    for (int i = 0; i < 60; i++) {
        vec3 p = ro + rd * t;
        vec3 p_local = p - cubePos;
        p_local.xz = ROT(-currentCubeRotationAngle) * p_local.xz;
        float d = sdRoundedBox(p_local, vec3(size), roundness);
        if (d < 0.001) return t;
        t += d;
        if (t > maxDist) break;
    }
    return maxDist;
}

// Calculate Phong shading for a surface
vec3 calculatePhong(vec3 surfPos, vec3 surfNormal, vec3 viewDir, vec3 lightPos, vec3 lightColor, float lightIntensity, vec3 diffuseColor, vec3 specularColor, float glossiness) {
    vec3 lightDir = normalize(lightPos - surfPos);
    float diff = max(dot(surfNormal, lightDir), 0.0);
    vec3 reflectedDir = reflect(-lightDir, surfNormal);
    float spec = pow(max(dot(reflectedDir, viewDir), 0.0), glossiness);

    vec3 ambient = diffuseColor * 0.2;
    vec3 diffuse = diffuseColor * diff * lightColor * lightIntensity;
    vec3 specular = specularColor * spec * lightColor * lightIntensity;

    return ambient + diffuse + specular;
}

// Renders the 3D cube and returns its color
vec4 renderCube(vec2 fragCoord, vec3 resolution, float time, vec2 screenQuadrantCenter) {
    vec3 ro_cube = vec3(0.0, 0.5, -2.0);
    vec3 ta_cube = vec3(0.0, 0.0, 0.0);

    float currentCubeRotationAngle = time * cubeRotationSpeed;

    vec3 fw_cube = normalize(ta_cube - ro_cube);
    vec3 up_cube = vec3(0.0, 1.0, 0.0);
    vec3 cu_cube = normalize(cross(fw_cube, up_cube));
    vec3 cv_cube = normalize(cross(cu_cube, fw_cube));

    vec2 local_fragCoord = fragCoord.xy - screenQuadrantCenter;
    vec2 uv_cube = local_fragCoord / (resolution.y * 0.5);
    vec3 rd_cube = normalize(uv_cube.x * cu_cube + uv_cube.y * cv_cube + fw_cube);

    float t_hit = raymarchCube(ro_cube, rd_cube, 100.0, currentCubeRotationAngle, cubePosition, cubeSize, cubeRoundness);

    if (t_hit < 100.0) {
        vec3 hitPos = ro_cube + rd_cube * t_hit;
        vec3 hitPos_local = hitPos - cubePosition;
        hitPos_local.xz = ROT(-currentCubeRotationAngle) * hitPos_local.xz;

        vec3 normal = normalize(vec3(
            sdRoundedBox(hitPos_local + vec3(0.001, 0.0, 0.0), vec3(cubeSize), cubeRoundness) - sdRoundedBox(hitPos_local - vec3(0.001, 0.0, 0.0), vec3(cubeSize), cubeRoundness),
            sdRoundedBox(hitPos_local + vec3(0.0, 0.001, 0.0), vec3(cubeSize), cubeRoundness) - sdRoundedBox(hitPos_local - vec3(0.0, 0.001, 0.0), vec3(cubeSize), cubeRoundness),
            sdRoundedBox(hitPos_local + vec3(0.0, 0.0, 0.001), vec3(cubeSize), cubeRoundness) - sdRoundedBox(hitPos_local - vec3(0.0, 0.0, 0.001), vec3(cubeSize), cubeRoundness)
        ));
        normal.xz = ROT(currentCubeRotationAngle) * normal.xz;

        vec3 viewDir = -rd_cube;

        vec3 finalColor = vec3(0.0);
        vec3 light1WorldPos = cubePosition + light1Offset;
        vec3 light2WorldPos = cubePosition + light2Offset;

        finalColor += calculatePhong(hitPos, normal, viewDir, light1WorldPos, light1Color, light1Intensity, cubeColor, cubeSpecularColor, cubeGlossLevel);
        finalColor += calculatePhong(hitPos, normal, viewDir, light2WorldPos, light2Color, light2Intensity, cubeColor, cubeSpecularColor, cubeGlossLevel);

        return vec4(finalColor, 1.0);
    }
    return vec4(0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  float backgroundRotationSpeed = 0.1;
  vec2 backgroundRotationCenter = vec2(0.75, 0.25);

  vec3 bgColor = vec3(0.82, 0.5, 0);
  vec3 lineColor = vec3(0.0);
  float lineThickness = 0.035;

  float background_angle = backgroundRotationSpeed * TIME;

  vec3 background_col = effect(p, bgColor, lineColor, lineThickness, background_angle, backgroundRotationCenter);
  background_col = sqrt(background_col);

  vec2 cubeScreenCenter = vec2(RESOLUTION.x * 0.25, RESOLUTION.y * 0.75);

  vec4 cube_render_output = renderCube(fragCoord, RESOLUTION.xyz, iTime, cubeScreenCenter);
  vec3 cube_col = cube_render_output.rgb;
  float cube_hit_flag = cube_render_output.a;

  vec3 final_color;

  if (cube_hit_flag > 0.5) {
      final_color = cube_col;
  } else {
      final_color = background_col;
      
      vec2 shadowScreenCenter = cubeScreenCenter + vec2(fauxShadowOffsetX, fauxShadowOffsetY) * RESOLUTION.y;
      float dist_to_shadow_center = length(fragCoord.xy - shadowScreenCenter);
      float shadow_factor = smoothstep(fauxShadowRadius * RESOLUTION.y, 
                                       (fauxShadowRadius + fauxShadowSoftness) * RESOLUTION.y, 
                                       dist_to_shadow_center);
      shadow_factor = 1.0 - shadow_factor;
      float final_shadow_effect = shadow_factor * fauxShadowStrength * (1.0 - fauxShadowTransparency);
      final_color = mix(final_color, final_color * (1.0 - final_shadow_effect), final_shadow_effect);
  }

  vec2 uv_vignette = fragCoord.xy / RESOLUTION.xy;
  uv_vignette *= 1.0 - uv_vignette.yx;
  float vignetteIntensity = 25.0;
  float vignettePower = 0.60;
  float vig = uv_vignette.x * uv_vignette.y * vignetteIntensity;
  vig = pow(vig, vignettePower);

  const float ditherStrength = 0.05;
  int x = int(mod(fragCoord.x, 2.0));
  int y = int(mod(fragCoord.y, 2.0));
  float dither = 0.0;
  if (x == 0 && y == 0) dither = 0.25 * ditherStrength;
  else if (x == 1 && y == 0) dither = 0.75 * ditherStrength;
  else if (x == 0 && y == 1) dither = 0.75 * ditherStrength;
  else if (x == 1 && y == 1) dither = 0.25 * ditherStrength;
  vig = clamp(vig + dither, 0.0, 1.0);

  final_color *= vig;

  fragColor = vec4(final_color, 1.0);
}