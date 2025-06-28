# Stratigos AI Platform - Deployment Guide

This guide provides comprehensive instructions for deploying the Stratigos AI Platform using AWS Lambda and API Gateway with optimized Lambda layers.

## 🏗️ Architecture Overview

The Stratigos AI Platform uses a serverless architecture with:

- **AWS Lambda Functions**: Portfolio management, optimization, Monte Carlo simulation, market data
- **Lambda Layers**: Optimized dependency management (Core, Numeric Computing, Visualization)
- **API Gateway**: RESTful API endpoints with authentication
- **DynamoDB**: NoSQL database for portfolios and results
- **S3**: Object storage for data and Lambda layers
- **CloudFormation/SAM**: Infrastructure as Code

## 📋 Prerequisites

### Required Tools

1. **AWS CLI** (v2.0+)
   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Configure AWS credentials
   aws configure
   ```

2. **AWS SAM CLI** (v1.0+)
   ```bash
   # Install SAM CLI
   pip install aws-sam-cli
   
   # Verify installation
   sam --version
   ```

3. **Python 3.11** (Required - exact version)
   ```bash
   # Check Python 3.11 version
   python3.11 --version
   
   # If not installed, use our setup script
   ./scripts/setup-python311.sh
   ```

4. **Additional Tools**
   ```bash
   # Required for scripts
   sudo apt-get install curl jq zip
   ```

### AWS Account Setup

1. **AWS Account**: Active AWS account with appropriate permissions
2. **IAM Permissions**: User/role with permissions for:
   - Lambda (create, update, delete functions and layers)
   - API Gateway (create, update, delete APIs)
   - DynamoDB (create, update, delete tables)
   - S3 (create, update, delete buckets and objects)
   - CloudFormation (create, update, delete stacks)
   - IAM (create, update roles and policies)

3. **AWS Region**: Choose your preferred region (default: us-east-1)

## 🐍 Python 3.11 Environment Setup

### Automated Setup (Recommended)

Use our automated setup script to ensure Python 3.11 consistency:

```bash
# Navigate to serverless directory
cd serverless

# Run Python 3.11 environment setup
./scripts/setup-python311.sh

# Activate the virtual environment
source stratigos-py311/bin/activate

# Verify Python version
python --version  # Should show Python 3.11.x
```

### Manual Setup

If you prefer manual setup:

```bash
# Install Python 3.11 (macOS)
brew install python@3.11

# Install Python 3.11 (Ubuntu/Debian)
sudo apt install python3.11 python3.11-pip python3.11-venv

# Create virtual environment
python3.11 -m venv stratigos-py311
source stratigos-py311/bin/activate

# Install dependencies
pip install awscli aws-sam-cli
pip install -r requirements.txt
```

## 🚀 Quick Start Deployment

### Option 1: One-Click Deployment (Recommended)

```bash
# Navigate to serverless directory
cd serverless

# Ensure Python 3.11 environment is active
source stratigos-py311/bin/activate

# Run complete deployment (interactive)
./scripts/deploy-complete.sh

# Or run clean installation directly
./scripts/deploy-complete.sh dev us-east-1 true
```

### Option 2: Step-by-Step Deployment

```bash
# 1. Clean existing resources (optional)
./scripts/cleanup.sh dev

# 2. Create Lambda layers
./scripts/create-layers.sh dev us-east-1

# 3. Deploy infrastructure
./scripts/deploy-infrastructure.sh dev us-east-1

# 4. Verify deployment
./scripts/verify-deployment.sh dev
```

## 📦 Lambda Layers Strategy

### Layer Architecture

The platform uses three optimized Lambda layers:

1. **Core Dependencies Layer** (~50MB)
   - boto3==1.28.0
   - pydantic==2.4.2
   - requests==2.31.0
   - python-dateutil==2.9.0.post0

2. **Numeric Computing Layer** (~150MB)
   - numpy==1.24.3
   - pandas==2.0.3
   - scipy==1.11.1

3. **Visualization Layer** (~100MB)
   - matplotlib==3.7.2

### Function-Layer Mapping

| Function Type | Layers Used | Memory | Timeout |
|---------------|-------------|---------|---------|
| Portfolio Management | Core | 256MB | 30s |
| Market Data | Core | 512MB | 60s |
| Optimization | Core + Numeric | 1024MB | 120s |
| Monte Carlo | Core + Numeric | 1536MB | 300s |
| Analytics | Core + Numeric + Viz | 1024MB | 120s |

### Benefits

- **Reduced Cold Start**: Shared dependencies loaded once
- **Smaller Packages**: Function code only contains business logic
- **Better Maintainability**: Update dependencies independently
- **Cost Optimization**: Shared layers reduce storage costs

## 🔧 Deployment Scripts

### 1. cleanup.sh
Removes all existing Stratigos resources from AWS.

```bash
./scripts/cleanup.sh [environment]

# Examples
./scripts/cleanup.sh dev
./scripts/cleanup.sh prod
```

**What it cleans:**
- Lambda functions
- API Gateways
- DynamoDB tables
- S3 buckets
- CloudFormation stacks
- Lambda layers

### 2. create-layers.sh
Creates and uploads optimized Lambda layers.

```bash
./scripts/create-layers.sh [environment] [region]

# Examples
./scripts/create-layers.sh dev us-east-1
./scripts/create-layers.sh prod eu-west-1
```

**Process:**
1. Creates S3 bucket for layers
2. Installs dependencies with Linux compatibility
3. Creates layer zip files
4. Uploads to S3
5. Verifies uploads

### 3. deploy-infrastructure.sh
Deploys the complete SAM infrastructure.

```bash
./scripts/deploy-infrastructure.sh [environment] [region]

# Examples
./scripts/deploy-infrastructure.sh dev us-east-1
./scripts/deploy-infrastructure.sh staging us-west-2
```

**Process:**
1. Validates prerequisites
2. Checks layer availability
3. Validates SAM template
4. Builds application
5. Deploys infrastructure
6. Runs health checks

### 4. verify-deployment.sh
Comprehensive testing of deployed infrastructure.

```bash
./scripts/verify-deployment.sh [environment]

# Examples
./scripts/verify-deployment.sh dev
./scripts/verify-deployment.sh prod
```

**Tests:**
- API Gateway connectivity
- Portfolio CRUD operations
- Optimization endpoints
- Monte Carlo simulation
- Market data endpoints
- Lambda function logs

### 5. deploy-complete.sh
Master script that orchestrates the entire deployment.

```bash
./scripts/deploy-complete.sh [environment] [region] [clean_install]

# Examples
./scripts/deploy-complete.sh                    # Interactive
./scripts/deploy-complete.sh dev us-east-1     # Interactive
./scripts/deploy-complete.sh prod us-west-2 true  # Clean install
```

**Options:**
1. **Clean Installation**: Full cleanup + fresh deployment
2. **Update Deployment**: Update existing infrastructure
3. **Custom Deployment**: Choose individual steps

## 🌍 Multi-Environment Deployment

### Environment Configuration

| Environment | Purpose | Configuration |
|-------------|---------|---------------|
| `dev` | Development | Lower memory, shorter timeouts |
| `staging` | Testing | Production-like settings |
| `prod` | Production | Optimized for performance |

### Deploy to Different Environments

```bash
# Development
./scripts/deploy-complete.sh dev us-east-1

# Staging
./scripts/deploy-complete.sh staging us-east-1

# Production
./scripts/deploy-complete.sh prod us-east-1
```

### Environment Isolation

Each environment creates separate:
- CloudFormation stacks
- DynamoDB tables
- S3 buckets
- Lambda functions
- API Gateways

## 🔍 Verification and Testing

### Automated Testing

The verification script tests:

1. **Infrastructure Health**
   - Stack status
   - Resource availability
   - API Gateway connectivity

2. **Portfolio Operations**
   - Create portfolio
   - Read portfolio
   - Update portfolio
   - Delete portfolio
   - List portfolios

3. **Advanced Features**
   - Risk parity optimization
   - Monte Carlo simulation
   - Market data retrieval

### Manual Testing

```bash
# Get API key
API_KEY=$(aws apigateway get-api-keys --include-values --query 'items[0].value' --output text)

# Get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name stratigos-ai-platform-dev --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text)

# Test portfolio creation
curl -X POST \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Portfolio",
    "description": "A test portfolio",
    "assets": {
      "AAPL": 0.4,
      "MSFT": 0.3,
      "GOOGL": 0.2,
      "AMZN": 0.1
    }
  }' \
  "$API_ENDPOINT/portfolios"
```

## 📊 Monitoring and Logging

### CloudWatch Integration

All Lambda functions automatically log to CloudWatch:

```bash
# View log groups
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/stratigos

# View recent logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/stratigos-ai-platform-dev-CreatePortfolioFunction-XXXXX \
  --start-time $(date -d '1 hour ago' +%s)000
```

### X-Ray Tracing

X-Ray tracing is enabled for request flow analysis:

```bash
# View traces in AWS X-Ray console
aws xray get-trace-summaries \
  --time-range-type TimeRangeByStartTime \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s)
```

### API Gateway Monitoring

```bash
# View API Gateway logs
aws logs describe-log-groups --log-group-name-prefix API-Gateway-Execution-Logs
```

## 🔧 Troubleshooting

### Common Issues

1. **Layer Creation Fails**
   ```bash
   # Check pip version and platform
   pip3 --version
   
   # Ensure Linux compatibility
   pip3 install --platform linux_x86_64 --only-binary=:all: package_name
   ```

2. **SAM Build Fails**
   ```bash
   # Clean and rebuild
   rm -rf .aws-sam
   sam build --use-container
   ```

3. **Deployment Timeout**
   ```bash
   # Check CloudFormation events
   aws cloudformation describe-stack-events --stack-name stratigos-ai-platform-dev
   ```

4. **API Gateway 403 Errors**
   ```bash
   # Verify API key
   aws apigateway get-api-keys --include-values
   
   # Check usage plan association
   aws apigateway get-usage-plans
   ```

### Debug Commands

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify SAM template
sam validate --template template.yaml

# Test local SAM
sam local start-api

# Check DynamoDB tables
aws dynamodb list-tables

# Check S3 buckets
aws s3 ls

# View CloudFormation stack
aws cloudformation describe-stacks --stack-name stratigos-ai-platform-dev
```

## 🔄 Updates and Maintenance

### Updating Dependencies

1. **Update requirements.txt**
2. **Recreate layers**:
   ```bash
   ./scripts/create-layers.sh dev us-east-1
   ```
3. **Redeploy infrastructure**:
   ```bash
   ./scripts/deploy-infrastructure.sh dev us-east-1
   ```

### Scaling Configuration

Modify `template.yaml` for different workloads:

```yaml
# High-performance configuration
MemorySize: 3008
Timeout: 900
ReservedConcurrencyLimit: 100

# Cost-optimized configuration
MemorySize: 512
Timeout: 60
```

### Backup and Recovery

```bash
# Backup DynamoDB tables
aws dynamodb create-backup --table-name dev-portfolios --backup-name portfolios-backup-$(date +%Y%m%d)

# Export S3 data
aws s3 sync s3://stratigos-dev-data ./backup/
```

## 💰 Cost Optimization

### Layer Benefits
- **Reduced storage**: Shared dependencies across functions
- **Faster deployments**: Only function code changes
- **Lower costs**: Efficient resource utilization

### Memory Optimization
- Portfolio functions: 256MB (sufficient for CRUD operations)
- Optimization functions: 1024MB (balance of performance/cost)
- Simulation functions: 1536MB (memory-intensive operations)

### DynamoDB Optimization
- **On-demand billing**: Automatic scaling for unpredictable workloads
- **TTL**: Automatic cleanup of temporary data
- **Global Secondary Indexes**: Efficient querying

## 🔐 Security Best Practices

### API Security
- API key authentication required
- CORS properly configured
- Rate limiting and throttling enabled

### IAM Security
- Least privilege access
- Function-specific roles
- Resource-based policies

### Data Security
- Encryption at rest (DynamoDB, S3)
- Encryption in transit (HTTPS)
- Input validation and sanitization

## 📚 Additional Resources

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)

## 🆘 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review CloudWatch logs
3. Examine CloudFormation events
4. Verify AWS service limits
5. Check AWS service health dashboard

---

**Happy Deploying! 🚀**

Your Stratigos AI Platform will be ready to handle portfolio management, optimization, and analytics at scale.
