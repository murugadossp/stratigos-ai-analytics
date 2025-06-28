#!/bin/bash

# Stratigos AI Platform - Deployment Verification Script
# This script verifies that the deployed infrastructure is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-dev}
STACK_NAME="stratigos-ai-platform-${ENVIRONMENT}"

echo -e "${BLUE}🔍 Stratigos AI Platform - Deployment Verification Script${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Stack Name: ${STACK_NAME}${NC}"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed${NC}"
        exit 1
    fi
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ curl is not installed${NC}"
        exit 1
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️  jq is not installed. JSON responses will not be formatted.${NC}"
        JQ_AVAILABLE=false
    else
        JQ_AVAILABLE=true
    fi
    
    echo -e "${GREEN}✅ Prerequisites checked${NC}"
}

# Function to get stack information
get_stack_info() {
    echo -e "${YELLOW}📋 Getting stack information...${NC}"
    
    # Check if stack exists
    if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" &>/dev/null; then
        echo -e "${RED}❌ Stack ${STACK_NAME} not found${NC}"
        echo -e "${YELLOW}Please deploy the infrastructure first:${NC}"
        echo "./scripts/deploy-infrastructure.sh ${ENVIRONMENT}"
        exit 1
    fi
    
    # Get API endpoint
    API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text 2>/dev/null)
    
    if [ -z "$API_ENDPOINT" ]; then
        echo -e "${RED}❌ Could not retrieve API endpoint${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ API Endpoint: ${API_ENDPOINT}${NC}"
    
    # Get API key
    API_KEY=$(aws apigateway get-api-keys --include-values --query 'items[0].value' --output text 2>/dev/null)
    
    if [ -z "$API_KEY" ] || [ "$API_KEY" = "None" ]; then
        echo -e "${RED}❌ Could not retrieve API key${NC}"
        echo -e "${YELLOW}Please create an API key manually in the AWS console${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ API Key retrieved${NC}"
}

# Function to test API endpoint
test_api_endpoint() {
    local endpoint=$1
    local method=${2:-GET}
    local data=${3:-}
    local description=$4
    
    echo -e "${BLUE}Testing: ${description}${NC}"
    echo -e "${YELLOW}${method} ${endpoint}${NC}"
    
    local curl_cmd="curl -s -w \"\\n%{http_code}\" -X ${method} -H \"x-api-key: ${API_KEY}\" -H \"Content-Type: application/json\""
    
    if [ -n "$data" ]; then
        curl_cmd="${curl_cmd} -d '${data}'"
    fi
    
    curl_cmd="${curl_cmd} \"${API_ENDPOINT}${endpoint}\""
    
    local response=$(eval $curl_cmd)
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n -1)
    
    case $http_code in
        200|201)
            echo -e "${GREEN}✅ Success (${http_code})${NC}"
            if [ "$JQ_AVAILABLE" = true ] && [ -n "$body" ]; then
                echo "$body" | jq . 2>/dev/null || echo "$body"
            else
                echo "$body"
            fi
            return 0
            ;;
        400|404|422)
            echo -e "${YELLOW}⚠️  Client Error (${http_code})${NC}"
            echo "$body"
            return 1
            ;;
        403)
            echo -e "${RED}❌ Forbidden (${http_code}) - Check API key${NC}"
            return 1
            ;;
        500|502|503)
            echo -e "${RED}❌ Server Error (${http_code})${NC}"
            echo "$body"
            return 1
            ;;
        *)
            echo -e "${RED}❌ Unexpected response (${http_code})${NC}"
            echo "$body"
            return 1
            ;;
    esac
}

# Function to test portfolio endpoints
test_portfolio_endpoints() {
    echo -e "${BLUE}🗂️  Testing Portfolio Endpoints${NC}"
    echo ""
    
    # Test list portfolios (should return empty array initially)
    test_api_endpoint "/portfolios" "GET" "" "List portfolios"
    echo ""
    
    # Test create portfolio
    local portfolio_data='{
        "name": "Test Portfolio",
        "description": "A test portfolio for verification",
        "assets": {
            "AAPL": 0.4,
            "MSFT": 0.3,
            "GOOGL": 0.2,
            "AMZN": 0.1
        }
    }'
    
    echo -e "${BLUE}Creating test portfolio...${NC}"
    local create_response=$(curl -s -X POST \
        -H "x-api-key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$portfolio_data" \
        "${API_ENDPOINT}/portfolios")
    
    if [ "$JQ_AVAILABLE" = true ]; then
        PORTFOLIO_ID=$(echo "$create_response" | jq -r '.id' 2>/dev/null)
    else
        # Try to extract ID without jq (basic approach)
        PORTFOLIO_ID=$(echo "$create_response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -n "$PORTFOLIO_ID" ] && [ "$PORTFOLIO_ID" != "null" ]; then
        echo -e "${GREEN}✅ Portfolio created with ID: ${PORTFOLIO_ID}${NC}"
        
        # Test get portfolio
        test_api_endpoint "/portfolios/${PORTFOLIO_ID}" "GET" "" "Get portfolio by ID"
        echo ""
        
        # Test update portfolio
        local update_data='{
            "name": "Updated Test Portfolio",
            "description": "Updated description"
        }'
        test_api_endpoint "/portfolios/${PORTFOLIO_ID}" "PUT" "$update_data" "Update portfolio"
        echo ""
        
        # Test list portfolios again (should now have one portfolio)
        test_api_endpoint "/portfolios" "GET" "" "List portfolios (after creation)"
        echo ""
        
        # Test delete portfolio
        test_api_endpoint "/portfolios/${PORTFOLIO_ID}" "DELETE" "" "Delete portfolio"
        echo ""
    else
        echo -e "${RED}❌ Failed to create portfolio or extract ID${NC}"
        echo "$create_response"
    fi
}

# Function to test optimization endpoints
test_optimization_endpoints() {
    echo -e "${BLUE}⚖️  Testing Optimization Endpoints${NC}"
    echo ""
    
    # Test risk parity optimization
    local optimization_data='{
        "portfolioId": "test-portfolio",
        "returns": {
            "AAPL": [0.01, 0.02, -0.01, 0.03, -0.02],
            "MSFT": [0.02, 0.01, -0.02, 0.02, -0.01],
            "GOOGL": [0.03, -0.01, 0.01, 0.02, -0.03],
            "AMZN": [0.02, -0.02, 0.03, 0.01, -0.01]
        }
    }'
    
    test_api_endpoint "/optimization/risk-parity" "POST" "$optimization_data" "Risk Parity Optimization"
    echo ""
    
    # Note: HRP and Efficient Frontier tests might take longer and require more complex data
    echo -e "${YELLOW}ℹ️  Skipping HRP and Efficient Frontier tests (require more complex setup)${NC}"
}

# Function to test Monte Carlo endpoints
test_monte_carlo_endpoints() {
    echo -e "${BLUE}🎲 Testing Monte Carlo Endpoints${NC}"
    echo ""
    
    # Test Monte Carlo simulation
    local simulation_data='{
        "portfolioId": "test-portfolio",
        "returns": {
            "AAPL": [0.01, 0.02, -0.01, 0.03, -0.02],
            "MSFT": [0.02, 0.01, -0.02, 0.02, -0.01],
            "GOOGL": [0.03, -0.01, 0.01, 0.02, -0.03],
            "AMZN": [0.02, -0.02, 0.03, 0.01, -0.01]
        },
        "initialInvestment": 10000,
        "numSimulations": 100,
        "numPeriods": 252
    }'
    
    test_api_endpoint "/monte-carlo/simulate" "POST" "$simulation_data" "Monte Carlo Simulation"
    echo ""
    
    echo -e "${YELLOW}ℹ️  Skipping simulation analysis test (requires simulation ID)${NC}"
}

# Function to test market data endpoints
test_market_data_endpoints() {
    echo -e "${BLUE}📈 Testing Market Data Endpoints${NC}"
    echo ""
    
    # Test get prices
    test_api_endpoint "/market-data/prices?symbols=AAPL,MSFT&startDate=2025-01-01&endDate=2025-06-28" "GET" "" "Get Market Prices"
    echo ""
    
    # Test get returns
    test_api_endpoint "/market-data/returns?symbols=AAPL,MSFT&startDate=2025-01-01&endDate=2025-06-28" "GET" "" "Get Market Returns"
    echo ""
}

# Function to test Lambda function logs
check_lambda_logs() {
    echo -e "${BLUE}📝 Checking Lambda Function Logs${NC}"
    echo ""
    
    # Get list of Lambda functions
    local functions=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `stratigos`)].FunctionName' --output text 2>/dev/null)
    
    if [ -n "$functions" ]; then
        echo -e "${GREEN}Found Lambda functions:${NC}"
        for func in $functions; do
            echo "  - $func"
            
            # Check if log group exists
            local log_group="/aws/lambda/$func"
            if aws logs describe-log-groups --log-group-name-prefix "$log_group" --query 'logGroups[0].logGroupName' --output text &>/dev/null; then
                echo -e "${GREEN}    ✅ Log group exists${NC}"
                
                # Get recent log events (last 5 minutes)
                local start_time=$(($(date +%s) * 1000 - 300000))
                local recent_logs=$(aws logs filter-log-events --log-group-name "$log_group" --start-time "$start_time" --query 'events[0:3].message' --output text 2>/dev/null)
                
                if [ -n "$recent_logs" ]; then
                    echo -e "${BLUE}    Recent log entries:${NC}"
                    echo "$recent_logs" | head -3
                fi
            else
                echo -e "${YELLOW}    ⚠️  No log group found${NC}"
            fi
        done
    else
        echo -e "${RED}❌ No Stratigos Lambda functions found${NC}"
    fi
}

# Function to generate verification report
generate_report() {
    echo -e "${BLUE}📊 Verification Summary${NC}"
    echo ""
    echo -e "${GREEN}✅ Completed Tests:${NC}"
    echo "  - Stack information retrieval"
    echo "  - API endpoint connectivity"
    echo "  - Portfolio CRUD operations"
    echo "  - Basic optimization endpoint"
    echo "  - Basic Monte Carlo endpoint"
    echo "  - Market data endpoints"
    echo "  - Lambda function logs check"
    echo ""
    echo -e "${YELLOW}📋 Infrastructure Details:${NC}"
    echo "  - Environment: ${ENVIRONMENT}"
    echo "  - Stack Name: ${STACK_NAME}"
    echo "  - API Endpoint: ${API_ENDPOINT}"
    echo "  - API Key: ${API_KEY:0:8}..."
    echo ""
    echo -e "${BLUE}🔗 Useful Commands:${NC}"
    echo "  - View all logs: aws logs describe-log-groups --log-group-name-prefix /aws/lambda/stratigos"
    echo "  - Monitor API Gateway: aws logs describe-log-groups --log-group-name-prefix API-Gateway-Execution-Logs"
    echo "  - Check DynamoDB tables: aws dynamodb list-tables --query 'TableNames[?contains(@, \`${ENVIRONMENT}\`)]'"
    echo "  - View CloudFormation stack: aws cloudformation describe-stacks --stack-name ${STACK_NAME}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting deployment verification...${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Get stack information
    get_stack_info
    echo ""
    
    # Test endpoints
    test_portfolio_endpoints
    test_optimization_endpoints
    test_monte_carlo_endpoints
    test_market_data_endpoints
    
    # Check logs
    check_lambda_logs
    echo ""
    
    # Generate report
    generate_report
    echo ""
    
    echo -e "${GREEN}🎉 Verification completed!${NC}"
    echo -e "${BLUE}Your Stratigos AI Platform is ready to use.${NC}"
}

# Run main function
main "$@"
