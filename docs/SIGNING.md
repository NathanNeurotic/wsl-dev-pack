# Release Signing

This kit includes a signing workflow placeholder rather than a fully active signing pipeline.

## Why it is a placeholder

Authenticode signing depends on your chosen signing model, for example:

- a local code-signing certificate
- Azure Trusted Signing
- Azure Key Vault-backed signing
- another enterprise signing service

## Included scaffold

- `.github/workflows/release-signing-placeholder.yml`

## Recommended path

1. Start with release ZIP creation
2. Add GitHub artifact attestations
3. Add real signing only after you have:
   - a signing certificate or service
   - secrets configured
   - a repeatable signing process
   - verification steps

## Minimum repository secrets to expect

These will vary by provider, but usually include some combination of:

- tenant or account identifiers
- client ID
- client secret or federated identity config
- certificate profile or signing profile names
