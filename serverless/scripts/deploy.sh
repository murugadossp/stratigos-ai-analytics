#!/bin/bash

# Stratigos AI Platform - Serverless Deployment Script
# This script deploys the Stratigos AI Platform to AWS Lambda.

# Set variables
STACK_NAME="stratigos-ai-platform"
REGION="us-east-1"
ENVIRONMENT="dev"

# Print header
print_header() {
    echo ""
    echo "================================================================================"
    echo "🚀 Stratigos AI Platform - Serverless Deployment"
    echo "================================================================================"
    echo ""
}

# Print section
print_section() {
    echo ""
    echo "📌 $1"
    echo "--------------------------------------------------------------------------------"
}

# Check if AWS CLI is installed
check_aws_cli() {
    print_section "Checking AWS CLI"
    
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    echo "✅ AWS CLI is installed"
}

# Check if AWS SAM CLI is installed
check_sam_cli() {
    print_section "Checking AWS SAM CLI"
    
    if ! command -v sam &> /dev/null; then
        echo "❌ AWS SAM CLI is not installed. Please install it first."
        exit 1
    fi
    
    echo "✅ AWS SAM CLI is installed"
}

# Check if Python is installed
check_python() {
    print_section "Checking Python"
    
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python 3 is not installed. Please install it first."
        exit 1
    fi
    
    echo "✅ Python 3 is installed"
}

# Install dependencies
install_dependencies() {
    print_section "Installing dependencies"
    
    echo "📦 Installing Python dependencies..."
    pip install -r requirements.txt
    
    echo "✅ Dependencies installed"
}

# Build the project
build_project() {
    print_section "Building the project"
    
    echo "🔨 Building the project with SAM..."
    sam build
    
    echo "✅ Project built"
}

# Deploy the project
deploy_project() {
    print_section "Deploying the project"
    
    echo "🚀 Deploying the project with SAM..."
    
    # Check if this is the first deployment
    if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null; then
        echo "📝 Updating existing stack: $STACK_NAME"
        sam deploy \
            --stack-name $STACK_NAME \
            --region $REGION \
            --parameter-overrides Environment=$ENVIRONMENT \
            --no-confirm-changeset \
            --no-fail-on-empty-changeset
    else
        echo "🆕 Creating new stack: $STACK_NAME"
        sam deploy \
            --stack-name $STACK_NAME \
            --region $REGION \
            --parameter-overrides Environment=$ENVIRONMENT \
            --guided
    fi
    
    echo "✅ Project deployed"
}

# Get API endpoint
get_api_endpoint() {
    print_section "Getting API endpoint"
    
    API_ENDPOINT=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
        --output text)
    
    echo "🔗 API endpoint: $API_ENDPOINT"
}

# Main function
main() {
    print_header
    
    # Check prerequisites
    check_aws_cli
    check_sam_cli
    check_python
    
    # Install dependencies
    install_dependencies
    
    # Build the project
    build_project
    
    # Deploy the project
    deploy_project
    
    # Get API endpoint
    get_api_endpoint
    
    echo ""
    echo "================================================================================"
    echo "🚀 Deployment Complete"
    echo "================================================================================"
    echo ""
}

# Run main function
main
