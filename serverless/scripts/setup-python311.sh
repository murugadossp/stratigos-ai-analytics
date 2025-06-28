#!/bin/bash

# Stratigos AI Platform - Python 3.11 Environment Setup Script
# This script helps set up a consistent Python 3.11 environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}🐍 Stratigos AI Platform - Python 3.11 Environment Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Function to check if Python 3.11 is installed
check_python311() {
    echo -e "${YELLOW}🔍 Checking Python 3.11 installation...${NC}"
    
    if command -v python3.11 &> /dev/null; then
        local version=$(python3.11 --version 2>&1 | cut -d' ' -f2)
        echo -e "${GREEN}✅ Python 3.11 found: ${version}${NC}"
        return 0
    else
        echo -e "${RED}❌ Python 3.11 not found${NC}"
        return 1
    fi
}

# Function to install Python 3.11 on macOS
install_python311_macos() {
    echo -e "${YELLOW}📦 Installing Python 3.11 on macOS...${NC}"
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}❌ Homebrew not found. Please install Homebrew first:${NC}"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    echo -e "${BLUE}Installing Python 3.11 via Homebrew...${NC}"
    brew install python@3.11
    
    # Add to PATH if needed
    echo -e "${BLUE}Adding Python 3.11 to PATH...${NC}"
    echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
    echo 'export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"' >> ~/.zshrc
    
    echo -e "${GREEN}✅ Python 3.11 installed successfully${NC}"
    echo -e "${YELLOW}Please restart your terminal or run: source ~/.zshrc${NC}"
}

# Function to install Python 3.11 on Linux
install_python311_linux() {
    echo -e "${YELLOW}📦 Installing Python 3.11 on Linux...${NC}"
    
    # Detect Linux distribution
    if [ -f /etc/debian_version ]; then
        echo -e "${BLUE}Detected Debian/Ubuntu system${NC}"
        sudo apt update
        sudo apt install -y python3.11 python3.11-pip python3.11-venv python3.11-dev
    elif [ -f /etc/redhat-release ]; then
        echo -e "${BLUE}Detected Red Hat/CentOS system${NC}"
        sudo yum install -y python3.11 python3.11-pip
    else
        echo -e "${RED}❌ Unsupported Linux distribution${NC}"
        echo -e "${YELLOW}Please install Python 3.11 manually${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Python 3.11 installed successfully${NC}"
}

# Function to setup pip3.11
setup_pip311() {
    echo -e "${YELLOW}🔧 Setting up pip3.11...${NC}"
    
    if ! command -v pip3.11 &> /dev/null; then
        echo -e "${BLUE}Installing pip for Python 3.11...${NC}"
        python3.11 -m ensurepip --upgrade
    fi
    
    # Upgrade pip
    python3.11 -m pip install --upgrade pip
    
    echo -e "${GREEN}✅ pip3.11 setup complete${NC}"
}

# Function to create virtual environment
create_virtual_environment() {
    echo -e "${YELLOW}🏗️  Creating Python 3.11 virtual environment...${NC}"
    
    local venv_name="stratigos-py311"
    
    if [ -d "$venv_name" ]; then
        echo -e "${YELLOW}⚠️  Virtual environment ${venv_name} already exists${NC}"
        read -p "Do you want to recreate it? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$venv_name"
        else
            echo -e "${BLUE}Using existing virtual environment${NC}"
            return 0
        fi
    fi
    
    python3.11 -m venv "$venv_name"
    echo -e "${GREEN}✅ Virtual environment created: ${venv_name}${NC}"
    
    # Activate and install dependencies
    echo -e "${BLUE}Activating virtual environment and installing dependencies...${NC}"
    source "$venv_name/bin/activate"
    
    # Upgrade pip in virtual environment
    pip install --upgrade pip
    
    # Install AWS CLI and SAM CLI
    pip install awscli aws-sam-cli
    
    # Install project dependencies if requirements.txt exists
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    fi
    
    echo -e "${GREEN}✅ Virtual environment setup complete${NC}"
    echo ""
    echo -e "${YELLOW}To activate the virtual environment, run:${NC}"
    echo "   source ${venv_name}/bin/activate"
}

# Function to verify installation
verify_installation() {
    echo -e "${YELLOW}🔍 Verifying installation...${NC}"
    
    # Check Python 3.11
    if command -v python3.11 &> /dev/null; then
        local python_version=$(python3.11 --version)
        echo -e "${GREEN}✅ ${python_version}${NC}"
    else
        echo -e "${RED}❌ Python 3.11 not found${NC}"
        return 1
    fi
    
    # Check pip3.11
    if command -v pip3.11 &> /dev/null; then
        local pip_version=$(pip3.11 --version | cut -d' ' -f1,2)
        echo -e "${GREEN}✅ ${pip_version} (Python 3.11)${NC}"
    else
        echo -e "${RED}❌ pip3.11 not found${NC}"
        return 1
    fi
    
    # Check AWS CLI
    if command -v aws &> /dev/null; then
        local aws_version=$(aws --version 2>&1 | cut -d' ' -f1)
        echo -e "${GREEN}✅ ${aws_version}${NC}"
    else
        echo -e "${YELLOW}⚠️  AWS CLI not found in PATH${NC}"
    fi
    
    # Check SAM CLI
    if command -v sam &> /dev/null; then
        local sam_version=$(sam --version 2>&1)
        echo -e "${GREEN}✅ ${sam_version}${NC}"
    else
        echo -e "${YELLOW}⚠️  SAM CLI not found in PATH${NC}"
    fi
    
    echo -e "${GREEN}✅ Installation verification complete${NC}"
}

# Function to display usage instructions
display_usage() {
    echo -e "${BLUE}📋 Usage Instructions:${NC}"
    echo ""
    echo "1. Activate the virtual environment:"
    echo "   source stratigos-py311/bin/activate"
    echo ""
    echo "2. Verify Python version:"
    echo "   python --version  # Should show Python 3.11.x"
    echo ""
    echo "3. Configure AWS credentials (if not done already):"
    echo "   aws configure"
    echo ""
    echo "4. Run deployment scripts:"
    echo "   ./scripts/deploy-complete.sh dev us-east-1 true"
    echo ""
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "- Always activate the virtual environment before running deployment scripts"
    echo "- Use 'deactivate' to exit the virtual environment"
    echo "- The virtual environment is portable and can be recreated anytime"
}

# Main execution
main() {
    local os_type=$(detect_os)
    
    echo -e "${BLUE}Detected OS: ${os_type}${NC}"
    echo ""
    
    # Check if Python 3.11 is already installed
    if check_python311; then
        echo -e "${BLUE}Python 3.11 is already installed${NC}"
    else
        echo -e "${YELLOW}Installing Python 3.11...${NC}"
        
        case $os_type in
            "macos")
                install_python311_macos
                ;;
            "linux")
                install_python311_linux
                ;;
            *)
                echo -e "${RED}❌ Unsupported operating system: ${os_type}${NC}"
                echo -e "${YELLOW}Please install Python 3.11 manually${NC}"
                exit 1
                ;;
        esac
    fi
    
    echo ""
    
    # Setup pip3.11
    setup_pip311
    echo ""
    
    # Create virtual environment
    create_virtual_environment
    echo ""
    
    # Verify installation
    verify_installation
    echo ""
    
    # Display usage instructions
    display_usage
    echo ""
    
    echo -e "${GREEN}${BOLD}🎉 Python 3.11 environment setup complete!${NC}"
    echo -e "${BLUE}You're now ready to deploy the Stratigos AI Platform${NC}"
}

# Show help if requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "${BLUE}Stratigos AI Platform - Python 3.11 Environment Setup${NC}"
    echo ""
    echo "This script sets up a consistent Python 3.11 environment for the Stratigos AI Platform."
    echo ""
    echo "Usage:"
    echo "  $0                    # Run interactive setup"
    echo "  $0 -h, --help       # Show this help message"
    echo ""
    echo "What this script does:"
    echo "1. Detects your operating system"
    echo "2. Installs Python 3.11 if not present"
    echo "3. Sets up pip3.11"
    echo "4. Creates a virtual environment with required dependencies"
    echo "5. Verifies the installation"
    echo ""
    exit 0
fi

# Run main function
main "$@"
