# Unit Test Generation Policy

## Agent Role

You are generating comprehensive unit tests for recently implemented code following test-driven development best practices.

## Required Inputs

Before starting, you MUST request the following from the user:

1. Git code repository path (workspace root)
2. Policy file path (this policy document location)
3. Implementation changes summary document path
4. Existing application BRD document path (current system documentation)
5. Existing application architecture documentation path (system architecture, design docs)

## Context Discovery Instructions

1. Review the existing application BRD to understand current system
2. Study the existing application architecture documentation
3. Analyze the implementation changes in the current branch
4. Review the changes summary document
5. Identify if changes affect existing functionality
6. Check for breaking changes and API versioning
7. Discover the codebase structure in the workspace root
8. Find existing test patterns and frameworks in context directories
9. Identify the testing framework being used (pytest, unittest, jest, mocha, etc.)
10. Understand existing test conventions and patterns
11. Locate test fixtures, mocks, and test utilities
12. Review code coverage requirements
13. Identify existing tests that need updates due to changes

## Unit Test Requirements

### Test Coverage Goals

1. **Code Coverage**: Aim for >90% line coverage
2. **Branch Coverage**: Test all conditional branches
3. **Edge Cases**: Test boundary conditions and edge cases
4. **Error Paths**: Test error handling and exceptions
5. **Happy Paths**: Test normal execution flows

### Test Organization

1. **File Structure**: Follow existing test file organization
2. **Naming Convention**: Use consistent test file and function names
3. **Test Grouping**: Group related tests in classes or describe blocks
4. **Test Isolation**: Each test should be independent
5. **Setup/Teardown**: Use appropriate setup and teardown methods

### What to Test

#### Functions and Methods

- All public functions and methods
- Different input combinations
- Edge cases and boundary values
- Error conditions
- Return values and side effects

#### Classes

- Constructor/initialization
- All public methods
- State changes
- Property getters and setters
- Class methods and static methods

#### API Endpoints (Mocked)

- Request validation
- Response format
- Error responses
- Authentication/authorization (mocked)
- Different HTTP methods
- Both old and new API versions (if versioning exists)
- Backward compatibility with old API contracts

#### Database Operations (Mocked)

- CRUD operations
- Query logic
- Transaction handling
- Error handling
- Data validation
- Schema migration compatibility
- Data migration validation

#### Business Logic

- Calculations and algorithms
- Validation rules
- State transitions
- Business rules enforcement

#### Regression Testing (CRITICAL)

- All existing functionality affected by changes
- Backward compatibility with existing behavior
- Integration points with modified components
- Existing features that depend on changed code

### Test Patterns

#### Arrange-Act-Assert (AAA)

```python
def test_example():
    # Arrange: Set up test data and mocks
    user = User(name="Test")

    # Act: Execute the code under test
    result = user.get_display_name()

    # Assert: Verify the results
    assert result == "Test"
```

#### Given-When-Then (BDD)

```python
def test_user_login():
    # Given: Initial state
    user = create_test_user()

    # When: Action occurs
    result = authenticate(user.email, "password")

    # Then: Expected outcome
    assert result.is_authenticated
```

### Mocking Strategy

1. **External Services**: Always mock external API calls
2. **Database**: Mock database operations in unit tests
3. **File System**: Mock file I/O operations
4. **Time**: Mock time-dependent operations
5. **Random**: Mock random number generation
6. **Network**: Mock network calls

### Test Data

1. **Fixtures**: Use fixtures for reusable test data
2. **Factories**: Use factory patterns for complex objects
3. **Realistic Data**: Use realistic but anonymized data
4. **Edge Cases**: Include edge case data (empty, null, max, min)
5. **Invalid Data**: Test with invalid inputs

### Assertions

1. **Specific**: Use specific assertions, not generic ones
2. **Clear Messages**: Include clear assertion messages
3. **Multiple Assertions**: Group related assertions
4. **Exception Testing**: Test expected exceptions
5. **Type Checking**: Verify return types

### Framework-Specific Guidelines

#### Python (pytest)

```python
import pytest
from unittest.mock import Mock, patch

class TestUserService:
    @pytest.fixture
    def user_service(self):
        return UserService()

    def test_create_user_success(self, user_service):
        # Arrange
        user_data = {"name": "Test", "email": "test@example.com"}

        # Act
        result = user_service.create_user(user_data)

        # Assert
        assert result.name == "Test"
        assert result.email == "test@example.com"

    @patch('module.external_api')
    def test_with_mock(self, mock_api, user_service):
        mock_api.return_value = {"status": "success"}
        result = user_service.call_external_api()
        assert result["status"] == "success"
```

#### JavaScript (Jest)

```javascript
describe("UserService", () => {
  let userService;

  beforeEach(() => {
    userService = new UserService();
  });

  test("should create user successfully", () => {
    // Arrange
    const userData = { name: "Test", email: "test@example.com" };

    // Act
    const result = userService.createUser(userData);

    // Assert
    expect(result.name).toBe("Test");
    expect(result.email).toBe("test@example.com");
  });

  test("should handle errors", () => {
    expect(() => userService.createUser(null)).toThrow();
  });
});
```

### Test Naming Conventions

#### Python

- **File**: `test_module_name.py`
- **Class**: `TestClassName`
- **Method**: `test_method_name_scenario`

#### JavaScript

- **File**: `module-name.test.js` or `module-name.spec.js`
- **Describe**: `describe('ClassName', ...)`
- **Test**: `test('should do something', ...)` or `it('should do something', ...)`

## Testing Breaking Changes and Impact

**CRITICAL**: When changes affect existing functionality, comprehensive regression testing is required.

### 1. Regression Test Requirements

When implementation modifies existing code:

#### Update Existing Tests

- Identify all existing tests affected by changes
- Update test expectations to match new behavior
- Ensure tests still validate core functionality
- Add comments explaining why tests changed

#### Backward Compatibility Tests

- Test that existing functionality still works
- Verify old API versions still function (if versioned)
- Test data migration compatibility
- Validate existing integrations

#### Breaking Change Tests

- Test both old and new behavior (if both supported)
- Verify deprecation warnings appear correctly
- Test migration path from old to new
- Validate error messages for unsupported old usage

### 2. API Versioning Tests

When API versioning is implemented:

#### Old Version Tests

- All existing tests for old API version
- Deprecation warning tests
- Backward compatibility validation
- Old version still meets original requirements

#### New Version Tests

- Complete test suite for new API version
- New features and improvements
- Breaking changes are intentional
- Migration path validation

#### Version Routing Tests

- Correct version selected based on request
- Version headers/parameters work correctly
- Default version behavior
- Invalid version handling

### 3. Database Migration Tests

When schema changes occur:

#### Migration Script Tests

- Migration runs successfully
- Data is migrated correctly
- Rollback works properly
- No data loss occurs

#### Backward Compatibility Tests

- Old code works with new schema (during transition)
- New code works with old schema (if applicable)
- Gradual migration scenarios

#### Data Validation Tests

- Migrated data meets new constraints
- Data integrity maintained
- Relationships preserved
- Indexes created correctly

### 4. Integration Point Tests

When changes affect integration points:

#### Existing Integration Tests

- Update tests for modified interfaces
- Test backward compatibility
- Verify contracts still met
- Test error handling

#### New Integration Tests

- Test new integration points
- Validate new contracts
- Test failure scenarios
- Verify timeouts and retries

### 5. Test Organization for Breaking Changes

Organize tests to clearly show impact:

```python
# Example structure for API versioning tests

class TestUserAPIV1:
    """Tests for deprecated v1 API - maintain during deprecation period"""

    def test_v1_get_user_still_works(self):
        """Verify v1 endpoint still functions"""
        response = client.get('/api/v1/users/123')
        assert response.status_code == 200

    def test_v1_shows_deprecation_warning(self):
        """Verify deprecation warning in response"""
        response = client.get('/api/v1/users/123')
        assert 'X-Deprecation-Warning' in response.headers

class TestUserAPIV2:
    """Tests for new v2 API"""

    def test_v2_get_user_with_new_fields(self):
        """Verify v2 includes new fields"""
        response = client.get('/api/v2/users/123')
        assert 'new_field' in response.json()

    def test_v2_backward_compatible_fields(self):
        """Verify v2 still includes old fields for compatibility"""
        response = client.get('/api/v2/users/123')
        assert 'id' in response.json()
        assert 'name' in response.json()

class TestUserAPIMigration:
    """Tests for migration from v1 to v2"""

    def test_migration_guide_examples_work(self):
        """Verify code examples in migration guide are correct"""
        # Test examples from migration documentation
        pass
```

### 6. Mandatory Tests for Breaking Changes

Always include these tests when breaking changes exist:

#### Regression Test Suite

- All affected existing functionality
- Minimum: same coverage as before changes
- All existing test cases updated or explained

#### Backward Compatibility Suite

- Old API version tests (if versioned)
- Old behavior tests (if supported)
- Migration path tests

#### Breaking Change Validation

- New behavior works as intended
- Breaking changes are intentional
- Error messages guide users correctly

#### Integration Impact Tests

- All affected integration points
- Existing consumers still work
- New consumers can integrate

### 7. Test Coverage Requirements for Changes

- **New Code**: Minimum 90% coverage
- **Modified Code**: Maintain or improve existing coverage
- **Affected Code**: Re-test all affected paths
- **Regression**: Test all related existing functionality

## Output File Requirements

Generate the following files in the output directory:

### 1. test-summary.md

````markdown
# Unit Test Summary

## PR Number

#123

## Test Files Created

- tests/unit/test_user_service.py (15 tests)
- tests/unit/test_auth.py (10 tests)

## Coverage Areas

- User Service: 95% coverage
- Authentication: 92% coverage
- Validation: 88% coverage

## Test Execution

```bash
# Run all unit tests
pytest tests/unit/

# Run with coverage
pytest tests/unit/ --cov=src --cov-report=html
```
````

## Setup Requirements

- Install test dependencies: `pip install -r requirements-test.txt`
- Set test environment variables: `export TEST_ENV=true`

## Test Statistics

- Total tests: 25
- Total assertions: 78
- Estimated execution time: 2.5 seconds

````

### 2. test-plan.md

```markdown
# Unit Test Plan

## Test Strategy

- Use pytest for Python tests
- Mock all external dependencies
- Aim for >90% code coverage
- Test happy paths and error cases

## Test Scenarios Covered

1. User creation with valid data
2. User creation with invalid data
3. Authentication success
4. Authentication failure
5. ...

## Known Limitations

- External API integration not tested (will be in integration tests)
- Database performance not tested

## Future Improvements

- Add property-based testing
- Add mutation testing
````

## Quality Standards

### Test Quality Checklist

- [ ] Tests are independent and isolated
- [ ] Tests are fast (< 100ms each)
- [ ] Tests are deterministic (no flaky tests)
- [ ] Tests have clear names
- [ ] Tests follow AAA pattern
- [ ] Mocks are used appropriately
- [ ] Edge cases are covered
- [ ] Error cases are tested
- [ ] Assertions are specific
- [ ] Test data is realistic

### Code Coverage Requirements

- **Line coverage**: >90%
- **Branch coverage**: >85%
- **Function coverage**: 100%
- **Critical paths**: 100%

## Common Test Patterns

### Testing Exceptions

```python
def test_raises_exception():
    with pytest.raises(ValueError, match="Invalid input"):
        function_that_raises("invalid")
```

### Parametrized Tests

```python
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input, expected):
    assert double(input) == expected
```

### Testing Async Code

```python
@pytest.mark.asyncio
async def test_async_function():
    result = await async_function()
    assert result == expected
```

## Validation Checklist

Before finalizing, verify:

- [ ] All new code is tested
- [ ] All modified code is tested
- [ ] Tests follow existing patterns
- [ ] Mocks are used appropriately
- [ ] Test names are descriptive
- [ ] Coverage goals are met
- [ ] Tests run successfully
- [ ] No implementation code was modified
- [ ] Test documentation is complete

## Success Criteria

The unit tests are successful when:

1. All new and modified code is tested
2. Code coverage exceeds 90%
3. All tests pass
4. Tests are fast and deterministic
5. Tests follow project conventions
6. Edge cases and errors are covered
7. Documentation is complete
