"""
Risk Parity Optimization Lambda Function

This function handles POST requests to the /optimization/risk-parity endpoint.
"""

import json
import logging
import os
import uuid
from datetime import datetime
from typing import Any, Dict, List

import numpy as np
from scipy.optimize import minimize

from src.lib.db import dynamo_client
from src.lib.utils import response

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get table names from environment variables
PORTFOLIO_TABLE = os.environ.get("PORTFOLIO_TABLE", "")
OPTIMIZATION_RESULT_TABLE = os.environ.get("OPTIMIZATION_RESULT_TABLE", "")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for risk parity optimization.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Running risk parity optimization")
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
                "Invalid optimization request", validation_errors
            )

        # Get portfolio ID
        portfolio_id = body.get("portfolioId")

        # Get portfolio
        portfolio = dynamo_client.query_by_id(PORTFOLIO_TABLE, portfolio_id)
        if not portfolio:
            return response.not_found("Portfolio", portfolio_id)

        # Get assets and returns
        assets = portfolio.get("assets", {})
        returns = body.get("returns", {})

        # Check if returns are provided for all assets
        missing_returns = [asset for asset in assets if asset not in returns]
        if missing_returns:
            return response.validation_error(
                "Missing returns data",
                [f"Returns data missing for assets: {', '.join(missing_returns)}"],
            )

        # Convert returns to numpy arrays
        asset_list = list(assets.keys())
        returns_matrix = []
        for asset in asset_list:
            returns_matrix.append(returns[asset])
        returns_matrix = np.array(returns_matrix)

        # Calculate covariance matrix
        cov_matrix = np.cov(returns_matrix)

        # Run risk parity optimization
        initial_weights = np.array([1.0 / len(asset_list)] * len(asset_list))
        bounds = [(0.0, 1.0) for _ in range(len(asset_list))]
        constraints = [{"type": "eq", "fun": lambda x: np.sum(x) - 1.0}]

        result = minimize(
            risk_parity_objective,
            initial_weights,
            args=(cov_matrix,),
            method="SLSQP",
            bounds=bounds,
            constraints=constraints,
            options={"disp": False, "maxiter": 1000},
        )

        # Check if optimization was successful
        if not result.success:
            return response.error(
                500,
                "OPTIMIZATION_ERROR",
                f"Optimization failed: {result.message}",
            )

        # Get optimized weights
        optimized_weights = result.x
        optimized_weights = optimized_weights / np.sum(optimized_weights)  # Normalize

        # Calculate risk contribution
        portfolio_variance = np.dot(optimized_weights.T, np.dot(cov_matrix, optimized_weights))
        portfolio_volatility = np.sqrt(portfolio_variance)
        marginal_contribution = np.dot(cov_matrix, optimized_weights)
        risk_contribution = np.multiply(marginal_contribution, optimized_weights) / portfolio_volatility

        # Create optimization result
        optimization_result = {
            "id": str(uuid.uuid4()),
            "portfolioId": portfolio_id,
            "type": "risk-parity",
            "parameters": {
                "method": "SLSQP",
                "maxIterations": 1000,
            },
            "result": {
                "weights": {asset: float(weight) for asset, weight in zip(asset_list, optimized_weights)},
                "metrics": {
                    "portfolioVolatility": float(portfolio_volatility),
                    "riskContribution": {
                        asset: float(contrib) for asset, contrib in zip(asset_list, risk_contribution)
                    },
                },
            },
            "createdAt": datetime.utcnow().isoformat(),
        }

        # Save optimization result to DynamoDB
        dynamo_client.put_item(OPTIMIZATION_RESULT_TABLE, optimization_result)

        # Return success response
        return response.success(optimization_result)

    except Exception as e:
        logger.error(f"Error running risk parity optimization: {str(e)}")
        return response.error(
            500,
            "INTERNAL_SERVER_ERROR",
            f"Error running risk parity optimization: {str(e)}",
        )


def risk_parity_objective(weights: np.ndarray, cov_matrix: np.ndarray) -> float:
    """
    Risk parity objective function.

    Args:
        weights: Asset weights
        cov_matrix: Covariance matrix

    Returns:
        float: Objective function value
    """
    portfolio_variance = np.dot(weights.T, np.dot(cov_matrix, weights))
    portfolio_volatility = np.sqrt(portfolio_variance)
    marginal_contribution = np.dot(cov_matrix, weights)
    risk_contribution = np.multiply(marginal_contribution, weights) / portfolio_volatility
    
    # Calculate the sum of squared differences between risk contributions
    risk_target = portfolio_volatility / len(weights)
    sum_sq_diff = np.sum(np.square(risk_contribution - risk_target))
    
    return sum_sq_diff


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
    if not body.get("portfolioId"):
        errors.append("Portfolio ID is required")

    # Check returns
    returns = body.get("returns")
    if not returns:
        errors.append("Returns data is required")
    elif not isinstance(returns, dict):
        errors.append("Returns data must be a dictionary")
    else:
        # Check returns format
        for asset, asset_returns in returns.items():
            if not isinstance(asset_returns, list):
                errors.append(f"Returns for asset {asset} must be a list")
            elif not all(isinstance(r, (int, float)) for r in asset_returns):
                errors.append(f"Returns for asset {asset} must be numeric")

    return errors
