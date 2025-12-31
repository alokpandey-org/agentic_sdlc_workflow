Test Execution with Auto-Fix Policy

Agent Role

You are analyzing test failures and automatically fixing them to ensure code quality and reliability.

Required Inputs

Before starting, you MUST request the following from the user:

1. Git code repository path (workspace root)
2. Policy file path (this policy document location)
3. Test output/failure logs path
4. Existing application BRD document path (current system documentation)
5. Existing application architecture documentation path (system architecture, design docs)

Context Discovery Instructions

1. Review the existing application BRD to understand current system
2. Study the existing application architecture documentation
3. Review the test output and failure messages
4. Analyze the codebase in the workspace root
5. Check if failures are due to breaking changes or impact on existing functionality
6. Identify if test expectations need updating due to intentional changes
7. Identify the root cause of test failures
8. Review recent code changes
9. Understand the test framework and patterns
10. Locate relevant implementation and test files
11. Determine if failures indicate regression in existing features

Failure Analysis Process

Step 1: Categorize Failures

Identify the type of failure:

Code Bugs
- Logic errors in implementation
- Incorrect calculations
- Missing validations
- Wrong return values
- State management issues

Test Bugs
- Incorrect test expectations
- Wrong test data
- Flaky tests
- Test setup issues
- Assertion errors

Breaking Change Impact (CRITICAL)
- Tests failing due to intentional API changes
- Tests expecting old behavior that has changed
- Tests not updated for new API version
- Tests not accounting for schema changes
- Tests failing due to backward compatibility issues

Environment Issues
- Missing dependencies
- Configuration problems
- Database state issues
- Network connectivity
- Permission problems

Race Conditions
- Timing issues
- Concurrent access problems
- Async operation issues
- Resource contention

Configuration Issues
- Wrong environment variables
- Missing configuration
- Incorrect settings
- Feature flag issues

Step 2: Root Cause Analysis

For each failure:
1. Read the error message carefully
2. Identify the failing line of code
3. Trace back through the call stack
4. Understand the expected vs actual behavior
5. Identify the root cause
6. Determine the appropriate fix

Fix Strategy

Priority 1: Fix Code Bugs

If the failure is due to a bug in implementation:
1. Locate the buggy code
2. Understand the intended behavior
3. Fix the bug
4. Verify the fix doesn't break other functionality
5. Document the fix

Priority 2: Fix Test Bugs

If the failure is due to a bug in tests:
1. Locate the incorrect test
2. Understand what should be tested
3. Fix the test expectations or setup
4. Ensure test is still meaningful
5. Document the fix

Priority 3: Fix Configuration

If the failure is due to configuration:
1. Identify missing or incorrect configuration
2. Add or update configuration
3. Document the configuration requirement
4. Ensure configuration is environment-agnostic

Priority 4: Fix Environment Issues

If the failure is due to environment:
1. Identify missing dependencies
2. Add dependencies to requirements
3. Update setup instructions
4. Document environment requirements

What NOT to Do

Never Do These
1. Skip or Disable Tests: Don't comment out or skip failing tests
2. Ignore Failures: Don't mark tests as expected failures without fixing
3. Work Around Issues: Don't add workarounds instead of fixing root cause
4. Change Test Data to Pass: Don't modify test data just to make tests pass
5. Remove Assertions: Don't remove assertions to make tests pass
6. Add Sleep/Wait: Don't add arbitrary sleeps to fix timing issues

Red Flags
- If you're tempted to skip a test, the fix is wrong
- If you're adding sleeps, there's a race condition to fix
- If you're changing test expectations without understanding why, stop
- If the fix seems too easy, verify it's correct

Fix Patterns

Pattern 1: Logic Error
```python
Before (Bug)
def calculate_total(items):
    return sum(item.price for item in items)  # Missing quantity

After (Fixed)
def calculate_total(items):
    return sum(item.price * item.quantity for item in items)
```

Pattern 2: Missing Validation
```python
Before (Bug)
def create_user(email, password):
    return User.objects.create(email=email, password=password)

After (Fixed)
def create_user(email, password):
    if not email or '@' not in email:
        raise ValueError("Invalid email")
    if len(password) < 8:
        raise ValueError("Password too short")
    return User.objects.create(email=email, password=password)
```

Pattern 3: Incorrect Test Expectation
```python
Before (Wrong Test)
def test_user_creation():
    user = create_user("test@example.com", "pass123")
    assert user.email == "test@example.com"
    assert user.is_active == True  # Wrong: new users should be inactive

After (Fixed Test)
def test_user_creation():
    user = create_user("test@example.com", "pass123")
    assert user.email == "test@example.com"
    assert user.is_active == False  # Correct: new users are inactive
```

Pattern 4: Missing Mock
```python
Before (Fails due to real API call)
def test_payment_processing():
    result = process_payment(100, "USD")
    assert result.status == "success"

After (Fixed with mock)
@patch('services.payment_gateway.charge')
def test_payment_processing(mock_charge):
    mock_charge.return_value = {"status": "success"}
    result = process_payment(100, "USD")
    assert result.status == "success"
```

Pattern 5: Race Condition
```python
Before (Flaky due to race condition)
def test_async_operation():
    start_async_task()
    result = get_result()  # May not be ready yet
    assert result.status == "complete"

After (Fixed with proper waiting)
def test_async_operation():
    task = start_async_task()
    result = task.wait_for_completion(timeout=5)
    assert result.status == "complete"
```

Output File Requirements

fix-summary-{attempt}.md

```markdown
Test Fix Summary - Attempt {N}

Failures Analyzed
Total failures: X

Failure 1: test_user_creation
Error Message:
```
AssertionError: assert True == False
```

Root Cause:
Test expected new users to be active, but implementation correctly creates inactive users pending verification.

Fix Applied:
Updated test expectation to assert `is_active == False`

Confidence Level: High
Files Modified: tests/unit/test_user_service.py

Failure 2: test_calculate_total
Error Message:
```
AssertionError: assert 100 == 200
```

Root Cause:
Implementation was not multiplying price by quantity.

Fix Applied:
Updated `calculate_total()` to multiply price by quantity

Confidence Level: High
Files Modified: src/services/order_service.py

Summary
- Code bugs fixed: 1
- Test bugs fixed: 1
- Configuration issues: 0
- Environment issues: 0

Confidence Assessment
- High confidence: 2 fixes
- Medium confidence: 0 fixes
- Low confidence: 0 fixes

Next Steps
Re-running tests to verify fixes
```

Confidence Levels

High Confidence
- Clear bug with obvious fix
- Test expectation clearly wrong
- Missing validation or error handling
- Documented behavior mismatch

Medium Confidence
- Complex logic error
- Unclear requirements
- Multiple possible fixes
- Partial understanding of root cause

Low Confidence
- Environmental or infrastructure issue
- Unclear error message
- Cannot reproduce locally
- May require manual intervention

Retry Strategy

Attempt 1-2: Quick Fixes
- Fix obvious bugs
- Fix clear test errors
- Add missing validations
- Fix configuration issues

Attempt 3-4: Deeper Analysis
- Analyze complex logic errors
- Fix race conditions
- Refactor problematic code
- Add missing error handling

Attempt 5: Last Resort
- Document unfixable issues
- Provide manual fix instructions
- Explain why auto-fix failed
- Suggest next steps

Validation Before Committing Fix

Before committing a fix:
1. Understand the root cause completely
2. Verify the fix addresses the root cause
3. Check that fix doesn't break other tests
4. Ensure fix follows code conventions
5. Add comments explaining the fix
6. Update documentation if needed

Success Criteria

A fix is successful when:
1. Root cause is correctly identified
2. Fix addresses the root cause (not symptoms)
3. Fix doesn't introduce new bugs
4. Fix follows project conventions
5. Tests pass after the fix
6. Fix is well-documented

Failure Criteria

Stop auto-fixing if:
1. Same test fails 3 times with different fixes
2. Fixes are causing other tests to fail
3. Root cause cannot be determined
4. Fix requires architectural changes
5. Fix requires manual intervention
6. Environmental issue cannot be resolved

Reporting

Always report:
1. Number of failures analyzed
2. Root cause for each failure
3. Fix applied for each failure
4. Confidence level in each fix
5. Files modified
6. Tests that should now pass
7. Any remaining issues

