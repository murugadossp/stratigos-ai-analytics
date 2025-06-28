#!/bin/bash

# Stratigos AI Platform - Test Script
# This script runs tests for the Stratigos AI Platform.

# Set variables
ENVIRONMENT="dev"

# Print header
print_header() {
    echo ""
    echo "================================================================================"
    echo "🚀 Stratigos AI Platform - Tests"
    echo "================================================================================"
    echo ""
}

# Print section
print_section() {
    echo ""
    echo "📌 $1"
    echo "--------------------------------------------------------------------------------"
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

# Run unit tests
run_unit_tests() {
    print_section "Running unit tests"
    
    echo "🧪 Running unit tests with pytest..."
    python -m pytest tests/unit -v
    
    echo "✅ Unit tests completed"
}

# Run integration tests
run_integration_tests() {
    print_section "Running integration tests"
    
    echo "🧪 Running integration tests with pytest..."
    python -m pytest tests/integration -v
    
    echo "✅ Integration tests completed"
}

# Run all tests
run_all_tests() {
    print_section "Running all tests"
    
    echo "🧪 Running all tests with pytest..."
    python -m pytest tests -v
    
    echo "✅ All tests completed"
}

# Show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --unit       Run unit tests only"
    echo "  --integration Run integration tests only"
    echo "  --all        Run all tests (default)"
    echo "  --help       Show this help message"
    echo ""
}

# Main function
main() {
    print_header
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        # No arguments, run all tests
        TEST_TYPE="all"
    else
        case "$1" in
            --unit)
                TEST_TYPE="unit"
                ;;
            --integration)
                TEST_TYPE="integration"
                ;;
            --all)
                TEST_TYPE="all"
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "❌ Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    fi
    
    # Check prerequisites
    check_python
    
    # Install dependencies
    install_dependencies
    
    # Run tests
    case "$TEST_TYPE" in
        unit)
            run_unit_tests
            ;;
        integration)
            run_integration_tests
            ;;
        all)
            run_all_tests
            ;;
    esac
    
    echo ""
    echo "================================================================================"
    echo "🚀 Tests Complete"
    echo "================================================================================"
    echo ""
}

# Run main function
main "$@"
