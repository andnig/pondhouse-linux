#!/bin/bash

set -e

# Colors for gum
BLUE="#00D9FF"
GREEN="#00FF9F"
PURPLE="#BD93F9"
RED="#FF5555"

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "❌ gum is not installed. Install it from: https://github.com/charmbracelet/gum"
    exit 1
fi

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ gh CLI is not installed. Install it from: https://cli.github.com"
    exit 1
fi

# 1. Check if authenticated with gh
gum style --border rounded --padding "1 2" --border-foreground "$PURPLE" "🔐 Checking GitHub authentication..."

if ! gh auth status &> /dev/null; then
    gum style --border rounded --padding "1 2" --border-foreground "$RED" "❌ Not authenticated with GitHub"

    if gum confirm "Would you like to authenticate now?"; then
        gh auth login
        gum style --border rounded --padding "1 2" --border-foreground "$GREEN" "✅ Successfully authenticated!"
    else
        gum style --border rounded --padding "1 2" --border-foreground "$RED" "Authentication required to continue"
        exit 1
    fi
else
    USERNAME=$(gh api user -q .login)
    gum style --border rounded --padding "1 2" --border-foreground "$GREEN" "✅ Authenticated as: $USERNAME"
fi

# 2. Let user search for repos
gum style --border rounded --padding "1 2" --border-foreground "$BLUE" "🔍 Searching repositories..."

# Get all repos (personal + orgs)
gum spin --spinner dot --title "Fetching your repositories..." -- gh repo list --limit 1000 --json nameWithOwner -q '.[].nameWithOwner' > /tmp/gh_repos.txt

# Get org repos
ORG_COUNT=$(gh api user/orgs --paginate -q '.[].login' 2>/dev/null | wc -l || echo "0")

if [ "$ORG_COUNT" -gt 0 ]; then
    gum spin --spinner dot --title "Fetching organization repositories..." -- bash -c '
        gh api user/orgs --paginate -q ".[].login" | while read org; do
            gh repo list "$org" --limit 1000 --json nameWithOwner -q ".[].nameWithOwner"
        done >> /tmp/gh_repos.txt
    '
fi

# Remove duplicates and sort
sort -u /tmp/gh_repos.txt > /tmp/gh_repos_sorted.txt

REPO_COUNT=$(wc -l < /tmp/gh_repos_sorted.txt)
gum style --foreground "$GREEN" "📦 Found $REPO_COUNT repositories"

# Let user filter and select a repo
SELECTED_REPO=$(gum filter --placeholder "Type to search repositories..." --height 15 < /tmp/gh_repos_sorted.txt)

if [ -z "$SELECTED_REPO" ]; then
    gum style --border rounded --padding "1 2" --border-foreground "$RED" "❌ No repository selected"
    rm /tmp/gh_repos.txt /tmp/gh_repos_sorted.txt
    exit 1
fi

gum style --border rounded --padding "1 2" --border-foreground "$PURPLE" "📍 Selected: $SELECTED_REPO"

# 3. Clone the repo to ~/github/ or a subfolder
GITHUB_DIR="$HOME/github"

# Create github directory if it doesn't exist
if [ ! -d "$GITHUB_DIR" ]; then
    gum style --foreground "$BLUE" "📁 Creating directory: $GITHUB_DIR"
    mkdir -p "$GITHUB_DIR"
fi

# Ask if user wants to select a subfolder
TARGET_DIR="$GITHUB_DIR"

if gum confirm "Clone to a subfolder in ~/github?"; then
    # Find directories in ~/github (max 3 levels deep, excluding .venv and node_modules)
    if [ -d "$GITHUB_DIR" ]; then
        FOLDERS=$(find "$GITHUB_DIR" -maxdepth 3 -type d \
            \( -name ".venv" -o -name "node_modules" -o -name ".git" \) -prune -o \
            -type d -print 2>/dev/null | \
            sed "s|$GITHUB_DIR/||" | \
            grep -v "^$GITHUB_DIR$" | \
            grep -v "^\.$" | \
            sort -u)

        if [ -n "$FOLDERS" ]; then
            # Add option to create new folder
            FOLDER_OPTIONS=$(echo -e "📁 [Create new folder]\n$FOLDERS")

            SELECTED_FOLDER=$(echo "$FOLDER_OPTIONS" | gum filter --placeholder "Select or search for a folder...")

            if [ "$SELECTED_FOLDER" = "📁 [Create new folder]" ]; then
                NEW_FOLDER=$(gum input --placeholder "Enter new folder name (e.g., work/projects)")
                if [ -n "$NEW_FOLDER" ]; then
                    TARGET_DIR="$GITHUB_DIR/$NEW_FOLDER"
                    mkdir -p "$TARGET_DIR"
                    gum style --foreground "$GREEN" "✅ Created: $TARGET_DIR"
                fi
            elif [ -n "$SELECTED_FOLDER" ]; then
                TARGET_DIR="$GITHUB_DIR/$SELECTED_FOLDER"
            fi
        else
            # No existing folders, ask to create one
            gum style --foreground "$BLUE" "No existing subfolders found"
            NEW_FOLDER=$(gum input --placeholder "Enter folder name (e.g., work/projects)")
            if [ -n "$NEW_FOLDER" ]; then
                TARGET_DIR="$GITHUB_DIR/$NEW_FOLDER"
                mkdir -p "$TARGET_DIR"
                gum style --foreground "$GREEN" "✅ Created: $TARGET_DIR"
            fi
        fi
    else
        # No github dir exists yet, ask to create subfolder
        gum style --foreground "$BLUE" "No existing subfolders found"
        NEW_FOLDER=$(gum input --placeholder "Enter folder name (e.g., work/projects)")
        if [ -n "$NEW_FOLDER" ]; then
            TARGET_DIR="$GITHUB_DIR/$NEW_FOLDER"
            mkdir -p "$TARGET_DIR"
            gum style --foreground "$GREEN" "✅ Created: $TARGET_DIR"
        fi
    fi
fi

# Extract repo name for the folder
REPO_NAME=$(basename "$SELECTED_REPO")
CLONE_PATH="$TARGET_DIR/$REPO_NAME"

# Check if repo already exists
if [ -d "$CLONE_PATH" ]; then
    gum style --border rounded --padding "1 2" --border-foreground "$RED" "⚠️  Repository already exists at: $CLONE_PATH"

    if gum confirm "Do you want to pull the latest changes instead?"; then
        cd "$CLONE_PATH"
        gum spin --spinner dot --title "Pulling latest changes..." -- git pull
        gum style --border rounded --padding "1 2" --border-foreground "$GREEN" "✅ Successfully updated: $CLONE_PATH"

        if gum confirm "Open the repository directory?"; then
            gum style --foreground "$PURPLE" "🚀 Opening new shell in repository..."
            exec $SHELL
        fi
    fi
else
    # Clone the repository
    gum spin --spinner dot --title "Cloning $SELECTED_REPO..." -- gh repo clone "$SELECTED_REPO" "$CLONE_PATH"

    gum style \
        --border rounded \
        --padding "1 2" \
        --border-foreground "$GREEN" \
        "✅ Successfully cloned!

📂 Location: $CLONE_PATH"

    # Ask if user wants to cd into the repo
    if gum confirm "Open the repository directory?"; then
        gum style --foreground "$PURPLE" "🚀 Opening new shell in repository..."
        cd "$CLONE_PATH"
        exec $SHELL
    fi
fi

# Cleanup
rm /tmp/gh_repos.txt /tmp/gh_repos_sorted.txt

gum style --border double --padding "1 2" --border-foreground "$PURPLE" --align center "🎉 All done!"
