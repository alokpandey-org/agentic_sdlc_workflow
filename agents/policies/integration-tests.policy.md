# Integration Test Generation Policy

## Agent Role

You are generating comprehensive integration tests that verify end-to-end workflows and component interactions.

## Required Inputs

Before starting, you MUST request the following from the user:

1. Git code repository path (workspace root)
2. Policy file path (this policy document location)
3. Epic and user stories document path
4. Implementation changes summary document path
5. Existing application BRD document path (current system documentation)
6. Existing application architecture documentation path (system architecture, design docs)

## Context Discovery Instructions

1. Review the existing application BRD to understand current system
2. Study the existing application architecture documentation
3. Review the epic and user stories
4. Review the implementation changes
5. Identify breaking changes and affected integrations
6. Check for API versioning requirements
7. Review the unit tests
8. Discover the codebase structure in the workspace root
9. Find existing integration test patterns in context directories
10. Identify the integration testing framework and tools
11. Understand API endpoints, database schemas, and external integrations
12. Locate test data, fixtures, and test environments
13. Review deployment and environment configuration
14. Identify existing integration tests that need updates

## Integration Test Requirements

### Test Scope

Integration tests verify:

1. **End-to-End Workflows**: Complete user journeys from start to finish
2. **Component Interactions**: How different parts of the system work together
3. **API Integration**: Real HTTP requests and responses
4. **Database Integration**: Real database operations (test database)
5. **External Services**: Integration with external APIs (mocked or test endpoints)
6. **Data Flow**: Data flowing correctly across system boundaries
7. **Business Processes**: Complete business workflows

### What to Test

#### API Endpoints

- Complete request/response cycle
- Authentication and authorization
- Request validation
- Response format and status codes
- Error handling
- Rate limiting
- CORS headers
- API version routing (if versioned)
- Backward compatibility with old API versions
- Deprecation warnings in responses

#### Database Operations

- CRUD operations with real database
- Transaction handling
- Data integrity and constraints
- Concurrent operations
- Migration compatibility
- Schema migration validation
- Data migration correctness
- Rollback procedures

#### Cross-Component Workflows

- User registration → Email verification → Login
- Order creation → Payment → Fulfillment
- Data import → Processing → Export
- Multi-step business processes

#### External Integrations

- Third-party API calls (mocked or test environment)
- Message queue operations
- Cache operations
- File storage operations
- Email sending (test mode)

#### Data Validation

- Data consistency across layers
- Business rule enforcement
- Validation across API boundaries
- Data transformation accuracy

#### Regression Testing (CRITICAL)

- All existing workflows affected by changes
- Existing integrations with modified components
- End-to-end flows that use changed features
- Backward compatibility of existing APIs

### Test Organization

#### File Structure

```
tests/integration/
├── test_user_workflows.py
├── test_order_processing.py
├── test_api_endpoints.py
├── fixtures/
│   ├── test_data.json
│   └── test_users.py
└── conftest.py
```

#### Test Naming

- **File**: `test_feature_name.py`
- **Class**: `TestFeatureIntegration`
- **Method**: `test_complete_workflow_scenario`

### Test Patterns

#### End-to-End Workflow Test

```python
def test_user_registration_and_login_workflow():
    # Step 1: Register user
    response = client.post('/api/register', json={
        'email': 'test@example.com',
        'password': 'secure123'
    })
    assert response.status_code == 201
    user_id = response.json()['id']

    # Step 2: Verify email (simulate)
    verify_token = get_verification_token(user_id)
    response = client.get(f'/api/verify/{verify_token}')
    assert response.status_code == 200

    # Step 3: Login
    response = client.post('/api/login', json={
        'email': 'test@example.com',
        'password': 'secure123'
    })
    assert response.status_code == 200
    assert 'access_token' in response.json()
```

#### API Integration Test

```python
def test_api_create_and_retrieve():
    # Create resource
    create_response = client.post('/api/items',
        json={'name': 'Test Item'},
        headers={'Authorization': f'Bearer {token}'}
    )
    assert create_response.status_code == 201
    item_id = create_response.json()['id']

    # Retrieve resource
    get_response = client.get(f'/api/items/{item_id}',
        headers={'Authorization': f'Bearer {token}'}
    )
    assert get_response.status_code == 200
    assert get_response.json()['name'] == 'Test Item'
```

### Test Environment Setup

#### Database Setup

```python
@pytest.fixture(scope='session')
def test_database():
    # Create test database
    db = create_test_database()
    run_migrations(db)
    yield db
    # Cleanup
    drop_test_database(db)

@pytest.fixture(scope='function')
def clean_database(test_database):
    # Clean data before each test
    truncate_all_tables(test_database)
    yield test_database
```

#### API Client Setup

```python
@pytest.fixture
def api_client():
    client = TestClient(app)
    return client

@pytest.fixture
def authenticated_client(api_client):
    # Create test user and get token
    token = create_test_user_and_login()
    api_client.headers['Authorization'] = f'Bearer {token}'
    return api_client
```

#### Test Data Setup

```python
@pytest.fixture
def test_data(clean_database):
    # Load test data
    users = create_test_users(5)
    products = create_test_products(10)
    return {'users': users, 'products': products}
```

## Testing Breaking Changes and API Versioning

**CRITICAL**: When changes affect existing integrations, comprehensive regression and compatibility testing is required.

### 1. API Versioning Integration Tests

When API versioning is implemented:

#### Test Both API Versions

```python
class TestUserAPIV1Integration:
    """Integration tests for deprecated v1 API"""

    def test_v1_complete_user_workflow(self, api_client, clean_database):
        """Test complete user workflow with v1 API"""
        # Create user via v1
        response = api_client.post('/api/v1/users', json={
            'name': 'Test User',
            'email': 'test@example.com'
        })
        assert response.status_code == 201
        user_id = response.json()['id']

        # Get user via v1
        response = api_client.get(f'/api/v1/users/{user_id}')
        assert response.status_code == 200
        assert response.json()['name'] == 'Test User'

        # Verify deprecation warning
        assert 'X-Deprecation-Warning' in response.headers
        assert 'v2' in response.headers['X-Deprecation-Warning']

    def test_v1_backward_compatibility(self, api_client, clean_database):
        """Ensure v1 API maintains backward compatibility"""
        # Test that old client code still works
        response = api_client.post('/api/v1/users', json={
            'name': 'Old Client',
            'email': 'old@example.com'
        })
        assert response.status_code == 201
        # Verify response format hasn't changed
        assert 'id' in response.json()
        assert 'name' in response.json()
        assert 'email' in response.json()

class TestUserAPIV2Integration:
    """Integration tests for new v2 API"""

    def test_v2_complete_user_workflow(self, api_client, clean_database):
        """Test complete user workflow with v2 API"""
        # Create user via v2 with new fields
        response = api_client.post('/api/v2/users', json={
            'name': 'Test User',
            'email': 'test@example.com',
            'preferences': {'theme': 'dark'}  # New field in v2
        })
        assert response.status_code == 201
        user_id = response.json()['id']

        # Get user via v2
        response = api_client.get(f'/api/v2/users/{user_id}')
        assert response.status_code == 200
        assert response.json()['preferences']['theme'] == 'dark'

    def test_v2_includes_old_fields(self, api_client, clean_database):
        """Ensure v2 maintains compatibility with old field names"""
        response = api_client.post('/api/v2/users', json={
            'name': 'Test',
            'email': 'test@example.com'
        })
        # Old fields still present
        assert 'id' in response.json()
        assert 'name' in response.json()
        assert 'email' in response.json()

class TestAPIVersionRouting:
    """Test API version routing and selection"""

    def test_version_routing_via_url(self, api_client):
        """Test version selection via URL path"""
        v1_response = api_client.get('/api/v1/users/1')
        v2_response = api_client.get('/api/v2/users/1')
        # Both should work but return different formats
        assert v1_response.status_code in [200, 404]
        assert v2_response.status_code in [200, 404]

    def test_version_routing_via_header(self, api_client):
        """Test version selection via Accept header"""
        headers_v1 = {'Accept': 'application/vnd.api.v1+json'}
        headers_v2 = {'Accept': 'application/vnd.api.v2+json'}

        v1_response = api_client.get('/api/users/1', headers=headers_v1)
        v2_response = api_client.get('/api/users/1', headers=headers_v2)

        # Verify correct version served
        assert v1_response.status_code in [200, 404]
        assert v2_response.status_code in [200, 404]

    def test_invalid_version_handling(self, api_client):
        """Test handling of invalid API version"""
        response = api_client.get('/api/v99/users/1')
        assert response.status_code == 404
        assert 'version' in response.json()['error'].lower()
```

### 2. Database Migration Integration Tests

When schema changes occur:

```python
class TestDatabaseMigration:
    """Integration tests for database migrations"""

    def test_migration_forward(self, test_database):
        """Test migration runs successfully"""
        # Run migration
        result = run_migration(test_database, 'forward')
        assert result.success

        # Verify schema changes
        assert table_exists(test_database, 'new_table')
        assert column_exists(test_database, 'users', 'new_column')

    def test_migration_backward(self, test_database):
        """Test migration rollback works"""
        # Run migration forward
        run_migration(test_database, 'forward')

        # Rollback
        result = run_migration(test_database, 'backward')
        assert result.success

        # Verify rollback
        assert not table_exists(test_database, 'new_table')
        assert not column_exists(test_database, 'users', 'new_column')

    def test_data_migration(self, test_database):
        """Test data is migrated correctly"""
        # Create old format data
        old_user = create_user_old_format(test_database, {
            'name': 'Test',
            'email': 'test@example.com'
        })

        # Run migration
        run_migration(test_database, 'forward')

        # Verify data migrated
        migrated_user = get_user(test_database, old_user.id)
        assert migrated_user.name == 'Test'
        assert migrated_user.email == 'test@example.com'
        # New field has default value
        assert migrated_user.new_field is not None

    def test_migration_with_existing_data(self, test_database):
        """Test migration works with large existing dataset"""
        # Create 1000 users
        create_test_users(test_database, count=1000)

        # Run migration
        result = run_migration(test_database, 'forward')
        assert result.success

        # Verify all data intact
        user_count = count_users(test_database)
        assert user_count == 1000
```

### 3. Regression Testing for Existing Workflows

When changes affect existing features:

```python
class TestExistingWorkflowsRegression:
    """Regression tests for existing workflows affected by changes"""

    def test_user_registration_still_works(self, api_client, clean_database):
        """Verify user registration workflow unchanged"""
        # This workflow should work exactly as before
        response = api_client.post('/api/users/register', json={
            'email': 'new@example.com',
            'password': 'secure123'
        })
        assert response.status_code == 201

        # Verify email sent (existing behavior)
        assert email_was_sent('new@example.com')

    def test_order_processing_with_new_changes(self, api_client, clean_database):
        """Test order processing works with new feature"""
        # Create order (existing workflow)
        order = create_test_order(api_client)

        # Process payment (existing workflow)
        payment = process_payment(api_client, order.id)
        assert payment.status == 'completed'

        # Verify new feature doesn't break existing flow
        order_status = get_order_status(api_client, order.id)
        assert order_status == 'processing'

    def test_existing_integrations_unaffected(self, api_client, clean_database):
        """Verify existing third-party integrations still work"""
        # Test webhook that existing partners use
        webhook_data = {
            'event': 'order.created',
            'order_id': '123'
        }
        response = api_client.post('/webhooks/partner', json=webhook_data)
        assert response.status_code == 200
        # Existing response format maintained
        assert 'status' in response.json()
        assert response.json()['status'] == 'received'
```

### 4. Cross-Version Compatibility Tests

Test interactions between old and new versions:

```python
class TestCrossVersionCompatibility:
    """Test compatibility between API versions"""

    def test_v1_created_data_accessible_via_v2(self, api_client, clean_database):
        """Data created via v1 should be accessible via v2"""
        # Create via v1
        v1_response = api_client.post('/api/v1/users', json={
            'name': 'Test',
            'email': 'test@example.com'
        })
        user_id = v1_response.json()['id']

        # Read via v2
        v2_response = api_client.get(f'/api/v2/users/{user_id}')
        assert v2_response.status_code == 200
        assert v2_response.json()['name'] == 'Test'

    def test_v2_created_data_accessible_via_v1(self, api_client, clean_database):
        """Data created via v2 should be accessible via v1"""
        # Create via v2 with new fields
        v2_response = api_client.post('/api/v2/users', json={
            'name': 'Test',
            'email': 'test@example.com',
            'preferences': {'theme': 'dark'}
        })
        user_id = v2_response.json()['id']

        # Read via v1 (new fields omitted)
        v1_response = api_client.get(f'/api/v1/users/{user_id}')
        assert v1_response.status_code == 200
        assert v1_response.json()['name'] == 'Test'
        # New fields not in v1 response
        assert 'preferences' not in v1_response.json()
```

### 5. Mandatory Integration Tests for Breaking Changes

Always include:

1. **Complete Regression Suite**: All existing workflows
2. **API Version Tests**: Both old and new versions
3. **Migration Tests**: Forward and backward migrations
4. **Cross-Version Tests**: Data compatibility between versions
5. **Integration Point Tests**: All affected external integrations
6. **Performance Tests**: Ensure changes don't degrade performance

## Mocking Strategy

### Mock External Services

```python
@pytest.fixture
def mock_payment_service():
    with patch('services.payment.PaymentGateway') as mock:
        mock.return_value.charge.return_value = {
            'status': 'success',
            'transaction_id': 'test_123'
        }
        yield mock
```

### Use Test Endpoints

```python
# For services with test environments
PAYMENT_API_URL = os.getenv('PAYMENT_API_URL', 'https://test.payment.com')
```

## Test Data Management

### Fixtures

- Use realistic but anonymized data
- Create reusable fixtures
- Clean up after each test
- Use factories for complex objects

### Test Database

- Use separate test database
- Run migrations before tests
- Truncate tables between tests
- Use transactions for isolation

## Performance Considerations

### Test Speed

- Integration tests can be slower than unit tests
- Aim for < 5 seconds per test
- Use database transactions for speed
- Parallelize tests where possible

### Resource Management

- Clean up resources after tests
- Close database connections
- Clear caches
- Remove temporary files

## Output File Requirements

### 1. test-summary.md

````markdown
Integration Test Summary

Test Files Created

- tests/integration/test_user_workflows.py (8 scenarios)
- tests/integration/test_api_endpoints.py (12 scenarios)

Test Scenarios Covered

1. User registration and login workflow
2. Order creation and payment processing
3. API CRUD operations
4. Multi-currency price conversion
5. ...

Test Data Requirements

- Test database with schema
- Test users with different roles
- Sample products and prices
- Mock payment gateway

Environment Setup

```bash
Create test database
createdb inventree_test

Run migrations
python manage.py migrate --database=test

Set environment variables
export TEST_DATABASE_URL=postgresql://localhost/inventree_test
export PAYMENT_API_URL=https://test.payment.com
```
````

**Test Execution:**

```bash
# Run all integration tests
pytest tests/integration/

# Run specific test file
pytest tests/integration/test_user_workflows.py

# Run with coverage
pytest tests/integration/ --cov=src --cov-report=html
```

### 2. test-environment.md

```markdown
Test Environment Setup

Required Services

- PostgreSQL test database
- Redis test instance
- Mock payment gateway

Configuration

- Environment variables
- Test configuration files
- Feature flags

Test Data Setup

- Database migrations
- Seed data scripts
- Test fixtures

Cleanup Procedures

- Truncate tables after tests
- Clear Redis cache
- Remove temporary files
```

### 3. test-scenarios.md

```markdown
# Integration Test Scenarios

## Scenario 1: User Registration Flow

**Steps:**

1. User submits registration form
2. System validates email uniqueness
3. System creates user account
4. System sends verification email
5. User clicks verification link
6. System activates account

**Expected Outcome:**

- User account created
- Verification email sent
- Account activated after verification

## Scenario 2: Multi-Currency Order

**Steps:**

1. User browses products in USD
2. User switches to EUR
3. Prices converted using exchange rate
4. User adds items to cart
5. User checks out in EUR
6. Payment processed in EUR
7. Order stored with EUR prices and exchange rate

**Expected Outcome:**

- Prices correctly converted
- Order stored with original currency
- Exchange rate locked at checkout
```

## Validation Checklist

Before finalizing, verify:

- [ ] All user workflows are tested
- [ ] API endpoints are tested end-to-end
- [ ] Database operations are tested
- [ ] External integrations are tested (mocked)
- [ ] Error scenarios are covered
- [ ] Test environment is documented
- [ ] Test data is realistic
- [ ] Cleanup procedures are in place
- [ ] Tests are repeatable
- [ ] Documentation is complete

## Success Criteria

The integration tests are successful when:

1. All user workflows are covered
2. Tests verify end-to-end functionality
3. Tests use real database (test instance)
4. External services are appropriately mocked
5. Tests are repeatable and idempotent
6. Environment setup is documented
7. Test data is realistic
8. All tests pass
