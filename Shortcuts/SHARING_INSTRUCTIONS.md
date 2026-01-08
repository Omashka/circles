# How to Share the "Import to Circles" Shortcut

## Step 1: Create the Shortcut

1. Open the **Shortcuts** app on your iPhone
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
   - Tap the URL field, then tap the variable bubble from "Extracted Text from Image"
   - Final URL should be: `circles://import?text=[Extracted Text from Image]`

4. Name the shortcut: **"Import to Circles"**
5. Tap **Done**

## Step 2: Share the Shortcut

1. In the Shortcuts app, find your **"Import to Circles"** shortcut
2. Tap the **...** (three dots) button on the shortcut
3. Tap the **Share** button (square with arrow)
4. Choose how to share:
   - **Copy Link** - Creates an iCloud link you can paste anywhere
   - **Messages** - Send directly via iMessage
   - **AirDrop** - Share to nearby devices
   - **More** - Other sharing options

## Step 3: Get the iCloud Link

When you share via "Copy Link", you'll get a URL like:
```
https://www.icloud.com/shortcuts/abc123def456ghi789...
```

## Step 4: Add Link to App

1. Open `ShortcutsOnboardingView.swift`
2. Find the `getShortcutURL()` function
3. Replace `return nil` with:
   ```swift
   return URL(string: "https://www.icloud.com/shortcuts/YOUR_ACTUAL_LINK_HERE")
   ```
4. Replace `YOUR_ACTUAL_LINK_HERE` with your actual iCloud shortcut link

## Step 5: Users Can Now Install

When users tap the "Download Shortcut" button in the app:
1. The Shortcuts app opens
2. They see your shortcut with an "Add Shortcut" button
3. One tap installs it!

## Alternative: Direct Link in App Store/Website

You can also:
- Add the iCloud link to your app's App Store description
- Include it in your website
- Share it via social media
- Add it to your README

Users just need to tap the link on their iPhone, and it will open in Shortcuts with the "Add Shortcut" option.

