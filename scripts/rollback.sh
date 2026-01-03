#!/bin/bash

# Automated Rollback Script for Flask Application
# This script rolls back to the previous successful Docker deployment

set -e  # Exit on any error

# Configuration
APP_NAME="flask-app"
IMAGE_NAME="sushilkumarsb/jenkins-cicd-app"
DEPLOYMENT_STATE_FILE="/var/jenkins_home/workspace/jenkins-cicd-automation/.deployment_state"
MAX_HEALTH_CHECK_ATTEMPTS=10
HEALTH_CHECK_INTERVAL=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get previous successful deployment tag
get_previous_tag() {
    if [ -f "$DEPLOYMENT_STATE_FILE" ]; then
        PREVIOUS_TAG=$(grep "PREVIOUS_TAG=" "$DEPLOYMENT_STATE_FILE" | cut -d'=' -f2)
        echo "$PREVIOUS_TAG"
    else
        log_error "No deployment state file found. Cannot rollback."
        exit 1
    fi
}

# Health check function
health_check() {
    local url=$1
    local attempt=1
    
    log_info "Starting health checks..."
    
    while [ $attempt -le $MAX_HEALTH_CHECK_ATTEMPTS ]; do
        log_info "Health check attempt $attempt/$MAX_HEALTH_CHECK_ATTEMPTS"
        
        if curl -sf "$url" > /dev/null 2>&1; then
            log_info "Health check passed!"
            return 0
        fi
        
        sleep $HEALTH_CHECK_INTERVAL
        attempt=$((attempt + 1))
    done
    
    log_error "Health check failed after $MAX_HEALTH_CHECK_ATTEMPTS attempts"
    return 1
}

# Main rollback function
rollback() {
    local previous_tag=$1
    
    if [ -z "$previous_tag" ]; then
        log_error "No previous deployment tag found"
        exit 1
    fi
    
    log_warning "====================================="
    log_warning "INITIATING ROLLBACK PROCEDURE"
    log_warning "====================================="
    log_info "Rolling back to: $IMAGE_NAME:$previous_tag"
    
    # Stop current container
    log_info "Stopping current container..."
    if docker stop $APP_NAME 2>/dev/null; then
        log_info "Container stopped successfully"
    else
        log_warning "Container was not running"
    fi
    
    # Remove current container
    log_info "Removing current container..."
    if docker rm $APP_NAME 2>/dev/null; then
        log_info "Container removed successfully"
    else
        log_warning "Container did not exist"
    fi
    
    # Pull previous image (if not already present)
    log_info "Pulling previous image: $IMAGE_NAME:$previous_tag"
    docker pull $IMAGE_NAME:$previous_tag
    
    # Start container with previous image
    log_info "Starting container with previous image..."
    docker run -d \
        --name $APP_NAME \
        --restart unless-stopped \
        -p 127.0.0.1:5000:5000 \
        $IMAGE_NAME:$previous_tag
    
    # Wait for container to start
    sleep 5
    
    # Verify container is running
    if docker ps | grep -q $APP_NAME; then
        log_info "Container started successfully"
    else
        log_error "Container failed to start"
        docker logs $APP_NAME
        exit 1
    fi
    
    # Perform health check
    if health_check "http://localhost:5000/health"; then
        log_info "====================================="
        log_info "ROLLBACK COMPLETED SUCCESSFULLY"
        log_info "====================================="
        log_info "Application is now running: $IMAGE_NAME:$previous_tag"
        
        # Show container status
        docker ps | grep $APP_NAME
        
        return 0
    else
        log_error "====================================="
        log_error "ROLLBACK FAILED"
        log_error "====================================="
        log_error "Container is running but health check failed"
        docker logs --tail 50 $APP_NAME
        exit 1
    fi
}

# Main execution
main() {
    log_info "Flask Application Rollback Script"
    log_info "Current time: $(date)"
    
    # Get previous tag
    PREVIOUS_TAG=$(get_previous_tag)
    
    if [ -z "$PREVIOUS_TAG" ]; then
        log_error "Cannot determine previous deployment version"
        exit 1
    fi
    
    # Execute rollback
    rollback "$PREVIOUS_TAG"
}

# Run main function
main
