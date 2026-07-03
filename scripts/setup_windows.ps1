# Windows Developer Onboarding Setup Script for IndiVerse Developer Platform
Write-Host "=== Setting up Windows Developer Environment ==="

# Verify git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git is already installed."
} else {
    Write-Host "WARNING: Git not found. Please install git from git-scm.com"
}

# Verify Node
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "Node.js is already installed."
} else {
    Write-Host "WARNING: Node.js not found. Please install Node.js from nodejs.org"
}
