// Inspired by:
//  http://cmdrkitten.tumblr.com/post/172173936860

//---------------------------------------------------------------
// Adjustable Color Definitions:
//---------------------------------------------------------------

// Blob (metaball) color: deep purple (grape tone).
#define object_color vec3(.320, .45, 0.20)

// Background (sky) color: saturated yellow.
#define BACKGROUND_COLOR vec3(0.6, 0.20, 0.0)

//---------------------------------------------------------------
// Other settings remain unchanged:
#define occlusion_enabled
#define occlusion_quality 4
//#define occlusion_preview

#define noise_use_smoothstep

#define light_color vec3(1.,1.,1.)
#define light_direction normalize(vec3(0.2,1.0,-0.2))
#define light_speed_modifier 1.0

#define object_count 9
#define object_speed_modifier 0.6
#define render_steps 33

//---------------------------------------------------------------
// Utility functions
//---------------------------------------------------------------
float hash(float x)
{
	return fract(sin(x * 0.0127863) * 17143.321);
}

float hash(vec2 x)
{
	return fract(cos(dot(x.xy, vec2(2.31, 53.21)) * 124.123) * 412.0); 
}

vec3 cc(vec3 color, float factor, float factor2) // A weird color modifier.
{
	float w = color.x + color.y + color.z;
	return mix(color, vec3(w) * factor, w * factor2);
}

float hashmix(float x0, float x1, float interp)
{
	x0 = hash(x0);
	x1 = hash(x1);
	#ifdef noise_use_smoothstep
	    interp = smoothstep(0.0, 1.0, interp);
	#endif
	return mix(x0, x1, interp);
}

float noise(float p) // 1D noise
{
	float pm = mod(p, 1.0);
	float pd = p - pm;
	return hashmix(pd, pd + 1.0, pm);
}

vec3 rotate_y(vec3 v, float angle)
{
	float ca = cos(angle); 
    float sa = sin(angle);
	return v * mat3(
		ca,  0.0, -sa,
		0.0, 1.0,  0.0,
		sa,  0.0,  ca);
}

vec3 rotate_x(vec3 v, float angle)
{
	float ca = cos(angle); 
    float sa = sin(angle);
	return v * mat3(
		1.0, 0.0,  0.0,
		0.0, ca, -sa,
		0.0, sa,  ca);
}

float max3(float a, float b, float c) // Returns the maximum of 3 values.
{
	return max(a, max(b, c));
}

vec3 bpos[object_count]; // Position for each metaball.

//---------------------------------------------------------------
// Scene Functions
//---------------------------------------------------------------
float dist(vec3 p) // Distance function for the metaballs.
{
	float d = 1920.0;
	float nd;
	for (int i = 0; i < object_count; i++)
	{
		vec3 np = p + bpos[i];
		float shape0 = max3(abs(np.x), abs(np.y), abs(np.z)) - 1.0;
		float shape1 = length(np) - 1.0;
		nd = shape0 + (shape1 - shape0) * 2.0;
		d = mix(d, nd, smoothstep(-1.0, +1.0, d - nd));
	}
	return d;
}

vec3 normal(vec3 p, float e) // Compute normal using the distance function.
{
	float d = dist(p);
	return normalize(vec3(
	    dist(p + vec3(e, 0, 0)) - d,
	    dist(p + vec3(0, e, 0)) - d,
	    dist(p + vec3(0, 0, e)) - d));
}

vec3 light = light_direction; // Global variable holding light direction.

//---------------------------------------------------------------
// Background Function
//---------------------------------------------------------------
vec3 background(vec3 d)
{
	float t = iTime * 0.5 * light_speed_modifier;
	float qq = dot(d, light) * 0.5 + 0.5;
	float bgl = qq;
	float q = (bgl + noise(bgl * 6.0 + t) * 0.85 + noise(bgl * 12.0 + t) * 0.85);
	q += pow(qq, 32.0) * 2.0;
	vec3 sky = BACKGROUND_COLOR * q;
	return sky;
}

float occlusion(vec3 p, vec3 d) // Occlusion from a given direction.
{
	float occ = 1.0;
	p = p + d;
	for (int i = 0; i < occlusion_quality; i++)
	{
		float dd = dist(p);
		p += d * dd;
		occ = min(occ, dd);
	}
	return max(0.0, occ);
}

//---------------------------------------------------------------
// Object Material with Subsurface Scattering (Waxy Effect)
//---------------------------------------------------------------
vec3 object_material(vec3 p, vec3 d)
{
	vec3 color = normalize(object_color * light_color);
	vec3 n = normal(p, 0.1);
	vec3 r = reflect(d, n);	
	
	float reflectance = dot(d, r) * 0.5 + 0.5;
	reflectance = pow(reflectance, 2.0);
	float diffuse = dot(light, n) * 0.5 + 0.5;
	diffuse = max(0.0, diffuse);
	
	#ifdef occlusion_enabled
		float oa = occlusion(p, n) * 0.4 + 0.6;
		float od = occlusion(p, light) * 0.95 + 0.05;
		float os = occlusion(p, r) * 0.95 + 0.05;
	#else
		float oa = 1.0;
	#endif
	
	//-----------------------------------------------------------
	float sss = pow(1.0 - clamp(dot(n, light), 0.0, 1.0), 2.0);
	vec3 subsurface = object_color * 0.3 * sss;
	//-----------------------------------------------------------
	
	#ifndef occlusion_preview
		color = color * oa * 0.2 +              // Ambient
		        color * diffuse * od * 0.7 +      // Diffuse
		        background(r) * os * reflectance * 0.7; // Reflection
		color += subsurface;
	#else
		color = vec3((oa + od + os) * 0.3);
	#endif
	
	return color;
}

#define offset1 4.7
#define offset2 4.6

//---------------------------------------------------------------
// Rounded Rectangle Distance Function for Vignette:
// Returns the distance from point p to the edge of a rounded rectangle
// centered at 'center' with half-size 'halfSize' and corner radius 'r'.
float roundedRect(vec2 p, vec2 center, vec2 halfSize, float r) {
    vec2 d = abs(p - center) - halfSize + vec2(r);
    return length(max(d, vec2(0.0))) - r;
}

//---------------------------------------------------------------
// Main Shader Function
//---------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy - 0.5;
	uv.x *= iResolution.x / iResolution.y; // Fix aspect ratio.
	vec3 mouse = vec3(iMouse.xy / iResolution.xy - 0.5, iMouse.z - 0.5);
	
	float t = iTime * 0.5 * object_speed_modifier + 2.0;
	
	for (int i = 0; i < object_count; i++)
	{
		bpos[i] = 1.3 * vec3(
			sin(t * 0.967 + float(i) * 42.0),
			sin(t * 0.423 + float(i) * 152.0),
			sin(t * 0.76321 + float(i))
		);
	}
	
	vec3 p = vec3(0.0, 0.0, -4.0);
	p = rotate_x(p, mouse.y * 9.0 + offset1);
	p = rotate_y(p, mouse.x * 9.0 + offset2);
	vec3 d = vec3(uv, 1.0);
	d.z -= length(d) * 0.5; // Lens distortion.
	d = normalize(d);
	d = rotate_x(d, mouse.y * 9.0 + offset1);
	d = rotate_y(d, mouse.x * 9.0 + offset2);
	
	float dd;
	vec3 color;
	for (int i = 0; i < render_steps; i++)
	{
		dd = dist(p);
		p += d * dd * 0.7;
		if (dd < 0.04 || dd > 4.0) break;
	}
	
	if (dd < 0.5)
		color = object_material(p, d);
	else
		color = background(d);
	
	color *= 0.7;
	color = mix(color, color * color, 0.3);
	color -= hash(color.xy + uv.xy) * 0.015;
	color -= length(uv) * 0.1;
	color = cc(color, 0.5, 0.6);
	
	//-----------------------------------------------------------
	// Dark Rounded Vignette Effect:
	// Adjustable parameters:
	// vignetteDarkness: 0.0 = no darkening, 1.0 = full black at edges.
	// vignetteBlur: controls the transition width.
	// vignetteRectSize: half-size of the inner bright rectangle (normalized).
	// vignetteCornerRadius: radius for corner rounding (normalized).
	float vignetteDarkness = 0.9;      // Adjust darkness (1.0 means edges become fully black).
	float vignetteBlur = 0.15;          // Adjust transition width (blur).
	float vignetteRectSize = 0.40;     // Adjust inner rectangle half-size.
	float vignetteCornerRadius = 0.2;  // Adjust corner radius.
	
	// Compute normalized screen coordinates (0 to 1).
	vec2 uv_norm = fragCoord.xy / iResolution.xy;
	// Use the rounded rectangle function to compute the distance to the edge of the rectangle.
	// For a vignette that darkens the edges, we want the center to have negative distance.
	float dRect = roundedRect(uv_norm, vec2(0.5), vec2(vignetteRectSize), vignetteCornerRadius);
	// Create a mask that is 1 in the center and 0 at the edges.
	// Here we use smoothstep: when dRect is less than 0, mask is 1; when dRect > vignetteBlur, mask falls to 0.
	float vignetteMask = 1.0 - smoothstep(0.0, vignetteBlur, dRect);
	// Multiply the final color by a factor that darkens edges.
	// At center (mask=1): factor = mix(1.0 - vignetteDarkness, 1.0, 1.0) = 1.0.
	// At edges (mask=0): factor = mix(1.0 - vignetteDarkness, 1.0, 0.0) = 1.0 - vignetteDarkness.
	color *= mix(1.0 - vignetteDarkness, 1.0, vignetteMask);
	//-----------------------------------------------------------
	
	fragColor = vec4(color, 1.0);
}
