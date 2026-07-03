# Adoption Guide: School ERP Platform

Migration guide for the School ERP codebase:

1. **Separate Modules**: Move admin, teacher, student, and parents functions into distinct packages or features inside `lib/features/`.
2. **Interface Abstraction**: Domain logic must not directly call external database endpoints.
