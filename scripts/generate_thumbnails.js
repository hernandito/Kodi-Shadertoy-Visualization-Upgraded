const fs = require('fs');
const path = require('path');

// Define the paths to your image folders and README.md
const THUMBNAILS_DIR = 'screensaver.shadertoy/Shader-Screens/thumbnails'; // Directory containing thumbnails
const FULL_RESOLUTION_DIR = 'screensaver.shadertoy/Shader-Screens'; // Directory containing full-res images
const README_PATH = 'README.md';

// Markers in README.md to define where the thumbnails should be inserted  
const START_MARKER = '<!-- THUMBNAIL_START -->';
const END_MARKER = '<!-- THUMBNAIL_END -->';

async function generateThumbnails() {
    try {
        // Read the entire content of the README.md file
        let readmeContent = await fs.promises.readFile(README_PATH, 'utf8');

        // Find the start and end markers in the README content
        const startIndex = readmeContent.indexOf(START_MARKER);
        const endIndex = readmeContent.indexOf(END_MARKER);

        // Error handling if markers are missing
        if (startIndex === -1 || endIndex === -1) {
            console.error(`Error: One or both thumbnail markers ('${START_MARKER}', '${END_MARKER}') not found in README.md.`);
            console.error('Please ensure these markers are present in your README.md file.');
            process.exit(1);
        }

        // Read the list of files in the thumbnail directory
        const thumbnailFiles = await fs.promises.readdir(THUMBNAILS_DIR);
        const imageMarkdown = [];

        // Define common image file extensions to filter by
        const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.tiff', '.tif'];

        // Process each thumbnail file
        for (const thumbnailFileName of thumbnailFiles) {
            const ext = path.extname(thumbnailFileName).toLowerCase();

            // Only process files that are recognized image types
            if (imageExtensions.includes(ext)) {
                // 1. Construct the relative path to the thumbnail image
                const thumbnailRelativePath = path.join(THUMBNAILS_DIR, thumbnailFileName).replace(/\\/g, '/');

                // 2. Extract the base name for the full-resolution image
                // Remove the extension (e.g., '.png') first
                const baseNameWithCustomSuffix = thumbnailFileName.substring(0, thumbnailFileName.length - ext.length);
                // Then remove the ' (Custom)' suffix
                const fullResBaseName = baseNameWithCustomSuffix.replace(' (Custom)', '');

                // 3. Construct the relative path to the full-resolution image
                // We assume the full-res image has the same extension as the thumbnail.
                const fullResRelativePath = path.join(FULL_RESOLUTION_DIR, `${fullResBaseName}${ext}`).replace(/\\/g, '/');

                // Create Markdown for a thumbnail link:
                // [![Alt text (thumbnail filename)](thumbnail_path?raw=true)](full_resolution_path?raw=true)
                // The `?raw=true` is crucial for GitHub to serve raw image content for display.
                // The outer `[]()` makes the thumbnail itself a clickable link.
                imageMarkdown.push(`[![${thumbnailFileName}](${thumbnailRelativePath}?raw=true)](${fullResRelativePath}?raw=true)`);
            }
        }

        // Join all generated image Markdown links with spaces to form a simple gallery layout
        const newContent = imageMarkdown.join(' ');

        // Reconstruct the README content by replacing the old thumbnail section
        const before = readmeContent.substring(0, startIndex + START_MARKER.length);
        const after = readmeContent.substring(endIndex);
        const updatedReadme = `${before}\n${newContent}\n${after}`; // Add newlines for better formatting

        // Write the updated README content back to the file
        await fs.promises.writeFile(README_PATH, updatedReadme);
        console.log('README.md updated successfully with image thumbnails linking to full resolution!');

    } catch (error) {
        // Log any errors that occur during the process
        console.error('Failed to generate thumbnails:', error);
        process.exit(1); // Exit with an error code
    }
}

// Execute the main function
generateThumbnails();