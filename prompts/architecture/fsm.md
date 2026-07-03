# Prompt: Finite State Machine Generator

- **Name**: FSM State & Event Boilerplate Generator
- **Purpose**: Creates the states, events, and transition mappings for an FSM.
- **Inputs**: State machine name, list of states, transitions list.
- **Outputs**: Sealed classes for States and Events, along with a transition controller template.
- **Constraints**: State transitions must be atomic and non-blocking.
- **Example**: `RideBookingFSM` states `[idle, searching, accepted, inProgress, completed]`.
- **Expected Result**:
- Sealed class `RideBookingState` with matching subclasses.
- Transition function mapping events to updated states.
