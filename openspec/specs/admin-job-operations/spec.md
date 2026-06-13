# Admin Job Operations Specification

## Purpose

Define the implemented authorization boundary for the Mission Control Jobs
operational dashboard mounted inside the Wild Waters application.

## Requirements

### Requirement: Application-authenticated jobs dashboard
The system SHALL protect the jobs dashboard with Wild Waters session and role checks rather than Mission Control HTTP basic authentication.

#### Scenario: Guest access
- **GIVEN** a visitor has no active application session
- **WHEN** the visitor requests `/admin/jobs`
- **THEN** the system redirects to application sign-in with an authentication-required message

#### Scenario: Non-admin member access
- **GIVEN** an authenticated user whose role is `member`
- **WHEN** the user requests `/admin/jobs`
- **THEN** the system redirects to the explore homepage with an admin-required message

#### Scenario: Admin access
- **GIVEN** an authenticated user whose role is `admin`
- **WHEN** the user requests `/admin/jobs`
- **THEN** the system renders the jobs dashboard successfully
