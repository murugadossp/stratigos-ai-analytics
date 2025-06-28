"""
List Portfolios Lambda Function

This function handles GET requests to the /portfolios endpoint.
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
    AWS Lambda handler for listing portfolios.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Listing portfolios")
    logger.info(f"Event: {json.dumps(event)}")

    try:
        # Get query parameters
        query_params = event.get("queryStringParameters", {}) or {}
        limit = int(query_params.get("limit", 100))

        # Get portfolios from DynamoDB
        portfolios = dynamo_client.scan_items(PORTFOLIO_TABLE, limit=limit)

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
        logger.error(f"Error listing portfolios: {str(e)}")
        return response.error(
            500, "INTERNAL_SERVER_ERROR", f"Error listing portfolios: {str(e)}"
        )
