"""
Get Market Prices Lambda Function

This function handles GET requests to the /market-data/prices endpoint.
"""

import json
import logging
import os
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

import pandas as pd
import requests
import yfinance as yf

from src.lib.utils import response

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get S3 bucket name from environment variables
DATA_BUCKET = os.environ.get("DATA_BUCKET", "")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for getting market prices.

    Args:
        event: Lambda event
        context: Lambda context

    Returns:
        Dict: API Gateway response
    """
    logger.info("Getting market prices")
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
        
        # Get interval
        interval = query_params.get("interval", "1d")
        
        # Validate parameters
        validation_errors = validate_parameters(symbols, start_date, end_date, interval)
        if validation_errors:
            return response.validation_error(
                "Invalid parameters", validation_errors
            )
        
        # Get market prices
        prices = get_market_prices(symbols, start_date, end_date, interval)
        
        # Return success response
        return response.success(prices)
        
    except Exception as e:
        logger.error(f"Error getting market prices: {str(e)}")
        return response.error(
            500, "INTERNAL_SERVER_ERROR", f"Error getting market prices: {str(e)}"
        )


def get_market_prices(
    symbols: List[str], start_date: str, end_date: str, interval: str
) -> Dict[str, Any]:
    """
    Get market prices for the specified symbols.

    Args:
        symbols: List of symbols
        start_date: Start date (YYYY-MM-DD)
        end_date: End date (YYYY-MM-DD)
        interval: Price interval (1d, 1wk, 1mo)

    Returns:
        Dict: Market prices
    """
    # Download data from Yahoo Finance
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
        
        # Convert to dictionary
        prices = {
            "dates": symbol_data.index.strftime("%Y-%m-%d").tolist(),
            "open": symbol_data["Open"].tolist(),
            "high": symbol_data["High"].tolist(),
            "low": symbol_data["Low"].tolist(),
            "close": symbol_data["Close"].tolist(),
            "volume": symbol_data["Volume"].tolist(),
        }
        
        result[symbol] = prices
    else:
        # Handle multiple symbols
        for symbol in symbols:
            if symbol in data.columns.levels[0]:
                symbol_data = data[symbol]
                
                # Convert to dictionary
                prices = {
                    "dates": symbol_data.index.strftime("%Y-%m-%d").tolist(),
                    "open": symbol_data["Open"].tolist(),
                    "high": symbol_data["High"].tolist(),
                    "low": symbol_data["Low"].tolist(),
                    "close": symbol_data["Close"].tolist(),
                    "volume": symbol_data["Volume"].tolist(),
                }
                
                result[symbol] = prices
    
    return result


def validate_parameters(
    symbols: List[str], start_date: str, end_date: str, interval: str
) -> List[str]:
    """
    Validate parameters.

    Args:
        symbols: List of symbols
        start_date: Start date
        end_date: End date
        interval: Price interval

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
    
    # Validate interval
    valid_intervals = ["1d", "1wk", "1mo"]
    if interval not in valid_intervals:
        errors.append(f"Invalid interval (should be one of {', '.join(valid_intervals)})")
    
    return errors
