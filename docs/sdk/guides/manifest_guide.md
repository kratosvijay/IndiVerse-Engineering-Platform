# Manifest Specifications Guide

Every plugin must expose a structured manifest declaring its constraints, dependencies, permissions, and capabilities.

## Manifest Properties

| Property | Type | Description |
|---|---|---|
| `id` | String | Unique package identifier (e.g. `google.gemini`). |
| `name` | String | User friendly display name. |
| `vendor` | String | Publisher name. |
| `version` | String | SemVer version string. |
| `minRuntimeVersion` | String | Minimal IDP execution engine version constraint (e.g. `0.3.0`). |
| `capabilities` | Set | List of capability tokens (e.g. `aiChat`, `streaming`, `embedding`). |
| `permissions` | Set | List of sandbox execution permissions (`filesystem`, `terminal`, `git`). |
| `dependencies` | List | Required system binaries (e.g. `python`, `docker`). |
