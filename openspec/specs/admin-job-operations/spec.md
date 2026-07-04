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

### Requirement: Jobs route coexistence with application admin namespace
The system SHALL keep the Mission Control Jobs dashboard protected and
reachable when the application-owned admin namespace is introduced.

#### Scenario: Jobs route remains protected
- **GIVEN** the application-owned admin routes exist
- **WHEN** a visitor requests `/admin/jobs`
- **THEN** the existing jobs dashboard authorization behavior remains in force for guest, member, and admin users

#### Scenario: Admin namespace does not shadow jobs engine
- **GIVEN** an authenticated admin can open an application-owned admin page
- **WHEN** the admin requests `/admin/jobs`
- **THEN** the system routes the request to the Mission Control Jobs engine rather than an application-owned Inertia admin page
