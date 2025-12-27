#!/bin/bash

###############################################################################
# Build Script
# This script builds the application and prepares it for testing/deployment
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

echo "=================================="
echo "Starting Build Process"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}Project Root: ${PROJECT_ROOT}${NC}"

# Create virtual environment if it doesn't exist
if [ ! -d "${PROJECT_ROOT}/venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "${PROJECT_ROOT}/venv"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "${PROJECT_ROOT}/venv/bin/activate" || source "${PROJECT_ROOT}/venv/Scripts/activate"

# Install dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install -r "${PROJECT_ROOT}/src/requirements.txt"

# Check Python syntax
echo "Checking Python syntax..."
python -m py_compile "${PROJECT_ROOT}/src/app.py"

# Build Docker image (optional, uncomment if needed)
# echo "Building Docker image..."
# docker build -f "${PROJECT_ROOT}/docker/Dockerfile" -t jenkins-cicd-app:latest "${PROJECT_ROOT}"

echo -e "${GREEN}=================================="
echo -e "Build Completed Successfully!"
echo -e "==================================${NC}"
