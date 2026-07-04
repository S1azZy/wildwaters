# Frontend UI System Specification

## Purpose

Define the implemented shadcn-backed UI kit, Wild Waters composition layer, and
frontend design workflow for application-owned React interfaces.

## Requirements

### Requirement: Shadcn-backed UI kit
The system SHALL use shadcn/ui as the preferred component foundation for
application-owned business and admin React interfaces.

#### Scenario: UI kit configuration exists
- **WHEN** frontend UI-kit configuration is inspected
- **THEN** shadcn project metadata is present for the existing Vite React frontend
- **AND** generated shadcn primitives resolve through the repository TypeScript alias

#### Scenario: Initial primitive inventory
- **WHEN** the shared UI primitive directory is inspected
- **THEN** it contains shadcn-backed primitives for actions, forms, cards, overlays, feedback, navigation, tables, and loading states needed by current public pages and future admin screens

### Requirement: Wild Waters composition layer
The system SHALL expose repeated product UI concepts through Wild Waters
composition components built from shadcn primitives.

#### Scenario: Product wrapper composition
- **WHEN** a repeated Wild Waters UI concept is implemented
- **THEN** it is composed from existing shadcn primitives when a suitable primitive exists
- **AND** the product wrapper owns only the Wild Waters state, layout, copy, or domain-specific presentation contract

#### Scenario: Fully custom control exception
- **WHEN** a frontend control cannot be represented by a suitable shadcn primitive or composition
- **THEN** a fully custom component may be introduced
- **AND** the reason is apparent from the component boundary, test, or design documentation

### Requirement: Frontend design workflow
The system SHALL document a design-first workflow that starts with intent,
tokens, and reusable components before page implementation.

#### Scenario: Design guide source of truth
- **WHEN** frontend design-system guidance is needed
- **THEN** the repository provides a routed design guide documenting visual direction, token ownership, shadcn-first component selection, and page implementation workflow

#### Scenario: Future frontend work routing
- **WHEN** task-specific context for UI-kit or design-system work is loaded
- **THEN** the context map routes the reader to the design guide, ADR, shadcn component layer, and relevant page/component tests

### Requirement: Design token ownership
The system SHALL keep Digital Naturalist token ownership while exposing shadcn
semantic tokens to frontend components.

#### Scenario: Single visual vocabulary
- **WHEN** shared frontend styles are inspected
- **THEN** shadcn semantic colors, radii, and interaction states map to the Wild Waters design vocabulary
- **AND** they do not introduce an unrelated parallel palette for business UI
