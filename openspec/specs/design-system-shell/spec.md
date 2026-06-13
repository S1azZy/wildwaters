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
The system SHALL require accessible labels and explicit supported states for shared interactive controls.

#### Scenario: Icon-only control
- **GIVEN** an icon button is constructed
- **WHEN** no accessible label is provided
- **THEN** the component rejects the invalid control

#### Scenario: Text or select field
- **GIVEN** a shared text or select field is constructed
- **WHEN** neither a visible label nor an ARIA label is provided
- **THEN** the component rejects the invalid field

#### Scenario: Disabled field
- **GIVEN** a shared field is disabled or has validation errors
- **WHEN** it is rendered
- **THEN** the output exposes matching disabled or error semantics

#### Scenario: Unsupported constrained option
- **GIVEN** a shared button, badge, card, field, flash, or icon button receives an option outside its documented closed set
- **WHEN** the component is constructed
- **THEN** the component rejects the unknown option instead of silently inventing a style
