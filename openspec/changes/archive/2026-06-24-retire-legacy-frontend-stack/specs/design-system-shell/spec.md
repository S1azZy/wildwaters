## MODIFIED Requirements

### Requirement: Accessible shared controls
The system SHALL render shared shell controls, auth form controls, and flash
messages with accessible labels, roles, states, and announcements through the
React frontend.

#### Scenario: Navigation links
- **GIVEN** the shared application shell is rendered
- **WHEN** a visitor navigates by keyboard or assistive technology
- **THEN** brand, Explore, sign-in, and profile actions are exposed as named
  links with Rails-generated destinations

#### Scenario: Auth form fields
- **GIVEN** a migrated authentication or password-reset page is rendered
- **WHEN** a visitor focuses or submits the form
- **THEN** each field has a visible label and appropriate input semantics
- **AND** disabled or processing controls expose matching browser states

#### Scenario: Flash messages
- **GIVEN** Rails provides notice or alert flash data
- **WHEN** the React shell renders the page
- **THEN** notice messages use status semantics with polite announcement priority
- **AND** alert messages use alert semantics with assertive announcement
  priority

#### Scenario: Accessibility regression check
- **GIVEN** a shared shell, auth shell, or migrated page component is tested
- **WHEN** frontend component tests run
- **THEN** configured accessibility checks complete without violations for the
  covered shell and form interactions
