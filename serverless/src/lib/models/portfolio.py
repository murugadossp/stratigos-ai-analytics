"""
Portfolio Model

Defines the structure and validation for portfolio objects.
"""

import uuid
from datetime import datetime
from typing import Dict, Optional

from pydantic import BaseModel, Field, field_validator


class Portfolio(BaseModel):
    """Portfolio model for investment portfolios."""

    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: str = ""
    assets: Dict[str, float]
    created_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())

    @field_validator("assets")
    @classmethod
    def validate_assets(cls, assets: Dict[str, float]) -> Dict[str, float]:
        """Validate that asset weights sum to 1.0."""
        if not assets:
            raise ValueError("Assets cannot be empty")

        # Validate asset tickers
        for ticker in assets.keys():
            if not isinstance(ticker, str) or len(ticker) > 10:
                raise ValueError(f"Invalid ticker: {ticker}")

        # Validate asset weights
        for ticker, weight in assets.items():
            if not isinstance(weight, (int, float)) or weight < 0 or weight > 1:
                raise ValueError(f"Invalid weight for {ticker}: {weight}")

        # Validate that weights sum to 1.0
        total_weight = sum(assets.values())
        if abs(total_weight - 1.0) > 0.0001:
            raise ValueError(f"Asset weights must sum to 1.0, got {total_weight}")

        return assets


def create_portfolio(
    name: str,
    assets: Dict[str, float],
    description: str = "",
    portfolio_id: Optional[str] = None,
    created_at: Optional[str] = None,
    updated_at: Optional[str] = None,
) -> Portfolio:
    """
    Create a new portfolio object.

    Args:
        name: Portfolio name
        assets: Dictionary of assets and their weights
        description: Portfolio description
        portfolio_id: Optional portfolio ID (generated if not provided)
        created_at: Optional creation timestamp (generated if not provided)
        updated_at: Optional update timestamp (generated if not provided)

    Returns:
        Portfolio: A new Portfolio object
    """
    now = datetime.utcnow().isoformat()
    return Portfolio(
        id=portfolio_id or str(uuid.uuid4()),
        name=name,
        description=description,
        assets=assets,
        created_at=created_at or now,
        updated_at=updated_at or now,
    )


def to_dict(portfolio: Portfolio) -> Dict:
    """
    Convert a Portfolio object to a dictionary.

    Args:
        portfolio: Portfolio object

    Returns:
        Dict: Dictionary representation of the portfolio
    """
    return portfolio.model_dump()


def from_dict(data: Dict) -> Portfolio:
    """
    Create a Portfolio object from a dictionary.

    Args:
        data: Dictionary representation of a portfolio

    Returns:
        Portfolio: Portfolio object
    """
    return Portfolio(**data)
