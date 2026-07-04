# Design System Shell Specification

## Purpose

Define the implemented shared application header, authentication shell, flash,
and accessible reusable-control behavior visible across Wild Waters pages.

## Requirements

### Requirement: Shared public header
The system SHALL render one shared header with brand identity, current primary
navigation, session-appropriate actions, and an authenticated account dropdown.

#### Scenario: Guest header
- **GIVEN** a visitor is not authenticated
- **WHEN** a public page is rendered
- **THEN** the header shows the brand, tagline, Explore navigation item, and sign-in action
- **AND** it does not show Map, Activity, Profile navigation, an account dropdown, an Admin action, Log out, or a create-account header action

#### Scenario: Authenticated member header
- **GIVEN** a member user is authenticated
- **WHEN** a public page is rendered
- **THEN** the header shows an account dropdown
- **AND** the dropdown contains a disabled Profile item and a Log out action
- **AND** it does not show the guest sign-in action or an Admin action

#### Scenario: Authenticated admin header
- **GIVEN** an admin user is authenticated
- **WHEN** a public page is rendered
- **THEN** the header shows a visible Account dropdown trigger
- **AND** the dropdown contains a disabled Profile item, an Admin action, and a Log out action
- **AND** the Admin action links to the Rails-generated admin entry point
- **AND** it does not show the guest sign-in action

#### Scenario: Authenticated admin header inside admin
- **GIVEN** an admin user is authenticated
- **WHEN** an admin page is rendered
- **THEN** the header shows a visible Account dropdown trigger
- **AND** the dropdown contains a disabled Profile item, a Main page action, and a Log out action
- **AND** it does not show an Admin action that links back to the current admin area

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

### Requirement: Account dropdown accessibility
The system SHALL render the account dropdown with accessible menu semantics and
least-data labels provided by Rails.

#### Scenario: Keyboard account menu
- **GIVEN** an authenticated user renders the shared application shell
- **WHEN** the user opens the account dropdown with a keyboard
- **THEN** the Profile placeholder, optional Admin link, and Log out action are exposed with accessible names and states
- **AND** the disabled Profile item cannot be activated

### Requirement: Kit-first shared controls
The system SHALL implement shared shell controls, auth controls, feedback, and
reusable UI states through shadcn primitives before introducing custom markup.

#### Scenario: Shared controls use kit primitives
- **WHEN** shared shell, flash, auth form, or reusable control source is inspected
- **THEN** buttons, fields, inputs, selects, cards, badges, alerts, overlays, and feedback states use shadcn-backed primitives or Wild Waters wrappers when a suitable primitive exists

#### Scenario: Auth forms preserve Rails and Inertia ownership
- **GIVEN** a migrated authentication or password-reset page uses shadcn-backed visual controls
- **WHEN** a visitor submits the form
- **THEN** Rails-generated URLs, Inertia form submission, CSRF-backed behavior, translated copy, processing state, and validation display continue to follow the existing auth contract

#### Scenario: Accessibility remains covered
- **WHEN** component tests cover shared shell controls, auth forms, or feedback states
- **THEN** accessible names, roles, disabled states, invalid states, live-region semantics, and configured accessibility checks remain valid
