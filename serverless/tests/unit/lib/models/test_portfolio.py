"""
Unit tests for the portfolio model.
"""

import pytest
from datetime import datetime
from src.lib.models.portfolio import Portfolio, create_portfolio, to_dict, from_dict


class TestPortfolio:
    """Test the Portfolio model."""

    def test_portfolio_creation(self):
        """Test creating a Portfolio object."""
        # Create a portfolio
        portfolio = Portfolio(
            name="Test Portfolio",
            description="Test Description",
            assets={"AAPL": 0.5, "MSFT": 0.5},
        )

        # Check attributes
        assert portfolio.name == "Test Portfolio"
        assert portfolio.description == "Test Description"
        assert portfolio.assets == {"AAPL": 0.5, "MSFT": 0.5}
        assert portfolio.id is not None
        assert portfolio.created_at is not None
        assert portfolio.updated_at is not None

    def test_portfolio_validation(self):
        """Test portfolio validation."""
        # Valid portfolio
        portfolio = Portfolio(
            name="Test Portfolio",
            description="Test Description",
            assets={"AAPL": 0.5, "MSFT": 0.5},
        )
        assert portfolio is not None

        # Invalid portfolio (assets don't sum to 1.0)
        with pytest.raises(ValueError):
            Portfolio(
                name="Test Portfolio",
                description="Test Description",
                assets={"AAPL": 0.5, "MSFT": 0.6},
            )

        # Invalid portfolio (empty assets)
        with pytest.raises(ValueError):
            Portfolio(
                name="Test Portfolio",
                description="Test Description",
                assets={},
            )

    def test_create_portfolio_function(self):
        """Test the create_portfolio function."""
        # Create a portfolio
        portfolio = create_portfolio(
            name="Test Portfolio",
            description="Test Description",
            assets={"AAPL": 0.5, "MSFT": 0.5},
        )

        # Check attributes
        assert portfolio.name == "Test Portfolio"
        assert portfolio.description == "Test Description"
        assert portfolio.assets == {"AAPL": 0.5, "MSFT": 0.5}
        assert portfolio.id is not None
        assert portfolio.created_at is not None
        assert portfolio.updated_at is not None

        # Create a portfolio with custom ID and timestamps
        custom_id = "test-id"
        created_at = "2025-01-01T00:00:00"
        updated_at = "2025-01-02T00:00:00"
        portfolio = create_portfolio(
            name="Test Portfolio",
            description="Test Description",
            assets={"AAPL": 0.5, "MSFT": 0.5},
            portfolio_id=custom_id,
            created_at=created_at,
            updated_at=updated_at,
        )

        # Check attributes
        assert portfolio.id == custom_id
        assert portfolio.created_at == created_at
        assert portfolio.updated_at == updated_at

    def test_to_dict_function(self):
        """Test the to_dict function."""
        # Create a portfolio
        portfolio = Portfolio(
            id="test-id",
            name="Test Portfolio",
            description="Test Description",
            assets={"AAPL": 0.5, "MSFT": 0.5},
            created_at="2025-01-01T00:00:00",
            updated_at="2025-01-02T00:00:00",
        )

        # Convert to dictionary
        portfolio_dict = to_dict(portfolio)

        # Check dictionary
        assert portfolio_dict["id"] == "test-id"
        assert portfolio_dict["name"] == "Test Portfolio"
        assert portfolio_dict["description"] == "Test Description"
        assert portfolio_dict["assets"] == {"AAPL": 0.5, "MSFT": 0.5}
        assert portfolio_dict["created_at"] == "2025-01-01T00:00:00"
        assert portfolio_dict["updated_at"] == "2025-01-02T00:00:00"

    def test_from_dict_function(self):
        """Test the from_dict function."""
        # Create a dictionary
        portfolio_dict = {
            "id": "test-id",
            "name": "Test Portfolio",
            "description": "Test Description",
            "assets": {"AAPL": 0.5, "MSFT": 0.5},
            "created_at": "2025-01-01T00:00:00",
            "updated_at": "2025-01-02T00:00:00",
        }

        # Convert to Portfolio object
        portfolio = from_dict(portfolio_dict)

        # Check attributes
        assert portfolio.id == "test-id"
        assert portfolio.name == "Test Portfolio"
        assert portfolio.description == "Test Description"
        assert portfolio.assets == {"AAPL": 0.5, "MSFT": 0.5}
        assert portfolio.created_at == "2025-01-01T00:00:00"
        assert portfolio.updated_at == "2025-01-02T00:00:00"
