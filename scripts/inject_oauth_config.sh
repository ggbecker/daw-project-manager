#!/bin/bash
# Bash script to inject OAuth config during build
# Usage: ./scripts/inject_oauth_config.sh -d "desktop-id" -s "secret" -a "android-id"
#   or: ./scripts/inject_oauth_config.sh --desktop-id "id" --secret "secret" --android-id "id"

set -e

DESKTOP_CLIENT_ID=""
DESKTOP_CLIENT_SECRET=""
ANDROID_WEB_CLIENT_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--desktop-id)
            DESKTOP_CLIENT_ID="$2"
            shift 2
            ;;
        -s|--secret)
            DESKTOP_CLIENT_SECRET="$2"
            shift 2
            ;;
        -a|--android-id)
            ANDROID_WEB_CLIENT_ID="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown option: $1"
            echo "Usage: $0 -d <desktop-id> -s <secret> -a <android-id>"
            exit 1
            ;;
    esac
done

# Paths
TEMPLATE_FILE="lib/config/oauth_config.dart.template"
OUTPUT_FILE="lib/config/oauth_config.dart"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Read template
CONTENT=$(cat "$TEMPLATE_FILE")

# Replace placeholders (all values are obfuscated with base64)
# Using awk for safer string replacement that handles special characters
if [ -n "$DESKTOP_CLIENT_ID" ]; then
    # Obfuscate desktop client ID (base64 encode)
    OBFUSCATED_DESKTOP_ID=$(echo -n "$DESKTOP_CLIENT_ID" | base64 | tr -d '\n')
    CONTENT=$(echo "$CONTENT" | awk -v old="{{DESKTOP_CLIENT_ID}}" -v new="$OBFUSCATED_DESKTOP_ID" '{gsub(old, new); print}')
fi

if [ -n "$DESKTOP_CLIENT_SECRET" ]; then
    # Obfuscate desktop client secret (base64 encode)
    OBFUSCATED_SECRET=$(echo -n "$DESKTOP_CLIENT_SECRET" | base64 | tr -d '\n')
    CONTENT=$(echo "$CONTENT" | awk -v old="{{DESKTOP_CLIENT_SECRET}}" -v new="$OBFUSCATED_SECRET" '{gsub(old, new); print}')
fi

if [ -n "$ANDROID_WEB_CLIENT_ID" ]; then
    # Obfuscate android web client ID (base64 encode)
    OBFUSCATED_ANDROID_ID=$(echo -n "$ANDROID_WEB_CLIENT_ID" | base64 | tr -d '\n')
    CONTENT=$(echo "$CONTENT" | awk -v old="{{ANDROID_WEB_CLIENT_ID}}" -v new="$OBFUSCATED_ANDROID_ID" '{gsub(old, new); print}')
fi

# Write output
echo "$CONTENT" > "$OUTPUT_FILE"

echo "Credentials injected successfully to $OUTPUT_FILE"
echo "  All values are obfuscated (base64 encoded)"
