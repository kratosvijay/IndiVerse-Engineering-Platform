# Prompt: Hardened Firestore Security Rules Generator

- **Name**: Hardened Firestore Security Rules Builder
- **Purpose**: Generates secure write/read schemas inside `firestore.rules`.
- **Inputs**: Collection path, allowed actions, user role specifications.
- **Outputs**: Firestore rule block.
- **Constraints**: No global write/read access. Assert document ownership.
- **Example**: `/rides/{rideId}` permissions.
- **Expected Result**: Verified rules matching request metadata to database fields.
