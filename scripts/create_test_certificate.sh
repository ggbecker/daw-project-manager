#!/bin/bash

# Script to create a self-signed certificate for testing macOS code signing workflow
# This is for LOCAL TESTING ONLY - not for production distribution
# For production, use a real Apple Developer ID certificate

set -e

echo "Creating test certificate for macOS code signing..."
echo "⚠️  WARNING: This is for testing only. Production builds require an Apple Developer certificate."

# Certificate details
CERT_NAME="Developer ID Application: Test Developer"
KEYCHAIN_NAME="test-signing.keychain"
KEYCHAIN_PASSWORD=$(openssl rand -base64 32)
CERT_PASSWORD="test123"  # Change this if needed

# Create a temporary keychain
echo "Creating temporary keychain..."
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
security list-keychains -s "$KEYCHAIN_NAME"
security default-keychain -s "$KEYCHAIN_NAME"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
security set-keychain-settings -t 3600 -u "$KEYCHAIN_NAME"

# Create a certificate signing request
echo "Creating certificate signing request..."
CSR_FILE="test_certificate.csr"
KEY_FILE="test_private_key.key"

openssl req -new -newkey rsa:2048 -nodes \
  -keyout "$KEY_FILE" \
  -out "$CSR_FILE" \
  -subj "/CN=Test Developer/O=Test Organization/C=US"

# Create a self-signed certificate (valid for 1 year)
echo "Creating self-signed certificate..."
CERT_FILE="test_certificate.crt"
openssl x509 -req -days 365 \
  -in "$CSR_FILE" \
  -signkey "$KEY_FILE" \
  -out "$CERT_FILE" \
  -extensions v3_req \
  -extfile <(cat <<EOF
[req]
distinguished_name = req_distinguished_name
[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = codeSigning
EOF
)

# Convert to .p12 format
echo "Converting to .p12 format..."
P12_FILE="test_certificate.p12"
openssl pkcs12 -export \
  -out "$P12_FILE" \
  -inkey "$KEY_FILE" \
  -in "$CERT_FILE" \
  -name "$CERT_NAME" \
  -passout pass:"$CERT_PASSWORD"

# Import into keychain
echo "Importing certificate into keychain..."
security import "$P12_FILE" -k "$KEYCHAIN_NAME" -P "$CERT_PASSWORD" -T /usr/bin/codesign

# Convert to base64 for GitHub Secrets
echo "Converting certificate to base64..."
BASE64_CERT=$(base64 -i "$P12_FILE")

# Clean up temporary files
rm -f "$CSR_FILE" "$KEY_FILE" "$CERT_FILE"

# Save keychain password
echo "$KEYCHAIN_PASSWORD" > keychain_password.txt

# Output instructions
echo ""
echo "=========================================="
echo "Test Certificate Created Successfully!"
echo "=========================================="
echo ""
echo "Files created:"
echo "  - $P12_FILE (certificate file)"
echo "  - keychain_password.txt (keychain password)"
echo ""
echo "⚠️  IMPORTANT: Keep these files secure and do NOT commit them to git!"
echo ""
echo "To use this certificate in GitHub Actions, add these secrets:"
echo ""
echo "APPLE_CERTIFICATE_BASE64:"
echo "$BASE64_CERT"
echo ""
echo "APPLE_CERTIFICATE_PASSWORD: $CERT_PASSWORD"
echo ""
echo "KEYCHAIN_PASSWORD: $KEYCHAIN_PASSWORD"
echo ""
echo "APPLE_DEVELOPER_ID: $CERT_NAME"
echo ""
echo "=========================================="
echo "⚠️  NOTE: This certificate will NOT work for:"
echo "  - Distribution outside your machine"
echo "  - Notarization with Apple"
echo "  - Users downloading your app"
echo ""
echo "For production, you MUST use a real Apple Developer certificate!"
echo "See .github/SIGNING_SETUP.md for production setup."
echo "=========================================="

