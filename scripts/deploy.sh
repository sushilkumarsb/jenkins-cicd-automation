#!/bin/bash

###############################################################################
# Deploy Script
# This script deploys the application to the specified environment
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

echo "=================================="
echo "Starting Deployment Process"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if environment is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No environment specified${NC}"
    echo "Usage: $0 <environment>"
    echo "Environments: staging, production"
    exit 1
fi

ENVIRONMENT=$1

echo -e "${YELLOW}Deploying to: ${ENVIRONMENT}${NC}"

# Load environment-specific configuration
case $ENVIRONMENT in
    staging)
        CONFIG_FILE="${PROJECT_ROOT}/config/staging-config.yaml"
        ;;
    production)
        CONFIG_FILE="${PROJECT_ROOT}/config/prod-config.yaml"
        ;;
    *)
        echo -e "${RED}Error: Invalid environment '${ENVIRONMENT}'${NC}"
        echo "Valid environments: staging, production"
        exit 1
        ;;
esac

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file not found: ${CONFIG_FILE}${NC}"
    exit 1
fi

echo "Loading configuration from: ${CONFIG_FILE}"

# Load Docker registry credentials
if [ -f "${PROJECT_ROOT}/config/docker-registry.env" ]; then
    source "${PROJECT_ROOT}/config/docker-registry.env"
fi

# Example deployment steps (customize based on your infrastructure)
echo "Pulling latest Docker image..."
# docker pull your-registry/jenkins-cicd-app:latest

echo "Stopping existing containers..."
# docker-compose -f docker-compose.${ENVIRONMENT}.yml down

echo "Starting new containers..."
# docker-compose -f docker-compose.${ENVIRONMENT}.yml up -d

echo "Running health checks..."
sleep 5
# curl -f http://localhost:5000/health || exit 1

echo -e "${GREEN}=================================="
echo -e "Deployment to ${ENVIRONMENT} Completed!"
echo -e "==================================${NC}"

# Send notification (optional)
# curl -X POST -H 'Content-type: application/json' \
#   --data '{"text":"Deployment to '"${ENVIRONMENT}"' completed successfully!"}' \
#   YOUR_WEBHOOK_URL
