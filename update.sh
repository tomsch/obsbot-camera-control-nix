#!/usr/bin/env bash
# Update script for obsbot-camera-control package
# Usage: ./update.sh
#
# Uses fetchFromGitHub with commit pinning (no releases available)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NIX="$SCRIPT_DIR/package.nix"

# Get current rev from package.nix
CURRENT_REV=$(grep 'rev = ' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/')
echo "Current rev: $CURRENT_REV"

# Get latest commit from GitHub API
echo "Checking GitHub for latest commit..."
CURL_OPTS=(-sL)
[ -n "${GITHUB_TOKEN:-}" ] && CURL_OPTS+=(-H "Authorization: token $GITHUB_TOKEN")
LATEST_DATA=$(curl "${CURL_OPTS[@]}" "https://api.github.com/repos/aaronsb/obsbot-camera-control/commits/main")

LATEST_REV=$(echo "$LATEST_DATA" | jq -r '.sha')
LATEST_DATE=$(echo "$LATEST_DATA" | jq -r '.commit.committer.date' | cut -d'T' -f1)

if [ -z "$LATEST_REV" ] || [ "$LATEST_REV" = "null" ]; then
    echo "Error: Could not fetch latest commit from GitHub"
    exit 1
fi

echo "Latest rev:  $LATEST_REV"
echo "Latest date: $LATEST_DATE"

if [ "$CURRENT_REV" = "$LATEST_REV" ]; then
    echo "Already up to date!"
    exit 0
fi

# Prefetch new hash
echo "Fetching hash for $LATEST_REV..."
SRI_HASH=$(nix-prefetch-url --unpack "https://github.com/aaronsb/obsbot-camera-control/archive/${LATEST_REV}.tar.gz" 2>&1 | tail -1)
SRI_HASH=$(nix hash convert --to sri --hash-algo sha256 "$SRI_HASH")

echo "New SRI hash: $SRI_HASH"

# Update package.nix - rev
sed -i "s|rev = \"$CURRENT_REV\"|rev = \"$LATEST_REV\"|" "$PACKAGE_NIX"

# Update package.nix - hash
sed -i "s|hash = \"sha256-.*\"|hash = \"$SRI_HASH\"|" "$PACKAGE_NIX"

# Update version date
sed -i "s|version = \"0-unstable-[0-9-]*\"|version = \"0-unstable-$LATEST_DATE\"|" "$PACKAGE_NIX"

echo "Updated package.nix to $LATEST_DATE ($LATEST_REV)"
echo ""
echo "Don't forget to rebuild: ./install.sh"
