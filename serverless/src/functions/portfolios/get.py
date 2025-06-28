"""
Get Portfolio Lambda Function

This function handles GET requests to the /portfolios/{id} endpoint.
"""

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
    AWS Lambda handler for getting a portfolio by ID.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Getting portfolio by ID")
    logger.info(f"Event: {json.dumps(event)}")

    try:
        # Get portfolio ID from path parameters
        path_parameters = event.get("pathParameters", {}) or {}
        portfolio_id = path_parameters.get("id")

        if not portfolio_id:
            return response.bad_request("Portfolio ID is required")

        # Get portfolio from DynamoDB
        portfolio_data = dynamo_client.query_by_id(PORTFOLIO_TABLE, portfolio_id)

        if not portfolio_data:
            return response.not_found("Portfolio", portfolio_id)

        # Convert to Portfolio object
        portfolio_obj = portfolio_model.from_dict(portfolio_data)

        # Convert to dictionary
        portfolio_dict = portfolio_model.to_dict(portfolio_obj)

        # Return success response
        return response.success(portfolio_dict)

    except Exception as e:
        logger.error(f"Error getting portfolio: {str(e)}")
        return response.error(
            500, "INTERNAL_SERVER_ERROR", f"Error getting portfolio: {str(e)}"
        )
