## ADDED Requirements

### Requirement: Shared React application shell
The system SHALL provide migrated business pages with a typed React application shell that preserves the current site identity, navigation actions, content frame, document title, and accessible flash presentation.

#### Scenario: Guest shell
- **GIVEN** a visitor is not authenticated
- **WHEN** a migrated business page renders
- **THEN** the shell displays the translated brand and Explore navigation
- **AND** it displays the sign-in action without exposing user or session data

#### Scenario: Authenticated shell
- **GIVEN** a visitor is authenticated
- **WHEN** a migrated business page renders
- **THEN** the shell displays the profile action targeting the Rails dashboard
- **AND** it does not display the guest sign-in action

#### Scenario: Shell flash message
- **GIVEN** Rails redirects to a migrated page with an allowed notice or alert flash
- **WHEN** the Inertia page renders
- **THEN** the shell presents the message with the matching status or alert semantics
- **AND** the one-time message does not become regular history-persisted shared data

#### Scenario: Shared shell prop exposure
- **GIVEN** Rails prepares shared data for an Inertia response
- **WHEN** the data is serialized
- **THEN** it contains only namespaced translated labels, Rails-generated navigation URLs, and the authentication state required by the shell
- **AND** it excludes credentials, raw session data, reset tokens, unnecessary user attributes, and policy internals

#### Scenario: Legacy destination
- **GIVEN** a shell or page link targets an unmigrated Rails route
- **WHEN** the visitor follows that link
- **THEN** the browser performs a full document visit to the legacy page
- **AND** the legacy route remains owned by Turbo, Stimulus, and importmap

## MODIFIED Requirements

### Requirement: Typed Rails-to-React page contract
The system SHALL provide explicit TypeScript types for shared and page-specific Inertia props while Rails remains the source of user-facing translations, formatted display values, and application URLs.

#### Scenario: Waterfall detail props
- **GIVEN** the published waterfall detail route is enabled
- **WHEN** Rails renders its Inertia page
- **THEN** the page receives typed public waterfall content, translated display copy, formatted detail values, and typed application URLs through props
- **AND** the React page renders those values without importing Rails locale files, duplicating domain formatting, or using a generated route catalog

#### Scenario: Frontend type error
- **GIVEN** a page or component violates its declared shared or page-specific prop contract
- **WHEN** the frontend typecheck runs
- **THEN** verification fails before the application build is accepted

#### Scenario: Sensitive server state
- **GIVEN** Rails prepares shared or page-specific Inertia props
- **WHEN** the response is serialized
- **THEN** it omits credentials, raw session tokens, password-reset tokens, policy internals, unpublished state, and other server-only material

### Requirement: Rails integration proof
The system SHALL prove the frontend platform through a production waterfall detail Inertia page and SHALL remove the superseded development/test smoke surface.

#### Scenario: Production business page
- **GIVEN** a published waterfall exists
- **WHEN** a visitor opens its detail route in development, test, or production
- **THEN** Rails returns the expected Inertia component and typed props
- **AND** React renders the page through the shared application shell and frontend styles

#### Scenario: Browser integration
- **GIVEN** frontend assets are built
- **WHEN** the waterfall detail route is exercised by request, component, and browser tests
- **THEN** the tests prove the Rails-to-Inertia-to-React response contract, client rendering, accessible interaction, and legacy-boundary navigation

#### Scenario: Smoke surface retirement
- **GIVEN** the production waterfall detail route proves the frontend runtime chain
- **WHEN** application routes and frontend pages are inspected
- **THEN** no development/test smoke route, controller, page, copy, or dedicated smoke test remains
