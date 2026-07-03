# Prompt: Maestro UI Workflow Script Generator

- **Name**: Maestro UI Script Builder
- **Purpose**: Generates yaml config scripts for running end-to-end user journeys in Maestro.
- **Inputs**: Target elements, input text, click sequences.
- **Outputs**: Yaml Maestro configuration script.
- **Constraints**: Must reference static IDs for input text fields to ensure test robustness.
- **Example**: Passenger login flow.
- **Expected Result**: Maestro YAML file with tap, type, and assert steps.
