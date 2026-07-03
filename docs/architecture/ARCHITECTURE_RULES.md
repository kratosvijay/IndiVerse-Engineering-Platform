# Architectural Rules for IndiVerse Studio Workbench (v1.0.0)

Every contributor and AI agent must adhere strictly to these rules. No architectural drift is permitted.

---

## The Rules

### Rule 1: Widget Access Restrictions
- **Widgets must never access PlatformSDK, REST services, or database engines directly.** 
- All data retrieval and actions must go through the `WorkbenchApi` facade layer.

### Rule 2: Unified Communication Facade
- **Widgets communicate only with the `WorkbenchApi` or dispatch commands through the command registry.**
- UI components are not allowed to call other feature controllers directly.

### Rule 3: Separation of Logic (Stateless Facade)
- **`WorkbenchApi` contains no business logic.** 
- It acts purely as a coordinator that delegates work to domain-specific services or state controllers.

### Rule 4: Business Logic Location
- **All business logic belongs to Services.**
- Controllers must remain thin, handling UI state transitions and dispatching commands.

### Rule 5: Capability Modularity
- **Providers communicate exclusively through interfaces.**
- Implementations (e.g., local workspace, remote workspace, LSP provider) must be interchangeable without modifying UI widgets.

### Rule 6: Decoupled Events
- **Events are published and consumed exclusively through the `WorkbenchEventBus`.**
- Direct listener coupling between features is forbidden.

### Rule 7: Platform SDK Gateway
- **The PlatformSDK remains the single, official gateway to the backend services.**
- Studio server and Flutter client must interact using defined versioned REST (`/api/v1/`) and WebSocket models.
