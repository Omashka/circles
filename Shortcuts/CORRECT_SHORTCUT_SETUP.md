# Correct Shortcut Setup for Circles

## The Right Actions

Your shortcut should have these actions in order:

1. **Get Current App** (optional - if you want to check it's Messages)
2. **If Current App is Messages** (optional - conditional check)
3. **Take Screenshot** (only if Messages app)
4. **Extract Text from Screenshot** (processes the screenshot)
5. **Open URL** ← This is the key action!

## The URL Format

In the **"Open URL"** action, use:

```
circles://import?text=[Extracted Text from Screenshot]
```

### How to Set It Up:

1. Add the "Open URL" action
2. In the URL field, type: `circles://import?text=`
3. **Important**: Tap on the URL field, then tap the variable bubble that appears
4. Select "Extracted Text from Screenshot" from the variable picker
5. The final URL should show: `circles://import?text=[Extracted Text from Screenshot]`

## Why "Open URL" Instead of "Get Contents of URL"?

- **"Open URL"** opens the URL in the app (triggers our URL scheme handler)
- **"Get Contents of URL"** makes an HTTP request (we don't have an HTTP server)

## What Happens When It Runs:

1. Takes screenshot of Messages
2. Extracts text from screenshot
3. Opens `circles://import?text=...` which launches Circles app
4. Circles app receives the text and processes it with AI
5. Text is assigned to a contact or added to Inbox

## Fix Your Current Shortcut:

Replace:
- ❌ "Get contents of URL" with webhook.site URL

With:
- ✅ "Open URL" with `circles://import?text=[Extracted Text from Screenshot]`

