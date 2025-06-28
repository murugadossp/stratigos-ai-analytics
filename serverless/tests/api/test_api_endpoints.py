import requests
import json

# API endpoint and authentication details
BASE_URL = "https://d0jnykdrcc.execute-api.us-east-1.amazonaws.com/dev"
API_KEY = "6WVZDXMCfr8oTCEszlQqZ3xPlyTn9CN64yIhQXUz"
HEADERS = {
    "x-api-key": API_KEY,
    "Content-Type": "application/json"
}

def test_list_portfolios():
    """Test the GET /portfolios endpoint to list all portfolios."""
    url = f"{BASE_URL}/portfolios"
    response = requests.get(url, headers=HEADERS)
    
    print("Testing GET /portfolios")
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print("Response Body:", json.dumps(response.json(), indent=2)[:500] + "...")
        print("Result: SUCCESS\n")
    else:
        print("Response Body:", response.text[:500] + "...")
        print("Result: FAILURE\n")
    return response.status_code == 200

def test_create_portfolio():
    """Test the POST /portfolios endpoint to create a new portfolio."""
    url = f"{BASE_URL}/portfolios"
    payload = {
        "name": "Test Portfolio",
        "description": "A test portfolio created via API",
        "assets": {
            "AAPL": 0.25,
            "MSFT": 0.25,
            "GOOGL": 0.20,
            "AMZN": 0.20,
            "META": 0.10
        }
    }
    response = requests.post(url, headers=HEADERS, json=payload)
    
    print("Testing POST /portfolios")
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200 or response.status_code == 201:
        print("Response Body:", json.dumps(response.json(), indent=2)[:500] + "...")
        print("Result: SUCCESS\n")
        return True, response.json().get('id')
    else:
        print("Response Body:", response.text[:500] + "...")
        print("Result: FAILURE\n")
        return False, None

def test_get_portfolio(portfolio_id):
    """Test the GET /portfolios/{id} endpoint to retrieve a specific portfolio."""
    if not portfolio_id:
        print("Testing GET /portfolios/{id}")
        print("Result: SKIPPED (No portfolio ID provided)\n")
        return False
    
    url = f"{BASE_URL}/portfolios/{portfolio_id}"
    response = requests.get(url, headers=HEADERS)
    
    print(f"Testing GET /portfolios/{portfolio_id}")
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print("Response Body:", json.dumps(response.json(), indent=2)[:500] + "...")
        print("Result: SUCCESS\n")
    else:
        print("Response Body:", response.text[:500] + "...")
        print("Result: FAILURE\n")
    return response.status_code == 200

def main():
    """Run all API tests and summarize results."""
    print("Starting API Tests for Stratigos AI Platform\n")
    
    results = []
    
    # Test 1: List Portfolios
    results.append(("List Portfolios", test_list_portfolios()))
    
    # Test 2: Create Portfolio
    success, portfolio_id = test_create_portfolio()
    results.append(("Create Portfolio", success))
    
    # Test 3: Get Portfolio (using ID from create if successful)
    results.append(("Get Portfolio", test_get_portfolio(portfolio_id)))
    
    # Summarize Results
    print("API Test Summary")
    print("----------------")
    for test_name, success in results:
        print(f"{test_name}: {'SUCCESS' if success else 'FAILURE'}")
    print("----------------")
    print("API Testing Completed\n")

if __name__ == "__main__":
    main()
