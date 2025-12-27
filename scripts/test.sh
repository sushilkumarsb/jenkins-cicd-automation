#!/bin/bash

###############################################################################
# Test Script
# This script runs unit tests and generates coverage reports
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

echo "=================================="
echo "Starting Test Process"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}Project Root: ${PROJECT_ROOT}${NC}"

# Activate virtual environment
echo "Activating virtual environment..."
source "${PROJECT_ROOT}/venv/bin/activate" || source "${PROJECT_ROOT}/venv/Scripts/activate"

# Create test results directory
mkdir -p "${PROJECT_ROOT}/test-results"
mkdir -p "${PROJECT_ROOT}/htmlcov"

# Run tests with coverage
echo "Running unit tests with coverage..."
cd "${PROJECT_ROOT}"

pytest tests/ \
    --verbose \
    --cov=src \
    --cov-report=html:htmlcov \
    --cov-report=xml:test-results/coverage.xml \
    --cov-report=term-missing \
    --junit-xml=test-results/junit.xml

# Check coverage threshold (80%)
COVERAGE_THRESHOLD=80
echo "Checking coverage threshold (${COVERAGE_THRESHOLD}%)..."

# Get coverage percentage
COVERAGE=$(pytest --cov=src --cov-report=term-missing tests/ | grep "TOTAL" | awk '{print $4}' | sed 's/%//')

if [ -n "$COVERAGE" ]; then
    if (( $(echo "$COVERAGE < $COVERAGE_THRESHOLD" | bc -l) )); then
        echo -e "${RED}Coverage ${COVERAGE}% is below threshold ${COVERAGE_THRESHOLD}%${NC}"
        exit 1
    else
        echo -e "${GREEN}Coverage ${COVERAGE}% meets threshold${NC}"
    fi
fi

echo -e "${GREEN}=================================="
echo -e "Tests Completed Successfully!"
echo -e "==================================${NC}"
