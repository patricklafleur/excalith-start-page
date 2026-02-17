#!/bin/bash

# Deployment script for Synology
# Builds and starts the container with custom settings

set -e

echo "========================================="
echo "Excalith Start Page - Deployment"
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
echo "Synology directory: $SYNOLOGY_DIR"
echo ""

# Check if docker-compose.yml exists
if [ ! -f "$SYNOLOGY_DIR/docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found in $SYNOLOGY_DIR${NC}"
    exit 1
fi

# Check if data/settings.json exists
if [ ! -f "$PROJECT_DIR/data/settings.json" ]; then
    echo -e "${RED}Error: data/settings.json not found${NC}"
    echo "Please run ./scripts/setup.sh first"
    exit 1
fi

echo "Checking for existing container..."
if docker ps -a | grep -q excalith-start-page; then
    echo -e "${YELLOW}Container already exists${NC}"
    read -p "Stop and remove existing container? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping and removing existing container..."
        cd "$SYNOLOGY_DIR"
        docker compose down
        echo -e "${GREEN}Existing container removed${NC}"
    else
        echo "Keeping existing container"
        exit 0
    fi
fi

echo ""
echo "Building Docker image with your customizations..."
echo "This may take a few minutes on first build..."
echo ""

cd "$SYNOLOGY_DIR"

# Build the image
if docker compose build; then
    echo -e "${GREEN}Image built successfully${NC}"
else
    echo -e "${RED}Error building image${NC}"
    exit 1
fi

echo ""
echo "Starting container..."

# Start the container
if docker compose up -d; then
    echo -e "${GREEN}Container started successfully${NC}"
else
    echo -e "${RED}Error starting container${NC}"
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
echo "Deployment complete!"
echo "========================================="
echo ""

# Get local IP
LOCAL_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || hostname -I | awk '{print $1}')

echo "Access your start page:"
echo -e "  ${BLUE}Local network:${NC} http://$LOCAL_IP:8080"

# Check if Tailscale is available
if command -v tailscale &> /dev/null; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
    if [ -n "$TAILSCALE_IP" ]; then
        echo -e "  ${BLUE}Tailscale:${NC} http://$TAILSCALE_IP:8080"
    fi
fi

echo ""
echo "To view logs: docker compose -f $SYNOLOGY_DIR/docker-compose.yml logs -f"
echo "To verify: $SCRIPT_DIR/verify.sh"
echo ""
