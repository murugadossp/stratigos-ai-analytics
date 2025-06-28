#!/bin/bash

# Stratigos AI Platform - Cleanup Script
# This script cleans up existing AWS resources before fresh deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default environment
ENVIRONMENT=${1:-dev}

echo -e "${BLUE}🧹 Stratigos AI Platform - Cleanup Script${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo ""

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ AWS CLI found${NC}"
}

# Function to check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
}

# Function to delete Lambda functions
cleanup_lambda_functions() {
    echo -e "${YELLOW}🔍 Searching for Stratigos Lambda functions...${NC}"
    
    # Get all Lambda functions that match our naming pattern
    FUNCTIONS=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `stratigos`) || contains(FunctionName, `Stratigos`)].FunctionName' --output text 2>/dev/null || echo "")
    
    if [ -z "$FUNCTIONS" ]; then
        echo -e "${GREEN}✅ No Stratigos Lambda functions found${NC}"
    else
        echo -e "${YELLOW}Found Lambda functions: $FUNCTIONS${NC}"
        for func in $FUNCTIONS; do
            echo -e "${YELLOW}🗑️  Deleting Lambda function: $func${NC}"
            aws lambda delete-function --function-name "$func" 2>/dev/null || echo -e "${RED}❌ Failed to delete $func${NC}"
        done
        echo -e "${GREEN}✅ Lambda functions cleanup completed${NC}"
    fi
}

# Function to delete API Gateways
cleanup_api_gateways() {
    echo -e "${YELLOW}🔍 Searching for Stratigos API Gateways...${NC}"
    
    # Get all API Gateways that match our naming pattern
    APIS=$(aws apigateway get-rest-apis --query 'items[?contains(name, `stratigos`) || contains(name, `Stratigos`)].id' --output text 2>/dev/null || echo "")
    
    if [ -z "$APIS" ]; then
        echo -e "${GREEN}✅ No Stratigos API Gateways found${NC}"
    else
        echo -e "${YELLOW}Found API Gateways: $APIS${NC}"
        for api in $APIS; do
            echo -e "${YELLOW}🗑️  Deleting API Gateway: $api${NC}"
            aws apigateway delete-rest-api --rest-api-id "$api" 2>/dev/null || echo -e "${RED}❌ Failed to delete $api${NC}"
        done
        echo -e "${GREEN}✅ API Gateways cleanup completed${NC}"
    fi
}

# Function to delete DynamoDB tables
cleanup_dynamodb_tables() {
    echo -e "${YELLOW}🔍 Searching for Stratigos DynamoDB tables...${NC}"
    
    # Get all DynamoDB tables that match our naming pattern
    TABLES=$(aws dynamodb list-tables --query 'TableNames[?contains(@, `stratigos`) || contains(@, `portfolio`) || contains(@, `optimization`) || contains(@, `simulation`)]' --output text 2>/dev/null || echo "")
    
    if [ -z "$TABLES" ]; then
        echo -e "${GREEN}✅ No Stratigos DynamoDB tables found${NC}"
    else
        echo -e "${YELLOW}Found DynamoDB tables: $TABLES${NC}"
        for table in $TABLES; do
            echo -e "${YELLOW}🗑️  Deleting DynamoDB table: $table${NC}"
            aws dynamodb delete-table --table-name "$table" 2>/dev/null || echo -e "${RED}❌ Failed to delete $table${NC}"
        done
        echo -e "${GREEN}✅ DynamoDB tables cleanup completed${NC}"
    fi
}

# Function to delete S3 buckets
cleanup_s3_buckets() {
    echo -e "${YELLOW}🔍 Searching for Stratigos S3 buckets...${NC}"
    
    # Get all S3 buckets that match our naming pattern
    BUCKETS=$(aws s3api list-buckets --query 'Buckets[?contains(Name, `stratigos`)].Name' --output text 2>/dev/null || echo "")
    
    if [ -z "$BUCKETS" ]; then
        echo -e "${GREEN}✅ No Stratigos S3 buckets found${NC}"
    else
        echo -e "${YELLOW}Found S3 buckets: $BUCKETS${NC}"
        for bucket in $BUCKETS; do
            echo -e "${YELLOW}🗑️  Emptying and deleting S3 bucket: $bucket${NC}"
            # Empty bucket first
            aws s3 rm "s3://$bucket" --recursive 2>/dev/null || echo -e "${RED}❌ Failed to empty $bucket${NC}"
            # Delete bucket
            aws s3api delete-bucket --bucket "$bucket" 2>/dev/null || echo -e "${RED}❌ Failed to delete $bucket${NC}"
        done
        echo -e "${GREEN}✅ S3 buckets cleanup completed${NC}"
    fi
}

# Function to delete CloudFormation stacks
cleanup_cloudformation_stacks() {
    echo -e "${YELLOW}🔍 Searching for Stratigos CloudFormation stacks...${NC}"
    
    # Get all CloudFormation stacks that match our naming pattern
    STACKS=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query 'StackSummaries[?contains(StackName, `stratigos`) || contains(StackName, `Stratigos`)].StackName' --output text 2>/dev/null || echo "")
    
    if [ -z "$STACKS" ]; then
        echo -e "${GREEN}✅ No Stratigos CloudFormation stacks found${NC}"
    else
        echo -e "${YELLOW}Found CloudFormation stacks: $STACKS${NC}"
        for stack in $STACKS; do
            echo -e "${YELLOW}🗑️  Deleting CloudFormation stack: $stack${NC}"
            aws cloudformation delete-stack --stack-name "$stack" 2>/dev/null || echo -e "${RED}❌ Failed to delete $stack${NC}"
        done
        echo -e "${GREEN}✅ CloudFormation stacks cleanup completed${NC}"
    fi
}

# Function to delete Lambda layers
cleanup_lambda_layers() {
    echo -e "${YELLOW}🔍 Searching for Stratigos Lambda layers...${NC}"
    
    # Get all Lambda layers that match our naming pattern
    LAYERS=$(aws lambda list-layers --query 'Layers[?contains(LayerName, `stratigos`)].LayerName' --output text 2>/dev/null || echo "")
    
    if [ -z "$LAYERS" ]; then
        echo -e "${GREEN}✅ No Stratigos Lambda layers found${NC}"
    else
        echo -e "${YELLOW}Found Lambda layers: $LAYERS${NC}"
        for layer in $LAYERS; do
            echo -e "${YELLOW}🗑️  Deleting Lambda layer versions for: $layer${NC}"
            # Get all versions of the layer
            VERSIONS=$(aws lambda list-layer-versions --layer-name "$layer" --query 'LayerVersions[].Version' --output text 2>/dev/null || echo "")
            for version in $VERSIONS; do
                aws lambda delete-layer-version --layer-name "$layer" --version-number "$version" 2>/dev/null || echo -e "${RED}❌ Failed to delete $layer version $version${NC}"
            done
        done
        echo -e "${GREEN}✅ Lambda layers cleanup completed${NC}"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Starting cleanup process...${NC}"
    echo ""
    
    # Check prerequisites
    check_aws_cli
    check_aws_credentials
    echo ""
    
    # Confirm cleanup
    echo -e "${YELLOW}⚠️  This will delete ALL Stratigos resources in your AWS account.${NC}"
    echo -e "${YELLOW}⚠️  This action cannot be undone.${NC}"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleanup cancelled.${NC}"
        exit 0
    fi
    
    echo ""
    echo -e "${BLUE}🚀 Starting cleanup...${NC}"
    echo ""
    
    # Cleanup in order (dependencies first)
    cleanup_lambda_functions
    echo ""
    
    cleanup_api_gateways
    echo ""
    
    cleanup_lambda_layers
    echo ""
    
    cleanup_dynamodb_tables
    echo ""
    
    cleanup_s3_buckets
    echo ""
    
    cleanup_cloudformation_stacks
    echo ""
    
    echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
    echo -e "${BLUE}You can now proceed with a fresh deployment.${NC}"
}

# Run main function
main "$@"
