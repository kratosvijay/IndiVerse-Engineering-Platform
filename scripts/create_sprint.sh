#!/usr/bin/env bash
# Sprint Folder Scaffolder

if [ -z "$1" ]; then
    echo "Usage: ./create_sprint.sh <sprint_number>"
    exit 1
fi

SPRINT_NUM="$1"
SPRINT_DIR="sprints/sprint-$SPRINT_NUM"

echo "Creating sprint workspace: $SPRINT_DIR"
mkdir -p "$SPRINT_DIR"

# Generate sprint file from template
if [ -f "templates/SPRINT_TEMPLATE.md" ]; then
    cp templates/SPRINT_TEMPLATE.md "$SPRINT_DIR/README.md"
    sed -i '' "s/\[Number\]/$SPRINT_NUM/g" "$SPRINT_DIR/README.md" 2>/dev/null || sed -i "s/\[Number\]/$SPRINT_NUM/g" "$SPRINT_DIR/README.md"
    echo "Created $SPRINT_DIR/README.md"
else
    echo "Warning: templates/SPRINT_TEMPLATE.md not found."
fi
