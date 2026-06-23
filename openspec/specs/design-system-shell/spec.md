# Design System Shell Specification

## Purpose

Define the implemented shared application header, authentication shell, flash,
and accessible reusable-control behavior visible across Wild Waters pages.

## Requirements

### Requirement: Shared public header
The system SHALL render one shared header with brand identity, current primary navigation, and session-appropriate actions.

#### Scenario: Guest header
- **GIVEN** a visitor is not authenticated
- **WHEN** a public page is rendered
- **THEN** the header shows the brand, tagline, Explore navigation item, and sign-in action
- **AND** it does not show Map, Activity, Profile navigation, or a create-account header action

#### Scenario: Authenticated header
- **GIVEN** a user is authenticated
- **WHEN** a public page is rendered
- **THEN** the header shows a Profile action linked to the dashboard
- **AND** it does not show the sign-in action

#### Scenario: Explore active state
- **GIVEN** the current URL is the explore path with or without query parameters
- **WHEN** the header is rendered
- **THEN** the Explore navigation item is marked current

### Requirement: Shared authentication shell
The system SHALL render sign-in, registration, and recovery pages through the shared authentication shell.

#### Scenario: Sign-in shell
- **GIVEN** a visitor opens sign-in
- **WHEN** the page is rendered
- **THEN** it uses the session variant, contains the auth card and alternate registration action, and contains no auth footer

#### Scenario: Registration shell
- **GIVEN** a visitor opens registration
- **WHEN** the page is rendered
- **THEN** it uses the registration variant, contains the auth card and alternate sign-in action, and contains no auth footer

#### Scenario: Recovery shell
- **GIVEN** a visitor opens password recovery
- **WHEN** the page is rendered
- **THEN** it uses the recovery variant, contains the auth card and alternate sign-in action, and contains no auth footer

### Requirement: Shared flash semantics
The system SHALL render non-blank application flash messages through the shared shell with accessible live-region semantics.

#### Scenario: Notice flash
- **GIVEN** a request sets a notice message
- **WHEN** the next page renders
- **THEN** the shared flash uses status semantics with polite announcement priority

#### Scenario: Alert flash
- **GIVEN** a request sets an alert message
- **WHEN** the page renders
- **THEN** the shared flash uses alert semantics with assertive announcement priority

#### Scenario: Blank flash
- **GIVEN** a flash entry has no message
- **WHEN** the flash collection is rendered
- **THEN** the blank entry is omitted

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
