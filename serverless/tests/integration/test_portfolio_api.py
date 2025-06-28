"""
Integration tests for the portfolio API.
"""

import json
import os
import pytest
import boto3
from moto import mock_dynamodb

# Import Lambda functions
from src.functions.portfolios.list import lambda_handler as list_handler
from src.functions.portfolios.get import lambda_handler as get_handler
from src.functions.portfolios.create import lambda_handler as create_handler
from src.functions.portfolios.update import lambda_handler as update_handler
from src.functions.portfolios.delete import lambda_handler as delete_handler


@pytest.fixture
def dynamodb_table():
    """Create a mock DynamoDB table for testing."""
    with mock_dynamodb():
        # Create DynamoDB client
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        
        # Create table
        table_name = "test-portfolios"
        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[
                {"AttributeName": "id", "KeyType": "HASH"},
            ],
            AttributeDefinitions=[
                {"AttributeName": "id", "AttributeType": "S"},
            ],
            ProvisionedThroughput={"ReadCapacityUnits": 5, "WriteCapacityUnits": 5},
        )
        
        # Set environment variable
        os.environ["PORTFOLIO_TABLE"] = table_name
        
        yield table
        
        # Clean up
        table.delete()
        if "PORTFOLIO_TABLE" in os.environ:
            del os.environ["PORTFOLIO_TABLE"]


class TestPortfolioAPI:
    """Integration tests for the portfolio API."""

    def test_create_portfolio(self, dynamodb_table):
        """Test creating a portfolio."""
        # Create event
        event = {
            "body": json.dumps({
                "name": "Test Portfolio",
                "description": "Test Description",
                "assets": {"AAPL": 0.5, "MSFT": 0.5},
            })
        }
        
        # Call Lambda function
        response = create_handler(event, {})
        
        # Check response
        assert response["statusCode"] == 201
        body = json.loads(response["body"])
        assert body["name"] == "Test Portfolio"
        assert body["description"] == "Test Description"
        assert body["assets"] == {"AAPL": 0.5, "MSFT": 0.5}
        assert "id" in body
        assert "created_at" in body
        assert "updated_at" in body
        
        # Save portfolio ID for later tests
        portfolio_id = body["id"]
        
        # Check DynamoDB
        item = dynamodb_table.get_item(Key={"id": portfolio_id})
        assert "Item" in item
        assert item["Item"]["name"] == "Test Portfolio"
        
        return portfolio_id

    def test_get_portfolio(self, dynamodb_table):
        """Test getting a portfolio."""
        # Create a portfolio first
        portfolio_id = self.test_create_portfolio(dynamodb_table)
        
        # Create event
        event = {
            "pathParameters": {
                "id": portfolio_id
            }
        }
        
        # Call Lambda function
        response = get_handler(event, {})
        
        # Check response
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["id"] == portfolio_id
        assert body["name"] == "Test Portfolio"
        assert body["description"] == "Test Description"
        assert body["assets"] == {"AAPL": 0.5, "MSFT": 0.5}

    def test_list_portfolios(self, dynamodb_table):
        """Test listing portfolios."""
        # Create a portfolio first
        portfolio_id = self.test_create_portfolio(dynamodb_table)
        
        # Create event
        event = {}
        
        # Call Lambda function
        response = list_handler(event, {})
        
        # Check response
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert isinstance(body, list)
        assert len(body) >= 1
        
        # Find our portfolio
        portfolio = next((p for p in body if p["id"] == portfolio_id), None)
        assert portfolio is not None
        assert portfolio["name"] == "Test Portfolio"

    def test_update_portfolio(self, dynamodb_table):
        """Test updating a portfolio."""
        # Create a portfolio first
        portfolio_id = self.test_create_portfolio(dynamodb_table)
        
        # Create event
        event = {
            "pathParameters": {
                "id": portfolio_id
            },
            "body": json.dumps({
                "name": "Updated Portfolio",
                "assets": {"AAPL": 0.3, "MSFT": 0.3, "GOOGL": 0.4},
            })
        }
        
        # Call Lambda function
        response = update_handler(event, {})
        
        # Check response
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["id"] == portfolio_id
        assert body["name"] == "Updated Portfolio"
        assert body["description"] == "Test Description"  # Unchanged
        assert body["assets"] == {"AAPL": 0.3, "MSFT": 0.3, "GOOGL": 0.4}
        
        # Check DynamoDB
        item = dynamodb_table.get_item(Key={"id": portfolio_id})
        assert "Item" in item
        assert item["Item"]["name"] == "Updated Portfolio"

    def test_delete_portfolio(self, dynamodb_table):
        """Test deleting a portfolio."""
        # Create a portfolio first
        portfolio_id = self.test_create_portfolio(dynamodb_table)
        
        # Create event
        event = {
            "pathParameters": {
                "id": portfolio_id
            }
        }
        
        # Call Lambda function
        response = delete_handler(event, {})
        
        # Check response
        assert response["statusCode"] == 204
        
        # Check DynamoDB
        item = dynamodb_table.get_item(Key={"id": portfolio_id})
        assert "Item" not in item

    def test_get_nonexistent_portfolio(self, dynamodb_table):
        """Test getting a nonexistent portfolio."""
        # Create event
        event = {
            "pathParameters": {
                "id": "nonexistent-id"
            }
        }
        
        # Call Lambda function
        response = get_handler(event, {})
        
        # Check response
        assert response["statusCode"] == 404
        body = json.loads(response["body"])
        assert "error" in body
        assert body["error"]["code"] == "NOT_FOUND"
