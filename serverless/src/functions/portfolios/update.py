"""
Update Portfolio Lambda Function

This function handles PUT requests to the /portfolios/{id} endpoint.
"""

import json
import logging
import os
from typing import Any, Dict, List, Optional

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
    AWS Lambda handler for updating a portfolio.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Updating portfolio")
    logger.info(f"Event: {json.dumps(event)}")

    try:
        # Get portfolio ID from path parameters
        path_parameters = event.get("pathParameters", {}) or {}
        portfolio_id = path_parameters.get("id")

        if not portfolio_id:
            return response.bad_request("Portfolio ID is required")

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

        # Get existing portfolio
        existing_portfolio = dynamo_client.query_by_id(PORTFOLIO_TABLE, portfolio_id)
        if not existing_portfolio:
            return response.not_found("Portfolio", portfolio_id)

        # Update portfolio
        try:
            # Create updated portfolio object
            updated_portfolio = portfolio_model.create_portfolio(
                name=body.get("name", existing_portfolio.get("name", "")),
                description=body.get("description", existing_portfolio.get("description", "")),
                assets=body.get("assets", existing_portfolio.get("assets", {})),
                portfolio_id=portfolio_id,
                created_at=existing_portfolio.get("created_at"),
            )
        except ValueError as e:
            return response.validation_error("Invalid portfolio data", [str(e)])

        # Convert to dictionary
        portfolio_dict = portfolio_model.to_dict(updated_portfolio)

        # Save to DynamoDB
        dynamo_client.put_item(PORTFOLIO_TABLE, portfolio_dict)

        # Return success response
        return response.success(portfolio_dict)

    except Exception as e:
        logger.error(f"Error updating portfolio: {str(e)}")
        return response.error(
            500, "INTERNAL_SERVER_ERROR", f"Error updating portfolio: {str(e)}"
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

    # Check if at least one field is provided
    if not body.get("name") and not body.get("description") and not body.get("assets"):
        errors.append("At least one field (name, description, assets) is required")

    # Check assets if provided
    assets = body.get("assets")
    if assets is not None:
        if not assets:
            errors.append("Assets cannot be empty")
        else:
            # Check asset weights
            try:
                total_weight = sum(assets.values())
                if abs(total_weight - 1.0) > 0.0001:
                    errors.append(f"Asset weights must sum to 1.0, got {total_weight}")
            except Exception:
                errors.append("Invalid asset weights")

    return errors
