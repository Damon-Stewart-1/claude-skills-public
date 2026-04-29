# Security

If you find a security issue in any hook, skill, or script in this repo, please report it privately rather than opening a public issue.

## How to report

Email: `security@earnedimpact.org`

Include:
- A description of the issue
- The file path and (if applicable) line number
- Steps to reproduce, or a proof-of-concept
- Any suggested fix

You will get an acknowledgement within 3 business days.

## Scope

In scope:
- Hook scripts that could be tricked into approving dangerous tool calls
- Skill flows that could leak secrets, exfiltrate files, or escalate permissions
- Anything in this repo that could be turned against the user running it

Out of scope:
- Issues in Claude Code itself (report to Anthropic)
- Issues in third-party tools the skills wrap (report upstream)
- Theoretical attacks that require already having local file access
