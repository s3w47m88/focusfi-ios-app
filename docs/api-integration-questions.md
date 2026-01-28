# API Integration Questions for FocusFi iOS App

The FocusFi iOS app needs to integrate with a backend API that connects to Supabase. Please answer the following questions to help configure the iOS app for data retrieval and user authentication.

---

## 1. API Server Configuration

### 1.1 Base Configuration
- What is the base URL for the API server?
- What port does the API run on?
- Is there a staging/development URL separate from production?
- What technology stack is the API built with (Node.js, Nest.js, Python, etc.)?

### 1.2 API Versioning
- Does the API use versioning (e.g., `/api/v1/`)?
- What is the current API version?

---

## 2. Authentication

### 2.1 Authentication Method
- What authentication method does the API use?
  - JWT (JSON Web Tokens)
  - OAuth 2.0
  - API Key
  - Session-based
  - Supabase Auth directly
- If JWT, what is the token expiration time?
- Is there a refresh token mechanism?

### 2.2 Authentication Endpoints
- What is the endpoint for user registration?
  - What fields are required (email, password, name, etc.)?
  - What is the request/response format?
- What is the endpoint for user login?
  - What credentials are required?
  - What does a successful response look like?
- What is the endpoint for token refresh?
- What is the endpoint for logout?
- What is the endpoint for password reset?

### 2.3 Authentication Headers
- How should the auth token be passed in requests?
  - `Authorization: Bearer <token>`?
  - Custom header?
- Are there any additional required headers (API key, client ID, etc.)?

### 2.4 Example Authentication Flow
Please provide a complete example of:
1. Registering a new user (request + response)
2. Logging in (request + response)
3. Making an authenticated request (with headers)
4. Refreshing an expired token (request + response)

---

## 3. Data Models & Endpoints

### 3.1 User Profile
- What is the endpoint to get the current user's profile?
- What is the endpoint to update user profile?
- What fields are available on the user object?

### 3.2 Transactions
The iOS app tracks financial transactions with these local fields:
- `id` (UUID)
- `title` (String)
- `details` (String)
- `amount` (Double)
- `date` (Date)
- `type` (income/expense)

Questions:
- What is the endpoint to list all transactions for the authenticated user?
  - Does it support pagination? If so, what parameters?
  - Does it support filtering by date range?
  - Does it support filtering by type (income/expense)?
- What is the endpoint to create a new transaction?
- What is the endpoint to update a transaction?
- What is the endpoint to delete a transaction?
- What is the exact field mapping between the API and the iOS model?
- Are there any additional fields returned by the API that the iOS app should store?

### 3.3 Bank Accounts
The iOS app tracks bank accounts with these local fields:
- `id` (UUID)
- `bankName` (String)
- `accountName` (String)
- `balance` (Double)

Questions:
- What is the endpoint to list all bank accounts for the authenticated user?
- What is the endpoint to create a new bank account?
- What is the endpoint to update a bank account?
- What is the endpoint to delete a bank account?
- What is the exact field mapping between the API and the iOS model?

### 3.4 Forecasts
The iOS app currently uses hardcoded forecast values:
- `forecastedIncome` (Double) - currently hardcoded to 10000
- `forecastedExpenses` (Double) - currently hardcoded to 8000

Questions:
- What is the endpoint to get forecast data?
- Are forecasts user-specific or global?
- Can users set their own forecast values?
- What is the response format for forecasts?
- Are forecasts monthly, yearly, or customizable by date range?

---

## 4. Request/Response Formats

### 4.1 General Format
- What content type does the API expect? (`application/json`?)
- What is the standard success response format?
- What is the standard error response format?

### 4.2 Date Format
- What date format does the API expect/return?
  - ISO 8601 (`2024-01-15T10:30:00Z`)?
  - Unix timestamp?
  - Other?

### 4.3 Pagination
- How does pagination work?
  - Offset-based (`?offset=0&limit=20`)?
  - Cursor-based?
  - Page-based (`?page=1&per_page=20`)?
- What does the paginated response look like?

### 4.4 Example Requests
Please provide curl examples for:
1. Creating a transaction
2. Listing transactions with date filter
3. Getting forecast data
4. Updating a bank account balance

---

## 5. Error Handling

### 5.1 HTTP Status Codes
- What status codes does the API return?
  - 200 - Success
  - 201 - Created
  - 400 - Bad Request
  - 401 - Unauthorized
  - 403 - Forbidden
  - 404 - Not Found
  - 422 - Validation Error
  - 500 - Server Error
  - Others?

### 5.2 Error Response Format
- What does an error response body look like?
- Are there error codes in addition to HTTP status?
- How are validation errors formatted?

### 5.3 Rate Limiting
- Is there rate limiting on the API?
- If so, what are the limits?
- How is rate limit status communicated (headers)?

---

## 6. Data Synchronization

### 6.1 Sync Strategy
- Should the iOS app use the API as the source of truth and abandon local SwiftData?
- Or should it maintain local SwiftData with periodic sync to the API?
- Is there a webhook or push notification system for real-time updates?

### 6.2 Conflict Resolution
- If using local + remote storage, how should conflicts be resolved?
- Is there a `last_modified` or `updated_at` timestamp on records?

### 6.3 Offline Support
- Should the app support offline mode with queued operations?
- How should failed requests be retried?

---

## 7. Security

### 7.1 Transport Security
- Is HTTPS required?
- Is certificate pinning recommended?

### 7.2 Sensitive Data
- Are there any fields that should not be stored locally?
- Should tokens be stored in iOS Keychain?

### 7.3 Session Management
- How should the app handle token expiration mid-session?
- Should there be automatic logout after inactivity?

---

## 8. API Documentation

### 8.1 Documentation Resources
- Is there an OpenAPI/Swagger specification available?
- Is there a Postman collection available?
- Where is the API documentation hosted?

### 8.2 SDK/Client Libraries
- Is there a pre-built Swift client library?
- Are there any recommended HTTP client libraries (Alamofire, URLSession, etc.)?

---

## 9. Environment & Configuration

### 9.1 Environment Variables
- What environment variables or configuration values does the iOS app need?
  - API base URL
  - API key (if applicable)
  - Supabase project URL (if connecting directly)
  - Supabase anon key (if connecting directly)

### 9.2 Configuration Management
- Should these values be in a plist, xcconfig, or environment-based?
- Are there different values for Debug vs Release builds?

---

## 10. Testing

### 10.1 Test Environment
- Is there a sandbox/test environment?
- Are there test user credentials?
- Is there test data available?

### 10.2 Mock Data
- Is there a mock server or local development option?

---

## Summary Response Format

Please respond with:
1. Answers to each question above
2. Complete code examples for:
   - API client configuration in Swift
   - Authentication service
   - Sample API calls for each endpoint
3. Any additional considerations or recommendations
