#!/bin/bash

###############################################################################
# Rollback Script
# This script rolls back to the previous stable version
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

echo "=================================="
echo "Starting Rollback Process"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${RED}WARNING: This will rollback to the previous version${NC}"

# Get environment (default to staging if not specified)
ENVIRONMENT=${1:-staging}

echo -e "${YELLOW}Rolling back environment: ${ENVIRONMENT}${NC}"

# Backup directory for version tracking
BACKUP_DIR="${PROJECT_ROOT}/.backup"
mkdir -p "$BACKUP_DIR"

# Example rollback steps (customize based on your infrastructure)
echo "Fetching previous stable version..."
# PREVIOUS_VERSION=$(cat ${BACKUP_DIR}/previous_version.txt || echo "unknown")

echo "Stopping current containers..."
# docker-compose -f docker-compose.${ENVIRONMENT}.yml down

echo "Deploying previous version..."
# docker pull your-registry/jenkins-cicd-app:${PREVIOUS_VERSION}
# docker-compose -f docker-compose.${ENVIRONMENT}.yml up -d

echo "Running health checks..."
sleep 5
# curl -f http://localhost:5000/health || exit 1

echo "Cleaning up failed deployment artifacts..."
# docker system prune -f

echo -e "${GREEN}=================================="
echo -e "Rollback Completed!"
echo -e "==================================${NC}"

# Send notification
echo "Sending rollback notification..."
# curl -X POST -H 'Content-type: application/json' \
#   --data '{"text":"Rollback completed for '"${ENVIRONMENT}"' environment"}' \
#   YOUR_WEBHOOK_URL

# Log rollback event
echo "$(date): Rollback performed for ${ENVIRONMENT}" >> "${BACKUP_DIR}/rollback.log"
