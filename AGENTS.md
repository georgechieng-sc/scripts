# SafetyCulture Development Scripts

Custom shell functions for Git, JIRA, PR review, and utilities.
Located at `~/Desktop/safetyculture/scripts/`.

## How to call these functions

These functions are already loaded in the user's shell. Call them directly:
```bash
<function> [args]
```

All functions accept direct arguments to bypass interactive prompts (fzf, read).
When args are provided, no TTY interaction is needed.

## Function Reference

### Installation (installation.sh)

Not sourced by the loader. Source it on demand: `source "$HOME/Desktop/safetyculture/scripts/installation.sh"`.

| Function | Usage | Description |
|----------|-------|-------------|
| `install-hb` | `install-hb` | Install Homebrew via the official script |
| `install-omzsh` | `install-omzsh` | Install Oh My Zsh |
| `install-deps` | `install-deps` | Tap required repos and install the CLI package set |
| `set-kubeconf` | `set-kubeconf` | Write the dev EKS kubeconfig entry (`sc-development`, ap-southeast-2) |

### Git (git.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `branch` | `branch <name>` | Switch to main, pull, create branch, push to remote |
| `pr` | `pr [--move-jira <status>] [--ready] [-t <title>] [-d <desc>]` | Create draft PR. Title auto-prefixed with branch name (JIRA ticket included). `--move-jira "In Progress"` moves JIRA ticket. `--ready` marks PR as ready. `-v` views existing PR in browser |
| `gbi` | `gbi <branch_name>` | Checkout branch |
| `gbdi` | `gbdi [--move-done] <branch_name>` | Delete branch. `--move-done` moves JIRA to Done |
| `gacp` | `gacp <message>` | Add, commit, push. Shorthand flags: `-rri` (remove redundant import), `-gmt` (go mod tidy), `-gga` (go get all), `-gmm` (merged main), `-vb` (version bump), `-ut` (updated unit tests), `-fmt` (formatted code) |

### PR Review (pr-review.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `stamp` | `stamp` | Approve PR (URL from clipboard) |
| `prd` | `prd <pr_url>` | Show PR diff |

### Repository (repository.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `repo` | `repo` | Sync SafetyCulture repo list to `repo.txt` |
| `grc` | `grc` | Clone a repo interactively (fzf) |

### Utilities (utilities.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `cdi` | `cdi <dir_name>` | Change to directory |
| `sci` | `sci <dir_name>` | cd to SafetyCulture dir, then into subdirectory |

### Specialized (specialized.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `s12id` | `s12id <s12id_string>` | Convert S12ID to UUID format |
| `ids12` | `ids12 <uuid> [prefix]` | Convert UUID to S12ID. Prefixes: `role`, `user`, `action`, `audit` |
| `pw` | `pw [-s] <input>` | Generate password from seed. `-s` shows seed only |

### Aliases (aliases.sh)

Key aliases available after sourcing:
- Navigation: `dk` (Desktop), `sc` (safetyculture), `fr` (frontend-reactor)
- Git: `gmm` (merge main), `gfm` (fetch main), `gpod` (push origin delete), `gplink` (set upstream)
- Docker: `docking` (open Docker), `dkc` (list containers), `dki` (list images)
- K8s: `sc-auth` (AWS SSO login), `kubedev`/`kubeslate` (switch context), `tidepods` (get pods)
- Build: `yb` (pnpm build in frontend-reactor), `gga` (go get all), `gmt` (go mod tidy)
