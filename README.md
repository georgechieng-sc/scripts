# Development Scripts (Modular)

Modular shell tooling for daily development (Git, JIRA, repositories, PR review, utilities). Split into focused modules for faster load, easier maintenance and selective sourcing.

All functions are LLM-friendly — interactive prompts (fzf, board/status selection) are bypassed when arguments are provided directly, making them callable from any LLM agent.

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
├── constants.sh            # Shared constants + ANSI colors
├── aliases.sh              # Command aliases
├── installation.sh         # Workstation setup helpers
├── utilities.sh            # Cross-cutting utility functions
├── git.sh                  # Git workflow helpers
├── jira.sh                 # JIRA integration
├── repository.sh           # Repository list + cloning helpers
├── pr-review.sh            # Pull request review helpers
├── slate.sh                # Slate environment management
├── specialized.sh          # Focused one-off utilities
└── prompts/
    └── analyze_pull-request.md  # PR review prompt template (reference)
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
| scli | Slate management |
| kubectl | Kubernetes context + namespace for slate |
| telepresence | Service interception for `tpa` |
| fzf | Interactive selection (branches/repos/tickets) |
| ffmpeg, gifsicle | Media conversion for `giffy` |
| glow | Markdown rendering for `review` |
| md5sum (md5sha1sum) | Hashing inside `pw` |

Optional: ensure AWS SSO (`awscli`) installed for auth aliases.

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
Contains: `SAFETYCULTURE_DIR`, `SCRIPTS_DIR`, `PROMPTS_DIR`, ANSI colors

### aliases.sh
Purpose: Frequently used shortcuts (reload, docker helpers, git helpers)
Note: Available after sourcing loader; add new aliases here not inline in other modules.

### installation.sh
Purpose: Workstation setup (Homebrew, Oh My Zsh, Kubernetes config, NVM)
Use: Run functions manually; not auto-run to avoid unintended installs.

### utilities.sh
Purpose: Shared helpers (input, selection, navigation, media conversion)
Examples: `yesno`, `select_board`, `select_status`, `cleanpipe`, `giffy`, `cdi [dir]`, `sci [dir]`
Depends on: `constants.sh`

### git.sh
Purpose: Git workflow acceleration
Examples:
- `branch <name>` — switch to main, pull, create branch, push
- `pr [title] [merge_dest]` — create draft PR (`-v` to view existing)
- `gacp <message|flag>` — add, commit, push (flags: `-rri`, `-gmt`, `-gga`, `-gmm`, `-vb`, `-ut`, `-fmt`)
- `gbi [branch]` — checkout branch (fzf if no arg)
- `gbdi [branch]` — delete branch with JIRA/slate cleanup
Depends on: `constants.sh`, `utilities.sh`

### jira.sh
Purpose: JIRA ticket integration
Examples:
- `sync_board [board]` — sync JIRA issues to local file
- `jbr [ticket_id]` — create branch from ticket (fzf if no arg)
- `mvj [ticket_id] [status]` — move ticket status (fzf/prompt if no args)
- `jdiff <title> <description>` — create ticket, branch, commit, and PR
Depends on: `constants.sh`, `utilities.sh`

### repository.sh
Purpose: Manage + clone internal repositories
Examples: `repo` (sync list), `grc` (clone interactively)
Depends on: `constants.sh`

### pr-review.sh
Purpose: Review, diff and approve PRs
Examples:
- `stamp` — approve PR from clipboard URL
- `prd [url]` — show PR diff (clipboard if no arg)
- `rr` — review then approve workflow
- `review [-c] <text>` — post or preview review text (`-c` posts as PR comment)
Depends on: `constants.sh`, `utilities.sh`

### specialized.sh
Purpose: Niche utilities (ID conversion, password generation, SQL file scaffolding)
Examples: `s12id <id>`, `ids12 <uuid> [prefix]`, `pw [-s] [input]`, `auto-sql`
Depends on: `constants.sh`

### slate.sh
Purpose: Ephemeral environment ("slate") lifecycle + Kubernetes context helpers
Examples: `slate up`, `slate ls`, `slate extend <id> <days>`, `slate delete <id>`, `slate tp <ticket> [svc]`, `slate tpa`
Depends on: External tools (`scli`, `kubectl`, `telepresence`)

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
4. Accept arguments directly to keep functions LLM-callable — fall back to interactive prompts (fzf, `select_*`) only when no args are given
5. Append description to this README if user-facing
6. Test standalone: source required modules then call function

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
Prompts: `prompts/analyze_pull-request.md` contains a PR review template for reference.
Slate Environments: Require valid kubectl context & `scli` installed; failing context switches are warned, not fatal.
Security: No secrets are stored in repo; ensure environment variables / credentials (AWS SSO) are managed externally.
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
Ensure the sourcing line is at end of `~/.zshrc` and no earlier `return` statements are short-circuiting.

### Slate Fails to Initialize
1. Confirm `scli` login (`sc-auth` / `sc-slate`).
2. Verify kubectl context via `kubectl config current-context`.

### Telepresence Not Connecting
1. Run `telepresence quit -s` before `tpa`.
2. Verify Kubernetes context via `kubectl config current-context`.
3. Check port conflicts with `cleanpipe <port>`.

## License / Usage
Internal tooling; adjust before external distribution. Remove organization-specific paths or secrets before sharing.

---
Suggestions / additions welcome. Update the README with substantive user-facing changes.
