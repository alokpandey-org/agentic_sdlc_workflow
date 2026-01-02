# Implementation Generation Policy

## Agent Role

You are implementing a user story in an existing codebase following established patterns and conventions.

## Context Discovery Instructions

1. Review the existing application BRD to understand current system
2. Study the existing application architecture documentation
3. Analyze the user story requirements and acceptance criteria
4. Perform impact analysis on existing functionality
5. Identify breaking changes and affected components
6. Discover the codebase structure in the workspace root
7. Find relevant context in the specified context directories
8. Identify existing patterns, conventions, and architecture
9. Locate related files, classes, APIs, and database models
10. Understand the testing framework and patterns
11. Review existing similar implementations
12. Identify configuration and deployment requirements
13. Check for API versioning requirements
14. Analyze data migration needs

## Implementation Requirements

### Code Quality Standards

1. **Follow Existing Patterns**: Use the same patterns, conventions, and style as existing code
2. **Maintain Backward Compatibility**: Unless explicitly stated, don't break existing functionality
3. **Error Handling**: Add proper error handling and validation for all edge cases
4. **Logging**: Include appropriate logging for debugging and monitoring following existing logging patterns
5. **Documentation**: Add clear comments, docstrings, and inline documentation
6. **Performance**: Consider performance implications and optimize where needed
7. **Security**: Follow security best practices and validate all inputs
8. **Testability**: Write code that is easy to test

### Code Organization

1. **File Structure**: Follow existing file and directory organization. Understand how the utilities and libraries are structured and how they are used.
2. **Naming Conventions**: Use consistent naming for files, classes, functions, variables
3. **Module Organization**: Group related functionality logically
4. **Separation of Concerns**: Keep business logic, data access, and presentation separate
5. **DRY Principle**: Don't repeat yourself - extract common functionality
6. **SOLID Principles**: Follow SOLID design principles where applicable

### Implementation Scope

#### What to Implement

1. **Core Functionality**: All features described in the user story
2. **Database Changes**: Migrations, models, schema updates
3. **API Changes**: New endpoints, request/response schemas, versioning
4. **Business Logic**: Calculations, validations, state management
5. **Configuration**: Environment variables, settings, feature flags
6. **Documentation**: Code comments, API docs, README updates
7. **Error Handling**: Graceful error handling and user-friendly messages
8. **Logging**: Appropriate log levels and messages

#### What NOT to Implement

1. **Tests**: Tests will be generated in a separate step
2. **Unrelated Features**: Stay focused on the user story
3. **Premature Optimization**: Don't optimize unless needed
4. **Breaking Changes**: Avoid unless explicitly required

### Database Changes

If database changes are needed:

1. **Create Migrations**: Generate proper migration scripts
2. **Backward Compatible**: Ensure migrations can be rolled back
3. **Data Migration**: Include data migration if needed
4. **Indexes**: Add appropriate indexes for performance
5. **Constraints**: Add necessary constraints and validations
6. **Documentation**: Document schema changes

### API Changes

If API changes are needed:

1. **Impact Analysis**: Identify all existing API consumers and affected endpoints
2. **Breaking Changes Detection**: Determine if changes break existing API contracts
3. **Versioning Strategy**:
   - Use API versioning (e.g., /v1/, /v2/) for ALL breaking changes
   - Maintain old version during deprecation period
   - Document migration path from old to new version
4. **Backward Compatibility**:
   - Maintain compatibility with existing clients whenever possible
   - If breaking changes are unavoidable, implement API versioning
   - Support both old and new versions during transition period
5. **Request Validation**: Validate all request parameters
6. **Response Format**: Follow existing response format conventions
7. **Error Responses**: Return consistent error responses
8. **Documentation**:
   - Update API documentation for new version
   - Document differences between versions
   - Provide migration guide for clients
9. **Deprecation Plan**:
   - Set deprecation timeline for old API version
   - Add deprecation warnings in responses
   - Communicate timeline to API consumers

### Configuration Changes

If configuration changes are needed:

1. **Environment Variables**: Add new environment variables with defaults
2. **Configuration Files**: Update configuration files
3. **Feature Flags**: Use feature flags for gradual rollout
4. **Documentation**: Document all configuration options
5. **Validation**: Validate configuration at startup

### Error Handling Strategy

1. **Input Validation**: Validate all inputs at entry points
2. **Exception Handling**: Catch and handle exceptions appropriately
3. **Error Messages**: Provide clear, actionable error messages
4. **Logging**: Log errors with sufficient context
5. **Graceful Degradation**: Fail gracefully when possible
6. **User Feedback**: Return user-friendly error messages

### Security Considerations

1. **Input Validation**: Validate and sanitize all user inputs
2. **Authentication**: Verify user authentication where required
3. **Authorization**: Check user permissions before operations
4. **SQL Injection**: Use parameterized queries
5. **XSS Prevention**: Escape output appropriately
6. **CSRF Protection**: Include CSRF tokens where needed
7. **Sensitive Data**: Don't log sensitive information

### Performance Considerations

1. **Database Queries**: Optimize queries, use indexes
2. **Caching**: Implement caching where appropriate
3. **Lazy Loading**: Load data only when needed
4. **Pagination**: Paginate large result sets
5. **Async Operations**: Use async for I/O-bound operations
6. **Resource Cleanup**: Properly close connections and resources

## Impact Analysis and Breaking Changes

**CRITICAL**: Before implementing, analyze the impact on existing functionality.

### 1. Existing Functionality Impact Assessment

Before writing any code:

#### Identify Affected Components

- List all existing files, classes, functions that will be modified
- Identify all callers/consumers of modified components
- Map dependencies and integration points
- Check for third-party integrations affected

#### Breaking Changes Detection

- API signature changes (parameters, return types)
- Database schema modifications
- Configuration changes
- Behavior changes in existing features
- Data format changes

#### Backward Compatibility Analysis

- Can existing clients continue to work?
- Will existing data remain valid?
- Are existing integrations affected?
- Do existing tests need updates?

### 2. Handling Breaking Changes

When breaking changes are unavoidable:

#### API Versioning

- Create new API version (e.g., /api/v2/)
- Maintain old version during deprecation period
- Implement version routing logic
- Add deprecation warnings to old version
- Document migration path

#### Database Schema Changes

- Create backward-compatible migrations when possible
- Use multi-step migrations for breaking changes:
  - Step 1: Add new columns/tables (backward compatible)
  - Step 2: Migrate data
  - Step 3: Remove old columns/tables (after deprecation)
- Include rollback procedures
- Test migrations on production-like data

#### Data Migration

- Write migration scripts for existing data
- Include data validation
- Implement rollback capability
- Test with production data volume
- Plan for zero-downtime migration if needed

#### Existing Feature Updates

- Update all affected existing features
- Maintain backward compatibility where possible
- Add feature flags for gradual rollout
- Update integration points
- Modify existing tests

### 3. Implementation Strategy for Breaking Changes

Follow this order:

**Phase 1: Preparation**

- Create new API version endpoints (if needed)
- Add new database columns/tables (backward compatible)
- Implement feature flags
- Add deprecation warnings

**Phase 2: New Implementation**

- Implement new functionality in new version
- Write data migration scripts
- Update configuration
- Add new tests

**Phase 3: Migration**

- Run data migrations
- Update internal consumers to new version
- Monitor for issues
- Validate data integrity

**Phase 4: Deprecation**

- Mark old version as deprecated
- Communicate to external consumers
- Set deprecation timeline
- Monitor old version usage

**Phase 5: Cleanup (after deprecation period)**

- Remove old API version
- Remove old database columns
- Clean up feature flags
- Remove deprecated code

### 4. Mandatory Documentation for Breaking Changes

When implementing breaking changes, include:

#### Migration Guide

- What changed and why
- How to migrate from old to new
- Code examples for both versions
- Timeline for deprecation

#### API Version Documentation

- Differences between versions
- Migration path
- Deprecation schedule
- Support policy

#### Rollback Procedures

- How to rollback if issues occur
- Data rollback procedures
- Configuration rollback
- Communication plan

### 5. Impact Analysis Checklist

Before finalizing implementation:

- [ ] All affected existing components identified
- [ ] Breaking changes documented
- [ ] API versioning implemented (if needed)
- [ ] Backward compatibility maintained (or migration path provided)
- [ ] Data migration scripts created (if needed)
- [ ] Rollback procedures documented
- [ ] Existing features updated to work with changes
- [ ] Integration points updated
- [ ] Deprecation timeline set (if applicable)
- [ ] Migration guide created (if breaking changes)
- [ ] All existing tests updated
- [ ] New tests cover backward compatibility

## Output File Requirements

Generate the following files in the output directory:

### 1. changes-summary.md

```markdown
# Implementation Summary

## Story

STORY-XXX: Story Title

## Files Created

- path/to/new/file.py - Description

## Files Modified

- path/to/existing/file.py - Description of changes

## Database Changes

- Migration: XXXX_migration_name.py
- Tables: table_name (created/modified)
- Columns: column_name (added/modified)

## API Changes

- New endpoints: POST /api/endpoint
- Modified endpoints: GET /api/endpoint (added parameter)
- Breaking changes: None / List of breaking changes

## Configuration Changes

- Environment variables: NEW_VAR (default: value)
- Settings: setting_name (updated)

## Migration Steps

1. Run database migrations
2. Update environment variables
3. Restart services

## Rollback Procedure

1. Revert database migrations
2. Restore previous configuration
3. Redeploy previous version

## Breaking Changes

None / List of breaking changes with migration guide

## Notes

Additional implementation notes
```

### 2. pr.json

A JSON file that can be used directly with GitHub CLI (`gh pr create`) to create a pull request.

**IMPORTANT**: Use the base branch and story branch names provided in the workspace context.

- **base**: The branch to merge INTO (provided as "Base Branch" in workspace context)
- **head**: The current story branch (provided as "Story Branch" in workspace context)

For dependent stories, the base branch might be another story branch (e.g., `story/STORY-122`) instead of `main`.

```json
{"title":"feat(STORY-XXX): Story Title","body":"## User Story\n\nSTORY-XXX: Story Title\n\nAs a [role], I want [goal], so that [benefit]\n\n## Implementation\n\nBrief description of the implementation approach\n\n## Changes\n\n- Feature 1: Description\n- Feature 2: Description\n\n## Database Changes\n\n- Migration: XXXX_migration_name.py\n- Tables: table_name (created/modified)\n\n## API Changes\n\n- New endpoints: POST /api/endpoint\n- Modified endpoints: GET /api/endpoint (added parameter)\n- Breaking changes: None\n\n## Testing\n\n- [ ] Unit tests (to be added in next step)\n- [ ] Integration tests (to be added in next step)\n- [ ] Manual testing completed\n\n## Acceptance Criteria\n\n- [x] AC1: Description\n- [x] AC2: Description\n\n## Migration Guide\n\nSteps for deploying this change:\n1. Run database migrations\n2. Update environment variables\n3. Restart services\n\n## Rollback Plan\n\nSteps for rolling back if needed:\n1. Revert database migrations\n2. Restore previous configuration\n3. Redeploy previous version\n\n## Checklist\n\n- [x] Code follows project conventions\n- [x] Documentation updated\n- [x] No breaking changes / Breaking changes documented\n- [ ] Tests added (next step)\n- [x] Ready for review","base":"base-branch","head":"current-story-branch"}
```

Key requirements for pr.json:

- **title**: PR title following conventional commits format: `feat(STORY-XXX): Brief description`
- **body**: Complete PR description in markdown format with `\n` for newlines
- **base**: Target branch to merge INTO - MUST use the "Base Branch" from workspace context (could be "main", "develop", or another story branch like "story/STORY-122" for dependent stories)
- **head**: Source branch name - MUST use the "Story Branch" from workspace context (e.g., "story/STORY-XXX")

The body should include:

- User Story section with story ID, title, and user story format
- Implementation section describing the approach
- Changes section listing key changes
- Database Changes section (if applicable)
- API Changes section (if applicable)
- Testing section with checkboxes
- Acceptance Criteria section with checkboxes
- Migration Guide section with deployment steps
- Rollback Plan section with rollback steps
- Checklist section with review items

Example body content structure:

```markdown
## User Story

STORY-123: Add user authentication

As a user, I want to log in securely, so that my data is protected

## Implementation

Implemented JWT-based authentication with refresh tokens

## Changes

- Added authentication middleware
- Created login/logout endpoints
- Implemented token refresh mechanism

## Database Changes

- Migration: 001_add_users_table.sql
- Tables: users (created), sessions (created)

## API Changes

- New endpoints: POST /api/auth/login, POST /api/auth/logout, POST /api/auth/refresh
- Breaking changes: None

## Testing

- [ ] Unit tests (to be added in next step)
- [ ] Integration tests (to be added in next step)
- [x] Manual testing completed

## Acceptance Criteria

- [x] Users can log in with email and password
- [x] JWT tokens are generated on successful login
- [x] Tokens expire after configured time
- [x] Refresh tokens work correctly

## Migration Guide

1. Run database migrations: `npm run migrate`
2. Update environment variables: Add JWT_SECRET
3. Restart services

## Rollback Plan

1. Revert database migrations: `npm run migrate:rollback`
2. Remove JWT_SECRET from environment
3. Redeploy previous version

## Checklist

- [x] Code follows project conventions
- [x] Documentation updated
- [x] No breaking changes
- [ ] Tests added (next step)
- [x] Ready for review
```

## Code Style Guidelines

### Python

- Follow PEP 8
- Use type hints
- Write docstrings for all public functions
- Use meaningful variable names
- Keep functions small and focused

### JavaScript/TypeScript

- Follow project's ESLint configuration
- Use TypeScript types
- Write JSDoc comments
- Use async/await for promises
- Follow functional programming patterns

### General

- Maximum line length: 100 characters
- Use 4 spaces for indentation (or follow project convention)
- Add blank lines between logical sections
- Group imports logically
- Remove unused imports and variables

## Commit Message Format

Follow conventional commits:

```
feat(scope): brief description

Detailed description of changes

BREAKING CHANGE: description of breaking change (if any)

Closes STORY-XXX
```

## Validation Checklist

Before finalizing, verify:

- [ ] All acceptance criteria are met
- [ ] Code follows existing patterns
- [ ] Error handling is comprehensive
- [ ] Logging is appropriate
- [ ] Documentation is updated
- [ ] Configuration changes are documented
- [ ] Migration steps are clear
- [ ] Rollback procedure is defined
- [ ] No tests are included (tests come later)
- [ ] Changes are focused on the user story

## Common Pitfalls to Avoid

1. **Over-engineering**: Keep it simple, don't add unnecessary complexity
2. **Ignoring Existing Patterns**: Always follow existing code patterns
3. **Missing Error Handling**: Handle all error cases
4. **Poor Naming**: Use clear, descriptive names
5. **Tight Coupling**: Keep components loosely coupled
6. **Missing Documentation**: Document all public APIs
7. **Hardcoded Values**: Use configuration for values that may change
8. **Ignoring Edge Cases**: Consider and handle edge cases

## Success Criteria

The implementation is successful when:

1. All acceptance criteria are met
2. Code follows project conventions
3. No breaking changes (unless required)
4. Error handling is comprehensive
5. Documentation is complete
6. Migration steps are clear
7. Rollback procedure is defined
8. Changes are focused and minimal
