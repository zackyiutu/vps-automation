# Security Policy

## Reporting

Report vulnerabilities via [GitHub Security Advisories](https://github.com/zackyiutu/vps-automation/security/advisories/new).

**DO NOT** open public issues for security vulnerabilities.

## Scope

- CLI tool (`abfool-vps`)
- Credential vault (SQLite)
- Worker scripts
- Configuration files

## Best Practices

- SSH keys auto-generated (Ed25519)
- Credentials stored in SQLite (local only)
- API tokens never logged
- Use `abfool-vps vault` for credential management
