#!/bin/bash

# Setup script for Synology deployment
# This script prepares the environment for deploying the start page

set -e

echo "========================================="
echo "Excalith Start Page - Synology Setup"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Synology
if [ ! -d "/volume1" ]; then
    echo -e "${YELLOW}Warning: /volume1 not found. Are you running this on a Synology NAS?${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker (Container Manager) via Package Center"
    exit 1
fi
echo -e "${GREEN}Docker: installed${NC}"

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}Error: docker compose is not available${NC}"
    exit 1
fi
echo -e "${GREEN}Docker Compose: installed${NC}"

if command -v git &> /dev/null; then
    echo -e "${GREEN}Git: installed${NC}"
else
    echo -e "${YELLOW}Git: not installed (optional)${NC}"
fi

echo ""

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Project directory: $PROJECT_DIR"
echo ""

# Check if data/settings.json exists
if [ ! -f "$PROJECT_DIR/data/settings.json" ]; then
    echo -e "${RED}Error: data/settings.json not found${NC}"
    echo "Please ensure you have a settings.json file in $PROJECT_DIR/data/"
    exit 1
fi
echo -e "${GREEN}Settings file: found${NC}"

# Create data directory if it doesn't exist
DATA_DIR="$PROJECT_DIR/data"
if [ ! -d "$DATA_DIR" ]; then
    echo "Creating data directory..."
    mkdir -p "$DATA_DIR"
fi

# Set correct permissions (uid 1001 = nextjs user in container)
echo "Setting permissions on data directory..."
chown -R 1001:1001 "$DATA_DIR" 2>/dev/null || {
    echo -e "${YELLOW}Warning: Could not set ownership to 1001:1001${NC}"
    echo "You may need to run this script with sudo"
    echo "Or manually run: sudo chown -R 1001:1001 $DATA_DIR"
}

echo -e "${GREEN}Data directory permissions: set${NC}"

# Create backup directory
BACKUP_DIR="$PROJECT_DIR/synology/backups"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    echo -e "${GREEN}Backup directory: created${NC}"
fi

echo ""
echo "========================================="
echo "Setup complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Review your settings in: $DATA_DIR/settings.json"
echo "  2. Run deployment script: ./scripts/deploy.sh"
echo "  3. Verify installation: ./scripts/verify.sh"
echo ""
echo "For Tailscale setup, see README.md"
echo ""
