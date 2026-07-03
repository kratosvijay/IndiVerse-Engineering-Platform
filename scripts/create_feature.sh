#!/usr/bin/env bash
# Feature Scaffolder Helper Script

if [ -z "$1" ]; then
    echo "Usage: ./create_feature.sh <feature_name>"
    exit 1
fi

FEATURE_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')

echo "Scaffolding Clean Architecture Feature: $FEATURE_NAME"

# Create directories
mkdir -p "lib/features/$FEATURE_NAME/domain/entities"
mkdir -p "lib/features/$FEATURE_NAME/domain/repositories"
mkdir -p "lib/features/$FEATURE_NAME/domain/usecases"
mkdir -p "lib/features/$FEATURE_NAME/data/models"
mkdir -p "lib/features/$FEATURE_NAME/data/repositories"
mkdir -p "lib/features/$FEATURE_NAME/data/datasources"
mkdir -p "lib/features/$FEATURE_NAME/presentation/controllers"
mkdir -p "lib/features/$FEATURE_NAME/presentation/screens"

echo "Successfully scaffolded 'lib/features/$FEATURE_NAME/' structures."
