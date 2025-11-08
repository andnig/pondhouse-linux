#!/bin/bash

# SharePoint File Manager with OAuth2 and Gum UI
# Requires: gum, jq, curl

set -e

# Enable debug mode if --debug flag is present
if [[ " $* " =~ " --debug " ]]; then
    set -x
    DEBUG=1
else
    DEBUG=0
fi

# Configuration file
CONFIG_DIR="$HOME/.config/sharepoint-manager"
CONFIG_FILE="$CONFIG_DIR/config.json"
TOKEN_FILE="$CONFIG_DIR/token.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
info() {
    echo -e "${BLUE}ℹ${NC} $1" >&2
}

success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

debug() {
    if [ "$DEBUG" -eq 1 ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()

    for cmd in gum jq curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install them with:"
        echo "  gum: https://github.com/charmbracelet/gum#installation"
        echo "  jq: sudo apt install jq  (or brew install jq)"
        echo "  curl: sudo apt install curl  (or brew install curl)"
        exit 1
    fi
}

# Initialize configuration
init_config() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        info "First time setup - let's configure your SharePoint connection"
        info "(Press Enter to use defaults)"
        echo ""

        # Get configuration from user with defaults
        TENANT_ID=$(gum input --placeholder "Azure AD Tenant ID (default: 42abcb50-0ca4-44ec-b66c-80926c94af9d)")
        TENANT_ID=${TENANT_ID:-42abcb50-0ca4-44ec-b66c-80926c94af9d}

        CLIENT_ID=$(gum input --placeholder "Azure AD Application/Client ID (default: f4b4a9be-d9b7-4bb0-a6a8-f7578164a822)")
        CLIENT_ID=${CLIENT_ID:-f4b4a9be-d9b7-4bb0-a6a8-f7578164a822}

        echo ""
        echo "SharePoint URL format: https://TENANT.sharepoint.com/sites/SITENAME"
        echo "Example: https://pondhousedataog.sharepoint.com/sites/FileTransfers"
        echo ""

        TENANT_NAME=$(gum input --placeholder "Tenant name (default: pondhousedataog)")
        TENANT_NAME=${TENANT_NAME:-pondhousedataog}

        SITE_NAME=$(gum input --placeholder "Site name (default: FileTransfers)")
        SITE_NAME=${SITE_NAME:-FileTransfers}

        # Create config file
        cat > "$CONFIG_FILE" <<EOF
{
    "tenant_id": "$TENANT_ID",
    "client_id": "$CLIENT_ID",
    "tenant_name": "$TENANT_NAME",
    "site_name": "$SITE_NAME",
    "redirect_uri": "http://localhost:8080"
}
EOF

        success "Configuration saved to $CONFIG_FILE"
        echo ""
    fi
}

# Load configuration
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Configuration file not found. Run with --init first."
        exit 1
    fi

    TENANT_ID=$(jq -r '.tenant_id' "$CONFIG_FILE")
    CLIENT_ID=$(jq -r '.client_id' "$CONFIG_FILE")
    TENANT_NAME=$(jq -r '.tenant_name // .site_name' "$CONFIG_FILE")  # Fallback to site_name for old configs
    SITE_NAME=$(jq -r '.site_name' "$CONFIG_FILE")
    REDIRECT_URI=$(jq -r '.redirect_uri' "$CONFIG_FILE")
}

# OAuth2 Device Code Flow Authentication
authenticate() {
    info "Starting OAuth2 authentication..."

    # Request device code
    DEVICE_CODE_RESPONSE=$(curl -s -X POST \
        "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/devicecode" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=$CLIENT_ID" \
        -d "scope=Files.ReadWrite.All Sites.ReadWrite.All offline_access")

    # Check for errors in response
    ERROR=$(echo "$DEVICE_CODE_RESPONSE" | jq -r '.error // empty')
    if [ -n "$ERROR" ]; then
        error "Failed to get device code: $ERROR"
        ERROR_DESC=$(echo "$DEVICE_CODE_RESPONSE" | jq -r '.error_description // empty')
        if [ -n "$ERROR_DESC" ]; then
            echo "$ERROR_DESC" >&2
        fi
        exit 1
    fi

    DEVICE_CODE=$(echo "$DEVICE_CODE_RESPONSE" | jq -r '.device_code // empty')
    USER_CODE=$(echo "$DEVICE_CODE_RESPONSE" | jq -r '.user_code // empty')
    VERIFICATION_URL=$(echo "$DEVICE_CODE_RESPONSE" | jq -r '.verification_uri // empty')
    EXPIRES_IN=$(echo "$DEVICE_CODE_RESPONSE" | jq -r '.expires_in // 300')

    if [ -z "$DEVICE_CODE" ] || [ -z "$USER_CODE" ] || [ -z "$VERIFICATION_URL" ]; then
        error "Failed to get device code - incomplete response"
        echo "Response received:" >&2
        echo "$DEVICE_CODE_RESPONSE" | jq >&2
        exit 1
    fi

    echo "" >&2
    echo "==========================================" >&2
    echo "  AUTHENTICATION REQUIRED" >&2
    echo "==========================================" >&2
    echo "" >&2
    echo "  1. Visit this URL:" >&2
    echo "     $VERIFICATION_URL" >&2
    echo "" >&2
    echo "  2. Enter this code:" >&2
    echo "" >&2
    echo "     ┌────────────────┐" >&2
    echo "     │  $USER_CODE  │" >&2
    echo "     └────────────────┘" >&2
    echo "" >&2
    echo "==========================================" >&2
    echo "" >&2

    # Also try gum style if available
    if command -v gum &> /dev/null; then
        gum style --border double --padding "1 2" --border-foreground 212 \
            "Visit: $VERIFICATION_URL" \
            "Code: $USER_CODE" >&2 2>/dev/null || true
        echo "" >&2
    fi

    # Wait for user to read the code before opening browser
    info "Press Enter to open browser, or Ctrl+C to cancel..."
    read -r

    # Open browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "$VERIFICATION_URL" 2>/dev/null &
    elif command -v open &> /dev/null; then
        open "$VERIFICATION_URL" 2>/dev/null &
    fi

    success "Browser opened! Go back to the browser and enter the code shown above."
    info "Waiting for you to complete authentication in the browser..."

    # Poll for token
    local interval=5
    local max_attempts=$((EXPIRES_IN / interval))

    for ((i=0; i<max_attempts; i++)); do
        sleep $interval

        TOKEN_RESPONSE=$(curl -s -X POST \
            "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "client_id=$CLIENT_ID" \
            -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
            -d "device_code=$DEVICE_CODE")

        ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')

        if [ -z "$ERROR" ]; then
            # Success!
            echo "$TOKEN_RESPONSE" > "$TOKEN_FILE"
            chmod 600 "$TOKEN_FILE"
            success "Authentication successful!"
            return 0
        elif [ "$ERROR" != "authorization_pending" ]; then
            echo "" >&2
            error "Authentication failed: $ERROR"
            ERROR_DESC=$(echo "$TOKEN_RESPONSE" | jq -r '.error_description // empty')
            if [ -n "$ERROR_DESC" ]; then
                echo "  Details: $ERROR_DESC" >&2
            fi
            echo "" >&2

            # Provide specific help for common errors
            case "$ERROR" in
                "invalid_client")
                    echo "╔═══════════════════════════════════════════════════════════╗" >&2
                    echo "║  TROUBLESHOOTING: Invalid Client Error                    ║" >&2
                    echo "╚═══════════════════════════════════════════════════════════╝" >&2
                    echo "" >&2
                    echo "This error usually means:" >&2
                    echo "" >&2
                    echo "1. ❌ 'Allow public client flows' is NOT enabled" >&2
                    echo "   Fix: In Azure Portal → Your App → Authentication → " >&2
                    echo "        Advanced settings → Enable 'Allow public client flows'" >&2
                    echo "" >&2
                    echo "2. ❌ Wrong Client ID" >&2
                    echo "   Fix: Double-check your Application (client) ID" >&2
                    echo "   Current Client ID: $CLIENT_ID" >&2
                    echo "" >&2
                    echo "3. ❌ Wrong Tenant ID" >&2
                    echo "   Fix: Verify your Directory (tenant) ID" >&2
                    echo "   Current Tenant ID: $TENANT_ID" >&2
                    echo "" >&2
                    echo "To reconfigure, run: $0 --init" >&2
                    echo "" >&2
                    ;;
                "invalid_grant")
                    echo "The authorization code/token is invalid or expired." >&2
                    echo "Try authenticating again: $0 --auth" >&2
                    ;;
            esac
            exit 1
        fi

        echo -n "." >&2
    done

    error "Authentication timed out"
    exit 1
}

# Refresh access token
refresh_token() {
    if [ ! -f "$TOKEN_FILE" ]; then
        authenticate
        return
    fi

    REFRESH_TOKEN=$(jq -r '.refresh_token' "$TOKEN_FILE")

    if [ "$REFRESH_TOKEN" == "null" ] || [ -z "$REFRESH_TOKEN" ]; then
        authenticate
        return
    fi

    TOKEN_RESPONSE=$(curl -s -X POST \
        "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=$CLIENT_ID" \
        -d "grant_type=refresh_token" \
        -d "refresh_token=$REFRESH_TOKEN" \
        -d "scope=Files.ReadWrite.All Sites.ReadWrite.All offline_access")

    ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')

    if [ -n "$ERROR" ]; then
        warning "Token refresh failed, re-authenticating..."
        authenticate
    else
        echo "$TOKEN_RESPONSE" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
    fi
}

# Get valid access token
get_access_token() {
    debug "Getting access token..."

    if [ ! -f "$TOKEN_FILE" ]; then
        debug "No token file found, authenticating..."
        authenticate
    else
        debug "Token file exists, checking expiration..."
        # Check if token is expired (simple check)
        # Just refresh if token file is older than 50 minutes
        CURRENT_TIME=$(date +%s)

        # Get file modification time - try both stat formats
        TOKEN_TIME=$(stat -c %Y "$TOKEN_FILE" 2>/dev/null || stat -f %m "$TOKEN_FILE" 2>/dev/null || echo "0")

        debug "Token time: $TOKEN_TIME, Current time: $CURRENT_TIME"

        # If we got a valid timestamp and it's been more than 50 minutes, refresh
        if [[ "$TOKEN_TIME" =~ ^[0-9]+$ ]] && [ "$TOKEN_TIME" -gt 0 ]; then
            TIME_DIFF=$((CURRENT_TIME - TOKEN_TIME))
            debug "Token age: $TIME_DIFF seconds"
            if [ "$TIME_DIFF" -gt 3000 ]; then
                debug "Token expired, refreshing..."
                refresh_token
            fi
        fi
    fi

    ACCESS_TOKEN=$(jq -r '.access_token' "$TOKEN_FILE")
    debug "Access token retrieved (length: ${#ACCESS_TOKEN})"
    echo "$ACCESS_TOKEN"
}

# Get SharePoint site ID
get_site_id() {
    debug "Getting site ID for: $TENANT_NAME.sharepoint.com/sites/$SITE_NAME"
    local ACCESS_TOKEN=$(get_access_token)

    local SITE_URL="https://graph.microsoft.com/v1.0/sites/$TENANT_NAME.sharepoint.com:/sites/$SITE_NAME"
    debug "API URL: $SITE_URL"

    SITE_RESPONSE=$(curl -s -X GET "$SITE_URL" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    debug "Site response received (length: ${#SITE_RESPONSE})"

    # Check for errors in response
    ERROR=$(echo "$SITE_RESPONSE" | jq -r '.error.code // empty')
    if [ -n "$ERROR" ]; then
        error "Failed to get site ID: $ERROR"
        ERROR_MSG=$(echo "$SITE_RESPONSE" | jq -r '.error.message // empty')
        if [ -n "$ERROR_MSG" ]; then
            echo "  $ERROR_MSG" >&2
        fi
        echo "" >&2
        echo "Troubleshooting:" >&2
        echo "  - Check your tenant name: $TENANT_NAME" >&2
        echo "  - Check your site name: $SITE_NAME" >&2
        echo "  - Verify you have access to this SharePoint site" >&2
        echo "  - Try: https://$TENANT_NAME.sharepoint.com/sites/$SITE_NAME" >&2
        echo "" >&2
        if [ "$DEBUG" -eq 1 ]; then
            echo "Full response:" >&2
            echo "$SITE_RESPONSE" | jq >&2
        fi
        exit 1
    fi

    SITE_ID=$(echo "$SITE_RESPONSE" | jq -r '.id // empty')

    if [ -z "$SITE_ID" ]; then
        error "Failed to get site ID. Response:"
        echo "$SITE_RESPONSE" | jq >&2
        exit 1
    fi

    debug "Site ID retrieved: $SITE_ID"
    echo "$SITE_ID"
}

# List available SharePoint sites
list_sites() {
    local ACCESS_TOKEN=$(get_access_token)

    info "Searching for available SharePoint sites..."

    # Search for all sites
    SITES_RESPONSE=$(curl -s -X GET \
        "https://graph.microsoft.com/v1.0/sites?search=*" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    ERROR=$(echo "$SITES_RESPONSE" | jq -r '.error.code // empty')
    if [ -n "$ERROR" ]; then
        error "Failed to list sites: $ERROR"
        return 1
    fi

    # Extract site names (filter for /sites/ pattern)
    SITE_LIST=$(echo "$SITES_RESPONSE" | jq -r '.value[] | select(.webUrl | contains("/sites/")) | .webUrl' | sed 's|.*/sites/||' | sort -u)

    if [ -z "$SITE_LIST" ]; then
        warning "No sites found"
        return 1
    fi

    echo "$SITE_LIST"
}

# Get drive ID
get_drive_id() {
    debug "Getting drive ID..."
    local ACCESS_TOKEN=$(get_access_token)
    local SITE_ID=$1

    debug "Site ID: $SITE_ID"

    DRIVE_RESPONSE=$(curl -s -X GET \
        "https://graph.microsoft.com/v1.0/sites/$SITE_ID/drives" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    debug "Drive response received (length: ${#DRIVE_RESPONSE})"

    # Check for errors in response
    ERROR=$(echo "$DRIVE_RESPONSE" | jq -r '.error.code // empty')
    if [ -n "$ERROR" ]; then
        error "Failed to get drives: $ERROR"
        ERROR_MSG=$(echo "$DRIVE_RESPONSE" | jq -r '.error.message // empty')
        if [ -n "$ERROR_MSG" ]; then
            echo "  $ERROR_MSG" >&2
        fi
        if [ "$DEBUG" -eq 1 ]; then
            echo "Full response:" >&2
            echo "$DRIVE_RESPONSE" | jq >&2
        fi
        exit 1
    fi

    # Get list of drives for user to select
    DRIVE_COUNT=$(echo "$DRIVE_RESPONSE" | jq '.value | length // 0')

    debug "Drive count: $DRIVE_COUNT"

    # Ensure DRIVE_COUNT is a valid number
    if ! [[ "$DRIVE_COUNT" =~ ^[0-9]+$ ]]; then
        error "Invalid response from SharePoint API"
        echo "Response received:" >&2
        echo "$DRIVE_RESPONSE" | jq >&2
        exit 1
    fi

    if [ "$DRIVE_COUNT" -eq 0 ]; then
        error "No drives found"
        exit 1
    elif [ "$DRIVE_COUNT" -eq 1 ]; then
        DRIVE_ID=$(echo "$DRIVE_RESPONSE" | jq -r '.value[0].id')
        debug "Single drive found: $DRIVE_ID"
        echo "$DRIVE_ID"
    else
        # Multiple drives, let user choose
        debug "Multiple drives found, prompting user..."
        DRIVE_NAMES=$(echo "$DRIVE_RESPONSE" | jq -r '.value[] | .name')
        SELECTED_DRIVE=$(echo "$DRIVE_NAMES" | gum choose --header "Select a drive:")
        DRIVE_ID=$(echo "$DRIVE_RESPONSE" | jq -r ".value[] | select(.name==\"$SELECTED_DRIVE\") | .id")
        debug "User selected drive: $DRIVE_ID"
        echo "$DRIVE_ID"
    fi
}

# List items in a folder
list_items() {
    local ACCESS_TOKEN=$(get_access_token)
    local DRIVE_ID=$1
    local FOLDER_ID=${2:-root}

    debug "Listing items: DRIVE_ID=$DRIVE_ID, FOLDER_ID=$FOLDER_ID"

    if [ -z "$DRIVE_ID" ]; then
        error "DRIVE_ID is empty!"
        exit 1
    fi

    if [ "$FOLDER_ID" == "root" ]; then
        ENDPOINT="https://graph.microsoft.com/v1.0/drives/$DRIVE_ID/root/children"
    else
        ENDPOINT="https://graph.microsoft.com/v1.0/drives/$DRIVE_ID/items/$FOLDER_ID/children"
    fi

    debug "Endpoint: $ENDPOINT"

    RESPONSE=$(curl -s -X GET "$ENDPOINT" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    # Check for errors
    ERROR=$(echo "$RESPONSE" | jq -r '.error.code // empty')
    if [ -n "$ERROR" ]; then
        error "API Error: $ERROR"
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // empty')
        if [ -n "$ERROR_MSG" ]; then
            echo "  $ERROR_MSG" >&2
        fi
        if [ "$DEBUG" -eq 1 ]; then
            echo "Full response:" >&2
            echo "$RESPONSE" | jq >&2
        fi
        exit 1
    fi

    echo "$RESPONSE"
}

# Download file
download_file() {
    local ACCESS_TOKEN=$(get_access_token)
    local DRIVE_ID=$1
    local ITEM_ID=$2
    local FILENAME=$3
    local OUTPUT_PATH=${4:-.}

    info "Downloading: $FILENAME"

    # Get download URL
    DOWNLOAD_URL=$(curl -s -X GET \
        "https://graph.microsoft.com/v1.0/drives/$DRIVE_ID/items/$ITEM_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.["@microsoft.graph.downloadUrl"]')

    if [ "$DOWNLOAD_URL" == "null" ] || [ -z "$DOWNLOAD_URL" ]; then
        error "Failed to get download URL"
        return 1
    fi

    # Download file with progress
    curl -# -L -o "$OUTPUT_PATH/$FILENAME" "$DOWNLOAD_URL"
    success "Downloaded: $OUTPUT_PATH/$FILENAME"
}

# Download file by ID (CLI mode)
download_file_by_id() {
    local DRIVE_ID=$1
    local FILE_ID=$2
    local OUTPUT_PATH=${3:-.}

    local ACCESS_TOKEN=$(get_access_token)

    info "Fetching file info..."

    # Get file info
    FILE_INFO=$(curl -s -X GET \
        "https://graph.microsoft.com/v1.0/drives/$DRIVE_ID/items/$FILE_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    ERROR=$(echo "$FILE_INFO" | jq -r '.error.code // empty')
    if [ -n "$ERROR" ]; then
        error "Failed to get file info: $ERROR"
        ERROR_MSG=$(echo "$FILE_INFO" | jq -r '.error.message // empty')
        if [ -n "$ERROR_MSG" ]; then
            echo "  $ERROR_MSG" >&2
        fi
        return 1
    fi

    FILENAME=$(echo "$FILE_INFO" | jq -r '.name')
    DOWNLOAD_URL=$(echo "$FILE_INFO" | jq -r '.["@microsoft.graph.downloadUrl"]')

    if [ "$DOWNLOAD_URL" == "null" ] || [ -z "$DOWNLOAD_URL" ]; then
        error "Failed to get download URL"
        return 1
    fi

    info "Downloading: $FILENAME"

    # Download file with progress
    curl -# -L -o "$OUTPUT_PATH/$FILENAME" "$DOWNLOAD_URL"
    success "Downloaded: $OUTPUT_PATH/$FILENAME"
}

# Upload file
upload_file() {
    local ACCESS_TOKEN=$(get_access_token)
    local DRIVE_ID=$1
    local FOLDER_ID=$2
    local FILE_PATH=$3

    local FILENAME=$(basename "$FILE_PATH")

    if [ ! -f "$FILE_PATH" ]; then
        error "File not found: $FILE_PATH"
        return 1
    fi

    info "Uploading: $FILENAME"

    if [ "$FOLDER_ID" == "root" ]; then
        ENDPOINT="https://graph.microsoft.com/v1.0/drives/$DRIVE_ID/root:/$FILENAME:/content"
    else
        ENDPOINT="https://graph.microsoft.com/v1.0/drives/$DRIVE_ID/items/$FOLDER_ID:/$FILENAME:/content"
    fi

    RESPONSE=$(curl -s -X PUT "$ENDPOINT" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        --data-binary "@$FILE_PATH")

    if echo "$RESPONSE" | jq -e '.id' >/dev/null 2>&1; then
        FILE_ID=$(echo "$RESPONSE" | jq -r '.id')
        success "Uploaded: $FILENAME"
        info "File ID: $FILE_ID"
        echo "$FILE_ID"  # Return file ID
        return 0
    else
        error "Upload failed"
        echo "$RESPONSE" | jq >&2
        return 1
    fi
}

# Create folder
create_folder() {
    local ACCESS_TOKEN=$(get_access_token)
    local DRIVE_ID=$1
    local FOLDER_ID=$2
    local FOLDER_NAME=$3

    info "Creating folder: $FOLDER_NAME"

    if [ "$FOLDER_ID" == "root" ]; then
        ENDPOINT="https://graph.microsoft.com/v1.0/drives/$DRIVE_ID/root/children"
    else
        ENDPOINT="https://graph.microsoft.com/v1.0/drives/$DRIVE_ID/items/$FOLDER_ID/children"
    fi

    RESPONSE=$(curl -s -X POST "$ENDPOINT" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$FOLDER_NAME\",
            \"folder\": {},
            \"@microsoft.graph.conflictBehavior\": \"fail\"
        }")

    ERROR=$(echo "$RESPONSE" | jq -r '.error.code // empty')
    if [ -n "$ERROR" ]; then
        error "Failed to create folder: $ERROR"
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // empty')
        if [ -n "$ERROR_MSG" ]; then
            echo "  $ERROR_MSG" >&2
        fi
        return 1
    fi

    if echo "$RESPONSE" | jq -e '.id' >/dev/null 2>&1; then
        success "Folder created: $FOLDER_NAME"
        return 0
    else
        error "Failed to create folder"
        echo "$RESPONSE" | jq >&2
        return 1
    fi
}

# Delete file
delete_file() {
    local ACCESS_TOKEN=$(get_access_token)
    local DRIVE_ID=$1
    local ITEM_ID=$2
    local FILENAME=$3

    warning "Deleting: $FILENAME"

    ENDPOINT="https://graph.microsoft.com/v1.0/drives/$DRIVE_ID/items/$ITEM_ID"

    RESPONSE=$(curl -s -X DELETE "$ENDPOINT" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    # DELETE returns 204 No Content on success, so empty response is good
    if [ -z "$RESPONSE" ]; then
        success "Deleted: $FILENAME"
        return 0
    else
        ERROR=$(echo "$RESPONSE" | jq -r '.error.code // empty')
        if [ -n "$ERROR" ]; then
            error "Failed to delete file: $ERROR"
            ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // empty')
            if [ -n "$ERROR_MSG" ]; then
                echo "  $ERROR_MSG" >&2
            fi
        else
            error "Failed to delete file"
            echo "$RESPONSE" | jq >&2
        fi
        return 1
    fi
}

# Interactive file browser
browse_and_download() {
    debug "Starting browse_and_download..."
    info "Connecting to SharePoint..."

    SITE_ID=$(get_site_id)
    if [ -z "$SITE_ID" ]; then
        error "Failed to get Site ID"
        exit 1
    fi
    debug "Site ID: $SITE_ID"
    success "Connected to SharePoint site"

    DRIVE_ID=$(get_drive_id "$SITE_ID")
    if [ -z "$DRIVE_ID" ]; then
        error "Failed to get Drive ID"
        exit 1
    fi
    debug "Drive ID: $DRIVE_ID"
    success "Drive selected"

    debug "Starting interactive browser loop..."

    local CURRENT_FOLDER="root"
    local FOLDER_STACK=()
    local FOLDER_NAME_STACK=("Root")

    while true; do
        clear
        gum style --border rounded --padding "1 2" --border-foreground 212 \
            "📁 SharePoint Browser" \
            "Site: $TENANT_NAME.sharepoint.com/sites/$SITE_NAME" \
            "Location: ${FOLDER_NAME_STACK[-1]}"
        echo ""

        # Get items in current folder
        ITEMS_RESPONSE=$(list_items "$DRIVE_ID" "$CURRENT_FOLDER")

        # Prepare choices
        CHOICES=()
        if [ "$CURRENT_FOLDER" != "root" ]; then
            CHOICES+=(".. (Go Back)")
        fi
        CHOICES+=("📁 Create New Folder" "🗑️ Delete File" "📥 Download Current Folder" "🔄 Refresh" "🌐 Change Site" "❌ Exit")

        # Add folders
        FOLDERS=$(echo "$ITEMS_RESPONSE" | jq -r '.value[] | select(.folder) | "📁 " + .name + " [ID: " + .id + "]"')
        if [ -n "$FOLDERS" ]; then
            while IFS= read -r folder; do
                CHOICES+=("$folder")
            done <<< "$FOLDERS"
        fi

        # Add files
        FILES=$(echo "$ITEMS_RESPONSE" | jq -r '.value[] | select(.file) | "📄 " + .name + " [ID: " + .id + "]"')
        if [ -n "$FILES" ]; then
            while IFS= read -r file; do
                CHOICES+=("$file")
            done <<< "$FILES"
        fi

        # Let user choose
        SELECTED=$(printf '%s\n' "${CHOICES[@]}" | gum choose --header "Select an item:")

        case "$SELECTED" in
            ".. (Go Back)")
                if [ ${#FOLDER_STACK[@]} -gt 0 ]; then
                    CURRENT_FOLDER=${FOLDER_STACK[-1]}
                    unset 'FOLDER_STACK[-1]'
                    unset 'FOLDER_NAME_STACK[-1]'
                fi
                ;;
            "📁 Create New Folder")
                NEW_FOLDER_NAME=$(gum input --placeholder "Enter folder name")
                if [ -n "$NEW_FOLDER_NAME" ]; then
                    if create_folder "$DRIVE_ID" "$CURRENT_FOLDER" "$NEW_FOLDER_NAME"; then
                        gum input --placeholder "Press Enter to continue..."
                    else
                        gum input --placeholder "Press Enter to continue..."
                    fi
                fi
                ;;
            "🗑️ Delete File")
                # Get list of files in current folder
                FILE_LIST=$(echo "$ITEMS_RESPONSE" | jq -r '.value[] | select(.file) | .name')

                if [ -z "$FILE_LIST" ]; then
                    warning "No files to delete in this folder"
                    gum input --placeholder "Press Enter to continue..."
                else
                    # Add cancel option
                    FILE_OPTIONS=$(echo -e "❌ Cancel\n$FILE_LIST")

                    SELECTED_FILE=$(echo "$FILE_OPTIONS" | gum choose --header "Select file to delete:")

                    if [ "$SELECTED_FILE" != "❌ Cancel" ] && [ -n "$SELECTED_FILE" ]; then
                        # Confirm deletion
                        clear
                        echo ""
                        warning "Are you sure you want to delete: $SELECTED_FILE?"
                        echo ""

                        CONFIRM=$(echo -e "Yes, delete it\nNo, cancel" | gum choose --header "Confirm deletion:")

                        if [ "$CONFIRM" == "Yes, delete it" ]; then
                            FILE_ID=$(echo "$ITEMS_RESPONSE" | jq -r ".value[] | select(.name==\"$SELECTED_FILE\") | .id")
                            if delete_file "$DRIVE_ID" "$FILE_ID" "$SELECTED_FILE"; then
                                gum input --placeholder "Press Enter to continue..."
                            else
                                gum input --placeholder "Press Enter to continue..."
                            fi
                        else
                            info "Deletion cancelled"
                            gum input --placeholder "Press Enter to continue..."
                        fi
                    fi
                fi
                ;;
            "🔄 Refresh")
                continue
                ;;
            "🌐 Change Site")
                clear
                echo ""
                echo "Current site: $TENANT_NAME.sharepoint.com/sites/$SITE_NAME"
                echo ""

                # Try to list available sites
                AVAILABLE_SITES=$(list_sites 2>/dev/null)

                if [ -n "$AVAILABLE_SITES" ]; then
                    # Add option to enter manually
                    SITE_OPTIONS=$(echo -e "✏️  Enter site name manually...\n$AVAILABLE_SITES")

                    SELECTED_SITE=$(echo "$SITE_OPTIONS" | gum choose --header "Select a site:")

                    if [ "$SELECTED_SITE" == "✏️  Enter site name manually..." ]; then
                        NEW_SITE_NAME=$(gum input --placeholder "Enter site name")
                    else
                        NEW_SITE_NAME="$SELECTED_SITE"
                    fi
                else
                    warning "Could not list sites, enter manually"
                    NEW_SITE_NAME=$(gum input --placeholder "Enter site name (default: $SITE_NAME)")
                    NEW_SITE_NAME=${NEW_SITE_NAME:-$SITE_NAME}
                fi

                if [ -z "$NEW_SITE_NAME" ]; then
                    info "No site selected"
                    gum input --placeholder "Press Enter to continue..."
                    continue
                fi

                if [ "$NEW_SITE_NAME" != "$SITE_NAME" ]; then
                    # Update config file
                    TMP_CONFIG=$(mktemp)
                    jq ".site_name = \"$NEW_SITE_NAME\"" "$CONFIG_FILE" > "$TMP_CONFIG"
                    mv "$TMP_CONFIG" "$CONFIG_FILE"

                    success "Site changed to: $TENANT_NAME.sharepoint.com/sites/$NEW_SITE_NAME"
                    info "Reconnecting..."

                    # Reload config and reconnect
                    load_config
                    SITE_ID=$(get_site_id)
                    if [ -z "$SITE_ID" ]; then
                        error "Failed to connect to new site"
                        gum input --placeholder "Press Enter to continue..."
                        # Revert to old site
                        TMP_CONFIG=$(mktemp)
                        jq ".site_name = \"$SITE_NAME\"" "$CONFIG_FILE" > "$TMP_CONFIG"
                        mv "$TMP_CONFIG" "$CONFIG_FILE"
                        load_config
                        continue
                    fi

                    DRIVE_ID=$(get_drive_id "$SITE_ID")
                    if [ -z "$DRIVE_ID" ]; then
                        error "Failed to get drive for new site"
                        gum input --placeholder "Press Enter to continue..."
                        # Revert to old site
                        TMP_CONFIG=$(mktemp)
                        jq ".site_name = \"$SITE_NAME\"" "$CONFIG_FILE" > "$TMP_CONFIG"
                        mv "$TMP_CONFIG" "$CONFIG_FILE"
                        load_config
                        continue
                    fi

                    success "Connected to new site!"

                    # Reset to root folder
                    CURRENT_FOLDER="root"
                    FOLDER_STACK=()
                    FOLDER_NAME_STACK=("Root")

                    gum input --placeholder "Press Enter to continue..."
                else
                    info "Site unchanged"
                    gum input --placeholder "Press Enter to continue..."
                fi
                ;;
            "❌ Exit")
                break
                ;;
            "📥 Download Current Folder")
                OUTPUT_DIR=$(gum input --placeholder "Enter output directory (default: ./downloads)" --value "./downloads")
                OUTPUT_DIR=${OUTPUT_DIR:-./downloads}
                mkdir -p "$OUTPUT_DIR"

                # Download all files in current folder
                FILE_IDS=$(echo "$ITEMS_RESPONSE" | jq -r '.value[] | select(.file) | .id')
                FILE_NAMES=$(echo "$ITEMS_RESPONSE" | jq -r '.value[] | select(.file) | .name')

                paste <(echo "$FILE_IDS") <(echo "$FILE_NAMES") | while IFS=$'\t' read -r id name; do
                    download_file "$DRIVE_ID" "$id" "$name" "$OUTPUT_DIR"
                done

                success "Downloaded all files to $OUTPUT_DIR"
                gum input --placeholder "Press Enter to continue..."
                ;;
            📁*)
                # Navigate into folder
                # Extract folder name (remove icon and ID)
                FOLDER_NAME="${SELECTED#📁 }"
                FOLDER_NAME="${FOLDER_NAME% \[ID:*}"
                FOLDER_ID=$(echo "$ITEMS_RESPONSE" | jq -r ".value[] | select(.name==\"$FOLDER_NAME\") | .id")
                FOLDER_STACK+=("$CURRENT_FOLDER")
                FOLDER_NAME_STACK+=("$FOLDER_NAME")
                CURRENT_FOLDER="$FOLDER_ID"
                ;;
            📄*)
                # Download file
                # Extract file name (remove icon and ID)
                FILE_NAME="${SELECTED#📄 }"
                FILE_NAME="${FILE_NAME% \[ID:*}"
                FILE_ID=$(echo "$ITEMS_RESPONSE" | jq -r ".value[] | select(.name==\"$FILE_NAME\") | .id")

                # Show download prompt with ESC hint
                clear
                echo ""
                info "Download: $FILE_NAME"
                echo ""

                # Capture output directory, handle ESC gracefully
                # Don't exit on error for this command
                set +e
                OUTPUT_DIR=$(gum input --placeholder "Enter output directory (default: .) - Press ESC to cancel")
                EXIT_CODE=$?
                set -e

                if [ $EXIT_CODE -eq 0 ]; then
                    # User entered a path or pressed Enter
                    OUTPUT_DIR=${OUTPUT_DIR:-.}
                    mkdir -p "$OUTPUT_DIR"

                    download_file "$DRIVE_ID" "$FILE_ID" "$FILE_NAME" "$OUTPUT_DIR"
                    gum input --placeholder "Press Enter to continue..."
                else
                    # User pressed ESC
                    info "Download cancelled"
                fi
                ;;
        esac
    done
}

# Show help
show_help() {
    cat <<EOF
SharePoint File Manager with OAuth2 and Gum UI

Usage:
    $(basename "$0") [options]

Options:
    --init              Initialize configuration (first time setup)
    --set-site          Change the SharePoint site
    --upload FILE       Upload a file to SharePoint
    --download          Download a file from SharePoint
    --browse            Browse and download files (default)
    --auth              Force re-authentication
    --debug             Enable debug logging
    --help              Show this help message

CLI Flags:
    --file-id ID        File ID for download (required with --download)
    --folder-id ID      Folder ID for upload (optional with --upload)
    --site SITENAME     Override site name for current command
    --output DIR        Output directory for downloads (default: .)

Features:
    - Browse SharePoint folders interactively
    - Download individual files or entire folders
    - Upload files to any folder
    - Create new folders in SharePoint
    - Delete files from SharePoint
    - Switch between different SharePoint sites
    - CLI mode for automated uploads/downloads

Examples:
    # First time setup
    $(basename "$0") --init

    # Browse and download files (interactive)
    $(basename "$0") --browse

    # Upload a file (interactive folder selection)
    $(basename "$0") --upload /path/to/file.pdf

    # Upload a file directly to a folder (CLI mode)
    $(basename "$0") --upload /path/to/file.pdf --folder-id FOLDER_ID

    # Upload to a different site
    $(basename "$0") --upload file.pdf --folder-id FOLDER_ID --site teamsite

    # Download a file by ID (CLI mode)
    $(basename "$0") --download --file-id FILE_ID

    # Download to specific directory
    $(basename "$0") --download --file-id FILE_ID --output ~/Downloads

    # Download from a different site
    $(basename "$0") --download --file-id FILE_ID --site admin

    # Change to a different site
    $(basename "$0") --set-site

    # Debug mode
    $(basename "$0") --debug --browse

Setup Instructions:
    1. Register an app in Azure AD:
       https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade

    2. Set up the app:
       - Set redirect URI: http://localhost:8080
       - Enable "Allow public client flows"
       - Add API permissions: Files.ReadWrite.All, Sites.ReadWrite.All

    3. Note your Tenant ID and Application (Client) ID

    4. Run: $(basename "$0") --init

EOF
}

# Main function
main() {
    # Parse command line arguments
    ARGS=()
    FILE_ID=""
    FOLDER_ID_CLI=""
    SITE_OVERRIDE=""
    OUTPUT_DIR_CLI="."

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --debug)
                # Already handled at script start
                shift
                ;;
            --file-id)
                FILE_ID="$2"
                shift 2
                ;;
            --folder-id)
                FOLDER_ID_CLI="$2"
                shift 2
                ;;
            --site)
                SITE_OVERRIDE="$2"
                shift 2
                ;;
            --output)
                OUTPUT_DIR_CLI="$2"
                shift 2
                ;;
            *)
                ARGS+=("$1")
                shift
                ;;
        esac
    done

    check_dependencies

    case "${ARGS[0]:-}" in
        --init)
            init_config
            ;;
        --auth)
            load_config
            authenticate
            ;;
        --download)
            if [ -z "$FILE_ID" ]; then
                error "Please specify a file ID to download"
                echo "Usage: $0 --download --file-id FILE_ID [--output /path/to/dir] [--site SITENAME]"
                exit 1
            fi

            load_config

            # Override site if specified
            if [ -n "$SITE_OVERRIDE" ]; then
                SITE_NAME="$SITE_OVERRIDE"
            fi

            info "Connecting to SharePoint..."
            SITE_ID=$(get_site_id)
            DRIVE_ID=$(get_drive_id "$SITE_ID")

            # Download file
            download_file_by_id "$DRIVE_ID" "$FILE_ID" "$OUTPUT_DIR_CLI"
            ;;
        --upload)
            if [ -z "${ARGS[1]:-}" ]; then
                error "Please specify a file to upload"
                echo "Usage: $0 --upload /path/to/file [--folder-id FOLDER_ID] [--site SITENAME]"
                exit 1
            fi
            load_config

            # Override site if specified
            if [ -n "$SITE_OVERRIDE" ]; then
                SITE_NAME="$SITE_OVERRIDE"
            fi

            debug "Upload mode: ${ARGS[1]}"

            info "Connecting to SharePoint..."
            SITE_ID=$(get_site_id)
            DRIVE_ID=$(get_drive_id "$SITE_ID")

            # If folder-id is provided, upload directly (CLI mode)
            if [ -n "$FOLDER_ID_CLI" ]; then
                upload_file "$DRIVE_ID" "$FOLDER_ID_CLI" "${ARGS[1]}"
                exit 0
            fi

            # Otherwise, interactive mode - let user choose destination folder
            CURRENT_FOLDER="root"
            FOLDER_STACK=()
            FOLDER_NAME_STACK=("Root")

            while true; do
                clear
                gum style --border rounded --padding "1 2" --border-foreground 212 \
                    "📤 Upload File" \
                    "Site: $TENANT_NAME.sharepoint.com/sites/$SITE_NAME" \
                    "File: $(basename "${ARGS[1]}")" \
                    "Destination: ${FOLDER_NAME_STACK[-1]}"
                echo ""

                ITEMS_RESPONSE=$(list_items "$DRIVE_ID" "$CURRENT_FOLDER")

                CHOICES=("✓ Upload Here" "🌐 Change Site")
                if [ "$CURRENT_FOLDER" != "root" ]; then
                    CHOICES+=(".. (Go Back)")
                fi

                FOLDERS=$(echo "$ITEMS_RESPONSE" | jq -r '.value[] | select(.folder) | "📁 " + .name + " [ID: " + .id + "]"')
                if [ -n "$FOLDERS" ]; then
                    while IFS= read -r folder; do
                        CHOICES+=("$folder")
                    done <<< "$FOLDERS"
                fi

                SELECTED=$(printf '%s\n' "${CHOICES[@]}" | gum choose --header "Select destination:")

                case "$SELECTED" in
                    "✓ Upload Here")
                        upload_file "$DRIVE_ID" "$CURRENT_FOLDER" "${ARGS[1]}"
                        break
                        ;;
                    "🌐 Change Site")
                        clear
                        echo ""
                        echo "Current site: $TENANT_NAME.sharepoint.com/sites/$SITE_NAME"
                        echo ""

                        # Try to list available sites
                        AVAILABLE_SITES=$(list_sites 2>/dev/null)

                        if [ -n "$AVAILABLE_SITES" ]; then
                            # Add option to enter manually
                            SITE_OPTIONS=$(echo -e "✏️  Enter site name manually...\n$AVAILABLE_SITES")

                            SELECTED_SITE=$(echo "$SITE_OPTIONS" | gum choose --header "Select a site:")

                            if [ "$SELECTED_SITE" == "✏️  Enter site name manually..." ]; then
                                NEW_SITE_NAME=$(gum input --placeholder "Enter site name")
                            else
                                NEW_SITE_NAME="$SELECTED_SITE"
                            fi
                        else
                            warning "Could not list sites, enter manually"
                            NEW_SITE_NAME=$(gum input --placeholder "Enter site name (default: $SITE_NAME)")
                            NEW_SITE_NAME=${NEW_SITE_NAME:-$SITE_NAME}
                        fi

                        if [ -z "$NEW_SITE_NAME" ]; then
                            info "No site selected"
                            gum input --placeholder "Press Enter to continue..."
                            continue
                        fi

                        if [ "$NEW_SITE_NAME" != "$SITE_NAME" ]; then
                            # Update config file
                            TMP_CONFIG=$(mktemp)
                            jq ".site_name = \"$NEW_SITE_NAME\"" "$CONFIG_FILE" > "$TMP_CONFIG"
                            mv "$TMP_CONFIG" "$CONFIG_FILE"

                            success "Site changed to: $TENANT_NAME.sharepoint.com/sites/$NEW_SITE_NAME"
                            info "Reconnecting..."

                            # Reload config and reconnect
                            load_config
                            SITE_ID=$(get_site_id)
                            if [ -z "$SITE_ID" ]; then
                                error "Failed to connect to new site"
                                gum input --placeholder "Press Enter to continue..."
                                # Revert to old site
                                TMP_CONFIG=$(mktemp)
                                jq ".site_name = \"$SITE_NAME\"" "$CONFIG_FILE" > "$TMP_CONFIG"
                                mv "$TMP_CONFIG" "$CONFIG_FILE"
                                load_config
                                continue
                            fi

                            DRIVE_ID=$(get_drive_id "$SITE_ID")
                            if [ -z "$DRIVE_ID" ]; then
                                error "Failed to get drive for new site"
                                gum input --placeholder "Press Enter to continue..."
                                # Revert to old site
                                TMP_CONFIG=$(mktemp)
                                jq ".site_name = \"$SITE_NAME\"" "$CONFIG_FILE" > "$TMP_CONFIG"
                                mv "$TMP_CONFIG" "$CONFIG_FILE"
                                load_config
                                continue
                            fi

                            success "Connected to new site!"

                            # Reset to root folder
                            CURRENT_FOLDER="root"
                            FOLDER_STACK=()
                            FOLDER_NAME_STACK=("Root")

                            gum input --placeholder "Press Enter to continue..."
                        else
                            info "Site unchanged"
                            gum input --placeholder "Press Enter to continue..."
                        fi
                        ;;
                    ".. (Go Back)")
                        if [ ${#FOLDER_STACK[@]} -gt 0 ]; then
                            CURRENT_FOLDER=${FOLDER_STACK[-1]}
                            unset 'FOLDER_STACK[-1]'
                            unset 'FOLDER_NAME_STACK[-1]'
                        fi
                        ;;
                    📁*)
                        # Extract folder name (remove icon and ID)
                        FOLDER_NAME="${SELECTED#📁 }"
                        FOLDER_NAME="${FOLDER_NAME% \[ID:*}"
                        FOLDER_ID=$(echo "$ITEMS_RESPONSE" | jq -r ".value[] | select(.name==\"$FOLDER_NAME\") | .id")
                        FOLDER_STACK+=("$CURRENT_FOLDER")
                        FOLDER_NAME_STACK+=("$FOLDER_NAME")
                        CURRENT_FOLDER="$FOLDER_ID"
                        ;;
                esac
            done
            ;;
        --set-site)
            load_config

            echo ""
            echo "Current site: $TENANT_NAME.sharepoint.com/sites/$SITE_NAME"
            echo ""

            # Try to list available sites
            AVAILABLE_SITES=$(list_sites 2>/dev/null)

            if [ -n "$AVAILABLE_SITES" ]; then
                # Add option to enter manually
                SITE_OPTIONS=$(echo -e "✏️  Enter site name manually...\n$AVAILABLE_SITES")

                SELECTED_SITE=$(echo "$SITE_OPTIONS" | gum choose --header "Select a site:")

                if [ "$SELECTED_SITE" == "✏️  Enter site name manually..." ]; then
                    NEW_SITE_NAME=$(gum input --placeholder "Enter site name")
                else
                    NEW_SITE_NAME="$SELECTED_SITE"
                fi
            else
                warning "Could not list sites, enter manually"
                NEW_SITE_NAME=$(gum input --placeholder "Enter new site name (default: $SITE_NAME)")
                NEW_SITE_NAME=${NEW_SITE_NAME:-$SITE_NAME}
            fi

            if [ -n "$NEW_SITE_NAME" ] && [ "$NEW_SITE_NAME" != "$SITE_NAME" ]; then
                # Update config file
                TMP_CONFIG=$(mktemp)
                jq ".site_name = \"$NEW_SITE_NAME\"" "$CONFIG_FILE" > "$TMP_CONFIG"
                mv "$TMP_CONFIG" "$CONFIG_FILE"

                success "Site changed to: $TENANT_NAME.sharepoint.com/sites/$NEW_SITE_NAME"
            else
                info "Site unchanged"
            fi
            ;;
        --browse|"")
            if [ ! -f "$CONFIG_FILE" ]; then
                warning "Not configured yet. Running initial setup..."
                init_config
            fi
            load_config
            browse_and_download
            ;;
        --help|-h)
            show_help
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
