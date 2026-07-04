## ADDED Requirements

### Requirement: Account dropdown sign-out
The system SHALL keep sign-out available to authenticated users from the shared
account dropdown while Rails retains session deletion ownership.

#### Scenario: Authenticated account dropdown
- **GIVEN** an authenticated user renders an application-owned Inertia page
- **WHEN** the shared header renders
- **THEN** it shows an account dropdown trigger instead of the guest sign-in
  action
- **AND** the dropdown contains a disabled Profile item
- **AND** the dropdown contains a bottom Log out action that submits the
  existing Rails-owned `DELETE /session` request

#### Scenario: Guest header remains sign-in only
- **GIVEN** a visitor is not authenticated
- **WHEN** an application-owned Inertia page renders
- **THEN** the shared header displays the sign-in action
- **AND** it does not display the account dropdown, Profile item, Admin item,
  or Log out action

### Requirement: Admin entry in account dropdown
The system SHALL expose the admin entry point in the account dropdown only to
authenticated admins.

#### Scenario: Admin sees admin entry
- **GIVEN** an authenticated user whose role is `admin`
- **WHEN** an application-owned Inertia page renders
- **THEN** the shared account dropdown contains an Admin action targeting the
  Rails-generated admin URL

#### Scenario: Member does not see admin entry
- **GIVEN** an authenticated user whose role is `member`
- **WHEN** an application-owned Inertia page renders
- **THEN** the shared account dropdown does not contain an Admin action
- **AND** the serialized shared props do not expose the user's raw role
