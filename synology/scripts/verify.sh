#!/bin/bash

# Verification script for Synology deployment
# Checks that everything is working correctly

set -e

echo "========================================="
echo "Excalith Start Page - Verification"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Running verification checks..."
echo ""

# Check 1: Container is running
echo -n "Checking if container is running... "
if docker ps | grep -q excalith-start-page; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "  Container is not running"
    ((ERRORS++))
fi

# Check 2: Container health
echo -n "Checking container health... "
HEALTH=$(docker inspect excalith-start-page --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
if [ "$HEALTH" = "healthy" ]; then
    echo -e "${GREEN}PASS${NC}"
elif [ "$HEALTH" = "starting" ]; then
    echo -e "${YELLOW}STARTING${NC}"
    echo "  Container is still starting up, wait a moment"
else
    echo -e "${RED}FAIL${NC}"
    echo "  Health status: $HEALTH"
    ((ERRORS++))
fi

# Check 3: BUILD_MODE environment variable
echo -n "Checking BUILD_MODE... "
BUILD_MODE=$(docker exec excalith-start-page printenv BUILD_MODE 2>/dev/null || echo "")
if [ "$BUILD_MODE" = "docker" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "  BUILD_MODE is '$BUILD_MODE', expected 'docker'"
    ((ERRORS++))
fi

# Check 4: Volume mount
echo -n "Checking volume mount... "
if docker inspect excalith-start-page | grep -q "/app/data"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "  Volume mount not found"
    ((ERRORS++))
fi

# Check 5: Settings file in container
echo -n "Checking settings file in container... "
if docker exec excalith-start-page test -f /app/data/settings.json; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "  settings.json not found in container"
    ((ERRORS++))
fi

# Check 6: Settings file permissions
echo -n "Checking settings file permissions... "
OWNER=$(docker exec excalith-start-page stat -c '%u:%g' /app/data/settings.json 2>/dev/null || echo "")
if [ "$OWNER" = "1001:1001" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARNING${NC}"
    echo "  Ownership is $OWNER, expected 1001:1001"
    echo "  This might cause permission issues"
fi

# Check 7: HTTP response
echo -n "Checking HTTP response (localhost:8080)... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "  HTTP status code: $HTTP_CODE (expected 200)"
    ((ERRORS++))
fi

# Check 8: Tailscale (optional)
echo -n "Checking Tailscale... "
if command -v tailscale &> /dev/null; then
    if tailscale status &> /dev/null; then
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
        if [ -n "$TAILSCALE_IP" ]; then
            echo -e "${GREEN}PASS${NC}"
            echo "  Tailscale IP: $TAILSCALE_IP"
        else
            echo -e "${YELLOW}WARNING${NC}"
            echo "  Tailscale is running but no IP found"
        fi
    else
        echo -e "${YELLOW}WARNING${NC}"
        echo "  Tailscale is installed but not running"
    fi
else
    echo -e "${YELLOW}SKIP${NC}"
    echo "  Tailscale not installed"
fi

echo ""
echo "========================================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    echo "========================================="
    echo ""

    # Get local IP
    LOCAL_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || hostname -I | awk '{print $1}')

    echo "Your start page is accessible at:"
    echo "  Local network: http://$LOCAL_IP:8080"

    if command -v tailscale &> /dev/null; then
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
        if [ -n "$TAILSCALE_IP" ]; then
            echo "  Tailscale: http://$TAILSCALE_IP:8080"
        fi
    fi

    echo ""
    echo "Test config reset:"
    echo "  1. Open the page in your browser"
    echo "  2. Run 'config reset' in the terminal"
    echo "  3. Verify YOUR customizations are restored (not defaults)"
    echo ""
    exit 0
else
    echo -e "${RED}$ERRORS check(s) failed${NC}"
    echo "========================================="
    echo ""
    echo "Troubleshooting:"
    echo "  View logs: docker logs excalith-start-page"
    echo "  Restart: docker restart excalith-start-page"
    echo "  See README.md for more troubleshooting steps"
    echo ""
    exit 1
fi
