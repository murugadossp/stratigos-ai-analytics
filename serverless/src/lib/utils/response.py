"""
Response Utility

Provides utility functions for formatting API responses.
"""

import json
from typing import Any, Dict, List, Optional, Union


def success(
    data: Union[Dict[str, Any], List[Dict[str, Any]], None] = None,
    status_code: int = 200,
    headers: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """
    Create a success response.

    Args:
        data: Response data
        status_code: HTTP status code
        headers: Optional HTTP headers

    Returns:
        Dict: API Gateway response
    """
    # Default headers
    default_headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
    }

    # Merge headers
    response_headers = {**default_headers, **(headers or {})}

    # Create response
    response_body = data if data is not None else {}
    
    return {
        "statusCode": status_code,
        "headers": response_headers,
        "body": json.dumps(response_body),
    }


def error(
    status_code: int,
    error_code: str,
    message: str,
    details: Optional[List[str]] = None,
    headers: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """
    Create an error response.

    Args:
        status_code: HTTP status code
        error_code: Error code
        message: Error message
        details: Optional error details
        headers: Optional HTTP headers

    Returns:
        Dict: API Gateway response
    """
    # Default headers
    default_headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
    }

    # Merge headers
    response_headers = {**default_headers, **(headers or {})}

    # Create error response
    error_response = {
        "error": {
            "code": error_code,
            "message": message,
        }
    }

    # Add details if provided
    if details:
        error_response["error"]["details"] = details

    return {
        "statusCode": status_code,
        "headers": response_headers,
        "body": json.dumps(error_response),
    }


def not_found(
    resource_type: str, resource_id: str, headers: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Create a not found response.

    Args:
        resource_type: Resource type (e.g., "Portfolio")
        resource_id: Resource ID
        headers: Optional HTTP headers

    Returns:
        Dict: API Gateway response
    """
    return error(
        404,
        "NOT_FOUND",
        f"{resource_type} not found: {resource_id}",
        headers=headers,
    )


def bad_request(
    message: str, details: Optional[List[str]] = None, headers: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Create a bad request response.

    Args:
        message: Error message
        details: Optional error details
        headers: Optional HTTP headers

    Returns:
        Dict: API Gateway response
    """
    return error(400, "BAD_REQUEST", message, details=details, headers=headers)


def validation_error(
    message: str, details: List[str], headers: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Create a validation error response.

    Args:
        message: Error message
        details: Validation error details
        headers: Optional HTTP headers

    Returns:
        Dict: API Gateway response
    """
    return error(400, "VALIDATION_ERROR", message, details=details, headers=headers)


def internal_server_error(
    message: str = "Internal server error", headers: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Create an internal server error response.

    Args:
        message: Error message
        headers: Optional HTTP headers

    Returns:
        Dict: API Gateway response
    """
    return error(500, "INTERNAL_SERVER_ERROR", message, headers=headers)


def unauthorized(
    message: str = "Unauthorized", headers: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Create an unauthorized response.

    Args:
        message: Error message
        headers: Optional HTTP headers

    Returns:
        Dict: API Gateway response
    """
    return error(401, "UNAUTHORIZED", message, headers=headers)


def forbidden(
    message: str = "Forbidden", headers: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Create a forbidden response.

    Args:
        message: Error message
        headers: Optional HTTP headers

    Returns:
        Dict: API Gateway response
    """
    return error(403, "FORBIDDEN", message, headers=headers)
