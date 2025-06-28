"""
Get Market Returns Lambda Function

This function handles GET requests to the /market-data/returns endpoint.
"""

import json
import logging
import os
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

import numpy as np
import pandas as pd
import yfinance as yf

from src.lib.utils import response

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get S3 bucket name from environment variables
DATA_BUCKET = os.environ.get("DATA_BUCKET", "")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for getting market returns.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Getting market returns")
    logger.info(f"Event: {json.dumps(event)}")

    try:
        # Get query parameters
        query_params = event.get("queryStringParameters", {}) or {}
        
        # Get symbols
        symbols_param = query_params.get("symbols")
        if not symbols_param:
            return response.bad_request("Symbols parameter is required")
        
        symbols = symbols_param.split(",")
        
        # Get date range
        start_date = query_params.get("startDate")
        end_date = query_params.get("endDate", datetime.now().strftime("%Y-%m-%d"))
        
        if not start_date:
            # Default to 1 year ago if not provided
            start_date = (datetime.now() - timedelta(days=365)).strftime("%Y-%m-%d")
        
        # Get return type
        return_type = query_params.get("returnType", "daily")
        
        # Validate parameters
        validation_errors = validate_parameters(symbols, start_date, end_date, return_type)
        if validation_errors:
            return response.validation_error(
                "Invalid parameters", validation_errors
            )
        
        # Get market returns
        returns = get_market_returns(symbols, start_date, end_date, return_type)
        
        # Return success response
        return response.success(returns)
        
    except Exception as e:
        logger.error(f"Error getting market returns: {str(e)}")
        return response.error(
            500, "INTERNAL_SERVER_ERROR", f"Error getting market returns: {str(e)}"
        )


def get_market_returns(
    symbols: List[str], start_date: str, end_date: str, return_type: str
) -> Dict[str, Any]:
    """
    Get market returns for the specified symbols.

    Args:
        symbols: List of symbols
        start_date: Start date (YYYY-MM-DD)
        end_date: End date (YYYY-MM-DD)
        return_type: Return type (daily, weekly, monthly)

    Returns:
        Dict: Market returns
    """
    # Download data from Yahoo Finance
    interval = "1d"  # Always download daily data
    
    data = yf.download(
        tickers=symbols,
        start=start_date,
        end=end_date,
        interval=interval,
        group_by="ticker",
        auto_adjust=True,
        prepost=False,
        threads=True,
    )
    
    # Process data
    result = {}
    
    # Handle single symbol case
    if len(symbols) == 1:
        symbol = symbols[0]
        symbol_data = data
        
        # Calculate returns
        returns_data = calculate_returns(symbol_data, return_type)
        
        result[symbol] = returns_data
    else:
        # Handle multiple symbols
        for symbol in symbols:
            if symbol in data.columns.levels[0]:
                symbol_data = data[symbol]
                
                # Calculate returns
                returns_data = calculate_returns(symbol_data, return_type)
                
                result[symbol] = returns_data
    
    return result


def calculate_returns(data: pd.DataFrame, return_type: str) -> List[float]:
    """
    Calculate returns from price data.

    Args:
        data: Price data
        return_type: Return type (daily, weekly, monthly)

    Returns:
        List[float]: Returns
    """
    # Get close prices
    close_prices = data["Close"]
    
    # Calculate returns based on return type
    if return_type == "daily":
        returns = close_prices.pct_change().dropna().tolist()
    elif return_type == "weekly":
        # Resample to weekly and calculate returns
        weekly_prices = close_prices.resample("W").last()
        returns = weekly_prices.pct_change().dropna().tolist()
    elif return_type == "monthly":
        # Resample to monthly and calculate returns
        monthly_prices = close_prices.resample("M").last()
        returns = monthly_prices.pct_change().dropna().tolist()
    else:
        # Default to daily
        returns = close_prices.pct_change().dropna().tolist()
    
    # Convert numpy float64 to Python float
    returns = [float(r) for r in returns]
    
    return returns


def validate_parameters(
    symbols: List[str], start_date: str, end_date: str, return_type: str
) -> List[str]:
    """
    Validate parameters.

    Args:
        symbols: List of symbols
        start_date: Start date
        end_date: End date
        return_type: Return type

    Returns:
        List[str]: Validation errors
    """
    errors = []
    
    # Validate symbols
    if not symbols:
        errors.append("At least one symbol is required")
    
    # Validate dates
    try:
        start_dt = datetime.strptime(start_date, "%Y-%m-%d")
    except ValueError:
        errors.append("Invalid start date format (should be YYYY-MM-DD)")
    
    try:
        end_dt = datetime.strptime(end_date, "%Y-%m-%d")
    except ValueError:
        errors.append("Invalid end date format (should be YYYY-MM-DD)")
    
    if 'start_dt' in locals() and 'end_dt' in locals() and start_dt > end_dt:
        errors.append("Start date cannot be after end date")
    
    # Validate return type
    valid_return_types = ["daily", "weekly", "monthly"]
    if return_type not in valid_return_types:
        errors.append(f"Invalid return type (should be one of {', '.join(valid_return_types)})")
    
    return errors
