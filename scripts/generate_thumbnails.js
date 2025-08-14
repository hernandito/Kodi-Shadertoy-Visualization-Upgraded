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
                const baseNameWithCustomSuffix = thumbnailFileName.substring(0, thumbnailFileName.length - ext.length);
                const fullResBaseName = baseNameWithCustomSuffix.replace(' (Custom)', '');

                // 3. Construct the relative path to the full-resolution image
                const fullResRelativePath = path.join(FULL_RESOLUTION_DIR, `${fullResBaseName}${ext}`).replace(/\\/g, '/');

                // Create HTML for a clickable thumbnail.
                // Removed margin from <a> tag.
                // Added padding to <img> tag for spacing (though GitHub may strip it).
                imageMarkdown.push(
                    `<a href="${fullResRelativePath}?raw=true" target=ShaderPreview style="display: inline-block; text-decoration: none;">` +
                    `<img src="${thumbnailRelativePath}?raw=true" alt="Thumbnail of ${fullResBaseName}" width="128" style="border: 1px solid #ddd; border-radius: 4px; box-shadow: 2px 2px 5px rgba(0,0,0,0.2); max-width: 100%; height: auto;">` + // Removed padding here, as it was not rendered.
                    `</a>`
                );
            }
        }

        // Join all generated HTML image links with non-breaking spaces for horizontal gaps.
        // Each `&nbsp;` creates a single space character. You can add more for larger gaps.
        const newContent = imageMarkdown.join('&nbsp;&nbsp;'); // Added 5 non-breaking spaces

        // Reconstruct the README content by replacing the old thumbnail section
        const before = readmeContent.substring(0, startIndex + START_MARKER.length);
        const after = readmeContent.substring(endIndex);
        const updatedReadme = `${before}\n${newContent}\n${after}`; // Add newlines for better formatting

        // Write the updated README content back to the file
        await fs.promises.writeFile(README_PATH, updatedReadme);
        console.log('README.md updated successfully with HTML image thumbnails linking to full resolution!');

    } catch (error) {
        console.error('Failed to generate thumbnails:', error);
        process.exit(1);
    }
}

generateThumbnails();
