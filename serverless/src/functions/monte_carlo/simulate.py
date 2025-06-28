"""
Monte Carlo Simulation Lambda Function

This function handles POST requests to the /monte-carlo/simulate endpoint.
"""

import json
import logging
import os
import uuid
from datetime import datetime
from typing import Any, Dict, List

import numpy as np

from src.lib.db import dynamo_client
from src.lib.utils import response

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get table names from environment variables
PORTFOLIO_TABLE = os.environ.get("PORTFOLIO_TABLE", "")
SIMULATION_RESULT_TABLE = os.environ.get("SIMULATION_RESULT_TABLE", "")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for Monte Carlo simulation.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Running Monte Carlo simulation")
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
                "Invalid simulation request", validation_errors
            )

        # Get portfolio ID
        portfolio_id = body.get("portfolioId")

        # Get portfolio
        portfolio = dynamo_client.query_by_id(PORTFOLIO_TABLE, portfolio_id)
        if not portfolio:
            return response.not_found("Portfolio", portfolio_id)

        # Get simulation parameters
        initial_investment = body.get("initialInvestment", 10000)
        num_simulations = body.get("numSimulations", 1000)
        num_periods = body.get("numPeriods", 252)  # Default to 1 year of trading days
        returns_data = body.get("returns", {})
        
        # Check if returns are provided for all assets
        assets = portfolio.get("assets", {})
        missing_returns = [asset for asset in assets if asset not in returns_data]
        if missing_returns:
            return response.validation_error(
                "Missing returns data",
                [f"Returns data missing for assets: {', '.join(missing_returns)}"],
            )

        # Convert returns to numpy arrays
        asset_list = list(assets.keys())
        returns_matrix = []
        for asset in asset_list:
            returns_matrix.append(returns_data[asset])
        returns_matrix = np.array(returns_matrix)

        # Calculate mean returns and covariance matrix
        mean_returns = np.mean(returns_matrix, axis=1)
        cov_matrix = np.cov(returns_matrix)

        # Get portfolio weights
        weights = np.array([assets[asset] for asset in asset_list])

        # Run Monte Carlo simulation
        simulation_results = run_monte_carlo_simulation(
            weights, mean_returns, cov_matrix, initial_investment, num_periods, num_simulations
        )

        # Calculate statistics
        final_values = simulation_results[:, -1]
        mean_final_value = np.mean(final_values)
        median_final_value = np.median(final_values)
        min_final_value = np.min(final_values)
        max_final_value = np.max(final_values)
        std_dev = np.std(final_values)
        
        # Calculate percentiles
        percentiles = {
            "5": float(np.percentile(final_values, 5)),
            "25": float(np.percentile(final_values, 25)),
            "50": float(np.percentile(final_values, 50)),
            "75": float(np.percentile(final_values, 75)),
            "95": float(np.percentile(final_values, 95)),
        }

        # Create simulation result
        simulation_result = {
            "id": str(uuid.uuid4()),
            "portfolioId": portfolio_id,
            "parameters": {
                "initialInvestment": initial_investment,
                "numSimulations": num_simulations,
                "numPeriods": num_periods,
            },
            "result": {
                "trajectories": simulation_results.tolist(),
                "statistics": {
                    "meanFinalValue": float(mean_final_value),
                    "medianFinalValue": float(median_final_value),
                    "minFinalValue": float(min_final_value),
                    "maxFinalValue": float(max_final_value),
                    "standardDeviation": float(std_dev),
                    "percentiles": percentiles,
                },
            },
            "createdAt": datetime.utcnow().isoformat(),
        }

        # Save simulation result to DynamoDB
        dynamo_client.put_item(SIMULATION_RESULT_TABLE, simulation_result)

        # Return success response
        return response.success(simulation_result)

    except Exception as e:
        logger.error(f"Error running Monte Carlo simulation: {str(e)}")
        return response.error(
            500,
            "INTERNAL_SERVER_ERROR",
            f"Error running Monte Carlo simulation: {str(e)}",
        )


def run_monte_carlo_simulation(
    weights: np.ndarray,
    mean_returns: np.ndarray,
    cov_matrix: np.ndarray,
    initial_investment: float,
    num_periods: int,
    num_simulations: int,
) -> np.ndarray:
    """
    Run Monte Carlo simulation.

    Args:
        weights: Portfolio weights
        mean_returns: Mean returns
        cov_matrix: Covariance matrix
        initial_investment: Initial investment
        num_periods: Number of periods
        num_simulations: Number of simulations

    Returns:
        np.ndarray: Simulation results
    """
    # Calculate portfolio mean and volatility
    portfolio_mean = np.sum(mean_returns * weights)
    portfolio_volatility = np.sqrt(np.dot(weights.T, np.dot(cov_matrix, weights)))

    # Initialize simulation results
    simulation_results = np.zeros((num_simulations, num_periods + 1))
    simulation_results[:, 0] = initial_investment

    # Run simulations
    for i in range(num_simulations):
        # Generate random returns
        random_returns = np.random.normal(
            portfolio_mean, portfolio_volatility, num_periods
        )

        # Calculate portfolio value over time
        for t in range(1, num_periods + 1):
            simulation_results[i, t] = simulation_results[i, t - 1] * (1 + random_returns[t - 1])

    return simulation_results


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

    # Check simulation parameters
    initial_investment = body.get("initialInvestment")
    if initial_investment is not None and (
        not isinstance(initial_investment, (int, float)) or initial_investment <= 0
    ):
        errors.append("Initial investment must be a positive number")

    num_simulations = body.get("numSimulations")
    if num_simulations is not None and (
        not isinstance(num_simulations, int) or num_simulations <= 0
    ):
        errors.append("Number of simulations must be a positive integer")

    num_periods = body.get("numPeriods")
    if num_periods is not None and (
        not isinstance(num_periods, int) or num_periods <= 0
    ):
        errors.append("Number of periods must be a positive integer")

    return errors
