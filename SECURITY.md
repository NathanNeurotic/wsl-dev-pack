# Security Policy

## Supported versions

Security fixes are generally applied to the latest maintained release branch and the latest published release ZIP.

## Reporting a vulnerability

Do not open a public GitHub issue for a suspected security vulnerability.

Please report vulnerabilities privately through one of these channels:

- GitHub Security Advisories, if enabled for the repository
- a private maintainer contact method listed on the repository page

## What to include

Please include as much of the following as possible:

- affected version or commit
- operating system and Windows version
- reproduction steps
- expected behavior
- actual behavior
- logs, if relevant
- risk assessment, if known

## Sensitive areas in this project

This repository touches local developer environments, so security reports involving the following are especially important:

- credential exposure
- unsafe shell quoting
- privilege escalation
- insecure SSH key handling
- unsafe file overwrite behavior
- command injection through user prompts
- unsafe GitHub API usage
- unsafe Docker or devcontainer defaults

## Disclosure expectations

Please allow reasonable time to investigate, reproduce, and patch reported issues before public disclosure.
