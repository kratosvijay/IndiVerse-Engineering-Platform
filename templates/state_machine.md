# State Machine Template

Use this template to outline Finite State Machine (FSM) behavior.

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing : ActionTrigger
    Processing --> Success : Completion
    Processing --> Failed : Exception
    Success --> [*]
    Failed --> Idle : Reset
```
