# PowerShell script to inject OAuth config during build
# Usage: .\scripts\inject_oauth_config.ps1 -DesktopClientId "id" -DesktopClientSecret "secret" -AndroidWebClientId "id"

param(
    [Parameter(Mandatory=$false)]
    [string]$DesktopClientId,
    
    [Parameter(Mandatory=$false)]
    [string]$DesktopClientSecret,
    
    [Parameter(Mandatory=$false)]
    [string]$AndroidWebClientId
)

$ErrorActionPreference = "Stop"

# Paths
$templateFile = "lib\config\oauth_config.dart.template"
$outputFile = "lib\config\oauth_config.dart"

if (-not (Test-Path $templateFile)) {
    Write-Error "Template file not found: $templateFile"
    exit 1
}

# Read template
$content = Get-Content $templateFile -Raw

# Replace placeholders (all values are obfuscated with base64)
if ($DesktopClientId) {
    # Obfuscate desktop client ID (base64 encode)
    $obfuscatedDesktopId = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($DesktopClientId))
    $content = $content -replace '\{\{DESKTOP_CLIENT_ID\}\}', $obfuscatedDesktopId
}

if ($DesktopClientSecret) {
    # Obfuscate desktop client secret (base64 encode)
    $obfuscatedSecret = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($DesktopClientSecret))
    $content = $content -replace '\{\{DESKTOP_CLIENT_SECRET\}\}', $obfuscatedSecret
}

if ($AndroidWebClientId) {
    # Obfuscate android web client ID (base64 encode)
    $obfuscatedAndroidId = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($AndroidWebClientId))
    $content = $content -replace '\{\{ANDROID_WEB_CLIENT_ID\}\}', $obfuscatedAndroidId
}

# Write output
$content | Out-File -FilePath $outputFile -Encoding UTF8 -NoNewline

Write-Host "Credentials injected successfully to $outputFile"
Write-Host "  All values are obfuscated (base64 encoded)"
