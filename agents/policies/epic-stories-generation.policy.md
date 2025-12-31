Epic & User Stories Generation Policy

Agent Role

You are analyzing a codebase to generate an Epic and User Stories from a BRD document.

Required Inputs

Before starting, you MUST request the following from the user:

1. Git code repository path (workspace root)
2. Policy file path (this policy document location)
3. New feature BRD document path (the feature to be implemented)
4. Existing application BRD document path (current system documentation)
5. Existing application architecture documentation path (system architecture, design docs)

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

Epic Format Requirements

Generate ONE Epic with the following structure:

- Epic ID: EPIC-XXX (auto-generated sequential ID)
- Epic Title: Clear, business-focused title (max 100 characters)
- Epic Description: Comprehensive description of the feature (2-3 paragraphs)
- Business Value: Why this matters to the business (quantifiable if possible)
- Acceptance Criteria: High-level success criteria (3-5 criteria)
- Dependencies: Technical and business dependencies
- Estimated Effort: T-shirt sizing (S/M/L/XL)
- Risk Assessment: Potential risks and mitigation strategies
- Stakeholders: Who is impacted by this feature

User Story Format Requirements

Generate MULTIPLE User Stories with the following structure for each:

- Story ID: STORY-XXX (auto-generated sequential ID)
- Story Title: User-focused title (max 80 characters)
- User Story: As a [role], I want [goal], so that [benefit]
- Acceptance Criteria: Specific, testable criteria (3-7 criteria per story)
- Technical Notes: Implementation guidance and technical considerations
- Dependencies: Other stories or systems this depends on
- Priority: P0 (Critical), P1 (High), P2 (Medium), P3 (Low)
- Estimated Effort: Story points (1, 2, 3, 5, 8, 13) or hours
- Test Strategy: How this should be tested (unit, integration, e2e)
- Definition of Done: Clear completion criteria

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

Story Prioritization Guidelines

P0 (Critical) - Must Have
- Core functionality required for feature to work
- Database schema changes
- Breaking API changes
- Security-critical changes

P1 (High) - Should Have
- Important business logic
- User-facing features
- Integration with existing systems
- Critical bug fixes

P2 (Medium) - Nice to Have
- Enhancements and optimizations
- Additional validations
- UI improvements
- Documentation

P3 (Low) - Future Consideration
- Technical debt cleanup
- Performance optimizations
- Nice-to-have features
- Future extensibility

Story Independence Guidelines

1. Stories should be as independent as possible
2. Minimize dependencies between stories
3. When dependencies exist, document them clearly
4. Order stories to minimize blocking
5. Consider parallel development opportunities

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

Generate the following files in the output directory:

1. epic.json
```json
{
  "epic_id": "EPIC-001",
  "title": "Epic Title",
  "description": "Detailed description",
  "business_value": "Business value statement",
  "acceptance_criteria": ["Criteria 1", "Criteria 2"],
  "dependencies": ["Dependency 1"],
  "estimated_effort": "L",
  "risk_assessment": "Risk analysis",
  "stakeholders": ["Stakeholder 1"]
}
```

2. stories.json
```json
[
  {
    "story_id": "STORY-001",
    "title": "Story Title",
    "user_story": "As a [role], I want [goal], so that [benefit]",
    "acceptance_criteria": ["AC1", "AC2"],
    "technical_notes": "Implementation notes",
    "dependencies": ["STORY-002"],
    "priority": "P0",
    "estimated_effort": 5,
    "test_strategy": "Unit and integration tests",
    "definition_of_done": ["DOD1", "DOD2"]
  }
]
```

3. summary.md
Human-readable summary with:
- Epic overview
- Prioritized backlog
- Dependency visualization
- Implementation roadmap
- Risk summary

4. dependencies.json
```json
{
  "nodes": [
    {"id": "STORY-001", "label": "Story Title"}
  ],
  "edges": [
    {"from": "STORY-001", "to": "STORY-002"}
  ]
}
```

5. top-priority-story.json
The highest priority story (P0, then P1, etc.) to implement first.

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
- [ ] Stories follow the specified format
- [ ] Priorities are assigned correctly
- [ ] Dependencies are documented
- [ ] Acceptance criteria are testable
- [ ] Technical notes reference actual code
- [ ] Effort estimates are reasonable
- [ ] All required output files are generated
- [ ] Summary is clear and actionable
- [ ] Impact severity is classified for each affected component

Error Handling

If the BRD is unclear or incomplete:
1. Document assumptions made
2. Flag areas needing clarification
3. Suggest questions for stakeholders
4. Proceed with best judgment

Success Criteria

The output is successful when:
1. All required files are generated
2. Epic and stories are well-formed
3. All BRD requirements are addressed
4. Stories are prioritized and estimated
5. Dependencies are clearly documented
6. Implementation roadmap is clear

