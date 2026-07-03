# Security Standards

Mandatory security gates for all systems.

## Data Isolation & Auth Gates
- Every user data read or write must assert authentication (`request.auth != null`).
- Restrict read permission of phone verifications and OTP paths strictly to Cloud Functions.
- Hard-code geofence calculations inside secure server scripts to avoid client-side spoofing.

## PII and Logging Controls
- Do not output driver license numbers, vehicle registers, phone numbers, or passwords to debug consoles.
- Strip user metadata before pushing event payloads to analytics dashboards.
