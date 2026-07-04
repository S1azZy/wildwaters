## ADDED Requirements

### Requirement: Kit-first shared controls
The system SHALL implement shared shell controls, auth controls, feedback, and
reusable UI states through shadcn primitives before introducing custom markup.

#### Scenario: Shared controls use kit primitives
- **WHEN** shared shell, flash, auth form, or reusable control source is
  inspected
- **THEN** buttons, fields, inputs, selects, cards, badges, alerts, overlays,
  and feedback states use shadcn-backed primitives or Wild Waters wrappers when
  a suitable primitive exists

#### Scenario: Auth forms preserve Rails and Inertia ownership
- **GIVEN** a migrated authentication or password-reset page uses shadcn-backed
  visual controls
- **WHEN** a visitor submits the form
- **THEN** Rails-generated URLs, Inertia form submission, CSRF-backed behavior,
  translated copy, processing state, and validation display continue to follow
  the existing auth contract

#### Scenario: Accessibility remains covered
- **WHEN** component tests cover shared shell controls, auth forms, or feedback
  states
- **THEN** accessible names, roles, disabled states, invalid states, live-region
  semantics, and configured accessibility checks remain valid
