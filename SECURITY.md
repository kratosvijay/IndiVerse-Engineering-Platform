# Security Policy

## Supported Versions
We provide security updates for the current active minor/major releases:
- `0.5.x` (Active)
- `0.4.x` (LTS)

## Reporting a Vulnerability
Please do not report security vulnerabilities publicly. Send report details to security@indiverse.io. We aim to respond within 48 hours.

## Secret Handling
- Never commit API keys or credentials.
- Use environment variables or secure credential storage providers.

## Sandbox Guarantees
- Plugins run within isolated context spaces.
- File system access is restricted unless explicitly requested and permitted in the integration manifest.
