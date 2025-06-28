#!/bin/bash

# Stratigos AI Platform - Infrastructure Deployment Script
# This script deploys the complete Stratigos AI Platform infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
STACK_NAME="stratigos-ai-platform-${ENVIRONMENT}"

echo -e "${BLUE}🚀 Stratigos AI Platform - Infrastructure Deployment Script${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"
echo -e "${BLUE}Stack Name: ${STACK_NAME}${NC}"
echo ""

# Function to check if required tools are installed
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ AWS CLI found${NC}"
    
    # Check SAM CLI
    if ! command -v sam &> /dev/null; then
        echo -e "${RED}❌ SAM CLI is not installed. Please install it first.${NC}"
        echo -e "${YELLOW}Install with: pip install aws-sam-cli${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ SAM CLI found${NC}"
    
    # Check Python 3.11 specifically
    if ! command -v python3.11 &> /dev/null; then
        echo -e "${RED}❌ Python 3.11 is not installed. Please install Python 3.11 first.${NC}"
        echo -e "${YELLOW}💡 Install with: brew install python@3.11 (macOS) or apt install python3.11 (Ubuntu)${NC}"
        exit 1
    fi
    
    # Verify Python 3.11 version
    PYTHON_VERSION=$(python3.11 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    if [ "$PYTHON_VERSION" != "3.11" ]; then
        echo -e "${RED}❌ Python 3.11 required, found: $PYTHON_VERSION${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Python 3.11 found and verified${NC}"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
    
    # Get AWS account info
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local current_region=$(aws configure get region)
    echo -e "${BLUE}AWS Account: ${account_id}${NC}"
    echo -e "${BLUE}Current Region: ${current_region}${NC}"
}

# Function to check if layers exist
check_layers() {
    echo -e "${YELLOW}🔍 Checking Lambda layers...${NC}"
    
    local bucket_name="stratigos-${ENVIRONMENT}-layers"
    local files=("stratigos_core_layer.zip" "stratigos_numeric_layer.zip" "stratigos_viz_layer.zip")
    local missing_files=()
    
    # Check if bucket exists
    if ! aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        echo -e "${RED}❌ Layers bucket ${bucket_name} does not exist${NC}"
        echo -e "${YELLOW}Please run: ./scripts/create-layers.sh ${ENVIRONMENT} ${REGION}${NC}"
        exit 1
    fi
    
    # Check if layer files exist
    for file in "${files[@]}"; do
        if ! aws s3api head-object --bucket "$bucket_name" --key "$file" &>/dev/null; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing layer files: ${missing_files[*]}${NC}"
        echo -e "${YELLOW}Please run: ./scripts/create-layers.sh ${ENVIRONMENT} ${REGION}${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All Lambda layers are available${NC}"
}

# Function to install Python dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Installing Python dependencies...${NC}"
    
    if [ -f "requirements.txt" ]; then
        pip3.11 install -r requirements.txt --quiet
        echo -e "${GREEN}✅ Dependencies installed${NC}"
    else
        echo -e "${YELLOW}⚠️  No requirements.txt found, skipping dependency installation${NC}"
    fi
}

# Function to validate SAM template
validate_template() {
    echo -e "${YELLOW}🔍 Validating SAM template...${NC}"
    
    if sam validate --template serverless/template.yaml; then
        echo -e "${GREEN}✅ SAM template is valid${NC}"
    else
        echo -e "${RED}❌ SAM template validation failed${NC}"
        exit 1
    fi
}

# Function to build SAM application
build_application() {
    echo -e "${YELLOW}🔨 Building SAM application...${NC}"
    
    # Clean previous builds
    rm -rf .aws-sam
    
    # Build the application
    if sam build --template serverless/template.yaml; then
        echo -e "${GREEN}✅ SAM application built successfully${NC}"
    else
        echo -e "${RED}❌ SAM build failed${NC}"
        exit 1
    fi
}

# Function to deploy infrastructure
deploy_infrastructure() {
    echo -e "${YELLOW}🚀 Deploying infrastructure...${NC}"
    
    # Check if this is first deployment
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" &>/dev/null; then
        echo -e "${BLUE}Updating existing stack: ${STACK_NAME}${NC}"
        
        # Deploy with existing configuration
        sam deploy \
            --stack-name "$STACK_NAME" \
            --parameter-overrides Environment="$ENVIRONMENT" \
            --capabilities CAPABILITY_IAM \
            --no-confirm-changeset \
            --no-fail-on-empty-changeset
    else
        echo -e "${BLUE}Creating new stack: ${STACK_NAME}${NC}"
        
        # First time deployment with guided setup
        sam deploy \
            --stack-name "$STACK_NAME" \
            --parameter-overrides Environment="$ENVIRONMENT" \
            --capabilities CAPABILITY_IAM \
            --guided \
            --save-params
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"
    else
        echo -e "${RED}❌ Infrastructure deployment failed${NC}"
        exit 1
    fi
}

# Function to get stack outputs
get_stack_outputs() {
    echo -e "${YELLOW}📋 Retrieving stack outputs...${NC}"
    
    local outputs=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs' --output table 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Stack Outputs:${NC}"
        echo "$outputs"
        echo ""
        
        # Get API endpoint specifically
        local api_endpoint=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text 2>/dev/null)
        if [ -n "$api_endpoint" ]; then
            echo -e "${GREEN}🌐 API Endpoint: ${api_endpoint}${NC}"
        fi
        
        # Get API key information
        echo -e "${YELLOW}🔑 To get your API key, run:${NC}"
        echo "aws apigateway get-api-keys --include-values --query 'items[0].value' --output text"
        
    else
        echo -e "${RED}❌ Failed to retrieve stack outputs${NC}"
    fi
}

# Function to run basic health checks
run_health_checks() {
    echo -e "${YELLOW}🏥 Running health checks...${NC}"
    
    # Check if API Gateway is accessible
    local api_endpoint=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text 2>/dev/null)
    
    if [ -n "$api_endpoint" ]; then
        echo -e "${BLUE}Testing API Gateway endpoint...${NC}"
        
        # Test basic connectivity (without API key, should return 403)
        local response_code=$(curl -s -o /dev/null -w "%{http_code}" "${api_endpoint}/portfolios" || echo "000")
        
        if [ "$response_code" = "403" ]; then
            echo -e "${GREEN}✅ API Gateway is responding (403 - API key required)${NC}"
        elif [ "$response_code" = "200" ]; then
            echo -e "${GREEN}✅ API Gateway is responding (200 - OK)${NC}"
        else
            echo -e "${YELLOW}⚠️  API Gateway response code: ${response_code}${NC}"
        fi
    fi
    
    # Check DynamoDB tables
    echo -e "${BLUE}Checking DynamoDB tables...${NC}"
    local tables=("${ENVIRONMENT}-portfolios" "${ENVIRONMENT}-optimization-results" "${ENVIRONMENT}-simulation-results")
    
    for table in "${tables[@]}"; do
        if aws dynamodb describe-table --table-name "$table" &>/dev/null; then
            echo -e "${GREEN}✅ Table ${table} exists${NC}"
        else
            echo -e "${RED}❌ Table ${table} not found${NC}"
        fi
    done
    
    # Check S3 buckets
    echo -e "${BLUE}Checking S3 buckets...${NC}"
    local buckets=("stratigos-${ENVIRONMENT}-data" "stratigos-${ENVIRONMENT}-layers")
    
    for bucket in "${buckets[@]}"; do
        if aws s3api head-bucket --bucket "$bucket" &>/dev/null; then
            echo -e "${GREEN}✅ Bucket ${bucket} exists${NC}"
        else
            echo -e "${RED}❌ Bucket ${bucket} not found${NC}"
        fi
    done
}

# Function to display next steps
display_next_steps() {
    echo -e "${BLUE}📝 Next Steps:${NC}"
    echo ""
    echo "1. Get your API key:"
    echo "   aws apigateway get-api-keys --include-values --query 'items[0].value' --output text"
    echo ""
    echo "2. Test the API:"
    echo "   curl -X GET \\"
    echo "     -H \"x-api-key: YOUR_API_KEY\" \\"
    echo "     \"$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text 2>/dev/null)/portfolios\""
    echo ""
    echo "3. Run verification script:"
    echo "   ./scripts/verify-deployment.sh ${ENVIRONMENT}"
    echo ""
    echo "4. View CloudWatch logs:"
    echo "   aws logs describe-log-groups --log-group-name-prefix /aws/lambda/stratigos"
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting infrastructure deployment...${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Check if layers exist
    check_layers
    echo ""
    
    # Install dependencies
    install_dependencies
    echo ""
    
    # Validate template
    validate_template
    echo ""
    
    # Build application
    build_application
    echo ""
    
    # Deploy infrastructure
    deploy_infrastructure
    echo ""
    
    # Get stack outputs
    get_stack_outputs
    echo ""
    
    # Run health checks
    run_health_checks
    echo ""
    
    # Display next steps
    display_next_steps
}

# Run main function
main "$@"
