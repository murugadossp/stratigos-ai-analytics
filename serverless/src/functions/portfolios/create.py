"""
Create Portfolio Lambda Function

This function handles POST requests to the /portfolios endpoint.
"""

import json
import logging
import os
from typing import Any, Dict, List

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
    AWS Lambda handler for creating a portfolio.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Creating portfolio")
    logger.info(f"Event: {json.dumps(event)}")

    try:
        # Parse request body
        body = event.get("body", "{}")
        if isinstance(body, str):
            body = json.loads(body)

        # Validate request body
        validation_errors = validate_request(body)
        if validation_errors:
            return response.validation_error(
                "Invalid portfolio data", validation_errors
            )

        # Create portfolio
        try:
            portfolio_obj = portfolio_model.create_portfolio(
                name=body.get("name", ""),
                description=body.get("description", ""),
                assets=body.get("assets", {}),
            )
        except ValueError as e:
            return response.validation_error("Invalid portfolio data", [str(e)])

        # Convert to dictionary
        portfolio_dict = portfolio_model.to_dict(portfolio_obj)

        # Save to DynamoDB
        dynamo_client.put_item(PORTFOLIO_TABLE, portfolio_dict)

        # Return success response
        return response.success(portfolio_dict, status_code=201)

    except Exception as e:
        logger.error(f"Error creating portfolio: {str(e)}")
        return response.error(
            500, "INTERNAL_SERVER_ERROR", f"Error creating portfolio: {str(e)}"
        )


def validate_request(body: Dict[str, Any]) -> List[str]:
    """
    Validate request body.

    Args:
        body: Request body

    Returns:
        List[str]: Validation errors
    """
    errors = []

    # Check required fields
    if not body.get("name"):
        errors.append("Name is required")

    # Check assets
    assets = body.get("assets", {})
    if not assets:
        errors.append("Assets are required")
    else:
        # Check asset weights
        try:
            total_weight = sum(assets.values())
            if abs(total_weight - 1.0) > 0.0001:
                errors.append(f"Asset weights must sum to 1.0, got {total_weight}")
        except Exception:
            errors.append("Invalid asset weights")

    return errors
