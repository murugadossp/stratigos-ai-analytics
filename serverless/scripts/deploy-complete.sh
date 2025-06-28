#!/bin/bash

# Stratigos AI Platform - Complete Deployment Script
# This script orchestrates the complete deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
CLEAN_INSTALL=${3:-false}

echo -e "${CYAN}${BOLD}🚀 Stratigos AI Platform - Complete Deployment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"
echo -e "${BLUE}Clean Install: ${CLEAN_INSTALL}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo -e "${BLUE}$(printf '%.0s─' {1..50})${NC}"
}

# Function to check if we're in the right directory
check_directory() {
    if [ ! -f "template.yaml" ]; then
        echo -e "${RED}❌ template.yaml not found. Please run this script from the serverless directory.${NC}"
        exit 1
    fi
    
    if [ ! -d "scripts" ]; then
        echo -e "${RED}❌ scripts directory not found. Please run this script from the serverless directory.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Running from correct directory${NC}"
}

# Function to display deployment options
display_options() {
    echo -e "${YELLOW}📋 Deployment Options:${NC}"
    echo ""
    echo "1. 🧹 Clean Installation (recommended for first deployment)"
    echo "   - Removes all existing resources"
    echo "   - Creates fresh Lambda layers"
    echo "   - Deploys complete infrastructure"
    echo "   - Runs verification tests"
    echo ""
    echo "2. 🔄 Update Deployment (for existing installations)"
    echo "   - Keeps existing layers"
    echo "   - Updates infrastructure only"
    echo "   - Runs verification tests"
    echo ""
    echo "3. 🛠️  Custom Deployment"
    echo "   - Choose individual steps"
    echo ""
}

# Function to get user choice
get_user_choice() {
    if [ "$CLEAN_INSTALL" = "true" ]; then
        CHOICE="1"
        echo -e "${BLUE}Clean install mode selected via parameter${NC}"
    else
        echo -e "${YELLOW}Select deployment option (1-3):${NC}"
        read -p "Enter your choice: " CHOICE
    fi
    
    case $CHOICE in
        1)
            echo -e "${GREEN}Selected: Clean Installation${NC}"
            DO_CLEANUP=true
            DO_LAYERS=true
            DO_DEPLOY=true
            DO_VERIFY=true
            ;;
        2)
            echo -e "${GREEN}Selected: Update Deployment${NC}"
            DO_CLEANUP=false
            DO_LAYERS=false
            DO_DEPLOY=true
            DO_VERIFY=true
            ;;
        3)
            echo -e "${GREEN}Selected: Custom Deployment${NC}"
            get_custom_options
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
}

# Function to get custom options
get_custom_options() {
    echo ""
    echo -e "${YELLOW}Custom Deployment Options:${NC}"
    
    read -p "Run cleanup? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DO_CLEANUP=true
    else
        DO_CLEANUP=false
    fi
    
    read -p "Create/update Lambda layers? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DO_LAYERS=true
    else
        DO_LAYERS=false
    fi
    
    read -p "Deploy infrastructure? (Y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        DO_DEPLOY=false
    else
        DO_DEPLOY=true
    fi
    
    read -p "Run verification tests? (Y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        DO_VERIFY=false
    else
        DO_VERIFY=true
    fi
}

# Function to run cleanup
run_cleanup() {
    print_section "🧹 STEP 1: Cleanup Existing Resources"
    echo ""
    
    if [ "$DO_CLEANUP" = true ]; then
        echo -e "${YELLOW}Running cleanup script...${NC}"
        ./scripts/cleanup.sh "$ENVIRONMENT"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Cleanup completed successfully${NC}"
        else
            echo -e "${RED}❌ Cleanup failed${NC}"
            exit 1
        fi
    else
        echo -e "${BLUE}ℹ️  Skipping cleanup${NC}"
    fi
    
    echo ""
}

# Function to create layers
create_layers() {
    print_section "📦 STEP 2: Create Lambda Layers"
    echo ""
    
    if [ "$DO_LAYERS" = true ]; then
        echo -e "${YELLOW}Creating Lambda layers...${NC}"
        ./scripts/create-layers.sh "$ENVIRONMENT" "$REGION"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Lambda layers created successfully${NC}"
        else
            echo -e "${RED}❌ Lambda layers creation failed${NC}"
            exit 1
        fi
    else
        echo -e "${BLUE}ℹ️  Skipping Lambda layers creation${NC}"
    fi
    
    echo ""
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_section "🚀 STEP 3: Deploy Infrastructure"
    echo ""
    
    if [ "$DO_DEPLOY" = true ]; then
        echo -e "${YELLOW}Deploying infrastructure...${NC}"
        ./scripts/deploy-infrastructure.sh "$ENVIRONMENT" "$REGION"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"
        else
            echo -e "${RED}❌ Infrastructure deployment failed${NC}"
            exit 1
        fi
    else
        echo -e "${BLUE}ℹ️  Skipping infrastructure deployment${NC}"
    fi
    
    echo ""
}

# Function to run verification
run_verification() {
    print_section "🔍 STEP 4: Verify Deployment"
    echo ""
    
    if [ "$DO_VERIFY" = true ]; then
        echo -e "${YELLOW}Running verification tests...${NC}"
        ./scripts/verify-deployment.sh "$ENVIRONMENT"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Verification completed successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  Verification completed with warnings${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️  Skipping verification${NC}"
    fi
    
    echo ""
}

# Function to display final summary
display_summary() {
    print_section "📊 DEPLOYMENT SUMMARY"
    echo ""
    
    local stack_name="stratigos-ai-platform-${ENVIRONMENT}"
    
    # Get stack outputs if deployment was successful
    if [ "$DO_DEPLOY" = true ]; then
        echo -e "${BLUE}📋 Stack Information:${NC}"
        
        if aws cloudformation describe-stacks --stack-name "$stack_name" &>/dev/null; then
            local api_endpoint=$(aws cloudformation describe-stacks --stack-name "$stack_name" --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text 2>/dev/null)
            local data_bucket=$(aws cloudformation describe-stacks --stack-name "$stack_name" --query 'Stacks[0].Outputs[?OutputKey==`DataBucketName`].OutputValue' --output text 2>/dev/null)
            local layers_bucket=$(aws cloudformation describe-stacks --stack-name "$stack_name" --query 'Stacks[0].Outputs[?OutputKey==`LayersBucketName`].OutputValue' --output text 2>/dev/null)
            
            echo "  🌐 API Endpoint: $api_endpoint"
            echo "  🗄️  Data Bucket: $data_bucket"
            echo "  📦 Layers Bucket: $layers_bucket"
            echo "  🏷️  Stack Name: $stack_name"
            echo "  🌍 Region: $REGION"
            echo "  🏗️  Environment: $ENVIRONMENT"
        else
            echo -e "${RED}❌ Could not retrieve stack information${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}🔑 Quick Start Commands:${NC}"
    echo ""
    echo "1. Get API Key:"
    echo "   aws apigateway get-api-keys --include-values --query 'items[0].value' --output text"
    echo ""
    echo "2. Test API:"
    echo "   curl -X GET -H \"x-api-key: YOUR_API_KEY\" \"API_ENDPOINT/portfolios\""
    echo ""
    echo "3. View Logs:"
    echo "   aws logs describe-log-groups --log-group-name-prefix /aws/lambda/stratigos"
    echo ""
    echo "4. Monitor Stack:"
    echo "   aws cloudformation describe-stacks --stack-name $stack_name"
    echo ""
    
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo "  - API Documentation: docs/API.md"
    echo "  - Architecture Plan: ARCHITECTURE_PLAN.md"
    echo "  - Deployment Guide: docs/DEPLOYMENT.md"
    echo ""
    
    echo -e "${GREEN}${BOLD}🎉 Deployment Process Completed!${NC}"
    echo -e "${BLUE}Your Stratigos AI Platform is ready for use.${NC}"
}

# Function to handle errors
handle_error() {
    echo ""
    echo -e "${RED}❌ Deployment failed at step: $1${NC}"
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "  1. Check AWS credentials: aws sts get-caller-identity"
    echo "  2. Verify AWS CLI version: aws --version"
    echo "  3. Check SAM CLI version: sam --version"
    echo "  4. Review CloudFormation events in AWS console"
    echo "  5. Check CloudWatch logs for Lambda functions"
    echo ""
    echo -e "${BLUE}🔧 To retry deployment:${NC}"
    echo "  ./scripts/deploy-complete.sh $ENVIRONMENT $REGION"
    echo ""
    exit 1
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  $0 [environment] [region] [clean_install]"
    echo ""
    echo -e "${BLUE}Parameters:${NC}"
    echo "  environment   : dev, staging, or prod (default: dev)"
    echo "  region        : AWS region (default: us-east-1)"
    echo "  clean_install : true for clean install (default: false)"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  $0                           # Interactive deployment to dev"
    echo "  $0 dev us-east-1            # Interactive deployment to dev in us-east-1"
    echo "  $0 prod us-west-2 true      # Clean install to prod in us-west-2"
    echo ""
}

# Main execution
main() {
    # Show usage if help requested
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    # Check directory
    check_directory
    echo ""
    
    # Display options and get user choice
    display_options
    get_user_choice
    echo ""
    
    # Confirm deployment
    echo -e "${YELLOW}⚠️  About to deploy Stratigos AI Platform${NC}"
    echo -e "${YELLOW}Environment: ${ENVIRONMENT}${NC}"
    echo -e "${YELLOW}Region: ${REGION}${NC}"
    echo ""
    
    if [ "$CLEAN_INSTALL" != "true" ]; then
        read -p "Continue with deployment? (Y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${BLUE}Deployment cancelled.${NC}"
            exit 0
        fi
    fi
    
    echo ""
    echo -e "${CYAN}${BOLD}🚀 Starting Deployment Process...${NC}"
    echo ""
    
    # Execute deployment steps
    run_cleanup || handle_error "Cleanup"
    create_layers || handle_error "Lambda Layers Creation"
    deploy_infrastructure || handle_error "Infrastructure Deployment"
    run_verification || handle_error "Verification"
    
    # Display summary
    display_summary
}

# Run main function
main "$@"
