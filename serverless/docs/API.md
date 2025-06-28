# Stratigos AI Platform - API Documentation

This document provides detailed information about the Stratigos AI Platform API.

## Base URL

The base URL for the API depends on your deployment environment:

- **Development**: `http://localhost:3000`
- **Production**: `https://[api-id].execute-api.[region].amazonaws.com/[stage]`

## Authentication

The API uses API keys for authentication. You must include the API key in the `x-api-key` header for all requests.

```
x-api-key: your-api-key
```

## Response Format

All API responses are in JSON format and follow a standard structure:

### Success Response

```json
{
  "id": "p-123456",
  "name": "Tech Concentrated",
  "description": "Technology-focused portfolio with high concentration",
  "assets": {
    "AAPL": 0.25,
    "MSFT": 0.25,
    "GOOGL": 0.20,
    "AMZN": 0.20,
    "META": 0.10
  },
  "createdAt": "2025-06-28T12:34:56Z",
  "updatedAt": "2025-06-28T12:34:56Z"
}
```

### Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid portfolio format",
    "details": [
      "Asset weights must sum to 1.0"
    ]
  }
}
```

## Endpoints

### Portfolio Management

#### List Portfolios

```
GET /portfolios
```

Returns a list of all portfolios.

**Query Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| limit | integer | Maximum number of portfolios to return (default: 100) |

**Response**

```json
[
  {
    "id": "p-123456",
    "name": "Tech Concentrated",
    "description": "Technology-focused portfolio with high concentration",
    "assets": {
      "AAPL": 0.25,
      "MSFT": 0.25,
      "GOOGL": 0.20,
      "AMZN": 0.20,
      "META": 0.10
    },
    "createdAt": "2025-06-28T12:34:56Z",
    "updatedAt": "2025-06-28T12:34:56Z"
  },
  {
    "id": "p-789012",
    "name": "Balanced Portfolio",
    "description": "Diversified across sectors",
    "assets": {
      "SPY": 0.40,
      "QQQ": 0.20,
      "VTI": 0.20,
      "AGG": 0.10,
      "GLD": 0.10
    },
    "createdAt": "2025-06-28T12:34:56Z",
    "updatedAt": "2025-06-28T12:34:56Z"
  }
]
```

#### Get Portfolio

```
GET /portfolios/{id}
```

Returns a specific portfolio by ID.

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | Portfolio ID |

**Response**

```json
{
  "id": "p-123456",
  "name": "Tech Concentrated",
  "description": "Technology-focused portfolio with high concentration",
  "assets": {
    "AAPL": 0.25,
    "MSFT": 0.25,
    "GOOGL": 0.20,
    "AMZN": 0.20,
    "META": 0.10
  },
  "createdAt": "2025-06-28T12:34:56Z",
  "updatedAt": "2025-06-28T12:34:56Z"
}
```

#### Create Portfolio

```
POST /portfolios
```

Creates a new portfolio.

**Request Body**

```json
{
  "name": "Tech Concentrated",
  "description": "Technology-focused portfolio with high concentration",
  "assets": {
    "AAPL": 0.25,
    "MSFT": 0.25,
    "GOOGL": 0.20,
    "AMZN": 0.20,
    "META": 0.10
  }
}
```

**Response**

```json
{
  "id": "p-123456",
  "name": "Tech Concentrated",
  "description": "Technology-focused portfolio with high concentration",
  "assets": {
    "AAPL": 0.25,
    "MSFT": 0.25,
    "GOOGL": 0.20,
    "AMZN": 0.20,
    "META": 0.10
  },
  "createdAt": "2025-06-28T12:34:56Z",
  "updatedAt": "2025-06-28T12:34:56Z"
}
```

#### Update Portfolio

```
PUT /portfolios/{id}
```

Updates an existing portfolio.

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | Portfolio ID |

**Request Body**

```json
{
  "name": "Updated Tech Portfolio",
  "assets": {
    "AAPL": 0.30,
    "MSFT": 0.30,
    "GOOGL": 0.20,
    "AMZN": 0.10,
    "META": 0.10
  }
}
```

**Response**

```json
{
  "id": "p-123456",
  "name": "Updated Tech Portfolio",
  "description": "Technology-focused portfolio with high concentration",
  "assets": {
    "AAPL": 0.30,
    "MSFT": 0.30,
    "GOOGL": 0.20,
    "AMZN": 0.10,
    "META": 0.10
  },
  "createdAt": "2025-06-28T12:34:56Z",
  "updatedAt": "2025-06-28T12:45:00Z"
}
```

#### Delete Portfolio

```
DELETE /portfolios/{id}
```

Deletes a portfolio.

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | Portfolio ID |

**Response**

```
204 No Content
```

### Portfolio Optimization

#### Risk Parity Optimization

```
POST /optimization/risk-parity
```

Performs risk parity optimization on a portfolio.

**Request Body**

```json
{
  "portfolioId": "p-123456",
  "returns": {
    "AAPL": [0.01, 0.02, -0.01, 0.03, -0.02],
    "MSFT": [0.02, 0.01, -0.02, 0.02, -0.01],
    "GOOGL": [0.03, -0.01, 0.01, 0.02, -0.03],
    "AMZN": [0.02, -0.02, 0.03, 0.01, -0.01],
    "META": [0.01, 0.03, -0.03, 0.02, -0.02]
  }
}
```

**Response**

```json
{
  "id": "o-123456",
  "portfolioId": "p-123456",
  "type": "risk-parity",
  "parameters": {
    "method": "SLSQP",
    "maxIterations": 1000
  },
  "result": {
    "weights": {
      "AAPL": 0.18,
      "MSFT": 0.22,
      "GOOGL": 0.15,
      "AMZN": 0.25,
      "META": 0.20
    },
    "metrics": {
      "portfolioVolatility": 0.12,
      "riskContribution": {
        "AAPL": 0.024,
        "MSFT": 0.024,
        "GOOGL": 0.024,
        "AMZN": 0.024,
        "META": 0.024
      }
    }
  },
  "createdAt": "2025-06-28T12:34:56Z"
}
```

#### Hierarchical Risk Parity Optimization

```
POST /optimization/hrp
```

Performs hierarchical risk parity optimization on a portfolio.

**Request Body**

```json
{
  "portfolioId": "p-123456",
  "returns": {
    "AAPL": [0.01, 0.02, -0.01, 0.03, -0.02],
    "MSFT": [0.02, 0.01, -0.02, 0.02, -0.01],
    "GOOGL": [0.03, -0.01, 0.01, 0.02, -0.03],
    "AMZN": [0.02, -0.02, 0.03, 0.01, -0.01],
    "META": [0.01, 0.03, -0.03, 0.02, -0.02]
  }
}
```

**Response**

```json
{
  "id": "o-789012",
  "portfolioId": "p-123456",
  "type": "hrp",
  "parameters": {
    "linkage": "single",
    "metric": "euclidean"
  },
  "result": {
    "weights": {
      "AAPL": 0.20,
      "MSFT": 0.25,
      "GOOGL": 0.15,
      "AMZN": 0.20,
      "META": 0.20
    },
    "metrics": {
      "portfolioVolatility": 0.11,
      "clusterTree": [
        [0, 1],
        [2, 3],
        [4, 5]
      ]
    }
  },
  "createdAt": "2025-06-28T12:34:56Z"
}
```

#### Efficient Frontier

```
POST /optimization/efficient-frontier
```

Generates the efficient frontier for a portfolio.

**Request Body**

```json
{
  "portfolioId": "p-123456",
  "returns": {
    "AAPL": [0.01, 0.02, -0.01, 0.03, -0.02],
    "MSFT": [0.02, 0.01, -0.02, 0.02, -0.01],
    "GOOGL": [0.03, -0.01, 0.01, 0.02, -0.03],
    "AMZN": [0.02, -0.02, 0.03, 0.01, -0.01],
    "META": [0.01, 0.03, -0.03, 0.02, -0.02]
  },
  "numPortfolios": 20
}
```

**Response**

```json
{
  "id": "o-345678",
  "portfolioId": "p-123456",
  "type": "efficient-frontier",
  "parameters": {
    "numPortfolios": 20
  },
  "result": {
    "portfolios": [
      {
        "weights": {
          "AAPL": 0.20,
          "MSFT": 0.25,
          "GOOGL": 0.15,
          "AMZN": 0.20,
          "META": 0.20
        },
        "return": 0.08,
        "risk": 0.12
      },
      {
        "weights": {
          "AAPL": 0.25,
          "MSFT": 0.20,
          "GOOGL": 0.20,
          "AMZN": 0.15,
          "META": 0.20
        },
        "return": 0.09,
        "risk": 0.13
      }
    ],
    "minVolatilityPortfolio": {
      "weights": {
        "AAPL": 0.20,
        "MSFT": 0.25,
        "GOOGL": 0.15,
        "AMZN": 0.20,
        "META": 0.20
      },
      "return": 0.08,
      "risk": 0.12
    },
    "maxSharpePortfolio": {
      "weights": {
        "AAPL": 0.25,
        "MSFT": 0.20,
        "GOOGL": 0.20,
        "AMZN": 0.15,
        "META": 0.20
      },
      "return": 0.09,
      "risk": 0.13,
      "sharpe": 0.69
    }
  },
  "createdAt": "2025-06-28T12:34:56Z"
}
```

### Monte Carlo Simulation

#### Run Simulation

```
POST /monte-carlo/simulate
```

Runs a Monte Carlo simulation on a portfolio.

**Request Body**

```json
{
  "portfolioId": "p-123456",
  "returns": {
    "AAPL": [0.01, 0.02, -0.01, 0.03, -0.02],
    "MSFT": [0.02, 0.01, -0.02, 0.02, -0.01],
    "GOOGL": [0.03, -0.01, 0.01, 0.02, -0.03],
    "AMZN": [0.02, -0.02, 0.03, 0.01, -0.01],
    "META": [0.01, 0.03, -0.03, 0.02, -0.02]
  },
  "initialInvestment": 10000,
  "numSimulations": 1000,
  "numPeriods": 252
}
```

**Response**

```json
{
  "id": "s-123456",
  "portfolioId": "p-123456",
  "parameters": {
    "initialInvestment": 10000,
    "numSimulations": 1000,
    "numPeriods": 252
  },
  "result": {
    "trajectories": [
      [10000, 10100, 10200, 10300, 10400],
      [10000, 10050, 10100, 10150, 10200]
    ],
    "statistics": {
      "meanFinalValue": 12500,
      "medianFinalValue": 12000,
      "minFinalValue": 8000,
      "maxFinalValue": 15000,
      "standardDeviation": 2000,
      "percentiles": {
        "5": 9000,
        "25": 11000,
        "50": 12000,
        "75": 13000,
        "95": 14000
      }
    }
  },
  "createdAt": "2025-06-28T12:34:56Z"
}
```

#### Analyze Simulation

```
POST /monte-carlo/analyze
```

Analyzes a Monte Carlo simulation.

**Request Body**

```json
{
  "simulationId": "s-123456"
}
```

**Response**

```json
{
  "id": "a-123456",
  "simulationId": "s-123456",
  "result": {
    "probabilityOfLoss": 0.05,
    "probabilityOfGain": 0.95,
    "expectedReturn": 0.25,
    "expectedRisk": 0.15,
    "valueAtRisk": {
      "95": 9000,
      "99": 8000
    },
    "maxDrawdown": {
      "mean": 0.15,
      "median": 0.12,
      "max": 0.25
    }
  },
  "createdAt": "2025-06-28T12:34:56Z"
}
```

### Market Data

#### Get Market Prices

```
GET /market-data/prices?symbols=AAPL,MSFT&startDate=2025-01-01&endDate=2025-06-28&interval=1d
```

Returns market prices for the specified symbols.

**Query Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| symbols | string | Comma-separated list of symbols |
| startDate | string | Start date (YYYY-MM-DD) |
| endDate | string | End date (YYYY-MM-DD) |
| interval | string | Price interval (1d, 1wk, 1mo) |

**Response**

```json
{
  "AAPL": {
    "dates": ["2025-01-01", "2025-01-02", "2025-01-03"],
    "open": [150.0, 152.0, 153.0],
    "high": [153.0, 154.0, 155.0],
    "low": [149.0, 151.0, 152.0],
    "close": [152.0, 153.0, 154.0],
    "volume": [1000000, 1100000, 1200000]
  },
  "MSFT": {
    "dates": ["2025-01-01", "2025-01-02", "2025-01-03"],
    "open": [250.0, 252.0, 253.0],
    "high": [253.0, 254.0, 255.0],
    "low": [249.0, 251.0, 252.0],
    "close": [252.0, 253.0, 254.0],
    "volume": [2000000, 2100000, 2200000]
  }
}
```

#### Get Market Returns

```
GET /market-data/returns?symbols=AAPL,MSFT&startDate=2025-01-01&endDate=2025-06-28&returnType=daily
```

Returns market returns for the specified symbols.

**Query Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| symbols | string | Comma-separated list of symbols |
| startDate | string | Start date (YYYY-MM-DD) |
| endDate | string | End date (YYYY-MM-DD) |
| returnType | string | Return type (daily, weekly, monthly) |

**Response**

```json
{
  "AAPL": [0.01, 0.02, -0.01, 0.03, -0.02],
  "MSFT": [0.02, 0.01, -0.02, 0.02, -0.01]
}
```

## Error Codes

| Code | Description |
|------|-------------|
| BAD_REQUEST | The request was invalid |
| VALIDATION_ERROR | The request failed validation |
| NOT_FOUND | The requested resource was not found |
| INTERNAL_SERVER_ERROR | An internal server error occurred |
| UNAUTHORIZED | Authentication failed |
| FORBIDDEN | Authorization failed |
