#!/bin/bash
# ============================================================
# GPS Trolling Motor — New Repo Setup Script
# Run this on your gaming PC to create the private repo
# ============================================================
#
# Prerequisites:
#   1. Install GitHub CLI: https://cli.github.com/
#   2. Run: gh auth login
#
# Usage:
#   chmod +x setup_new_repo.sh
#   ./setup_new_repo.sh
# ============================================================

set -e

REPO_NAME="GPS-trolling-motor"
GITHUB_USER="Jrroot97"

echo "========================================="
echo "  GPS Trolling Motor — Repo Setup"
echo "========================================="
echo ""

# Step 1: Create private repo on GitHub
echo "[1/5] Creating private repo: $GITHUB_USER/$REPO_NAME"
gh repo create "$GITHUB_USER/$REPO_NAME" --private \
  --description "DIY GPS spot-lock trolling motor with wind sensor, wave prediction ML, sonar, and phone dashboard"
echo "  ✓ Private repo created"

# Step 2: Clone it
echo ""
echo "[2/5] Cloning repo..."
gh repo clone "$GITHUB_USER/$REPO_NAME"
cd "$REPO_NAME"
echo "  ✓ Cloned to $(pwd)"

# Step 3: Copy files from learning-area
echo ""
echo "[3/5] Copying project files..."

# If learning-area is cloned locally, copy from there
if [ -d "../learning-area/pontoon-gps-hold" ]; then
    cp -r ../learning-area/pontoon-gps-hold/* .
    echo "  ✓ Copied from local learning-area"
else
    # Otherwise clone the branch and copy
    echo "  Cloning learning-area to get project files..."
    git clone --branch claude/explore-next-steps-Qc9hQ --depth 1 \
        "https://github.com/$GITHUB_USER/learning-area.git" /tmp/learning-area-temp
    cp -r /tmp/learning-area-temp/pontoon-gps-hold/* .
    rm -rf /tmp/learning-area-temp
    echo "  ✓ Copied from GitHub"
fi

# Step 4: Commit
echo ""
echo "[4/5] Committing all files..."
git add -A
git commit -m "Initial commit — GPS Spot-Lock Trolling Motor

DIY 12V GPS spot-lock system for a jon boat with:
- ESP32 firmware (GPS hold, compass, wind, sonar, dashboard)
- RPi wave prediction (camera + ML inference)
- ML training pipeline (PyTorch for RTX 3050)
- Parts list with prices and purchase links"
echo "  ✓ Committed"

# Step 5: Push
echo ""
echo "[5/5] Pushing to GitHub..."
git push origin main
echo "  ✓ Pushed"

echo ""
echo "========================================="
echo "  Done! Your private repo is at:"
echo "  https://github.com/$GITHUB_USER/$REPO_NAME"
echo "========================================="
echo ""
echo "Files:"
find . -not -path './.git/*' -not -name '.git' -type f | sort | head -20
