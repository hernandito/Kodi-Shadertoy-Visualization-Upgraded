/*
    Original Source edited by David Hoskins - 2013.
    Modified to include background effects from "Deadly Halftones" by Julien Vergnaud @duvengar-2018:
    - Dark blue background with noise effect
    - Thin horizontal scanline effect
    - Screen vignette effect
    - Added BCS (Brightness, Contrast, Saturation) adjustments in post-processing
*/

// I took and completed this http://glsl.heroku.com/e#9743.20 - just for fun! 8|
// Locations in 3x7 font grid, inspired by http://www.claudiocc.com/the-1k-notebook-part-i/
// Had to edit it to remove some duplicate lines.
// ABC  a:GIOMJL b:AMOIG c:IGMO d:COMGI e:OMGILJ f:CBN g:OMGIUS h:AMGIO i:EEHN j:GHTS k:AMIKO l:BN m:MGHNHIO n:MGIO
// DEF  o:GIOMG p:SGIOM q:UIGMO r:MGI s:IGJLOM t:BNO u:GMOI v:GJNLI w:GMNHNOI x:GOKMI y:GMOIUS z:GIMO
// GHI
// JKL 
// MNO
// PQR
// STU

// --- Common Definitions from "Deadly Halftones" (Renamed to Avoid Conflicts) ---
#define MACRO_TIME iTime
#define MACRO_RES iResolution.xy
#define MACRO_SMOOTH(a, b, c) smoothstep(a, b, c)

// --- Define Background Color Here for Easy Tweaking ---
#define BACKGROUND_COLOR vec4(0, 0.149, 0.114, 1.) // Dark blue background color (tweakable)

// --- Define BCS Adjustments Here for Easy Tweaking ---
#define BRIGHTNESS -0.070 // Range: -1.0 to 1.0 (0.0 is neutral)
#define CONTRAST 1.30   // Range: 0.0 to 2.0 (1.0 is neutral)
#define SATURATION 1.0 // Range: 0.0 to 2.0 (1.0 is neutral)

// --- Define Line Spacing Parameter ---
#define LINE_SPACING 0.14 // Adjustable vertical spacing between lines (default value)

// --- Define Glow Brightness Parameter ---
#define GLOW_BRIGHTNESS 3.25 // Adjustable brightness of letter glow (default matches original)

// --- Noise Function from "Deadly Halftones" ---
float hash2(vec2 p) {  
    vec3 p3 = fract(vec3(p.xyx) * .2831);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// --- BCS Adjustment Function ---
vec4 adjustBCS(vec4 color, float brightness, float contrast, float saturation) {
    // Brightness: Add the brightness value to RGB components
    vec3 result = color.rgb + vec3(brightness);
    
    // Contrast: Adjust around the midpoint (0.5)
    result = (result - 0.5) * contrast + 0.5;
    
    // Saturation: Blend with luminance to adjust saturation
    float luminance = dot(result, vec3(0.299, 0.587, 0.114)); // Standard luminance weights
    result = mix(vec3(luminance), result, saturation);
    
    // Clamp the result to valid range and preserve alpha
    return vec4(clamp(result, 0.0, 1.0), color.a);
}

// --- Original Shader Code ---
vec2 coord;

#define font_size 28.8 //  Original value = 24  to make smaller (multiply by % factor ie 24 x 1.2 (20%) = 28.8
#define font_spacing .036  //  Original value = .045 to make smaller, (multiply by % factor ie .045 x .80 (20%) = .036
vec2 caret_origin = vec2(2.10, 0.65);
vec2 caret;

#define STROKEWIDTH 0.05
#define PI 3.14159265359

#define A_ vec2(0.,0.)
#define B_ vec2(1.,0.)
#define C_ vec2(2.,0.)

#define E_ vec2(1.,1.)

#define G_ vec2(0.,2.)
#define H_ vec2(1.,2.)
#define I_ vec2(2.,2.)

#define J_ vec2(0.,3.)
#define K_ vec2(1.,3.)
#define L_ vec2(2.,3.)

#define M_ vec2(0.,4.)
#define N_ vec2(1.,4.)
#define O_ vec2(2.,4.)

#define S_ vec2(0.,6.)
#define T_ vec2(1.,6.)
#define U_ vec2(2.0,6.)

#define A(p) t(G_,I_,p) + t(I_,O_,p) + t(O_,M_, p) + t(M_,J_,p) + t(J_,L_,p);caret.x += 1.0;
#define B(p) t(A_,M_,p) + t(M_,O_,p) + t(O_,I_, p) + t(I_,G_,p);caret.x += 1.0;
#define C(p) t(I_,G_,p) + t(G_,M_,p) + t(M_,O_,p);caret.x += 1.0;
#define D(p) t(C_,O_,p) + t(O_,M_,p) + t(M_,G_,p) + t(G_,I_,p);caret.x += 1.0;
#define E(p) t(O_,M_,p) + t(M_,G_,p) + t(G_,I_,p) + t(I_,L_,p) + t(L_,J_,p);caret.x += 1.0;
#define F(p) t(C_,B_,p) + t(B_,N_,p) + t(G_,I_,p);caret.x += 1.0;
#define G(p) t(O_,M_,p) + t(M_,G_,p) + t(G_,I_,p) + t(I_,U_,p) + t(U_,S_,p);caret.x += 1.0;
#define H(p) t(A_,M_,p) + t(G_,I_,p) + t(I_,O_,p);caret.x += 1.0;
#define I(p) t(E_,E_,p) + t(H_,N_,p);caret.x += 1.0;
#define J(p) t(E_,E_,p) + t(H_,T_,p) + t(T_,S_,p);caret.x += 1.0;
#define K(p) t(A_,M_,p) + t(M_,I_,p) + t(K_,O_,p);caret.x += 1.0;
#define L(p) t(B_,N_,p);caret.x += 1.0;
#define M(p) t(M_,G_,p) + t(G_,I_,p) + t(H_,N_,p) + t(I_,O_,p);caret.x += 1.0;
#define N(p) t(M_,G_,p) + t(G_,I_,p) + t(I_,O_,p);caret.x += 1.0;
#define O(p) t(G_,I_,p) + t(I_,O_,p) + t(O_,M_, p) + t(M_,G_,p);caret.x += 1.0;
#define P(p) t(S_,G_,p) + t(G_,I_,p) + t(I_,O_,p) + t(O_,M_, p);caret.x += 1.0;
#define Q(p) t(U_,I_,p) + t(I_,G_,p) + t(G_,M_,p) + t(M_,O_, p);caret.x += 1.0;
#define R(p) t(M_,G_,p) + t(G_,I_,p);caret.x += 1.0;
#define S(p) t(I_,G_,p) + t(G_,J_,p) + t(J_,L_,p) + t(L_,O_,p) + t(O_,M_,p);caret.x += 1.0;
#define T(p) t(B_,N_,p) + t(N_,O_,p) + t(G_,I_,p);caret.x += 1.0;
#define U(p) t(G_,M_,p) + t(M_,O_,p) + t(O_,I_,p);caret.x += 1.0;
#define V(p) t(G_,J_,p) + t(J_,N_,p) + t(N_,L_,p) + t(L_,I_,p);caret.x += 1.0;
#define W(p) t(G_,M_,p) + t(M_,O_,p) + t(N_,H_,p) + t(O_,I_,p);caret.x += 1.0;
#define X(p) t(G_,O_,p) + t(I_,M_,p);caret.x += 1.0;
#define Y(p) t(G_,M_,p) + t(M_,O_,p) + t(I_,U_,p) + t(U_,S_,p);caret.x += 1.0;
#define Z(p) t(G_,I_,p) + t(I_,M_,p) + t(M_,O_,p);caret.x += 1.0;
#define STOP(p) t(N_,N_,p);caret.x += 1.0;

//-----------------------------------------------------------------------------------
float minimum_distance(vec2 v, vec2 w, vec2 p)
{	// Return minimum distance between line segment vw and point p
  	float l2 = (v.x - w.x)*(v.x - w.x) + (v.y - w.y)*(v.y - w.y); //length_squared(v, w);  // i.e. |w-v|^2 -  avoid a sqrt
  	if (l2 == 0.0) {
		return distance(p, v);   // v == w case
	}
	
	// Consider the line extending the segment, parameterized as v + t (w - v).
  	// We find projection of point p onto the line.  It falls where t = [(p-v) . (w-v)] / |w-v|^2
  	float t = dot(p - v, w - v) / l2;
  	if(t < 0.0) {
		// Beyond the 'v' end of the segment
		return distance(p, v);
	} else if (t > 1.0) {
		return distance(p, w);  // Beyond the 'w' end of the segment
	}
  	vec2 projection = v + t * (w - v);  // Projection falls on the segment
	return distance(p, projection);
}

//-----------------------------------------------------------------------------------
float textColor(vec2 from, vec2 to, vec2 p)
{
	p *= font_size;
	float inkNess = 0., nearLine, corner;
	nearLine = minimum_distance(from,to,p); // basic distance from segment, thanks http://glsl.heroku.com/e#6140.0
	inkNess += smoothstep(0., 1., 1.- 14.*(nearLine - STROKEWIDTH)); // core letter brightness
	inkNess += smoothstep(0., GLOW_BRIGHTNESS, 1.- (nearLine + 5. * STROKEWIDTH)); // glow brightness
	return inkNess;
}

//-----------------------------------------------------------------------------------
vec2 grid(vec2 letterspace) 
{
	return ( vec2( (letterspace.x / 2.) * .65 , 1.0-((letterspace.y / 2.) * .95) ));
}

//-----------------------------------------------------------------------------------
float count = 0.0;
float gtime;
float t(vec2 from, vec2 to, vec2 p) 
{
	count++;
	if (count > gtime*40.0) return 0.0;
	return textColor(grid(from), grid(to), p);
}

//-----------------------------------------------------------------------------------
vec2 r()
{
	vec2 pos = coord.xy/iResolution.xy;
	pos.y -= caret.y;
	pos.x -= font_spacing*caret.x;
	return pos;
}

//-----------------------------------------------------------------------------------
void _()
{
	caret.x += 1.5;
}

//-----------------------------------------------------------------------------------
void newline()
{
	caret.x = caret_origin.x;
	caret.y -= LINE_SPACING; // Use LINE_SPACING for vertical adjustment
}

//-----------------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float time = mod(iTime, 11.0);
    gtime = time;

    float d = 0.;

    // --- Background Effects from "Deadly Halftones" ---
    vec2 U = fragCoord;
    vec2 V = 1. - 2. * U / MACRO_RES;

    // 1. Dark Blue Background with Noise (Using Defined Color)
    fragColor = BACKGROUND_COLOR; // Use the defined background color
    fragColor += .06 * hash2(MACRO_TIME + V * vec2(1462.439, 297.185)); // Noise effect

    // --- Text Rendering ---
    vec3 col = vec3(0.0); // Initialize col for text rendering
    coord = fragCoord;
    caret = caret_origin;
// =====================================
//  START OF COPY TO BE RENDERED 
// =====================================


    d += S(r()); d += O(r()); d += Y(r()); d += L(r()); d += E(r()); d += N(r()); d += T(r()); _();	
	d += G(r()); d += R(r()); d += E(r()); d += E(r()); d += N(r()); _();	
	d += I(r()); d += S(r()); _();	
newline();	
	d += M(r()); d += A(r()); d += D(r()); d += E(r()); _();	
	d += O(r()); d += U(r()); d += T(r()); _();	
	d += O(r()); d += F(r()); _();	
	d += P(r()); d += E(r()); d += O(r()); d += P(r()); d += L(r()); d += E(r()); d += STOP(r()); d += STOP(r()); d += STOP(r()); _();	


// =====================================
// END OF TEXT COPY
// =====================================

    col += vec3(d * .5, d, d * .85);
    fragColor += vec4(col, 0.0); // Add glowing text to background

    // --- Post-Processing Effects from "Deadly Halftones" ---
    // 2. Vignette Effect
    fragColor *= 1.25 * vec4(1. - MACRO_SMOOTH(.1, 1.8, length(V * V)));
    fragColor += .14 * vec4(pow(1. - length(V * vec2(.5, .35)), 3.), .0, .0, 1.);

    // 3. Horizontal Scanline Effect
    float scanLine = 0.75 + .35 * sin(fragCoord.y * 1.9); // Adjusted frequency and amplitude
    fragColor *= scanLine;

    // --- Original Vignette (Preserved) ---
    vec2 xy = fragCoord.xy / iResolution.xy;
    fragColor *= vec4(.4, .4, .3, 1.0) + 0.5 * pow(100.0 * xy.x * xy.y * (1.0 - xy.x) * (1.0 - xy.y), .4);

    // --- Final BCS Adjustment ---
    fragColor = adjustBCS(fragColor, BRIGHTNESS, CONTRAST, SATURATION);
}

/* 



Soylent Green is made out of people	
    d += S(r()); d += O(r()); d += O(r()); d += L(r()); d += E(r()); d += N(r()); d += T(r()); _();	
	d += G(r()); d += R(r()); d += E(r()); d += E(r()); d += N(r()); _();	
	d += I(r()); d += S(r()); _();	
newline();	
	d += M(r()); d += A(r()); d += D(r()); d += E(r()); _();	
	d += O(r()); d += U(r()); d += T(r()); _();	
	d += O(r()); d += F(r()); _();	
	d += P(r()); d += E(r()); d += O(r()); d += P(r()); d += L(r()); d += E(r()); d += STOP(r()); _();		






Who is John Gault. We should all be.	
    // who is
    d += W(r());  d += H(r()); d += O(r()); _();
    d += I(r()); d += S(r()); _();
    
    newline();
    // john gault 
    d += J(r()); d += O(r()); d += H(r()); d += N(r()); _();
    d += G(r()); d += A(r()); d += U(r()); d += L(r()); d += T(r()); d += STOP(r()); d += STOP(r()); d += STOP(r()); _();
    newline();
    newline();
    
    // we should all be
    d += W(r()); d += E(r());  _();
    d += S(r()); d += H(r()); d += O(r()); d += U(r()); d += L(r()); d += D(r()); _();
    d += A(r()); d += L(r()); d += L(r()); _();
    d += B(r()); d += E(r()); d += STOP(r());  _();	
	

Ensure return of 
organism for analysis 
All other considerations
secondary.Crew is
expendable.

	d += E(r()); d += N(r()); d += S(r()); d += U(r()); d += R(r()); d += E(r()); _();	
	d += R(r()); d += E(r()); d += T(r()); d += U(r()); d += R(r()); d += N(r()); _();	
	d += O(r()); d += F(r()); _();	
newline();	
	d += O(r()); d += R(r()); d += G(r()); d += A(r()); d += N(r()); d += I(r()); d += S(r()); d += M(r()); _();	
	d += F(r()); d += O(r()); d += R(r()); _();	
	d += A(r()); d += N(r()); d += A(r()); d += Y(r()); d += S(r()); d += I(r()); d += S(r()); d += STOP(r()); _();		
newline();	
	d += A(r()); d += L(r()); d += L(r()); _();	
	d += O(r()); d += T(r()); d += H(r()); d += E(r()); d += R(r()); _();		
	d += C(r()); d += O(r()); d += N(r()); d += S(r()); d += I(r()); d += D(r()); d += E(r()); d += R(r()); d += A(r()); d += T(r()); ; d += I(r()); d += O(r()); d += N(r()); ; d += S(r()); _();	
newline();		
	d += S(r()); d += E(r()); d += C(r()); d += O(r()); d += N(r()); d += D(r()); d += A(r()); d += R(r()); d += Y(r()); d += STOP(r()); _();
	d += C(r()); d += R(r()); d += E(r()); d += W(r()); _();		
	d += I(r()); d += S(r()); _();	
newline();	
	d += E(r()); d += X(r()); d += P(r()); d += E(r()); d += N(r()); d += D(r()); d += A(r()); d += B(r()); d += L(r()); d += E(r()); d += STOP(r()); _();




All these wrolds are yours
except europa. attempt no 
landing there. use them 
together, use them in peace.

Sentence 1
	d += A(r()); d += L(r()); d += L(r()); _();
	d += T(r()); d += H(r()); d += E(r()); d += S(r()); d += E(r()) _();	
	d += A(r()); d += R(r()); d += E(r()); _();
	d += Y(r()); d += O(r()); d += U(r()); d += R(r()); d += S(r()); _();
newline();
    d += E(r()); d += X(r()); d += C(r()); d += E(r()); d += P(r()); d += T(r()); _();
    d += E(r()); d += U(r()); d += R(r()); d += O(r()); d += P(r()); d += A(r()); d += STOP(r()); _();
    d += A(r()); d += T(r()); d += T(r()); d += E(r()); d += M(r()); d += P(r()); d += T(r()); _();
    d += N(r()); d += O(r()); _();
newline();	
	d += L(r()); d += A(r()); d += N(r()); d += D(r()); d += I(r()); d += N(r()); d += G(r()); _();	
    d += T(r()); d += H(r()); d += E(r()); d += R(r()); d += E(r());; d += STOP(r()); _();	
    d += U(r()); d += S(r()); d += E(r()); _();	
    d += T(r()); d += H(r()); d += E(r()); d += M(r()); _();		
newline();	
	d += T(r()); d += O(r()); d += G(r()); d += E(r()); d += T(r()); d += H(r()); d += E(r()); d += R(r()); d += STOP(r()); _();	
    d += U(r()); d += S(r()); d += E(r()); _();	
    d += T(r()); d += H(r()); d += E(r()); d += M(r()); _();	
    d += I(r()); d += H(r()); d += N(r()); _();	
    d += P(r()); d += E(r()); d += A(r()); d += C(r()); d += E(r()); d += STOP(r()); _();		
	


Who is John Gault. We should all be.	
    // who is
    d += W(r());  d += H(r()); d += O(r()); _();
    d += I(r()); d += S(r()); _();
    
    newline();
    // john gault 
    d += J(r()); d += O(r()); d += H(r()); d += N(r()); _();
    d += G(r()); d += A(r()); d += U(r()); d += L(r()); d += T(r()); d += STOP(r()); d += STOP(r()); d += STOP(r()); _();
    newline();
    newline();
    
    // we should all be
    d += W(r()); d += E(r());  _();
    d += S(r()); d += H(r()); d += O(r()); d += U(r()); d += L(r()); d += D(r()); _();
    d += A(r()); d += L(r()); d += L(r()); _();
    d += B(r()); d += E(r()); d += STOP(r());  _();	
	
*/	