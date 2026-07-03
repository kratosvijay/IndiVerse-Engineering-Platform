# Architecture Review Checklist

Use this checklist during architecture reviews, pull request assessments, and major design sessions to verify alignment with the platform constitution.

---

## 🏗️ Architecture
- **Provider SDKs**: Do vendor-specific SDK types leak into core layers?
- **Interface Driven**: Are all components decoupled through clean interfaces?
- **Replaceable**: Can indexers, databases, or models be easily swapped out?

## 🔌 Platform
- **Plugin Sandbox**: Are file system and terminal operations restricted?
- **Least Privilege**: Does the manifest request only the narrowest possible permissions?
- **Offline First**: Does the capability continue to function without network connectivity?
- **Graceful Degradation**: If an external provider goes down, is the user presented with a clean fallback?

## 🎯 Quality
- **Observable**: Are event trace logs and cost calculations instrumented?
- **Testable**: Is the component fully mockable and verified by unit tests?
- **Human Approval**: Do destructive writes require explicit user approval?
- **Documentation as Code**: Have corresponding guides, schemas, or ADRs been updated?

## 📈 Evolution
- **Open Standards**: Does this leverage standard industry protocols (MCP, LSP, Git)?
- **Explainable AI**: Is the reason why this context chunk or resolution was suggested visible?
- **Backward Compatible**: Does this break existing plugin hooks or public SDK APIs?
- **Versioned Contracts**: Are new public interfaces explicitly versioned?
