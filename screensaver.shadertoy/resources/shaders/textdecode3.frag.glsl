// New Multi-Line Text Display Shader (Kodi Compatible)

#ifdef GL_ES
precision mediump float; // Added for broader compatibility
#endif

// 随机数生成函数 (compatible with GLSL ES 1.00)
float rand(float seed)
{
    return fract(sin(seed) * 43758.5453);
}

// --- CONFIGURATION PARAMETERS ---
// Lengths of the two messages
#define STATIC_PASSWORD_LENGTH    17      // "DECODING PASSWORD:"
#define SCRAMBLING_MESSAGE_LENGTH 14      // "I_love_Staci"

#define DISPLAY_HOLD_TIME       12.0    // How long (in seconds) the final message stays on screen after revealing (applies to scrambling lines)
#define LINE_VERTICAL_SPACING   1.2     // Vertical space between lines (multiplier of cell size)

// --- NEW: Font Scale for Line 1 ---
// Controls the size of letters on Line 1.
// 1.0 = 100% (original size)
// 0.8 = 80% (making letters smaller, creating more effective spacing between them)
// Adjust this value to scale Line 1's font size.
#define LINE1_FONT_SCALE 0.6 // 80% of current size


// --- Line Color Parameters ---
// Adjust these RGB values (0.0 to 1.0) to change the color of each line's text.
#define LINE1_COLOR vec3(0.176, 0.784, 0.812) // Terminal Green for Line 1 ("DECODING PASSWORD:")
#define LINE2_COLOR vec3(1.0, 0.75, 0.0)    // Amber for Line 2 ("I_love_Staci")


// --- ASCII Lookup Functions (GLSL ES 1.00 compatible workaround for const arrays) ---

// ASCII values for "DECODING PASSWORD:" (This is the content for the STATIC line)
int getAsciiForStaticPassword(int index) {
    if (index == 0) return 73; // D I
    if (index == 1) return 78; // E N
    if (index == 2) return 67; // C C
    if (index == 3) return 79; // O
    if (index == 4) return 77; // D M
    if (index == 5) return 73; // I
    if (index == 6) return 78; // N
    if (index == 7) return 71; // G
    if (index == 8) return 32; // [SPACE]
    if (index == 9) return 77; // P M
    if (index == 10) return 69; // A E
    if (index == 11) return 83; // S
    if (index == 12) return 83; // S
    if (index == 13) return 65; // W A
    if (index == 14) return 71; // O G
    if (index == 15) return 69; // R E
    if (index == 16) return 58; // :
    return 32; // Default for out-of-bounds
}

// ASCII values for "I_love_Staci" (This is the content for the SCRAMBLING line)
int getAsciiForScramblingMessage(int index) {
    if (index == 0) return 87;  // I W
    if (index == 1) return 97;  // _ a
    if (index == 2) return 116; // l t
    if (index == 3) return 99; // o c
    if (index == 4) return 104; // v h
    if (index == 5) return 32; // e {SPACE}
    if (index == 6) return 77;  // _ M
    if (index == 7) return 111;  // S o
    if (index == 8) return 114; // t r
    if (index == 9) return 101;  // a e
    if (index == 10) return 32; // e {SPACE}
    if (index == 11) return 84; // c T
    if (index == 12) return 86; // i V

    if (index == 13) return 29; // e Smiley
    return 32; // Default for out-of-bounds
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    const float CYCLE_DURATION_PER_CHAR = 0.850;
    float totalScrambleTime = float(SCRAMBLING_MESSAGE_LENGTH) * CYCLE_DURATION_PER_CHAR;
    float totalEffectTime = totalScrambleTime + DISPLAY_HOLD_TIME;

    float baseCellSize = min(iResolution.x, iResolution.y) / 16.0; // The original unscaled character cell size
    
    // --- Layout for the two lines ---

    // Position for "I_love_Staci" (Physically TOP LINE - scrambling)
    // This line uses the base (unscaled) character size
    float scrambling_line_width = baseCellSize * float(SCRAMBLING_MESSAGE_LENGTH);
    vec2 scrambling_line_start_pos = (iResolution.xy - vec2(scrambling_line_width, baseCellSize)) * 0.5;
    scrambling_line_start_pos.y -= baseCellSize * (LINE_VERTICAL_SPACING * 0.5); // Position it above center

    // Position for "DECODING PASSWORD:" (Physically BOTTOM LINE - static)
    // This line uses the scaled character size
    float scaledCellSize_line1 = baseCellSize * LINE1_FONT_SCALE;
    float static_line_width = scaledCellSize_line1 * float(STATIC_PASSWORD_LENGTH);
    vec2 static_line_start_pos = (iResolution.xy - vec2(static_line_width, scaledCellSize_line1)) * 0.5;
    // Adjust Y position, still relative to the overall line spacing based on baseCellSize
    // but now adjusted for the smaller height of line 1 itself
    static_line_start_pos.y += baseCellSize * (LINE_VERTICAL_SPACING * 0.5);
    // Further adjust to align baselines or visual center better due to different heights
    static_line_start_pos.y += (baseCellSize - scaledCellSize_line1) * 0.5; // Shift down by half the height difference

    // --- Determine which line (if any) the current fragment belongs to ---
    vec2 localPos;      // Position within the character cell, will be adjusted for scaling
    int asciiCode = 32; // Default to space
    bool found_active_line = false; // Flag to indicate if we're rendering text
    vec3 currentLineColor = vec3(0.0); // Will hold the color for the active line

    // Check if fragment is within the SCRAMBLING MESSAGE line's area (PHYSICALLY TOP LINE)
    localPos = fragCoord.xy - scrambling_line_start_pos;
    if (localPos.x >= 0.0 && localPos.x < scrambling_line_width && 
        localPos.y >= 0.0 && localPos.y < baseCellSize) // Check against baseCellSize for unscaled line
    {
        int charIndex = int(floor(localPos.x / baseCellSize)); // Use baseCellSize for charIndex
        if (charIndex < SCRAMBLING_MESSAGE_LENGTH) {
            // Apply scrambling logic
            float currentEffectTime = mod(iTime, totalEffectTime);
            float stopTimeForChar = float(charIndex + 1) * CYCLE_DURATION_PER_CHAR;
            bool isStopped = currentEffectTime >= stopTimeForChar;
            
            if (isStopped) {
                asciiCode = getAsciiForScramblingMessage(charIndex); // Revealed (scrambling content)
            } else {
                float timeStep = floor(iTime / 0.01);
                float randomSeed = timeStep + float(charIndex) * 0.123;
                float randomValue = rand(randomSeed);
                asciiCode = int(mod(floor(randomValue * 256.0), 256.0));
            }
            found_active_line = true;
            currentLineColor = LINE2_COLOR; // Assign color for scrambling line
        }
    }

    // Check if fragment is within the STATIC PASSWORD line's area (PHYSICALLY BOTTOM LINE)
    if (!found_active_line) {
        vec2 original_local_coords_for_line1 = fragCoord.xy - static_line_start_pos;
        
        // Scale localPos for LINE1 based on its font scale. This effectively "zooms in" to the character.
        // We're stretching the UV coordinates here to sample a smaller part of the texture.
        localPos = original_local_coords_for_line1 / LINE1_FONT_SCALE; 

        // Check bounds using the scaled_local_pos against the original full cell dimensions
        if (localPos.x >= 0.0 && localPos.x < float(STATIC_PASSWORD_LENGTH) * baseCellSize && 
            localPos.y >= 0.0 && localPos.y < baseCellSize)
        {
            int charIndex = int(floor(localPos.x / baseCellSize)); // charIndex still based on original cellSize
            if (charIndex < STATIC_PASSWORD_LENGTH) {
                asciiCode = getAsciiForStaticPassword(charIndex); // "DECODING PASSWORD:" (static)
                found_active_line = true;
                currentLineColor = LINE1_COLOR; // Assign color for static line
            }
        }
    }

    if (!found_active_line)
    {
        fragColor = vec4(0.0); // Outside any text area, draw black/transparent
        return;
    }
    
    // --- Font Texture Sampling ---
    int texX = int(mod(float(asciiCode), 16.0)); 
    int texY = 15 - int(floor(float(asciiCode) / 16.0));
    
    // charLocalUV now accurately represents the 0-1 coordinate within the character's *scaled* cell.
    vec2 charLocalUV = fract(localPos / baseCellSize); 
    
    // No charLocalUV flipping here as per previous discussion, assuming image is pre-processed.
    
    vec2 texUV = (vec2(texX, texY) + charLocalUV) / 16.0; // Global UV on the font texture
    
    // Sample the texture and apply the line-specific color
    fragColor = vec4(texture(iChannel0, texUV).r * currentLineColor, 1.0);
}