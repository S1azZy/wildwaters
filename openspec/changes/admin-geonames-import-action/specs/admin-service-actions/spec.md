## MODIFIED Requirements

### Requirement: Admin shell layout
The system SHALL render admin pages with a top toolbar, a left sidebar, and a
central working area built from the approved React frontend and shadcn-backed
component foundation.

#### Scenario: Service actions navigation
- **GIVEN** an admin opens the admin service-actions page
- **WHEN** the admin shell renders
- **THEN** the sidebar shows Dashboard, Service Actions, and a separated Models section
- **AND** Service Actions is marked as the current subsection
- **AND** the central workspace renders a GeoNames region import panel with latest-run state and a launch action

#### Scenario: Service action has an operational side effect only on submit
- **GIVEN** an admin opens the service-actions page
- **WHEN** the page renders
- **THEN** it does not enqueue imports, start jobs, retry imports, or execute any service command before the admin submits the launch action

