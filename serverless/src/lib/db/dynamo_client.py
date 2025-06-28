"""
DynamoDB Client

Provides utility functions for interacting with DynamoDB.
"""

import os
from typing import Any, Dict, List, Optional, Union

import boto3
from boto3.dynamodb.conditions import Key


class DynamoDBClient:
    """Client for interacting with DynamoDB."""

    def __init__(self, table_name: str = None):
        """
        Initialize DynamoDB client.

        Args:
            table_name: Optional DynamoDB table name
        """
        self.dynamodb = boto3.resource("dynamodb")
        self.table_name = table_name
        self.table = self.dynamodb.Table(table_name) if table_name else None

    def set_table(self, table_name: str) -> None:
        """
        Set the table to use for operations.

        Args:
            table_name: DynamoDB table name
        """
        self.table_name = table_name
        self.table = self.dynamodb.Table(table_name)

    def get_item(self, key: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Get an item from DynamoDB.

        Args:
            key: Key object (e.g., {"id": "abc123"})

        Returns:
            Optional[Dict]: Item from DynamoDB or None if not found
        """
        if not self.table:
            raise ValueError("Table not set")

        response = self.table.get_item(Key=key)
        return response.get("Item")

    def put_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """
        Put an item in DynamoDB.

        Args:
            item: Item to put in DynamoDB

        Returns:
            Dict: Response from DynamoDB
        """
        if not self.table:
            raise ValueError("Table not set")

        response = self.table.put_item(Item=item)
        return response

    def update_item(
        self, key: Dict[str, Any], updates: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Update an item in DynamoDB.

        Args:
            key: Key object (e.g., {"id": "abc123"})
            updates: Updates to apply

        Returns:
            Dict: Updated item
        """
        if not self.table:
            raise ValueError("Table not set")

        # Build update expression and attribute values
        update_expressions = []
        expression_attribute_names = {}
        expression_attribute_values = {}

        for field, value in updates.items():
            attribute_name = f"#{field}"
            attribute_value = f":{field}"

            update_expressions.append(f"{attribute_name} = {attribute_value}")
            expression_attribute_names[attribute_name] = field
            expression_attribute_values[attribute_value] = value

        # Add updatedAt timestamp
        from datetime import datetime

        now = datetime.utcnow().isoformat()
        update_expressions.append("#updatedAt = :updatedAt")
        expression_attribute_names["#updatedAt"] = "updated_at"
        expression_attribute_values[":updatedAt"] = now

        response = self.table.update_item(
            Key=key,
            UpdateExpression=f"SET {', '.join(update_expressions)}",
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW",
        )

        return response.get("Attributes", {})

    def delete_item(self, key: Dict[str, Any]) -> Dict[str, Any]:
        """
        Delete an item from DynamoDB.

        Args:
            key: Key object (e.g., {"id": "abc123"})

        Returns:
            Dict: Response from DynamoDB
        """
        if not self.table:
            raise ValueError("Table not set")

        response = self.table.delete_item(Key=key)
        return response

    def query_items(
        self,
        key_condition_expression: Any,
        expression_attribute_values: Dict[str, Any] = None,
        index_name: str = None,
        limit: int = None,
        scan_index_forward: bool = True,
    ) -> List[Dict[str, Any]]:
        """
        Query items from DynamoDB.

        Args:
            key_condition_expression: Key condition expression
            expression_attribute_values: Expression attribute values
            index_name: Optional index name
            limit: Optional limit
            scan_index_forward: Optional scan direction

        Returns:
            List[Dict]: Items from DynamoDB
        """
        if not self.table:
            raise ValueError("Table not set")

        params: Dict[str, Any] = {
            "KeyConditionExpression": key_condition_expression,
        }

        if expression_attribute_values:
            params["ExpressionAttributeValues"] = expression_attribute_values

        if index_name:
            params["IndexName"] = index_name

        if limit:
            params["Limit"] = limit

        if scan_index_forward is not None:
            params["ScanIndexForward"] = scan_index_forward

        response = self.table.query(**params)
        return response.get("Items", [])

    def scan_items(
        self,
        filter_expression: Any = None,
        expression_attribute_values: Dict[str, Any] = None,
        limit: int = None,
    ) -> List[Dict[str, Any]]:
        """
        Scan items from DynamoDB.

        Args:
            filter_expression: Optional filter expression
            expression_attribute_values: Optional expression attribute values
            limit: Optional limit

        Returns:
            List[Dict]: Items from DynamoDB
        """
        if not self.table:
            raise ValueError("Table not set")

        params: Dict[str, Any] = {}

        if filter_expression:
            params["FilterExpression"] = filter_expression

        if expression_attribute_values:
            params["ExpressionAttributeValues"] = expression_attribute_values

        if limit:
            params["Limit"] = limit

        response = self.table.scan(**params)
        return response.get("Items", [])


# Create a singleton instance
dynamo_client = DynamoDBClient()


def get_table_name(table_key: str) -> str:
    """
    Get the full table name from environment variables.

    Args:
        table_key: Table key (e.g., "PORTFOLIO_TABLE")

    Returns:
        str: Full table name
    """
    return os.environ.get(table_key, "")


def get_item(table_name: str, key: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Get an item from DynamoDB.

    Args:
        table_name: DynamoDB table name
        key: Key object (e.g., {"id": "abc123"})

    Returns:
        Optional[Dict]: Item from DynamoDB or None if not found
    """
    dynamo_client.set_table(table_name)
    return dynamo_client.get_item(key)


def put_item(table_name: str, item: Dict[str, Any]) -> Dict[str, Any]:
    """
    Put an item in DynamoDB.

    Args:
        table_name: DynamoDB table name
        item: Item to put in DynamoDB

    Returns:
        Dict: Response from DynamoDB
    """
    dynamo_client.set_table(table_name)
    return dynamo_client.put_item(item)


def update_item(
    table_name: str, key: Dict[str, Any], updates: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Update an item in DynamoDB.

    Args:
        table_name: DynamoDB table name
        key: Key object (e.g., {"id": "abc123"})
        updates: Updates to apply

    Returns:
        Dict: Updated item
    """
    dynamo_client.set_table(table_name)
    return dynamo_client.update_item(key, updates)


def delete_item(table_name: str, key: Dict[str, Any]) -> Dict[str, Any]:
    """
    Delete an item from DynamoDB.

    Args:
        table_name: DynamoDB table name
        key: Key object (e.g., {"id": "abc123"})

    Returns:
        Dict: Response from DynamoDB
    """
    dynamo_client.set_table(table_name)
    return dynamo_client.delete_item(key)


def query_items(
    table_name: str,
    key_condition_expression: Any,
    expression_attribute_values: Dict[str, Any] = None,
    index_name: str = None,
    limit: int = None,
    scan_index_forward: bool = True,
) -> List[Dict[str, Any]]:
    """
    Query items from DynamoDB.

    Args:
        table_name: DynamoDB table name
        key_condition_expression: Key condition expression
        expression_attribute_values: Expression attribute values
        index_name: Optional index name
        limit: Optional limit
        scan_index_forward: Optional scan direction

    Returns:
        List[Dict]: Items from DynamoDB
    """
    dynamo_client.set_table(table_name)
    return dynamo_client.query_items(
        key_condition_expression,
        expression_attribute_values,
        index_name,
        limit,
        scan_index_forward,
    )


def scan_items(
    table_name: str,
    filter_expression: Any = None,
    expression_attribute_values: Dict[str, Any] = None,
    limit: int = None,
) -> List[Dict[str, Any]]:
    """
    Scan items from DynamoDB.

    Args:
        table_name: DynamoDB table name
        filter_expression: Optional filter expression
        expression_attribute_values: Optional expression attribute values
        limit: Optional limit

    Returns:
        List[Dict]: Items from DynamoDB
    """
    dynamo_client.set_table(table_name)
    return dynamo_client.scan_items(
        filter_expression, expression_attribute_values, limit
    )


def query_by_id(table_name: str, item_id: str) -> Optional[Dict[str, Any]]:
    """
    Query an item by ID.

    Args:
        table_name: DynamoDB table name
        item_id: Item ID

    Returns:
        Optional[Dict]: Item from DynamoDB or None if not found
    """
    return get_item(table_name, {"id": item_id})


def query_by_portfolio_id(
    table_name: str, portfolio_id: str, index_name: str = "ByPortfolio"
) -> List[Dict[str, Any]]:
    """
    Query items by portfolio ID.

    Args:
        table_name: DynamoDB table name
        portfolio_id: Portfolio ID
        index_name: Index name (default: "ByPortfolio")

    Returns:
        List[Dict]: Items from DynamoDB
    """
    dynamo_client.set_table(table_name)
    return dynamo_client.query_items(
        Key("portfolioId").eq(portfolio_id),
        expression_attribute_values=None,
        index_name=index_name,
    )
