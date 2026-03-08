# Contributing

Thank you for contributing to WSL Dev Pack.

## Goals

Changes should improve one or more of the following:

- reliability
- safety
- portability
- onboarding speed
- clarity of prompts and documentation

## Before opening a pull request

Please do the following:

1. Test changes on a real Windows machine if possible.
2. Prefer testing both:
   - a machine with no WSL installed
   - a machine with existing WSL installed
3. Validate that changes do not silently break:
   - self-elevation
   - resume-after-reboot flow
   - Linux provisioning
   - GitHub CLI flows
   - SSH key handling
4. Update documentation if prompts, defaults, or generated files change.

## Coding guidance

- Prefer explicit, readable PowerShell over compressed one-liners.
- Avoid destructive defaults.
- Preserve prompts for user-only variables.
- Back up files before overwriting when practical.
- Treat all user-provided strings as potentially unsafe and quote carefully.
- Keep Windows-side and Linux-side responsibilities clearly separated.

## Commit guidance

Use clear commit messages describing the actual behavior change.

Examples:

- `Add Docker Desktop WSL integration validation`
- `Fix resume flow after reboot on fresh Ubuntu install`
- `Guard SSH key upload when gh auth has not completed`

## Pull requests

A good pull request should include:

- what changed
- why it changed
- what was tested
- what remains untested
- screenshots or logs if the UX changed

## Testing checklist

At minimum, test:

- fresh run on Windows with no distro
- rerun on already-configured system
- optional SSH key generation
- optional GitHub login
- optional repo clone
- optional devcontainer scaffold
