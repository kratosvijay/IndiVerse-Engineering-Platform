#!/usr/bin/env bash
# macOS Developer Onboarding Setup Script for IndiVerse Developer Platform

echo "=== Setting up macOS Developer Environment ==="

# Check Homebrew
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Install dependencies
echo "Installing tools via Homebrew..."
brew install git node python3

# Verify Flutter
if ! command -v flutter &> /dev/null; then
    echo "WARNING: Flutter SDK is not installed on path. Please install Flutter from flutter.dev"
else
    echo "Flutter SDK is active."
fi

echo "=== Onboarding complete ==="
