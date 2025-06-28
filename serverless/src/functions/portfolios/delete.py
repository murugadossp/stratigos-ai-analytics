"""
Delete Portfolio Lambda Function

This function handles DELETE requests to the /portfolios/{id} endpoint.
"""

import json
import logging
import os
from typing import Any, Dict

from src.lib.db import dynamo_client
from src.lib.utils import response

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get table name from environment variables
PORTFOLIO_TABLE = os.environ.get("PORTFOLIO_TABLE", "")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for deleting a portfolio.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Deleting portfolio")
    logger.info(f"Event: {json.dumps(event)}")

    try:
        # Get portfolio ID from path parameters
        path_parameters = event.get("pathParameters", {}) or {}
        portfolio_id = path_parameters.get("id")

        if not portfolio_id:
            return response.bad_request("Portfolio ID is required")

        # Check if portfolio exists
        existing_portfolio = dynamo_client.query_by_id(PORTFOLIO_TABLE, portfolio_id)
        if not existing_portfolio:
            return response.not_found("Portfolio", portfolio_id)

        # Delete portfolio
        dynamo_client.delete_item(PORTFOLIO_TABLE, {"id": portfolio_id})

        # Return success response
        return response.success(None, status_code=204)

    except Exception as e:
        logger.error(f"Error deleting portfolio: {str(e)}")
        return response.error(
            500, "INTERNAL_SERVER_ERROR", f"Error deleting portfolio: {str(e)}"
        )
