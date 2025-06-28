#!/bin/bash

# Stratigos AI Platform - Create Lambda Layers Script
# This script creates and uploads Lambda layers for the Stratigos AI Platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default environment
ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}

echo -e "${BLUE}📦 Stratigos AI Platform - Lambda Layers Creation Script${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"
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
    
    # Check pip3.11
    if ! command -v pip3.11 &> /dev/null; then
        echo -e "${RED}❌ pip3.11 is not installed. Please install it first.${NC}"
        echo -e "${YELLOW}💡 Try: python3.11 -m ensurepip --upgrade${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ pip3.11 found${NC}"
    
    # Check zip
    if ! command -v zip &> /dev/null; then
        echo -e "${RED}❌ zip is not installed. Please install it first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ zip found${NC}"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
}

# Function to create S3 bucket for layers
create_layers_bucket() {
    local bucket_name="stratigos-${ENVIRONMENT}-layers"
    
    echo -e "${YELLOW}🪣 Creating S3 bucket for layers: ${bucket_name}${NC}"
    
    # Check if bucket already exists
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        echo -e "${GREEN}✅ Bucket ${bucket_name} already exists${NC}"
    else
        # Create bucket
        if [ "$REGION" = "us-east-1" ]; then
            aws s3api create-bucket --bucket "$bucket_name" --region "$REGION"
        else
            aws s3api create-bucket --bucket "$bucket_name" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
        fi
        
        # Enable versioning
        aws s3api put-bucket-versioning --bucket "$bucket_name" --versioning-configuration Status=Enabled
        
        # Block public access
        aws s3api put-public-access-block --bucket "$bucket_name" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
        
        echo -e "${GREEN}✅ Created S3 bucket: ${bucket_name}${NC}"
    fi
}

# Function to create core dependencies layer
create_core_layer() {
    echo -e "${YELLOW}📦 Creating Core Dependencies Layer...${NC}"
    
    # Create directory structure
    local layer_dir="stratigos_core_layer"
    local python_dir="${layer_dir}/python/lib/python3.11/site-packages"
    
    rm -rf "$layer_dir"
    mkdir -p "$python_dir"
    
    echo -e "${BLUE}Installing core dependencies...${NC}"
    pip3.11 install \
        boto3 \
        pydantic \
        requests \
        python-dateutil \
        -t "$python_dir" \
        --upgrade
    
    # Create zip file
    echo -e "${BLUE}Creating zip file...${NC}"
    cd "$layer_dir"
    zip -r "../stratigos_core_layer.zip" python/ -q
    cd ..
    
    # Upload to S3
    local bucket_name="stratigos-${ENVIRONMENT}-layers"
    echo -e "${BLUE}Uploading to S3...${NC}"
    aws s3 cp "stratigos_core_layer.zip" "s3://${bucket_name}/stratigos_core_layer.zip"
    
    # Cleanup
    rm -rf "$layer_dir"
    
    echo -e "${GREEN}✅ Core Dependencies Layer created and uploaded${NC}"
}

# Function to create numeric computing layer
create_numeric_layer() {
    echo -e "${YELLOW}📦 Creating Numeric Computing Layer...${NC}"
    
    # Create directory structure
    local layer_dir="stratigos_numeric_layer"
    local python_dir="${layer_dir}/python/lib/python3.11/site-packages"
    
    rm -rf "$layer_dir"
    mkdir -p "$python_dir"
    
    echo -e "${BLUE}Installing numeric dependencies...${NC}"
    pip3.11 install \
        numpy \
        pandas \
        scipy \
        -t "$python_dir" \
        --upgrade
    
    # Create zip file
    echo -e "${BLUE}Creating zip file...${NC}"
    cd "$layer_dir"
    zip -r "../stratigos_numeric_layer.zip" python/ -q
    cd ..
    
    # Upload to S3
    local bucket_name="stratigos-${ENVIRONMENT}-layers"
    echo -e "${BLUE}Uploading to S3...${NC}"
    aws s3 cp "stratigos_numeric_layer.zip" "s3://${bucket_name}/stratigos_numeric_layer.zip"
    
    # Cleanup
    rm -rf "$layer_dir"
    
    echo -e "${GREEN}✅ Numeric Computing Layer created and uploaded${NC}"
}

# Function to create visualization layer
create_visualization_layer() {
    echo -e "${YELLOW}📦 Creating Visualization Layer...${NC}"
    
    # Create directory structure
    local layer_dir="stratigos_viz_layer"
    local python_dir="${layer_dir}/python/lib/python3.11/site-packages"
    
    rm -rf "$layer_dir"
    mkdir -p "$python_dir"
    
    echo -e "${BLUE}Installing visualization dependencies...${NC}"
    pip3.11 install \
        matplotlib \
        -t "$python_dir" \
        --upgrade
    
    # Create zip file
    echo -e "${BLUE}Creating zip file...${NC}"
    cd "$layer_dir"
    zip -r "../stratigos_viz_layer.zip" python/ -q
    cd ..
    
    # Upload to S3
    local bucket_name="stratigos-${ENVIRONMENT}-layers"
    echo -e "${BLUE}Uploading to S3...${NC}"
    aws s3 cp "stratigos_viz_layer.zip" "s3://${bucket_name}/stratigos_viz_layer.zip"
    
    # Cleanup
    rm -rf "$layer_dir"
    
    echo -e "${GREEN}✅ Visualization Layer created and uploaded${NC}"
}

# Function to verify uploads
verify_uploads() {
    echo -e "${YELLOW}🔍 Verifying layer uploads...${NC}"
    
    local bucket_name="stratigos-${ENVIRONMENT}-layers"
    
    # Check if all layer files exist in S3
    local files=("stratigos_core_layer.zip" "stratigos_numeric_layer.zip" "stratigos_viz_layer.zip")
    
    for file in "${files[@]}"; do
        if aws s3api head-object --bucket "$bucket_name" --key "$file" &>/dev/null; then
            local size=$(aws s3api head-object --bucket "$bucket_name" --key "$file" --query 'ContentLength' --output text)
            echo -e "${GREEN}✅ ${file} (${size} bytes)${NC}"
        else
            echo -e "${RED}❌ ${file} not found${NC}"
        fi
    done
}

# Function to cleanup local files
cleanup_local_files() {
    echo -e "${YELLOW}🧹 Cleaning up local files...${NC}"
    
    rm -f stratigos_core_layer.zip
    rm -f stratigos_numeric_layer.zip
    rm -f stratigos_viz_layer.zip
    rm -rf stratigos_*_layer/
    
    echo -e "${GREEN}✅ Local cleanup completed${NC}"
}

# Function to display layer information
display_layer_info() {
    echo -e "${BLUE}📋 Layer Information:${NC}"
    echo ""
    echo -e "${YELLOW}Core Dependencies Layer:${NC}"
    echo "  - boto3==1.28.0"
    echo "  - pydantic==2.4.2"
    echo "  - requests==2.31.0"
    echo "  - python-dateutil==2.9.0.post0"
    echo ""
    echo -e "${YELLOW}Numeric Computing Layer:${NC}"
    echo "  - numpy==1.24.3"
    echo "  - pandas==2.0.3"
    echo "  - scipy==1.11.1"
    echo ""
    echo -e "${YELLOW}Visualization Layer:${NC}"
    echo "  - matplotlib==3.7.2"
    echo ""
    echo -e "${BLUE}S3 Bucket: stratigos-${ENVIRONMENT}-layers${NC}"
    echo -e "${BLUE}Region: ${REGION}${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting Lambda layers creation...${NC}"
    echo ""
    
    # Display layer information
    display_layer_info
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Create S3 bucket for layers
    create_layers_bucket
    echo ""
    
    # Create layers
    echo -e "${BLUE}🚀 Creating Lambda layers...${NC}"
    echo ""
    
    create_core_layer
    echo ""
    
    create_numeric_layer
    echo ""
    
    create_visualization_layer
    echo ""
    
    # Verify uploads
    verify_uploads
    echo ""
    
    # Cleanup
    cleanup_local_files
    echo ""
    
    echo -e "${GREEN}🎉 Lambda layers creation completed successfully!${NC}"
    echo -e "${BLUE}You can now deploy the SAM template.${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Run: sam build"
    echo "2. Run: sam deploy --guided --parameter-overrides Environment=${ENVIRONMENT}"
}

# Run main function
main "$@"
