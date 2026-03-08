# Generic Codex Bootstrap Notes

This pack does not hardcode Codex credentials.

What it can do:
- prepare a clean WSL terminal environment
- prepare a generic devcontainer scaffold
- prepare Git / SSH / GitHub CLI
- prepare a repo for local terminal-based coding workflows

What the user still does manually:
- sign into Codex / ChatGPT / OpenAI tooling as needed
- install any IDE extension they specifically want
- provide their own API keys or workspace login when required

Environment variable safety reference:
- Prefer storing secrets in shell profile files or secret managers, not inside repositories.
