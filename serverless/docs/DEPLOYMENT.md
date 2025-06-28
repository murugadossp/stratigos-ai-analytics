# Stratigos AI Platform - Deployment Guide

This document provides detailed instructions for deploying the Stratigos AI Platform to AWS using the Serverless Application Model (SAM).

## Prerequisites

Before deploying the Stratigos AI Platform, ensure you have the following prerequisites:

1. **AWS Account**: You need an AWS account with appropriate permissions to create and manage the following resources:
   - AWS Lambda
   - Amazon API Gateway
   - Amazon DynamoDB
   - Amazon S3
   - AWS CloudFormation
   - AWS IAM

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

4. **Python 3.11**: Install Python 3.11 or later.
   ```bash
   # Check Python version
   python --version
   ```

5. **Git**: Install Git for version control.
   ```bash
   # Check Git version
   git --version
   ```

## Deployment Steps

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/stratigos-ai-platform-serverless.git
cd stratigos-ai-platform-serverless
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Build the Project

The SAM CLI builds the application using Docker containers that simulate the Lambda execution environment.

```bash
sam build
```

### 4. Deploy the Project

You can deploy the project using the guided deployment process:

```bash
sam deploy --guided
```

This will prompt you for the following information:
- **Stack Name**: The name of the CloudFormation stack (e.g., `stratigos-ai-platform-dev`)
- **AWS Region**: The AWS region to deploy to (e.g., `us-east-1`)
- **Environment**: The deployment environment (e.g., `dev`, `staging`, `prod`)
- **Confirm changes before deploy**: Whether to confirm changes before deployment
- **Allow SAM CLI IAM role creation**: Whether to allow SAM CLI to create IAM roles
- **Save arguments to samconfig.toml**: Whether to save the deployment configuration

Alternatively, you can use the provided deployment scripts for a more streamlined process:

```bash
# Create Lambda layers (run once per environment)
./scripts/create-layers.sh dev us-east-1

# Deploy the infrastructure
./scripts/deploy-infrastructure.sh dev us-east-1
```

### 5. Verify Deployment

After deployment, you can verify that the resources were created correctly:

```bash
# List CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Describe the stack
aws cloudformation describe-stacks --stack-name stratigos-ai-platform

# Get the API Gateway endpoint
aws cloudformation describe-stacks --stack-name stratigos-ai-platform --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text
```

## Environment-Specific Deployments

### Development Environment

```bash
sam deploy --parameter-overrides Environment=dev
```

### Staging Environment

```bash
sam deploy --parameter-overrides Environment=staging
```

### Production Environment

```bash
sam deploy --parameter-overrides Environment=prod
```

## Continuous Integration/Continuous Deployment (CI/CD)

You can set up CI/CD for the Stratigos AI Platform using GitHub Actions. Here's an example workflow:

1. Create a `.github/workflows/deploy.yml` file:

```yaml
name: Deploy

on:
  push:
    branches:
      - main
      - develop

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.11'
      - uses: aws-actions/setup-sam@v1
      - uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Build
        run: sam build

      - name: Deploy (develop)
        if: github.ref == 'refs/heads/develop'
        run: sam deploy --parameter-overrides Environment=dev --no-confirm-changeset --no-fail-on-empty-changeset

      - name: Deploy (main)
        if: github.ref == 'refs/heads/main'
        run: sam deploy --parameter-overrides Environment=prod --no-confirm-changeset --no-fail-on-empty-changeset
```

2. Add the following secrets to your GitHub repository:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key ID
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key

## Monitoring and Logging

### CloudWatch Logs

All Lambda functions log to CloudWatch Logs. You can view the logs in the AWS Management Console or using the AWS CLI:

```bash
# Get the log group name
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/stratigos-ai-platform

# Get the log streams
aws logs describe-log-streams --log-group-name /aws/lambda/stratigos-ai-platform-ListPortfoliosFunction-XXXXXXXXXXXX

# Get the log events
aws logs get-log-events --log-group-name /aws/lambda/stratigos-ai-platform-ListPortfoliosFunction-XXXXXXXXXXXX --log-stream-name 2025/06/28/[$LATEST]XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### CloudWatch Metrics

You can monitor the performance of your Lambda functions using CloudWatch Metrics:

```bash
# Get Lambda function metrics
aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Invocations --dimensions Name=FunctionName,Value=stratigos-ai-platform-ListPortfoliosFunction-XXXXXXXXXXXX --start-time 2025-06-28T00:00:00Z --end-time 2025-06-28T23:59:59Z --period 3600 --statistics Sum
```

### X-Ray Tracing

You can enable X-Ray tracing for your Lambda functions to trace requests through your application:

```yaml
# In template.yaml
Globals:
  Function:
    Tracing: Active
```

## Troubleshooting

### Common Issues

1. **Deployment Fails**: If deployment fails, check the CloudFormation events:

```bash
aws cloudformation describe-stack-events --stack-name stratigos-ai-platform-dev
```

2. **Lambda Function Errors**: If a Lambda function is failing, check the CloudWatch Logs:

```bash
aws logs get-log-events --log-group-name /aws/lambda/stratigos-ai-platform-ListPortfoliosFunction-XXXXXXXXXXXX --log-stream-name 2025/06/28/[$LATEST]XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

3. **API Gateway Errors**: If the API Gateway is returning errors, check the CloudWatch Logs for the API Gateway:

```bash
aws logs get-log-events --log-group-name API-Gateway-Execution-Logs_XXXXXXXXXX/dev
```

4. **Lambda Layer Size Limit Exceeded**: If you encounter an error like "Layers consume more than the available size of 262144000 bytes", reduce the number of layers attached to each function in `template.yaml` by removing non-essential layers from functions that don't require them.

5. **Stack in ROLLBACK_COMPLETE State**: If the stack is in a `ROLLBACK_COMPLETE` state and cannot be updated, delete the stack first before redeploying:

```bash
aws cloudformation delete-stack --stack-name stratigos-ai-platform-dev
```

### Rollback

If you need to rollback to a previous version, you can use the CloudFormation rollback feature:

```bash
aws cloudformation rollback-stack --stack-name stratigos-ai-platform
```

## Cleanup

To remove all resources created by the deployment, you can delete the CloudFormation stack:

```bash
aws cloudformation delete-stack --stack-name stratigos-ai-platform
```

## Security Considerations

### API Keys

The API uses API keys for authentication. You can create and manage API keys in the API Gateway console or using the AWS CLI:

```bash
# Create an API key
aws apigateway create-api-key --name StrategosApiKey --enabled

# Get the API key ID
aws apigateway get-api-keys --name-query StrategosApiKey --include-values

# Create a usage plan
aws apigateway create-usage-plan --name StrategosUsagePlan --api-stages apiId=XXXXXXXXXX,stage=dev

# Add the API key to the usage plan
aws apigateway create-usage-plan-key --usage-plan-id XXXXXXXXXX --key-id XXXXXXXXXX --key-type API_KEY
```

### IAM Roles

The Lambda functions use IAM roles to access AWS resources. You can view and manage these roles in the IAM console or using the AWS CLI:

```bash
# List IAM roles
aws iam list-roles --query "Roles[?contains(RoleName, 'stratigos-ai-platform')]"

# Get IAM role details
aws iam get-role --role-name stratigos-ai-platform-LambdaExecutionRole-XXXXXXXXXXXX
```

### Encryption

DynamoDB tables and S3 buckets are encrypted at rest using AWS managed keys. You can view and manage these keys in the KMS console or using the AWS CLI:

```bash
# List KMS keys
aws kms list-keys

# Describe KMS key
aws kms describe-key --key-id XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

## Additional Resources

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Amazon API Gateway Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html)
- [Amazon DynamoDB Documentation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)
- [Amazon S3 Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
