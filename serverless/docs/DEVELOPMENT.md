# Stratigos AI Platform - Development Guide

This document provides detailed information for developers working on the Stratigos AI Platform.

## Development Environment Setup

### Prerequisites

1. **Python 3.11**: Install Python 3.11 or later.
   ```bash
   # Check Python version
   python --version
   ```

2. **AWS CLI**: Install and configure the AWS Command Line Interface (CLI).
   ```bash
   # Install AWS CLI
   pip install awscli

   # Configure AWS CLI
   aws configure
   ```

3. **AWS SAM CLI**: Install the AWS Serverless Application Model Command Line Interface (SAM CLI).
   ```bash
   # Install AWS SAM CLI
   pip install aws-sam-cli
   ```

4. **Git**: Install Git for version control.
   ```bash
   # Check Git version
   git --version
   ```

5. **Docker**: Install Docker for local testing.
   ```bash
   # Check Docker version
   docker --version
   ```

### Clone the Repository

```bash
git clone https://github.com/yourusername/stratigos-ai-platform-serverless.git
cd stratigos-ai-platform-serverless
```

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Local Development

You can run the API locally using the SAM CLI:

```bash
# Start the local API
sam local start-api

# Or use the provided script
./scripts/local.sh
```

This will start a local API Gateway instance that simulates the AWS environment. You can then test your API endpoints using tools like curl, Postman, or a web browser.

```bash
# Example: Get all portfolios
curl http://localhost:3000/portfolios

# Example: Create a portfolio
curl -X POST http://localhost:3000/portfolios \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Portfolio","description":"Test Description","assets":{"AAPL":0.5,"MSFT":0.5}}'
```

## Project Structure

The project follows a standard structure for AWS SAM applications:

```
stratigos-ai-platform-serverless/
├── README.md
├── template.yaml                  # SAM/CloudFormation template
├── requirements.txt               # Python dependencies
├── src/
│   ├── functions/                 # Lambda function handlers
│   │   ├── portfolios/
│   │   │   ├── __init__.py        # Package initialization
│   │   │   ├── create.py          # Create portfolio handler
│   │   │   ├── get.py             # Get portfolio handler
│   │   │   ├── list.py            # List portfolios handler
│   │   │   ├── update.py          # Update portfolio handler
│   │   │   └── delete.py          # Delete portfolio handler
│   │   ├── optimization/
│   │   │   ├── __init__.py        # Package initialization
│   │   │   ├── risk_parity.py     # Risk parity optimization handler
│   │   │   ├── hrp.py             # HRP optimization handler
│   │   │   └── efficient_frontier.py # Efficient frontier handler
│   │   ├── monte_carlo/
│   │   │   ├── __init__.py        # Package initialization
│   │   │   ├── simulate.py        # Monte Carlo simulation handler
│   │   │   └── analyze.py         # Simulation analysis handler
│   │   └── market_data/
│   │       ├── __init__.py        # Package initialization
│   │       ├── get_prices.py      # Get market prices handler
│   │       └── get_returns.py     # Get market returns handler
│   ├── lib/                       # Shared library code
│   │   ├── __init__.py            # Package initialization
│   │   ├── models/                # Data models
│   │   │   ├── __init__.py        # Package initialization
│   │   │   ├── portfolio.py       # Portfolio model
│   │   │   └── optimization.py    # Optimization model
│   │   ├── services/              # Business logic services
│   │   │   ├── __init__.py        # Package initialization
│   │   │   ├── portfolio_service.py  # Portfolio service
│   │   │   ├── optimization_service.py # Optimization service
│   │   │   └── market_service.py  # Market data service
│   │   ├── utils/                 # Utility functions
│   │   │   ├── __init__.py        # Package initialization
│   │   │   ├── validation.py      # Input validation
│   │   │   ├── response.py        # Response formatting
│   │   │   └── error_handler.py   # Error handling
│   │   └── db/                    # Database access
│   │       ├── __init__.py        # Package initialization
│   │       ├── dynamo_client.py   # DynamoDB client
│   │       └── s3_client.py       # S3 client
│   └── config/                    # Configuration
│       ├── __init__.py            # Package initialization
│       ├── constants.py           # Constants
│       └── settings.py            # Settings
├── tests/                         # Tests
│   ├── __init__.py                # Package initialization
│   ├── unit/                      # Unit tests
│   │   ├── __init__.py            # Package initialization
│   │   ├── functions/             # Function tests
│   │   ├── lib/                   # Library tests
│   │   └── utils/                 # Utility tests
│   └── integration/               # Integration tests
│       └── __init__.py            # Package initialization
├── scripts/                       # Utility scripts
│   ├── deploy.sh                  # Deployment script
│   ├── test.sh                    # Test script
│   └── local.sh                   # Local development script
└── docs/                          # Documentation
    ├── API.md                     # API documentation
    ├── DEPLOYMENT.md              # Deployment documentation
    └── DEVELOPMENT.md             # Development documentation
```

## Coding Standards

### Python Style Guide

We follow the [PEP 8](https://www.python.org/dev/peps/pep-0008/) style guide for Python code. Some key points:

- Use 4 spaces for indentation
- Use snake_case for variable and function names
- Use CamelCase for class names
- Maximum line length is 88 characters (using Black formatter)
- Use docstrings for all functions, classes, and modules

### Code Formatting

We use [Black](https://black.readthedocs.io/en/stable/) for code formatting:

```bash
# Install Black
pip install black

# Format code
black src/ tests/
```

### Type Hints

We use type hints for all functions and methods:

```python
def add_numbers(a: int, b: int) -> int:
    return a + b
```

### Documentation

We use docstrings for all functions, classes, and modules:

```python
def add_numbers(a: int, b: int) -> int:
    """
    Add two numbers together.

    Args:
        a: First number
        b: Second number

    Returns:
        int: Sum of a and b
    """
    return a + b
```

## Testing

### Unit Tests

We use [pytest](https://docs.pytest.org/en/stable/) for unit testing:

```bash
# Run all unit tests
python -m pytest tests/unit

# Or use the provided script
./scripts/test.sh --unit
```

### Integration Tests

We use [pytest](https://docs.pytest.org/en/stable/) for integration testing:

```bash
# Run all integration tests
python -m pytest tests/integration

# Or use the provided script
./scripts/test.sh --integration
```

### Test Coverage

We use [pytest-cov](https://pytest-cov.readthedocs.io/en/latest/) for test coverage:

```bash
# Run tests with coverage
python -m pytest --cov=src tests/

# Generate coverage report
python -m pytest --cov=src --cov-report=html tests/
```

## Working with AWS Resources

### DynamoDB

We use [boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html) to interact with DynamoDB:

```python
import boto3
from src.lib.db import dynamo_client

# Get an item from DynamoDB
item = dynamo_client.get_item("my-table", {"id": "123"})

# Put an item in DynamoDB
dynamo_client.put_item("my-table", {"id": "123", "name": "Test"})
```

For local development, you can use [DynamoDB Local](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html):

```bash
# Start DynamoDB Local
docker run -p 8000:8000 amazon/dynamodb-local

# Configure AWS CLI to use DynamoDB Local
aws configure set aws_access_key_id dummy
aws configure set aws_secret_access_key dummy
aws configure set region us-east-1

# Create a table
aws dynamodb create-table \
    --table-name my-table \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --endpoint-url http://localhost:8000
```

### S3

We use [boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html) to interact with S3:

```python
import boto3
from src.lib.db import s3_client

# Get an object from S3
obj = s3_client.get_object("my-bucket", "my-key")

# Put an object in S3
s3_client.put_object("my-bucket", "my-key", "my-data")
```

For local development, you can use [LocalStack](https://localstack.cloud/):

```bash
# Start LocalStack
docker run -p 4566:4566 localstack/localstack

# Configure AWS CLI to use LocalStack
aws configure set aws_access_key_id dummy
aws configure set aws_secret_access_key dummy
aws configure set region us-east-1

# Create a bucket
aws s3 mb s3://my-bucket --endpoint-url http://localhost:4566
```

## API Development

### Adding a New Endpoint

To add a new endpoint, you need to:

1. Create a new Lambda function handler in the appropriate directory
2. Add the function to the `template.yaml` file
3. Add the API event to the function in the `template.yaml` file
4. Add the endpoint to the API documentation in `docs/API.md`

Example:

```python
# src/functions/portfolios/get_by_name.py
import json
import logging
import os
from typing import Any, Dict

from src.lib.db import dynamo_client
from src.lib.models import portfolio as portfolio_model
from src.lib.utils import response

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get table name from environment variables
PORTFOLIO_TABLE = os.environ.get("PORTFOLIO_TABLE", "")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for getting a portfolio by name.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Getting portfolio by name")
    logger.info(f"Event: {json.dumps(event)}")

    try:
        # Get portfolio name from query parameters
        query_params = event.get("queryStringParameters", {}) or {}
        name = query_params.get("name")

        if not name:
            return response.bad_request("Portfolio name is required")

        # Get portfolios from DynamoDB
        portfolios = dynamo_client.scan_items(
            PORTFOLIO_TABLE,
            filter_expression="name = :name",
            expression_attribute_values={":name": name},
        )

        if not portfolios:
            return response.not_found("Portfolio", name)

        # Convert to Portfolio objects
        portfolio_objects = [
            portfolio_model.from_dict(item) for item in portfolios
        ]

        # Convert to dictionaries
        portfolio_dicts = [
            portfolio_model.to_dict(portfolio) for portfolio in portfolio_objects
        ]

        # Return success response
        return response.success(portfolio_dicts)

    except Exception as e:
        logger.error(f"Error getting portfolio by name: {str(e)}")
        return response.error(
            500, "INTERNAL_SERVER_ERROR", f"Error getting portfolio by name: {str(e)}"
        )
```

```yaml
# template.yaml
GetPortfolioByNameFunction:
  Type: AWS::Serverless::Function
  Properties:
    CodeUri: src/functions/portfolios/
    Handler: get_by_name.lambda_handler
    Role: !GetAtt LambdaExecutionRole.Arn
    Environment:
      Variables:
        PORTFOLIO_TABLE: !Ref PortfolioTable
    Events:
      ApiEvent:
        Type: Api
        Properties:
          RestApiId: !Ref StrategosApi
          Path: /portfolios/by-name
          Method: GET
```

### Error Handling

We use a standardized error response format:

```python
from src.lib.utils import response

# Return a bad request error
return response.bad_request("Invalid input")

# Return a validation error
return response.validation_error("Invalid portfolio data", ["Asset weights must sum to 1.0"])

# Return a not found error
return response.not_found("Portfolio", "123")

# Return an internal server error
return response.internal_server_error("Something went wrong")
```

### Input Validation

We use [Pydantic](https://pydantic-docs.helpmanual.io/) for input validation:

```python
from pydantic import BaseModel, Field, validator

class Portfolio(BaseModel):
    id: str
    name: str
    description: str = ""
    assets: Dict[str, float]

    @validator("assets")
    def validate_assets(cls, assets):
        if not assets:
            raise ValueError("Assets cannot be empty")
        
        total_weight = sum(assets.values())
        if abs(total_weight - 1.0) > 0.0001:
            raise ValueError(f"Asset weights must sum to 1.0, got {total_weight}")
        
        return assets
```

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions.

## Troubleshooting

### Common Issues

1. **SAM CLI not found**: Make sure you have installed the SAM CLI and it's in your PATH.

2. **Docker not running**: Make sure Docker is running for local development.

3. **AWS credentials not configured**: Make sure you have configured your AWS credentials.

4. **Import errors**: Make sure you have installed all dependencies.

5. **Lambda function timeout**: Increase the timeout in the `template.yaml` file.

6. **Lambda function memory limit**: Increase the memory allocation in the `template.yaml` file.

7. **API Gateway errors**: Check the CloudWatch Logs for the API Gateway.

8. **DynamoDB errors**: Check the CloudWatch Logs for the Lambda function.

### Debugging

You can use the SAM CLI to debug Lambda functions locally:

```bash
# Debug a Lambda function
sam local invoke -d 5858 ListPortfoliosFunction

# Debug an API endpoint
sam local start-api -d 5858
```

Then attach your debugger to port 5858.

## Contributing

### Branching Strategy

We use a simplified Git flow:

- `main`: Production-ready code
- `develop`: Development code
- Feature branches: `feature/feature-name`
- Bug fix branches: `bugfix/bug-name`
- Release branches: `release/version`

### Pull Requests

1. Create a new branch from `develop`
2. Make your changes
3. Run tests
4. Create a pull request to `develop`
5. Wait for code review
6. Merge to `develop`

### Code Reviews

All code must be reviewed before merging to `develop`. Code reviews should check:

- Code quality
- Test coverage
- Documentation
- Security
- Performance

## Resources

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Amazon API Gateway Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html)
- [Amazon DynamoDB Documentation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)
- [Amazon S3 Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
- [Python Documentation](https://docs.python.org/3/)
- [Pydantic Documentation](https://pydantic-docs.helpmanual.io/)
- [pytest Documentation](https://docs.pytest.org/en/stable/)
- [Black Documentation](https://black.readthedocs.io/en/stable/)
