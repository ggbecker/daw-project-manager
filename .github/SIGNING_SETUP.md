# macOS Code Signing Setup Guide

This guide explains how to set up code signing for macOS builds in GitHub Actions.

## Prerequisites

1. **Apple Developer Account** (Individual or Organization)
   - Sign up at https://developer.apple.com
   - Annual fee: $99 USD

2. **Developer ID Certificate**
   - Used for signing apps distributed outside the Mac App Store
   - Download from: https://developer.apple.com/account/resources/certificates/list

## Step 1: Create a Developer ID Application Certificate

1. Log in to [Apple Developer Portal](https://developer.apple.com/account)
2. Go to **Certificates, Identifiers & Profiles**
3. Click **Certificates** → **+** (Add)
4. Select **Developer ID Application** → Continue
5. Follow the instructions to create a Certificate Signing Request (CSR):
   - Open **Keychain Access** on your Mac
   - Go to **Keychain Access** → **Certificate Assistant** → **Request a Certificate From a Certificate Authority**
   - Enter your email and name
   - Select **Save to disk**
   - Upload the CSR file
6. Download the certificate and double-click to install it in Keychain Access

## Step 2: Export Certificate as .p12

1. Open **Keychain Access** on your Mac
2. Find your **Developer ID Application** certificate
3. Right-click → **Export "Developer ID Application: Your Name"**
4. Choose **Personal Information Exchange (.p12)** format
5. Set a password (you'll need this for GitHub Secrets)
6. Save the file

## Step 3: Convert Certificate to Base64

Run this command on your Mac (or any machine with the certificate):

```bash
base64 -i YourCertificate.p12 | pbcopy
```

Or on Linux/Windows:

```bash
base64 -i YourCertificate.p12
```

Copy the entire output (it's a long string).

## Step 4: Get Your Apple ID and Team ID

1. Log in to [Apple Developer Portal](https://developer.apple.com/account)
2. Your **Team ID** is shown in the top right corner (e.g., `ABC123DEF4`)
3. Your **Apple ID** is the email you use to log in

## Step 5: Create App-Specific Password (for Notarization)

1. Go to https://appleid.apple.com
2. Sign in with your Apple ID
3. Go to **Sign-In and Security** → **App-Specific Passwords**
4. Click **Generate an app-specific password**
5. Name it (e.g., "GitHub Actions Notarization")
6. Copy the password (you'll only see it once)

## Step 6: Get Your Developer ID

Your Developer ID is in the format: `Developer ID Application: Your Name (TEAM_ID)`

You can find it by:
1. Opening Keychain Access
2. Finding your Developer ID Application certificate
3. The full name is your Developer ID

Or extract it from the certificate:
```bash
security find-identity -v -p codesigning | grep "Developer ID"
```

## Step 7: Add GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

### Required Secrets:

1. **`APPLE_CERTIFICATE_BASE64`**
   - Value: The base64-encoded .p12 certificate (from Step 3)
   - This is a long string starting with `MII...`

2. **`APPLE_CERTIFICATE_PASSWORD`**
   - Value: The password you set when exporting the .p12 file (from Step 2)

3. **`KEYCHAIN_PASSWORD`**
   - Value: A random password for the temporary keychain (e.g., `$(openssl rand -base64 32)`)
   - This is just for the build process

4. **`APPLE_DEVELOPER_ID`**
   - Value: Your full Developer ID (e.g., `Developer ID Application: John Doe (ABC123DEF4)`)
   - From Step 6

### Optional Secrets (for Notarization):

5. **`APPLE_ID`**
   - Value: Your Apple ID email address
   - From Step 4

6. **`APPLE_APP_SPECIFIC_PASSWORD`**
   - Value: The app-specific password you generated (from Step 5)
   - Format: `xxxx-xxxx-xxxx-xxxx`

7. **`APPLE_TEAM_ID`**
   - Value: Your Team ID (e.g., `ABC123DEF4`)
   - From Step 4

## Step 8: Create Entitlements File (if needed)

If you don't have an entitlements file, create one at:
`macos/Runner/DebugProfile.entitlements`

Example content:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
```

## Verification

After setting up, when you push a tag, the workflow will:
1. Import and install your certificate
2. Sign the .app bundle
3. (Optional) Notarize the app with Apple
4. Create and sign the DMG
5. Upload both ZIP and DMG to the release

## Troubleshooting

### "No signing certificate found"
- Verify `APPLE_DEVELOPER_ID` matches exactly (including spaces and parentheses)
- Check that the certificate was imported correctly

### "Notarization failed"
- Verify `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, and `APPLE_TEAM_ID` are correct
- Check that your Apple Developer account is active
- Notarization can take 5-30 minutes

### "Invalid signature"
- Make sure you're using a Developer ID certificate (not a Mac App Store certificate)
- Verify the entitlements file exists and is valid

## Security Notes

- Never commit certificates or passwords to the repository
- Use GitHub Secrets for all sensitive information
- Rotate app-specific passwords regularly
- The keychain is automatically deleted after the build

