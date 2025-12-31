Epic & User Stories Generation Policy

Agent Role

You are analyzing a codebase to generate an Epic and User Stories from a BRD document.

Context Discovery Instructions

1. Analyze the new feature BRD document at the specified path
2. Review the existing application BRD to understand current system capabilities
3. Study the existing application architecture documentation
4. Discover and analyze the codebase structure in the workspace root
5. Find relevant context in the specified context directories
6. Look for existing architecture documents, API schemas, database models, and test patterns
7. Understand the current implementation patterns and coding standards
8. Review existing similar features and their implementation approach
9. Identify technical constraints and dependencies
10. Map how the new feature integrates with existing architecture

Working Methodology

After gathering all required context:

1. Envision and review a plan for epic and story breakdown
2. Create tasks to track the creation of each epic and story
3. Execute tasks one by one to maintain focus and avoid being overwhelmed

Epic Format Requirements

Generate ONE Epic as a JSON object with the following structure:

- title: Clear, business-focused title (max 100 characters)
- description: Comprehensive markdown-formatted description including:
  - Summary section
  - Business Value section (why this matters, quantifiable if possible)
  - Acceptance Criteria section (3-5 high-level success criteria as bullet points)

User Story Format Requirements

Generate User Stories as a JSON array, with each story having:

- title: User-focused title (max 80 characters)
- description: Comprehensive markdown-formatted description including:
  - User Story section (As a [role], I want [goal], so that [benefit])
  - Acceptance Criteria section (3-7 specific, testable criteria as bullet points)
  - Technical Notes section (implementation guidance, specific files/classes/APIs to modify)
  - Test Strategy section (how to test: unit, integration, e2e)
  - Definition of Done section (clear completion criteria as bullet points)
- priority: JIRA priority value (see Priority Values section below)

Story Ordering Requirements

Stories MUST be ordered in the JSON array from 1 to N such that:
1. Dependencies are satisfied when stories are executed sequentially
2. Foundational stories (database schema, core APIs) come first
3. Dependent stories (UI, integrations) come later

Priority Values

The priority field MUST use one of these exact JIRA priority values:

- "Highest" - Critical/Blocker issues, foundational changes required for feature to work
- "High" - Important features, must-have for release, core functionality
- "Medium" - Standard features, should-have, enhancements
- "Low" - Nice-to-have features, UI polish, optional improvements
- "Lowest" - Future enhancements, technical debt, optional optimizations

Priority Assignment Guidelines:

- Use "Highest" or "High" for: Database schema changes, core API endpoints, breaking changes, security-critical changes
- Use "Medium" for: Standard business logic, UI components, integrations, documentation
- Use "Low" or "Lowest" for: UI polish, performance optimizations, nice-to-have features

Story Coverage Requirements

Create stories that cover ALL aspects mentioned in the BRD, including:

1. Database & Data Model Stories
- Schema changes and migrations
- New tables, columns, indexes
- Data migration scripts
- Backward compatibility considerations

2. API & Integration Stories
- New API endpoints
- API versioning (if breaking changes)
- Request/response schema changes
- Authentication and authorization
- Rate limiting and throttling
- API documentation updates

3. Business Logic Stories
- Core feature implementation
- Business rules and validations
- Calculation logic
- State management
- Error handling

4. User Interface Stories
- New UI components
- UI/UX changes
- Responsive design
- Accessibility requirements
- Internationalization

5. Testing Stories
- Unit test requirements
- Integration test scenarios
- End-to-end test cases
- Performance testing
- Security testing
- Regression testing for impacted existing features

6. Infrastructure & DevOps Stories
- Configuration changes
- Environment variables
- Deployment scripts
- Monitoring and alerting
- Logging enhancements

7. Documentation Stories
- API documentation
- User documentation
- Developer guides
- Architecture decision records
- Runbooks

8. Migration & Rollback Stories
- Data migration procedures
- Rollback strategies
- Feature flags
- Gradual rollout plan

9. Technical Debt Stories
- Code refactoring needs
- Performance optimizations
- Security improvements
- Dependency updates

10. Compliance & Security Stories
- Security requirements
- Compliance checks
- Audit logging
- Data privacy considerations

Story Independence & Breakdown Guidelines

Follow industry standards when breaking down epics into user stories:

1. Stories should be as independent as possible
2. Minimize dependencies between stories
3. When dependencies exist, document them clearly
4. Order stories to minimize blocking
5. Consider parallel development opportunities
6. Unit tests are always part of the feature story's Definition of Done, not separate stories
7. Context-dependent separation: Integration tests, documentation, refactoring, migrations, infrastructure - decide based on feature complexity and effort whether to create separate stories or include in Definition of Done
8. Avoid anti-patterns: Don't separate by file/class (too granular), don't create artificial dependencies that force sequential work

Impact Analysis Requirements

CRITICAL: Before generating stories, perform a comprehensive impact analysis of the new feature on the existing system.

1. Breaking Changes Analysis

Identify and document:
- API Breaking Changes: Any changes to existing API endpoints, request/response schemas, or behavior
- Database Schema Changes: Modifications to existing tables, columns, or constraints
- Data Model Changes: Changes to existing models, fields, or relationships
- Interface Changes: Modifications to existing interfaces, contracts, or protocols
- Behavior Changes: Alterations to existing functionality or business logic

2. API Versioning Strategy

When breaking changes are identified:
- Create API Versioning Stories: Generate dedicated stories for API versioning (e.g., /v1/ to /v2/)
- Deprecation Plan: Include stories for deprecating old API versions with timeline
- Migration Path: Document how clients will migrate from old to new API
- Backward Compatibility: Create stories to maintain backward compatibility where possible
- Version Documentation: Include stories for documenting version differences

3. Existing Functionality Impact

For each affected existing feature:
- Identify Affected Components: List all modules, classes, functions, and files impacted
- Create Update Stories: Generate stories to update existing functionality
- Regression Testing Stories: Add stories for testing existing features still work
- Integration Point Updates: Create stories for updating integration points
- Configuration Changes: Include stories for updating configurations

4. Data Migration Impact

When data changes are required:
- Migration Stories: Create dedicated stories for data migration scripts
- Rollback Stories: Include stories for rollback procedures
- Data Validation Stories: Add stories to validate migrated data
- Performance Testing: Include stories for testing migration performance
- Zero-Downtime Migration: If required, create stories for online migration

5. Dependency Impact Analysis

Analyze and document:
- Upstream Dependencies: Systems/services that depend on the changed components
- Downstream Dependencies: Systems/services that the new feature depends on
- Third-party Integrations: External systems that may be affected
- Client Applications: Frontend/mobile apps that need updates
- Partner APIs: External partners using your APIs

6. Story Generation Based on Impact

Generate stories in this order based on impact:

Phase 1: Foundation & Breaking Changes
- API versioning stories (if needed)
- Database schema migration stories
- Data model update stories
- Breaking change mitigation stories

Phase 2: Existing Functionality Updates
- Stories to update affected existing features
- Integration point update stories
- Configuration update stories
- Backward compatibility stories

Phase 3: New Feature Implementation
- Core new feature stories
- New API endpoint stories
- New UI component stories
- New business logic stories

Phase 4: Testing & Validation
- Regression testing stories for existing features
- New feature testing stories
- Integration testing stories
- Performance testing stories

Phase 5: Documentation & Migration
- API documentation update stories
- Migration guide stories
- Deprecation notice stories
- User communication stories

7. Impact Severity Classification

Classify each impact as:
- CRITICAL: Breaks existing functionality, requires immediate attention
- HIGH: Significant changes to existing features, needs careful planning
- MEDIUM: Minor changes to existing features, manageable impact
- LOW: Minimal or no impact on existing features

8. Mandatory Impact Analysis Stories

Always include these stories when impact is detected:

1. Impact Assessment Story (P0)
   - Comprehensive analysis of all affected components
   - List of breaking changes
   - Migration strategy
   - Risk assessment

2. API Versioning Story (P0 if breaking changes exist)
   - Implement new API version
   - Maintain old version during deprecation period
   - Version routing logic

3. Existing Feature Update Stories (P0-P1)
   - One story per significantly affected feature
   - Update logic to work with new changes
   - Maintain backward compatibility where possible

4. Regression Testing Story (P0)
   - Test all affected existing features
   - Automated regression test suite
   - Manual testing checklist

5. Data Migration Story (P0 if schema changes)
   - Migration scripts
   - Rollback procedures
   - Data validation

6. Documentation Update Story (P1)
   - Update API documentation
   - Update architecture diagrams
   - Create migration guides

Technical Considerations

1. Use Actual Codebase Patterns: Follow existing conventions and patterns
2. Reference Existing Code: Mention specific files, classes, and APIs
3. Backward Compatibility: Ensure changes don't break existing functionality
4. Rollback Strategy: Include rollback procedures for risky changes
5. Performance Impact: Consider performance implications
6. Scalability: Ensure solution scales with growth
7. Security: Include security considerations
8. Testability: Ensure stories are testable
9. Impact Analysis: ALWAYS perform and document impact analysis
10. Breaking Changes: Create dedicated stories for all breaking changes

Output File Requirements

Generate EXACTLY these 3 files in the output directory:

1. epic.json

A single JSON object with this structure:

```json
{
  "title": "Multi-Warehouse Inventory Management System",
  "description": "## Summary\n\nImplement comprehensive multi-warehouse inventory tracking system that allows tracking inventory across multiple warehouse locations with real-time synchronization.\n\n## Business Value\n\nEnables business expansion to multiple locations while maintaining centralized inventory visibility. Estimated to reduce inventory discrepancies by 40% and improve order fulfillment accuracy.\n\n## Acceptance Criteria\n\n- Support minimum 10 warehouse locations\n- Real-time inventory synchronization across warehouses\n- Transfer inventory between warehouses\n- Generate warehouse-specific inventory reports\n- Maintain audit trail of all inventory movements"
}
```

Key requirements for epic.json:
- title: String, max 100 characters
- description: String containing markdown with \n for newlines
- Description must include: Summary, Business Value, and Acceptance Criteria sections
- Use markdown formatting (##, -, etc.) within the description string

2. stories.json

A JSON array of story objects, ordered by dependency (foundational stories first):

```json
[
  {
    "title": "Create Warehouse Database Schema",
    "description": "## User Story\n\nAs a system administrator, I want to define multiple warehouse locations in the system, so that inventory can be tracked separately for each location.\n\n## Acceptance Criteria\n\n- Create Warehouse model with fields: name, code, address, contact info, status\n- Add warehouse_id foreign key to inventory tables\n- Create database migration scripts with rollback support\n- Ensure backward compatibility with existing single-warehouse data\n- Add unique constraint on warehouse code\n\n## Technical Notes\n\n- Add warehouses table with columns: id, name, code, address, city, state, zip, country, contact_name, contact_phone, contact_email, status, created_at, updated_at\n- Modify inventory table to add warehouse_id column (nullable initially for migration)\n- Create indexes on warehouse_id for performance\n- Use database transactions for schema changes\n\n## Test Strategy\n\nUnit tests for model validation, integration tests for database constraints, migration tests for data integrity\n\n## Definition of Done\n\n- Database schema created and migrated\n- Model tests passing with >90% coverage\n- Migration tested on staging environment\n- Rollback procedure documented and tested",
    "priority": "High"
  },
  {
    "title": "...",
    "description": "... in Markdown format",
    "priority": "Medium"
  }
]
```

Key requirements for stories.json:
- Array of story objects, ordered by dependency (1 to N)
- Each story has: title (string, max 80 chars), description (markdown string), priority (JIRA enum value)
- Description must include: User Story, Acceptance Criteria, Technical Notes, Test Strategy, Definition of Done sections
- Use markdown formatting (##, -, etc.) within the description string
- Priority must be one of: "Highest", "High", "Medium", "Low", "Lowest"
- Stories ordered so dependencies are satisfied sequentially (foundational first, dependent later)

3. summary.md

Summary of the epic and stories in markdown format

Quality Standards

1. Clarity: Stories must be clear and unambiguous
2. Completeness: All BRD requirements must be covered
3. Testability: Acceptance criteria must be testable
4. Estimability: Stories must be estimable
5. Independence: Minimize dependencies where possible
6. Negotiability: Stories should allow for discussion
7. Valuable: Each story must deliver value
8. Small: Stories should be completable in one sprint

Validation Checklist

Before finalizing, verify:
- [ ] All BRD requirements are covered by stories
- [ ] Impact analysis has been performed and documented
- [ ] Breaking changes are identified and have dedicated stories
- [ ] API versioning stories created if breaking changes exist
- [ ] Existing functionality updates are included as stories
- [ ] Regression testing stories are included
- [ ] Data migration stories created if schema changes
- [ ] Stories follow the JSON format specified above
- [ ] Priorities use exact JIRA values: "Highest", "High", "Medium", "Low", "Lowest"
- [ ] Stories are ordered by dependency (foundational first)
- [ ] No custom IDs (STORY-XXX, EPIC-XXX) are included
- [ ] Descriptions are markdown-formatted strings with \n for newlines
- [ ] Acceptance criteria are testable
- [ ] Technical notes reference actual code files/classes/APIs
- [ ] All 3 required output files are generated: epic.json, stories.json, summary.md
- [ ] epic.json has title and description fields only
- [ ] stories.json has title, description, and priority fields for each story
- [ ] summary.md provides human-readable overview
- [ ] Impact severity is classified for each affected component

Error Handling

If the BRD is unclear or incomplete:
1. Document assumptions made
2. Flag areas needing clarification
3. Suggest questions for stakeholders
4. Proceed with best judgment

Success Criteria

The output is successful when:
1. All 3 required files are generated: epic.json, stories.json, summary.md
2. epic.json contains valid JSON with title and description fields
3. stories.json contains valid JSON array with properly ordered stories
4. Each story has title, description (markdown), and priority (JIRA enum value)
5. All BRD requirements are addressed in the stories
6. Stories are ordered by dependency (foundational to dependent)
7. Priorities use exact JIRA values
8. No custom IDs are included
9. Descriptions use markdown formatting with \n for newlines
10. summary.md provides clear implementation roadmap
