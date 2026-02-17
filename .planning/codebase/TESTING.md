# Testing Patterns

**Analysis Date:** 2026-02-17

## Test Framework

**JavaScript/TypeScript:**
- Framework: Not detected (No Jest/Vitest config files found)
- Status: **No automated test infrastructure currently in use**
- Projects affected: CompassV2, essentials, ev-ui, EV-prototypes
- Manual testing via browser dev tools and local dev server

**Go:**
- Framework: `testing` (standard library)
- Location: `internal/essentials/geocoding/google_test.go`
- Tests are optional; only geocoding integration test found
- Run: `go test ./...` to discover and run all tests

## Test File Organization

**Location:**
- Go: Tests co-located with source (same package, `*_test.go` suffix)
- Example: `internal/essentials/geocoding/google_test.go` tests `internal/essentials/geocoding/google.go`
- JavaScript/TypeScript: No test files found in source directories

**Naming:**
- Go: `{filename}_test.go` (e.g., `google_test.go`)
- Pattern: `func Test{FeatureName}(t *testing.T)` (e.g., `TestGeocode`)

**Structure:**
```
internal/
├── essentials/
│   └── geocoding/
│       ├── google.go          (implementation)
│       └── google_test.go      (test)
```

## Go Test Structure

**Suite Organization:**
From `internal/essentials/geocoding/google_test.go`:

```go
func TestGeocode(t *testing.T) {
	// 1. Skip test if prerequisites not met
	if os.Getenv("GOOGLE_MAPS_API_KEY") == "" {
		t.Skip("GOOGLE_MAPS_API_KEY not set")
	}

	// 2. Setup: Initialize client/dependencies
	client, err := NewClient()
	if err != nil {
		t.Fatalf("NewClient failed: %v", err)
	}
	if client == nil {
		t.Fatal("Expected non-nil client when API key is set")
	}

	// 3. Execute: Call function under test
	ctx := context.Background()
	result, err := client.Geocode(ctx, "1600 Pennsylvania Ave NW, Washington, DC")
	if err != nil {
		t.Logf("Geocode error: %v", err)
		t.Logf("This might mean the Google Maps Geocoding API is not enabled for this key.")
		t.FailNow()
	}

	// 4. Verify: Assert expected outcomes
	if result.Zip != "20500" && result.Zip != "20006" {
		t.Errorf("Expected ZIP 20500 or 20006, got %s", result.Zip)
	}
	if result.State != "DC" {
		t.Errorf("Expected state DC, got %s", result.State)
	}
}
```

**Patterns:**
- **Setup phase:** Initialize clients, mock services, set up test data
- **Execution phase:** Call the function/method being tested
- **Verification phase:** Assert outputs match expectations
- **Error handling:** Use `t.Fatal()` to stop test, `t.Errorf()` to report failures, `t.Logf()` for context

## Go Testing Helpers

**Common Assertions:**
- `t.Fatalf(message, args...)` - Fatal error; stops test immediately
- `t.FailNow()` - Marks test as failed and stops
- `t.Errorf(message, args...)` - Marks test as failed; continues
- `t.Logf(message, args...)` - Logs without failing
- `t.Skip(reason)` - Skip test with reason

**Skip Patterns:**
- Skip tests that require external services (e.g., API keys)
- From example: `t.Skip("GOOGLE_MAPS_API_KEY not set")`
- Useful for integration tests that shouldn't block CI when dependencies unavailable

## Mocking

**Framework:**
- Go: No explicit mocking library detected (e.g., testify, gomock)
- Approach: Manual mocking via interfaces and dependency injection

**Patterns:**
- Interface-based design allows injecting test doubles
- Example from codebase: API clients accept `*http.Client` parameter, allowing tests to inject custom HTTP client with mocked responses
- From `ballotready/client.go`:
```go
type Client struct {
	apiKey     string
	endpoint   string
	httpClient *http.Client
}

func NewClient(apiKey, endpoint string) *Client {
	return &Client{
		apiKey:   apiKey,
		endpoint: endpoint,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}
```
- Tests could create a `Client` with custom `httpClient` that returns mocked responses

**What to Mock:**
- External API calls (BallotReady, Google Maps)
- Database operations (use test database or transactions)
- Time-dependent logic (inject time function)

**What NOT to Mock:**
- Core business logic (e.g., classification algorithms, matching)
- Data structures/types (test with real types)
- Standard library functions (strings, JSON, etc.)

## Coverage

**Requirements:**
- No coverage thresholds enforced
- No coverage reports generated currently

**Viewing Coverage:**
```bash
# Go: Generate coverage report
go test -cover ./...

# Go: Generate detailed coverage HTML
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Test Types

**Go Integration Tests:**
- Location: `internal/essentials/geocoding/google_test.go`
- Scope: Tests actual Google Maps Geocoding API
- Approach: Requires API key; skipped if credential unavailable
- Characteristics:
  - Tests real external service behavior
  - Validates end-to-end data flow (address → coordinates → ZIP + state)
  - Slow (network calls); only run when explicitly needed

**Unit Tests:**
- Expected pattern (not currently used in codebase):
```go
func TestFunctionName(t *testing.T) {
	// Arrange
	input := "test value"
	expected := "expected output"

	// Act
	result := FunctionBeingTested(input)

	// Assert
	if result != expected {
		t.Errorf("Expected %v, got %v", expected, result)
	}
}
```

**JavaScript/TypeScript:**
- Currently: Manual testing via browser
- Pattern when implemented should follow:
  - Unit tests for utilities (e.g., `lib/classify.js`)
  - Integration tests for API hooks
  - Component tests for UI behavior (swipe gestures, drag-and-drop)

## Error Testing

**Go Pattern:**
```go
// Test that invalid input returns error
func TestGeocodeInvalidAddress(t *testing.T) {
	client, _ := NewClient()
	_, err := client.Geocode(context.Background(), "")
	if err == nil {
		t.Error("Expected error for empty address, got nil")
	}
}
```

## Async Testing

**Go:**
- Context used for cancellation and timeout (e.g., `context.Background()`)
- HTTP client has `Timeout: 30 * time.Second` configured
- No special async patterns needed; goroutines handled by runtime

**JavaScript/TypeScript:**
- Pattern when implemented (based on codebase async patterns):
```typescript
// Expected pattern for testing async hooks
test('useDeviceType updates on touch', async () => {
  render(<Component useDeviceType={useDeviceType} />);
  fireEvent.touchStart(window);
  await waitFor(() => {
    expect(screen.getByText('touch')).toBeInTheDocument();
  });
});
```

## Test Data & Fixtures

**Go:**
- Inline test data in test functions (e.g., hardcoded addresses, expected ZIP codes)
- Example from `google_test.go`:
```go
result, err := client.Geocode(ctx, "1600 Pennsylvania Ave NW, Washington, DC")
if result.Zip != "20500" && result.Zip != "20006" {
	t.Errorf("Expected ZIP 20500 or 20006, got %s", result.Zip)
}
```
- No fixture files or factories detected

**JavaScript/TypeScript:**
- Mock data patterns in stores (e.g., `initialState` in `useReadRankStore.ts`)
- Test data embedded in component files during development
- When formalized, fixtures should go in `__fixtures__/` or `test/fixtures/`

## Run Commands

**Go:**
```bash
# Run all tests in module
go test ./...

# Run tests in specific package
go test ./internal/essentials/geocoding

# Run with verbose output
go test -v ./...

# Run with coverage
go test -cover ./...

# Run specific test by name
go test -run TestGeocode ./internal/essentials/geocoding
```

**JavaScript/TypeScript:**
- No test runner configured
- When adding tests, recommend Jest or Vitest:
```bash
# Example (not currently in codebase)
npm run test              # Run tests
npm run test:watch       # Watch mode
npm run test:coverage    # Coverage report
```

## Test Coverage Gaps

**High Priority (Integration layers):**
- `internal/essentials/ballotready/` - GraphQL client with real API calls (needs integration test)
- `internal/compass/handlers.go` - API endpoint logic untested
- `internal/auth/handlers.go` - Authentication flows (login, register, logout)
- `internal/staging/handlers.go` - Data entry workflow

**High Priority (Frontend):**
- CompassV2 Quiz flow with topic/answer selection
- essentials Dashboard ZIP search and politician filtering
- read-rank swipe evaluation and quote ranking
- Drag-and-drop interactions via @dnd-kit

**Medium Priority:**
- Error scenarios (API failures, invalid input)
- Edge cases (empty results, boundary values)
- State persistence (localStorage/Zustand)

**Recommendation:**
Add test coverage incrementally; start with high-value scenarios:
1. API endpoint tests (Go) using table-driven tests
2. Hook tests (JavaScript) using @testing-library/react-hooks
3. Integration tests for critical user flows

## Testing Best Practices

**From existing code:**
- Skip integration tests gracefully when dependencies unavailable (good for CI)
- Use context for timeout control
- Log diagnostic information for debugging (`t.Logf`)
- Test realistic data (e.g., actual address format for geocoding)
- Fail fast with `t.Fatalf` for setup errors

**Recommendations for enhancement:**
- Add table-driven tests in Go for multiple input scenarios
- Use dependency injection to enable easier testing
- Create test helpers/assertions as test count grows
- Document test prerequisites (e.g., "requires GOOGLE_MAPS_API_KEY")

---

*Testing analysis: 2026-02-17*
