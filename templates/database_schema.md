# Database Schema Design: [Collection/Table Name]

- **Storage Engine**: [Firestore / Relational Postgres / Realtime DB]

## 📋 Document Structure / Schema Definition

| Field Name | Type | Required | Description | Constraints |
| :--- | :--- | :--- | :--- | :--- |
| `id` | String | Yes | Unique identifier | Primary Key / UUID |
| `createdAt` | Timestamp | Yes | Creation epoch | Auto-populated |
| `status` | String | Yes | State of the record | Enum: [active, inactive] |

## ⚡ Indexing Requirements
List all composite or single-field indexes needed.
