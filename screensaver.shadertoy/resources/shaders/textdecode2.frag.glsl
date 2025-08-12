// 随机数生成函数
float rand(float seed)
{
    return fract(sin(seed) * 43758.5453);
}

// --- CONFIGURATION PARAMETERS ---
#define MESSAGE_LENGTH      12      // Total number of characters in your message
#define DISPLAY_HOLD_TIME   120.0    // How long (in seconds) the final message stays on screen after revealing

// Helper function to get ASCII value, replaces const array due to GLSL ES 1.00 limitations
// You will need to manually map your message here.
int getTargetAscii(int index) {
    // Current message: "HELLO STACI!"
    // H  E  L  L  O  _  S  T  A  C  I  !
    if (index == 0) return 72; // H
    if (index == 1) return 69; // E
    if (index == 2) return 76; // L
    if (index == 3) return 76; // L
    if (index == 4) return 79; // O
    if (index == 5) return 32; // [SPACE]
    if (index == 6) return 83; // S
    if (index == 7) return 84; // T
    if (index == 8) return 65; // A
    if (index == 9) return 67; // C
    if (index == 10) return 73; // I
    if (index == 11) return 33; // !
    return 32; // Default for out-of-bounds or shorter messages (space)
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // --- Multi-Line Message Notes ---
    // (These notes remain, but the implementation for multi-line will also need the getTargetAscii approach)
    // To create a multi-line message (e.g., "DECODING PASSWORD:\nI-Love-My-Wife"):
    // 1. You would need to add a newline character (e.g., ASCII 10) to your TARGET_ASCII array.
    //    However, your current font texture (iChannel0) does NOT contain a glyph for newline (ASCII 10).
    //    It would likely display as a blank square or an incorrect character.
    // 2. To properly support multi-line, you would need to:
    //    a. Update your font texture (iChannel0) to include a distinct glyph for newline or a custom line-break indicator.
    //    b. Modify the shader's layout logic:
    //       - Instead of a single `textStart` and `totalWidth`, you'd need to track `currentLineX` and `currentLineY`.
    //       - When a newline character is encountered in TARGET_ASCII, increment `currentLineY` and reset `currentLineX` to the start of the next line.
    //       - This would involve more complex `charIndex` and `localPos` calculations to account for wrapping.
    // For now, this shader is designed for a single line of text.
    // ---------------------------------

    const float CYCLE_DURATION_PER_CHAR = .30; // Time it takes for each char to stop scrambling
    
    // Calculate total time for scrambling and display hold
    float totalScrambleTime = float(MESSAGE_LENGTH) * CYCLE_DURATION_PER_CHAR;
    float totalEffectTime = totalScrambleTime + DISPLAY_HOLD_TIME;

    float cellSize = min(iResolution.x, iResolution.y) / 16.0;
    
    float totalWidth = cellSize * float(MESSAGE_LENGTH); // Use MESSAGE_LENGTH for total width
    vec2 textStart = (iResolution.xy - vec2(totalWidth, cellSize)) * 0.5;
    
    vec2 localPos = fragCoord.xy - textStart;
    
    // Check if fragment is outside the text area
    if (localPos.x < 0.0 || localPos.x >= totalWidth || localPos.y < 0.0 || localPos.y >= cellSize)
    {
        fragColor = vec4(0.0);
        return;
    }
    
    int charIndex = int(floor(localPos.x / cellSize));
    
    // Ensure charIndex is within bounds of the message length
    if (charIndex >= MESSAGE_LENGTH) {
        fragColor = vec4(0.0);
        return;
    }

    float currentEffectTime = mod(iTime, totalEffectTime); // Loop through the entire effect duration
    
    float stopTimeForChar = float(charIndex + 1) * CYCLE_DURATION_PER_CHAR;
    
    bool isStopped = currentEffectTime >= stopTimeForChar;
    
    // Decide which ASCII code to display
    int asciiCode;
    if (isStopped)
    {
        // Display the target ASCII for the character using the helper function
        asciiCode = getTargetAscii(charIndex);
    }   
    else
    {
        // Display a random character during scrambling phase
        float timeStep = floor(iTime / 0.01);
        float randomSeed = timeStep + float(charIndex) * 0.123;
        float randomValue = rand(randomSeed);
        // CORRECTED: Replaced % with mod() for GLSL ES 1.00 compatibility
        asciiCode = int(mod(floor(randomValue * 256.0), 256.0)); 
    }
    
    // Calculate UVs for the font texture
    // The texture is assumed to be a 16x16 grid of characters
    // CORRECTED: Replaced % with mod() for GLSL ES 1.00 compatibility
    int texX = int(mod(float(asciiCode), 16.0)); 
    int texY = 15 - int(floor(float(asciiCode) / 16.0)); // floor is fine here
    
    vec2 charLocalUV = fract(localPos / cellSize); // UV within the current character cell
    vec2 texUV = (vec2(texX, texY) + charLocalUV) / 16.0; // Global UV on the font texture
    
    fragColor = texture(iChannel0, texUV).rrrr; // Use .rrrr for grayscale effect as the font is likely monochrome
}