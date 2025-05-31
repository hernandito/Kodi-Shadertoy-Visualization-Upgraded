// --- Configurable Parameters ---
#define TIME_SCALE 0.15      // Overall animation speed (Increased from 0.3)
#define POINT_DENSITY 12.0   // Density of the network nodes
#define POINT_DRIFT 1.15    // How much nodes move over time (Slightly increased from 0.1)
#define EDGE_GLOW 0.03     // Thickness/Glow of the connections
#define PULSE_SPEED 10.5     // Speed of the light pulses (Increased from 1.5)
#define PULSE_WIDTH 1.15    // Length of the pulses
#define CELL_GLOW_INTENSITY 0.15 // Background glow within cells
#define ACTIVE_COLOR vec3(0.878, 0.749, 0.459) // Cyan/Green (Active Signal)
#define RESTING_COLOR vec3(0.522, 0.416, 0.176) // Deep Blue (Network Structure)
#define BACKGROUND_COLOR vec3(0,0,0) // Very dark blue

vec2 hash( vec2 p ) {
    p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
    return -1.0 + 2.0 * fract(sin(p)*43758.5453123);
}

// Voronoi calculation (returns F1 distance, F2 distance, and nearest point offset)
vec3 voronoi( vec2 x, float time_offset ) {
    vec2 n = floor(x); // Integer part of cell
    vec2 f = fract(x); // Fractional part within cell

    vec3 m = vec3( 8.0 ); // Min distance squared (F1, F2), init high
    vec2 mg; // Position offset of nearest point

    for( int j=-1; j<=1; j++ ) {
        for( int i=-1; i<=1; i++ ) {
            vec2 g = vec2(float(i),float(j)); // Neighbor cell offset
            vec2 o = hash( n + g ); // Get a random offset for the point in this cell

            // Animate point position slightly over time
            o = 0.5 + 0.5*sin( time_offset*POINT_DRIFT + 6.2831*o );

            vec2 r = g + o - f; // Vector from pixel to point
            float d = dot(r,r); // Distance squared

            if( d<m.x ) { // New F1 found
                m.z = m.y; // Old F2 becomes F3 (unused here)
                m.y = m.x; // Old F1 becomes F2
                m.x = d;   // New F1
                mg = g+o;  // Store this point's relative position
            } else if( d<m.y ) { // New F2 found
                 m.z = m.y; // Old F2 becomes F3 (unused here)
                 m.y = d; // New F2
            } else if( d<m.z) { // New F3 found
                 m.z = d;
            }
        }
    }
    m = sqrt(m); // Get actual distances
    return vec3(m.x, m.y, m.z); // F1, F2, F3 distances
}


// --- Main Shader ---
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1), aspect corrected
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y; // Correct aspect ratio

    float time = iTime * TIME_SCALE;

    // Scale UV for desired density and apply global rotation/shift
    vec2 p = uv * POINT_DENSITY;
    // Optional: Add slight rotation
    // float angle = time * 0.05;
    // mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    // p = rot * p;
    p += time * 0.02; // Slow global drift (influenced by TIME_SCALE now)

    // Calculate Voronoi distances (F1 = dist to nearest, F2 = dist to 2nd nearest)
    vec3 v = voronoi( p, time ); // Pass adjusted time here for drift
    float f1 = v.x;
    float f2 = v.y;

    // --- Draw Connections (Edges) ---
    // Edges are where F1 and F2 are close. Use F2-F1.
    float edge = smoothstep(EDGE_GLOW, 0.0, f2 - f1);
    vec3 col = vec3(edge) * RESTING_COLOR * 2.0; // Make resting lines visible

    // --- Draw Pulses on Connections ---
    // We can simulate pulses by checking distance to center (f1)
    // modulated by time and a hash based on the cell.
    // Get the integer cell coordinate to derive a stable cell ID
    vec2 cell_n = floor(p);
    float cell_hash = hash(cell_n).x; // Use one component of hash for variation

    // Create a time-modulated wave based on distance from cell center (f1)
    // and cell hash for variation across cells.
    float pulse_wave = sin(f1 * 10.0 - time * PULSE_SPEED + cell_hash * 10.0);
    // Sharpen the wave into pulses using smoothstep
    float pulse = smoothstep(1.0 - PULSE_WIDTH, 1.0, pulse_wave);
    // Apply pulse only near the edges
    pulse *= edge; // Only show pulse on the connection lines

    col = mix(col, ACTIVE_COLOR, pulse * 1.5); // Additive blend pulse color

    // --- Cell Background Glow ---
    // Add a faint glow based on distance to the nearest center (f1)
    // Inverse relationship: brighter closer to the center.
    float cell_glow = smoothstep(0.5, 0.0, f1) * CELL_GLOW_INTENSITY;
    col += RESTING_COLOR * cell_glow;

    // --- Final Output ---
    // Add background color
    col += BACKGROUND_COLOR;

    // Tone mapping / Gamma Correction (simple)
    col = pow(col, vec3(0.8)); // Adjust contrast/brightness slightly
    col = clamp(col, 0.0, 1.0);
    fragColor = vec4(col, 1.0);
}