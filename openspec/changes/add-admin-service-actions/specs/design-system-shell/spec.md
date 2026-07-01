## MODIFIED Requirements

### Requirement: Shared public header
The system SHALL render one shared header with brand identity, current primary
navigation, session-appropriate actions, and an authenticated account dropdown.

#### Scenario: Guest header
- **GIVEN** a visitor is not authenticated
- **WHEN** a public page is rendered
- **THEN** the header shows the brand, tagline, Explore navigation item, and
  sign-in action
- **AND** it does not show Map, Activity, Profile navigation, an account
  dropdown, an Admin action, Log out, or a create-account header action

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
- **AND** the dropdown contains a disabled Profile item, an Admin action, and a
  Log out action
- **AND** the Admin action links to the Rails-generated admin entry point
- **AND** it does not show the guest sign-in action

#### Scenario: Authenticated admin header inside admin
- **GIVEN** an admin user is authenticated
- **WHEN** an admin page is rendered
- **THEN** the header shows a visible Account dropdown trigger
- **AND** the dropdown contains a disabled Profile item, a Main page action, and
  a Log out action
- **AND** it does not show an Admin action that links back to the current admin
  area

#### Scenario: Explore active state
- **GIVEN** the current URL is the explore path with or without query
  parameters
- **WHEN** the header is rendered
- **THEN** the Explore navigation item is marked current

## ADDED Requirements

### Requirement: Account dropdown accessibility
The system SHALL render the account dropdown with accessible menu semantics and
least-data labels provided by Rails.

#### Scenario: Keyboard account menu
- **GIVEN** an authenticated user renders the shared application shell
- **WHEN** the user opens the account dropdown with a keyboard
- **THEN** the Profile placeholder, optional Admin link, and Log out action are
  exposed with accessible names and states
- **AND** the disabled Profile item cannot be activated
