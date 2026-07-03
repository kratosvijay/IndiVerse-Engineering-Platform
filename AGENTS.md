# The AI Constitution (AGENTS.md)

This document is the primary instruction set and operational constitution for all Artificial Intelligence entities (coding assistants, reviewers, generators, and agents) operating within the IndiVerse Developer Platform.

---

## 1. Project Philosophy
- **Reusability First**: Write components, prompts, and configurations to be independent of business logic. The IDP is an operating system for developer execution.
- **Fail Closed**: Security rules, exceptions, and authentication boundaries must always default to strict enforcement.
- **Single Source of Truth**: System versions, configurations, and pricing models must reside in unified definitions.

---

## 2. Core Architecture Rules
- **Clean Architecture Separation**:
  - **Domain Layer**: Completely pure. Zero dependency on external frameworks (Firebase, Flutter, or UI packages). Contains entities, use-cases, and repository abstractions.
  - **Data Layer**: Implements repository contracts. Deals with network data, databases (Firestore, SQL), and cache providers.
  - **Presentation Layer**: UI widgets and State Controllers (e.g. GetX). Translates actions into domain use-cases.

- **Reactive State Flow**:
  - Minimize manual polling. Rely on Firestore snapshots (`StreamBuilder`) or local reactive observables.

---

## 3. General Coding Standards
- **Strong Typing**: Avoid dynamic variables. Define concrete models and serializers.
- **Null Safety**: Treat compiler warnings as errors.
- **Consistency**: 
  - Class names: `PascalCase`
  - Variables, functions: `camelCase`
  - File names: `snake_case`

---

## 4. Folder Structure Rules
- Follow clean architecture naming standards strictly:
  ```text
  lib/
  ├── domain/
  │   ├── entities/
  │   └── repositories/
  ├── data/
  │   ├── models/
  │   ├── datasources/
  │   └── repositories/
  └── presentation/
      ├── controllers/
      └── screens/
  ```

---

## 5. Review Guidelines
Every code change must be evaluated against the following gates:
- **Architecture Integrity**: No presentation layer code inside data/domain layers.
- **Performance Constraints**: Avoid heavy calculations inside UI build methods.
- **Security Check**: Check parameters, auth context, and resource ownership.
- **Testing Coverage**: Require unit tests for domain use-cases and entities.
- **AI-Safety Audit**: Ensure no API keys or PII are logged or leaked.
