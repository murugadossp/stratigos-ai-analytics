#!/bin/bash

# Stratigos AI Platform - Local Development Script
# This script runs the Stratigos AI Platform locally for development.

# Set variables
PORT=3000
ENVIRONMENT="dev"

# Print header
print_header() {
    echo ""
    echo "================================================================================"
    echo "🚀 Stratigos AI Platform - Local Development"
    echo "================================================================================"
    echo ""
}

# Print section
print_section() {
    echo ""
    echo "📌 $1"
    echo "--------------------------------------------------------------------------------"
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

# Start local API
start_local_api() {
    print_section "Starting local API"
    
    echo "🚀 Starting local API on port $PORT..."
    sam local start-api --port $PORT --parameter-overrides Environment=$ENVIRONMENT
}

# Main function
main() {
    print_header
    
    # Check prerequisites
    check_sam_cli
    check_python
    
    # Install dependencies
    install_dependencies
    
    # Build the project
    build_project
    
    # Start local API
    start_local_api
}

# Run main function
main
