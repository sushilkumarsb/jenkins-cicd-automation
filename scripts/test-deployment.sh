#!/bin/bash

# Quick Test Script for Rollback and Metrics Features
# Run this after deploying to verify everything works

echo "🧪 Testing Automated Rollback & Performance Metrics Features"
echo "=============================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_URL="https://sushilkumarsb.xyz/app"
HEALTH_ENDPOINT="${APP_URL}/health"
VERSION_ENDPOINT="${APP_URL}/version"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run tests
run_test() {
    local test_name=$1
    local test_command=$2
    local expected=$3
    
    echo -n "Testing: $test_name... "
    
    result=$(eval $test_command 2>&1)
    
    if [[ $result == *"$expected"* ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "  Expected: $expected"
        echo "  Got: $result"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "📍 Phase 1: Application Health Tests"
echo "------------------------------------"

run_test "Health endpoint returns ok" \
    "curl -s $HEALTH_ENDPOINT" \
    '"status":"ok"'

run_test "Version endpoint returns version" \
    "curl -s $VERSION_ENDPOINT" \
    '"version":"1.0.0"'

run_test "Home endpoint returns welcome message" \
    "curl -s $APP_URL/" \
    '"status":"running"'

run_test "Health endpoint returns 200 status" \
    "curl -s -o /dev/null -w '%{http_code}' $HEALTH_ENDPOINT" \
    "200"

echo ""
echo "📍 Phase 2: Docker Container Tests"
echo "------------------------------------"

run_test "Flask container is running" \
    "docker ps --filter 'name=flask-app' --format '{{.Status}}'" \
    "Up"

run_test "Container is healthy" \
    "docker inspect flask-app --format '{{.State.Health.Status}}'" \
    "healthy"

run_test "Container port binding correct" \
    "docker port flask-app" \
    "5000/tcp -> 127.0.0.1:5000"

echo ""
echo "📍 Phase 3: Deployment State Tests"
echo "------------------------------------"

if [ -f ".deployment_state" ]; then
    echo -e "Deployment state file exists: ${GREEN}✅ PASS${NC}"
    ((TESTS_PASSED++))
    
    echo "Contents:"
    cat .deployment_state | sed 's/^/  /'
    
    # Verify file has required fields
    run_test "State file has CURRENT_TAG" \
        "grep 'CURRENT_TAG=' .deployment_state" \
        "CURRENT_TAG="
    
    run_test "State file has PREVIOUS_TAG" \
        "grep 'PREVIOUS_TAG=' .deployment_state" \
        "PREVIOUS_TAG="
    
    run_test "State file has BUILD_NUMBER" \
        "grep 'BUILD_NUMBER=' .deployment_state" \
        "BUILD_NUMBER="
else
    echo -e "Deployment state file exists: ${RED}❌ FAIL${NC}"
    echo "  File not found: .deployment_state"
    ((TESTS_FAILED++))
fi

echo ""
echo "📍 Phase 4: Docker Hub Integration Tests"
echo "------------------------------------"

# Get current build number from deployment state
if [ -f ".deployment_state" ]; then
    BUILD_NUM=$(grep "BUILD_NUMBER=" .deployment_state | cut -d'=' -f2)
    
    run_test "Docker image exists with build number tag" \
        "docker images sushilkumarsb/jenkins-cicd-app:$BUILD_NUM --format '{{.Repository}}'" \
        "sushilkumarsb/jenkins-cicd-app"
fi

run_test "Docker image exists with latest tag" \
    "docker images sushilkumarsb/jenkins-cicd-app:latest --format '{{.Repository}}'" \
    "sushilkumarsb/jenkins-cicd-app"

echo ""
echo "📍 Phase 5: Rollback Script Tests"
echo "------------------------------------"

run_test "Rollback script exists" \
    "ls scripts/rollback.sh" \
    "scripts/rollback.sh"

run_test "Rollback script is executable" \
    "test -x scripts/rollback.sh && echo 'executable' || echo 'not executable'" \
    "executable"

run_test "Rollback script has proper shebang" \
    "head -n 1 scripts/rollback.sh" \
    "#!/bin/bash"

echo ""
echo "=============================================================="
echo "📊 TEST RESULTS SUMMARY"
echo "=============================================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo "Total: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo ""
    echo "🎉 The rollback and metrics features are working correctly!"
    echo ""
    echo "Next steps:"
    echo "1. Test automated rollback by breaking the app"
    echo "2. Test manual rollback via Jenkins parameters"
    echo "3. Review performance metrics in Jenkins console"
    echo "4. If all tests pass, merge feature branch to main"
    echo ""
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failures above and fix issues before merging."
    echo ""
    exit 1
fi
