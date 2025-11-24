# Development Scripts (Modular)

Modular shell tooling for daily development (Git, JIRA, repositories, PR review, utilities). Split into focused modules for faster load, easier maintenance and selective sourcing.

## Table of Contents
1. Structure
2. Quick Start
3. Usage (Full vs Selective Load)
4. Module Reference
5. Migration (Monolithic → Modular)
6. Development Guidelines
7. Notes
8. Troubleshooting

## 1. Structure

```
scripts/
├── my-script-modular.sh    # Loader (sources modules in order)
├── my-script.sh            # Legacy monolithic version (kept for fallback)
├── constants.sh            # Shared constants + ANSI colors
├── aliases.sh              # Command aliases
├── installation.sh         # Workstation setup helpers
├── utilities.sh            # Cross-cutting utility functions
├── git.sh                  # Git workflow helpers
├── jira.sh                 # JIRA integration
├── repository.sh           # Repository list + cloning helpers
├── pr-review.sh            # Pull request review + AI assist
└── specialized.sh          # Focused one-off utilities
```

## 2. Quick Start

Clone (or update) the scripts directory somewhere under `$HOME` (recommended: `$HOME/scripts`). Then source the modular loader from your shell profile.

```bash
# Clone (example)
git clone <repo-url> "$HOME/scripts"

# Add to ~/.zshrc (one line)
source "$HOME/scripts/my-script-modular.sh"

# Reload shell
exec zsh
```

Verify:
```bash
type branch       # from git.sh
type jbr          # from jira.sh
type review       # from pr-review.sh
```

### Prerequisites
Install (or verify) required tools. Most are bundled by `install-deps`.

| Tool | Why |
|------|-----|
| gh | PR creation, diff, comments |
| jira-cli | Ticket listing, moves, creation |
| chatgpt-cli | AI generation (PR, review, JIRA diff) |
| scli | Slate + LiteLLM key management |
| kubectl, kubie | Kubernetes context + namespace for slate |
| telepresence | Service interception for `tpa` |
| fzf | Interactive selection (branches/repos/tickets) |
| ffmpeg, gifsicle | Media conversion for `giffy` |
| jq | JSON parsing (`litellm`) |
| md5sum (md5sha1sum) | Hashing inside `pw` |
| pwgen | Additional password utilities |
| expect | Potential scripted interaction support |

Optional: ensure AWS SSO (`awscli`) installed for auth aliases; `kubie` improves context switching reliability.

Bulk install after sourcing loader:
```bash
install-deps
```

## 3. Usage

### Load All Modules (recommended)
```bash
source "$HOME/scripts/my-script-modular.sh"
```

### Selective Loading (only what you need)
Ensure `constants.sh` first, then any dependencies.
```bash
# Git only
source "$HOME/scripts/constants.sh"
source "$HOME/scripts/utilities.sh"
source "$HOME/scripts/git.sh"

# JIRA only
source "$HOME/scripts/constants.sh"
source "$HOME/scripts/utilities.sh"
source "$HOME/scripts/jira.sh"
```

## 4. Module Reference

### constants.sh
Purpose: Core constants + color codes
Contains: `SAFETYCULTURE_DIR`, `PROMPTS_DIR`, ANSI colors

### aliases.sh
Purpose: Frequently used shortcuts (reload, docker helpers, git helpers)
Note: Available after sourcing loader; add new aliases here not inline in other modules.

### installation.sh
Purpose: Workstation setup (Homebrew, Oh My Zsh, Kubernetes config, NVM)
Use: Run functions manually; not auto-run to avoid unintended installs.

### utilities.sh
Purpose: Shared helpers (input, selection, navigation, media conversion)
Examples: `yesno`, `select_board`, `tpa`, `cleanpipe`, `giffy`
Depends on: `constants.sh`

### git.sh
Purpose: Git workflow acceleration
Examples: `branch`, `pr`, `gacp`, `gbdi`
Depends on: `constants.sh`, `utilities.sh`
AI Flags: `pr -ai` generates title/body via diff + prompt; `pr -v` prints help (if implemented). Prompts live in `prompts/generate_pull-request.md`.

### jira.sh
Purpose: JIRA ticket integration
Examples: `sync_board`, `jbr`, `mvj`, `jdiff` (AI ticket creation)
Depends on: `constants.sh`, `utilities.sh`
AI Flags: `jdiff` supports dry-run (`--dry-run`), chat-only (`--chat-only`), quiet (`--quiet`). Use `jdiff --help` for full list; color output toggled by `--no-color`.

### repository.sh
Purpose: Manage + clone internal repositories
Examples: `repo` (sync list), `grc` (clone interactively)
Depends on: `constants.sh`

### pr-review.sh
Purpose: Review, diff and AI analysis for PRs
Examples: `stamp`, `prd`, `rr`, `review`
Depends on: `constants.sh`, `utilities.sh`
AI Flags: `review -c` posts generated analysis as a PR comment; omit `-c` to preview with `glow`.

### specialized.sh
Purpose: Niche utilities (ID conversion, password generation, SQL file scaffolding)
Examples: `s12id`, `ids12`, `pw`, `auto-sql`
Depends on: `constants.sh`

### slate.sh
Purpose: Ephemeral environment ("slate") lifecycle + Kubernetes context helpers
Examples: `slate_up`, `slate_ls`, `slate_create`, `slate_session`, `slate_extend`, `slate_delete`, `slate_help`, wrapper `slate <cmd>`
Depends on: External tools (`scli`, `kubie`, `kubectl`); sources after utilities.
Notes: Namespace/session functions lowercase ticket IDs; validates JIRA pattern `PROJECT-123`.

## 5. Migration (Monolithic → Modular)

1. Replace sourcing in `~/.zshrc`:
```bash
# Old
source "$HOME/scripts/my-script.sh"
# New
source "$HOME/scripts/my-script-modular.sh"
```
2. Reload shell: `exec zsh`
3. (Optional) Remove monolithic sourcing from any other dotfiles.
4. For partial usage, only source required modules (see section 3).

## 6. Development Guidelines

### Add a Function
1. Pick module matching responsibility (Git, JIRA, etc.)
2. Require only necessary dependencies (source order matters)
3. Keep naming consistent and short (`verbNoun` where helpful)
4. Append description to this README if user-facing
5. Test standalone: source required modules then call function

### Add a Module
1. Create `<name>.sh` with brief header comment
2. Avoid side effects on load (no automatic installs/executions)
3. Update `my-script-modular.sh` to source it in dependency order
4. Document in sections 1 & 4
5. Keep cross-cutting logic in `utilities.sh` not in the new module

## 7. Notes
Dependency Order: Loader enforces required order.
Backward Compatibility: Interfaces mirror legacy script where feasible.
Performance: Selective loading reduces shell startup time.
Isolation: Source individual files to debug without full stack.
AI Usage: Some functions rely on prompt files under `prompts/`.
Prompts: `prompts/analyze_pull-request.md` (review output structure), `prompts/generate_pull-request.md` (used for AI PR generation in `pr -ai`). Keep these concise and version them when updating wording—changes affect AI output determinism.
Slate Environments: Require valid kubie context & `scli` installed; failing context switches are warned, not fatal.
Security: No secrets are stored in repo; ensure environment variables / credentials (AWS SSO, LiteLLM keys) are managed externally.
Idempotency: Loader can be safely re-sourced; installation functions intentionally not auto-invoked.
Extensibility: Prefer adding new shared helpers to `utilities.sh` to avoid duplication.

## 8. Troubleshooting

### Module Load Check
```bash
source "$HOME/scripts/utilities.sh" && echo OK || echo FAIL
```

### Function Not Found
```bash
grep -r "function_name" "$HOME/scripts" | cut -d: -f1 | sort -u
```

### Missing Dependency
```bash
source "$HOME/scripts/constants.sh"
source "$HOME/scripts/utilities.sh"    # then your target module
```

### Reload After Edits
```bash
reload   # if alias exists; otherwise
source "$HOME/scripts/my-script-modular.sh"
```

### Shell Init Not Applying
Ensure the sourcing line is at end of `~/.zshrc` and no earlier `return` statements are short‑circuiting.

### AI Output Unexpected
If `pr -ai` or `review` produce low-quality text:
1. Check prompts in `prompts/` for accidental edits.
2. Verify `chatgpt-cli` model selection (`llm` alias) matches desired model.
3. Re-run with fresh diff (`git diff` clean) or include fewer unrelated changes.

### Slate Fails to Initialize
1. Confirm `scli` login (`sc-auth` / `sc-slate`).
2. Ensure `kubie` installed (`brew install kubie`).
3. Verify context variable (e.g. `SLATE_DEV`) exported in shell profile.

### LiteLLM Key Not Set
Run `litellm` to refresh; ensure `jq` is installed; key stored in `~/.scli/litellm.json`.

### Telepresence Not Connecting
1. Run `telepresence quit -s` before `tpa`.
2. Verify Kubernetes context via `kubectl config current-context`.
3. Check port conflicts with `cleanpipe <port>`.

## License / Usage
Internal tooling; adjust before external distribution. Remove organization‑specific paths or secrets before sharing.

---
Suggestions / additions welcome. Update the README with substantive user-facing changes.
