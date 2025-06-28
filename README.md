# Stratigos AI Analytics

A comprehensive platform for portfolio management, optimization, and risk analysis using serverless architecture.

## Project Structure

This repository contains the serverless implementation of the Stratigos AI Platform:

### Serverless (AWS Lambda)

The `serverless` directory contains a serverless implementation of the Stratigos AI Platform using AWS Lambda, API Gateway, DynamoDB, and S3.

```bash
cd serverless
```

See [serverless/README.md](serverless/README.md) for more information.

## Getting Started

### Prerequisites

- Python 3.11 or later
- AWS CLI
- AWS SAM CLI (for serverless implementation)
- An AWS account

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/stratigos-ai-analytics.git
cd stratigos-ai-analytics
```

2. Navigate to the serverless implementation:

```bash
cd serverless
pip install -r requirements.txt
./scripts/local.sh  # For local development
./scripts/deploy.sh  # For deployment to AWS
```

## Documentation

- [API Documentation](serverless/docs/API.md)
- [Deployment Guide](serverless/docs/DEPLOYMENT.md)
- [Development Guide](serverless/docs/DEVELOPMENT.md)

## Features

- **Portfolio Management**: Create, read, update, and delete portfolios
- **Portfolio Optimization**: Optimize portfolios using various strategies
  - Risk Parity Optimization
  - Hierarchical Risk Parity
  - Efficient Frontier
- **Monte Carlo Simulation**: Simulate portfolio performance
- **Market Data**: Access market data for analysis

## Architecture

This project uses a pure serverless approach with the following AWS services:

- **AWS Lambda**: For executing code in response to events
- **Amazon API Gateway**: For creating, publishing, and managing APIs
- **Amazon DynamoDB**: For storing and retrieving data
- **Amazon S3**: For storing static assets and large datasets
- **AWS CloudFormation/SAM**: For infrastructure as code
- **AWS CloudWatch**: For monitoring and logging

For a detailed architecture overview, see [serverless/ARCHITECTURE_PLAN.md](serverless/ARCHITECTURE_PLAN.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
