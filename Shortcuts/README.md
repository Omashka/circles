# Import to Circles - Shortcut Setup

This shortcut automatically extracts text from screenshots and imports it into the Circles app.

## Quick Setup

### Method 1: Import from iCloud Link (Easiest)

1. Tap this link on your iPhone: [Import to Circles Shortcut](https://www.icloud.com/shortcuts/YOUR_SHORTCUT_ID)
2. The Shortcuts app will open
3. Tap "Add Shortcut"
4. Done!

### Method 2: Create Manually

1. Open the **Shortcuts** app
2. Tap the **+** button (top right)
3. Add these actions in order:

   **Action 1: Get Latest Screenshots**
   - Search for "Get Latest Screenshots"
   - Set count to **1**

   **Action 2: Extract Text from Image**
   - Search for "Extract Text from Image"
   - Connect it to the screenshot from Action 1

   **Action 3: Open URL**
   - Search for "Open URL"
   - Enter: `circles://import?text=`
   - Tap the URL field, then tap the variable bubble from "Extracted Text from Image" to insert it
   - Final URL should look like: `circles://import?text=[Extracted Text from Image]`

4. Name the shortcut: **"Import to Circles"**
5. Tap **Done**

## Setting Up Back Tap

1. Open **Settings** app
2. Go to **Accessibility** → **Touch** → **Back Tap**
3. Select **Double Tap**
4. Choose **"Import to Circles"** shortcut

## How to Use

1. Take a screenshot of a message conversation (iMessage, WhatsApp, etc.)
2. **Double tap the back of your iPhone** (if Back Tap is set up)
   - OR manually run the shortcut from the Shortcuts app
3. The text will be automatically imported to Circles
4. Review in the **Inbox** (tray icon in the app)

## Troubleshooting

- **Shortcut doesn't run**: Make sure the Circles app is installed
- **Text not importing**: Check that the URL format is correct: `circles://import?text=[variable]`
- **Back Tap not working**: Ensure it's enabled in Settings → Accessibility → Touch → Back Tap

## Sharing the Shortcut

To share this shortcut with others:

1. Open the shortcut in Shortcuts app
2. Tap the **...** (three dots) button
3. Tap the **Share** button
4. Choose how to share (Messages, AirDrop, etc.)
5. Recipients can tap the link to add it to their device

