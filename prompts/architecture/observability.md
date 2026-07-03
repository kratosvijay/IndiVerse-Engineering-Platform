# Prompt: Observability & Logger Wrapper

- **Name**: Observability Wrapper Generator
- **Purpose**: Generates structured, GDPR-compliant performance logs and tracing tags.
- **Inputs**: Class/Function name, attributes to log, sensitive attributes to redact.
- **Outputs**: Middleware logging statements that redact sensitive fields.
- **Constraints**: Do not log raw PII.
- **Example**: Log `Driver` coordinates without driver name or phone.
- **Expected Result**: Clean structural logs with redacted PII fields.
