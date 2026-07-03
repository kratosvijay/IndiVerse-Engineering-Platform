#!/usr/bin/env bash
# Linux Developer Onboarding Setup Script for IndiVerse Developer Platform

echo "=== Setting up Linux Developer Environment ==="

# Update repositories
sudo apt-get update -y

# Install tools
sudo apt-get install -y git nodejs npm python3

echo "=== Onboarding complete ==="
