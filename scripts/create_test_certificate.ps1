# PowerShell script to create a self-signed certificate for testing macOS code signing workflow
# This is for LOCAL TESTING ONLY - not for production distribution
# For production, use a real Apple Developer ID certificate

Write-Host "Creating test certificate for macOS code signing..." -ForegroundColor Yellow
Write-Host "⚠️  WARNING: This is for testing only. Production builds require an Apple Developer certificate." -ForegroundColor Red

# Certificate details
$CertName = "Developer ID Application: Test Developer"
$CertPassword = "test123"  # Change this if needed

# Generate random keychain password
$KeychainPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Create certificate using OpenSSL (requires OpenSSL to be installed)
# If OpenSSL is not installed, install it via: choco install openssl

$ErrorActionPreference = "Stop"

try {
    # Check if OpenSSL is available
    $opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
    if (-not $opensslPath) {
        Write-Host "OpenSSL not found. Please install it first:" -ForegroundColor Red
        Write-Host "  choco install openssl" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Creating certificate signing request..."
    $csrFile = "test_certificate.csr"
    $keyFile = "test_private_key.key"
    
    openssl req -new -newkey rsa:2048 -nodes `
        -keyout $keyFile `
        -out $csrFile `
        -subj "/CN=Test Developer/O=Test Organization/C=US"

    Write-Host "Creating self-signed certificate..."
    $certFile = "test_certificate.crt"
    
    # Create extension file
    $extFile = "cert_extensions.txt"
    @"
[req]
distinguished_name = req_distinguished_name
[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = codeSigning
"@ | Out-File -FilePath $extFile -Encoding ASCII

    openssl x509 -req -days 365 `
        -in $csrFile `
        -signkey $keyFile `
        -out $certFile `
        -extensions v3_req `
        -extfile $extFile

    Write-Host "Converting to .p12 format..."
    $p12File = "test_certificate.p12"
    
    openssl pkcs12 -export `
        -out $p12File `
        -inkey $keyFile `
        -in $certFile `
        -name $CertName `
        -passout pass:$CertPassword

    # Convert to base64
    Write-Host "Converting certificate to base64..."
    $base64Cert = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $p12File)))

    # Clean up temporary files
    Remove-Item $csrFile, $keyFile, $certFile, $extFile -ErrorAction SilentlyContinue

    # Save keychain password
    $KeychainPassword | Out-File -FilePath "keychain_password.txt" -Encoding ASCII -NoNewline

    # Output instructions
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Test Certificate Created Successfully!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Files created:"
    Write-Host "  - $p12File (certificate file)"
    Write-Host "  - keychain_password.txt (keychain password)"
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Keep these files secure and do NOT commit them to git!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To use this certificate in GitHub Actions, add these secrets:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "APPLE_CERTIFICATE_BASE64:"
    Write-Host $base64Cert
    Write-Host ""
    Write-Host "APPLE_CERTIFICATE_PASSWORD: $CertPassword"
    Write-Host ""
    Write-Host "KEYCHAIN_PASSWORD: $KeychainPassword"
    Write-Host ""
    Write-Host "APPLE_DEVELOPER_ID: $CertName"
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "⚠️  NOTE: This certificate will NOT work for:" -ForegroundColor Red
    Write-Host "  - Distribution outside your machine"
    Write-Host "  - Notarization with Apple"
    Write-Host "  - Users downloading your app"
    Write-Host ""
    Write-Host "For production, you MUST use a real Apple Developer certificate!" -ForegroundColor Yellow
    Write-Host "See .github/SIGNING_SETUP.md for production setup."
    Write-Host "==========================================" -ForegroundColor Yellow

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

