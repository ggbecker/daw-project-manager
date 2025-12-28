# Testing macOS Code Signing Locally

This guide explains how to test the macOS code signing workflow using self-signed certificates before you have an Apple Developer account.

## ⚠️ Important Notes

- **Test certificates will NOT work for distribution** - users will see security warnings
- **Test certificates cannot be notarized** - Apple only accepts real Developer ID certificates
- **This is only for testing the workflow structure** - to ensure the signing process works correctly
- **For production, you MUST use a real Apple Developer certificate** (see `SIGNING_SETUP.md`)

## Quick Start

### On macOS/Linux:

```bash
chmod +x scripts/create_test_certificate.sh
./scripts/create_test_certificate.sh
```

### On Windows:

```powershell
# Install OpenSSL first if needed
choco install openssl

# Run the script
.\scripts\create_test_certificate.ps1
```

## What the Script Does

1. Creates a self-signed certificate with code signing capabilities
2. Exports it as a `.p12` file (password-protected)
3. Converts it to base64 for GitHub Secrets
4. Generates a random keychain password
5. Outputs all the values you need for GitHub Secrets

## Setting Up GitHub Secrets for Testing

After running the script, you'll get output like this:

```
APPLE_CERTIFICATE_BASE64: [long base64 string]
APPLE_CERTIFICATE_PASSWORD: test123
KEYCHAIN_PASSWORD: [random password]
APPLE_DEVELOPER_ID: Developer ID Application: Test Developer
```

### Steps:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each value:

   - **Name**: `APPLE_CERTIFICATE_BASE64`
     - **Value**: The base64 string from the script output
   
   - **Name**: `APPLE_CERTIFICATE_PASSWORD`
     - **Value**: `test123` (or whatever password you used)
   
   - **Name**: `KEYCHAIN_PASSWORD`
     - **Value**: The random password from `keychain_password.txt`
   
   - **Name**: `APPLE_DEVELOPER_ID`
     - **Value**: `Developer ID Application: Test Developer`

### Optional (Skip for Testing):

- `APPLE_ID` - Not needed for testing (notarization won't work anyway)
- `APPLE_APP_SPECIFIC_PASSWORD` - Not needed for testing
- `APPLE_TEAM_ID` - Not needed for testing

## Testing the Workflow

1. **Push a test tag:**
   ```bash
   git tag v1.0.0-test
   git push origin v1.0.0-test
   ```

2. **Create a GitHub Release** with that tag (or the workflow will fail)

3. **Watch the workflow run:**
   - Go to **Actions** tab in GitHub
   - The workflow should:
     - Import the test certificate ✅
     - Sign the app bundle ✅
     - Create DMG/ZIP ✅
     - Sign the DMG ✅
     - Skip notarization (since we don't have real credentials) ⚠️

## What to Expect

### ✅ Will Work:
- Certificate import
- Code signing process
- DMG/ZIP creation
- DMG signing
- Workflow completion

### ⚠️ Will Skip:
- Notarization (requires real Apple credentials)
- The workflow will continue without errors

### ❌ Won't Work:
- Users downloading the app will see "unidentified developer" warnings
- The app cannot be distributed to others
- Notarization will fail if attempted

## Switching to Production

When you're ready to use real Apple Developer credentials:

1. **Follow the guide in `SIGNING_SETUP.md`** to get a real Developer ID certificate

2. **Update GitHub Secrets:**
   - Replace `APPLE_CERTIFICATE_BASE64` with your real certificate
   - Replace `APPLE_CERTIFICATE_PASSWORD` with your real password
   - Replace `APPLE_DEVELOPER_ID` with your real Developer ID
   - Add `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, and `APPLE_TEAM_ID` for notarization

3. **The workflow will automatically:**
   - Use the real certificate
   - Sign properly
   - Notarize with Apple
   - Create distributable artifacts

## Troubleshooting

### "Certificate not found"
- Make sure `APPLE_DEVELOPER_ID` matches exactly (including spaces and parentheses)
- Verify the certificate was imported correctly in the workflow logs

### "Signing failed"
- Check that the certificate has code signing capabilities
- Verify the entitlements file exists at `macos/Runner/Release.entitlements`

### "Notarization skipped"
- This is expected with test certificates
- Notarization will work once you add real Apple credentials

## Security Notes

- **Never commit** the `.p12` file or `keychain_password.txt` to git
- Add them to `.gitignore`:
  ```
  *.p12
  *.key
  *.crt
  *.csr
  keychain_password.txt
  ```
- Delete test certificates after testing
- Use real certificates for production

## Next Steps

Once testing is complete:
1. Get an Apple Developer account ($99/year)
2. Follow `SIGNING_SETUP.md` for production setup
3. Replace test secrets with production values
4. Your workflow will automatically use the real certificate

