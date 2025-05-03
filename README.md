# Clarity Property Registry

A smart contract-based property title management system built with Clarity for the Stacks blockchain. This ledger provides a secure, immutable, and transparent registry for property metadata, ownership, access control, and historical validation.

## 📚 Features

- Property title registration with metadata (description, tags, document size)
- Ownership verification and secure title transfer
- Granular access control for viewing title details
- Emergency locking of titles to prevent tampering
- Tag-based metadata enhancement
- Authentication of ownership history and block-based timeline
- Optimized helper functions for on-chain performance

## 🛠 Contract Functions

### Public Functions
- `register-title`: Registers a new property title.
- `update-title-details`: Modifies all title fields including tags and metadata.
- `add-property-tags`: Appends new tags to an existing title.
- `secure-title-emergency`: Applies an emergency lock for additional security.
- `authenticate-title`: Verifies ownership and registration history.
- `grant-title-access`: Allows others to view title metadata.
- `remove-title-access`: Revokes viewing permissions.
- `transfer-title`: Transfers ownership of a title to another address.
- `delete-title`: Permanently deletes a title.
- `get-total-registered-titles`: Returns total titles registered.
- `get-title-info`: Returns full metadata if authorized.

### Private Functions
- `title-registered?`: Validates if a title ID exists.
- `verify-title-owner`: Verifies if a user is the owner.
- `fetch-document-size`: Returns document size.
- `validate-tag-format`: Ensures a single tag is properly formatted.
- `validate-tag-collection`: Ensures a list of tags meets length and format constraints.

## 🧪 Test & Deploy

Deploy using Clarinet or Stacks CLI, and write integration tests using JavaScript or Clarity unit tests.

## 🔒 Security

Security is enforced via:
- Admin-restricted functions (`secure-title-emergency`)
- Ownership assertions
- Emergency lock tags
- Validation of all input metadata

## 📜 License

MIT License
