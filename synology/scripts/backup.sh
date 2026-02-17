#!/bin/bash

# Backup script for settings.json
# Creates timestamped backups and handles rotation

set -e

echo "========================================="
echo "Excalith Start Page - Backup"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SYNOLOGY_DIR="$PROJECT_DIR/synology"
BACKUP_DIR="$SYNOLOGY_DIR/backups"
DATA_DIR="$PROJECT_DIR/data"

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
fi

# Check if settings.json exists
if [ ! -f "$DATA_DIR/settings.json" ]; then
    echo -e "${RED}Error: settings.json not found in $DATA_DIR${NC}"
    exit 1
fi

# Create timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/settings_$TIMESTAMP.json"

# Create backup
echo "Creating backup..."
cp "$DATA_DIR/settings.json" "$BACKUP_FILE"

if [ -f "$BACKUP_FILE" ]; then
    echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"
else
    echo -e "${RED}Error creating backup${NC}"
    exit 1
fi

# Get file size
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "Backup size: $SIZE"

# Rotation: keep only last N backups
MAX_BACKUPS=10

echo ""
echo "Checking backup rotation (keeping last $MAX_BACKUPS backups)..."

BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/settings_*.json 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    DELETE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
    echo "Found $BACKUP_COUNT backups, removing $DELETE_COUNT old backup(s)..."

    # Delete oldest backups
    ls -1t "$BACKUP_DIR"/settings_*.json | tail -n "$DELETE_COUNT" | xargs rm -f

    echo -e "${GREEN}Cleanup complete${NC}"
else
    echo "Total backups: $BACKUP_COUNT (no cleanup needed)"
fi

echo ""
echo "========================================="
echo "Backup complete!"
echo "========================================="
echo ""
echo "Latest backup: $BACKUP_FILE"
echo ""
echo "To restore this backup:"
echo "  cp $BACKUP_FILE $DATA_DIR/settings.json"
echo "  docker restart excalith-start-page"
echo ""
echo "All backups:"
ls -lh "$BACKUP_DIR"/settings_*.json 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""
