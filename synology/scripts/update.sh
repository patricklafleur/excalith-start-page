#!/bin/bash

# Update script for Synology deployment
# Pulls latest code, rebuilds image, and restarts container
# Settings are preserved via volume mount

set -e

echo "========================================="
echo "Excalith Start Page - Update"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNOLOGY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$SYNOLOGY_DIR/.." && pwd)"

echo "Project directory: $PROJECT_DIR"
echo ""

# Check if git is available
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed${NC}"
    echo "Please install git or manually update the code"
    exit 1
fi

# Check if we're in a git repository
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo -e "${RED}Error: Not a git repository${NC}"
    echo "Please manually update the code"
    exit 1
fi

# Backup settings before update
echo "Creating backup of current settings..."
"$SCRIPT_DIR/backup.sh"

echo ""
echo "Pulling latest code from repository..."
cd "$PROJECT_DIR"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
    echo "Changes will be stashed before update"
    git stash
    STASHED=true
else
    STASHED=false
fi

# Pull latest changes
if git pull; then
    echo -e "${GREEN}Code updated successfully${NC}"
else
    echo -e "${RED}Error pulling latest code${NC}"
    exit 1
fi

# Restore stashed changes if any
if [ "$STASHED" = true ]; then
    echo "Restoring your local changes..."
    git stash pop
fi

echo ""
echo "Rebuilding Docker image..."
cd "$SYNOLOGY_DIR"

# Rebuild the image
if docker compose build --no-cache; then
    echo -e "${GREEN}Image rebuilt successfully${NC}"
else
    echo -e "${RED}Error rebuilding image${NC}"
    exit 1
fi

echo ""
echo "Restarting container..."

# Restart the container
if docker compose down && docker compose up -d; then
    echo -e "${GREEN}Container restarted successfully${NC}"
else
    echo -e "${RED}Error restarting container${NC}"
    exit 1
fi

echo ""
echo "Waiting for container to be healthy..."
sleep 5

# Check if container is running
if docker ps | grep -q excalith-start-page; then
    echo -e "${GREEN}Container is running${NC}"
else
    echo -e "${RED}Container is not running${NC}"
    echo "Checking logs..."
    docker compose logs start-page
    exit 1
fi

echo ""
echo "========================================="
echo "Update complete!"
echo "========================================="
echo ""

# Get local IP
LOCAL_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || hostname -I | awk '{print $1}')

echo "Your start page is accessible at:"
echo -e "  ${BLUE}Local network:${NC} http://$LOCAL_IP:8080"

# Check if Tailscale is available
if command -v tailscale &> /dev/null; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
    if [ -n "$TAILSCALE_IP" ]; then
        echo -e "  ${BLUE}Tailscale:${NC} http://$TAILSCALE_IP:8080"
    fi
fi

echo ""
echo "Settings have been preserved in the volume mount"
echo "To verify: $SCRIPT_DIR/verify.sh"
echo ""
