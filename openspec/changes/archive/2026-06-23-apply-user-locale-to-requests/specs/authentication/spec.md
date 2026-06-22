## ADDED Requirements

### Requirement: Request-scoped authenticated locale
The system SHALL process an application request that begins with an active
persisted session using the authenticated user's supported stored locale, and
SHALL process an unauthenticated request using the application default locale.

#### Scenario: Russian locale for an authenticated request
- **GIVEN** an active persisted session for a user whose stored locale is `ru`
- **WHEN** the user makes an application request
- **THEN** Rails translations produced during that request use the `ru` locale

#### Scenario: English locale for an authenticated request
- **GIVEN** an active persisted session for a user whose stored locale is `en`
- **WHEN** the user makes an application request
- **THEN** Rails translations produced during that request use the `en` locale

#### Scenario: Default locale for a guest request
- **GIVEN** a request without an active persisted session
- **WHEN** the application processes the request
- **THEN** Rails translations produced during that request use the application
  default locale

#### Scenario: Locale isolation between requests
- **GIVEN** one request was processed using an authenticated user's non-default
  locale
- **WHEN** a later unauthenticated request is processed by the application
- **THEN** the later request uses the application default locale
