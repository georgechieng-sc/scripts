# SafetyCulture Development Scripts

Custom shell functions for Git, JIRA, PR review, Slate, and utilities.
Located at `~/Desktop/safetyculture/scripts/`.

## How to call these functions

These functions are already loaded in the user's shell. Call them directly:
```bash
<function> [args]
```

All functions accept direct arguments to bypass interactive prompts (fzf, read).
When args are provided, no TTY interaction is needed.

## Function Reference

### Git (git.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `branch` | `branch <name>` | Switch to main, pull, create branch, push to remote |
| `pr` | `pr [--move-jira <status>] [--ready] [title] [merge_dest]` | Create draft PR. `--move-jira "Code Review"` moves JIRA ticket. `--ready` marks PR as ready. `-v` views existing PR in browser |
| `gbi` | `gbi <branch_name>` | Checkout branch |
| `gbdi` | `gbdi [--delete-slate] [--move-done] <branch_name>` | Delete branch. `--delete-slate` removes slate instance. `--move-done` moves JIRA to Done |
| `gacp` | `gacp <message>` | Add, commit, push. Shorthand flags: `-rri` (remove redundant import), `-gmt` (go mod tidy), `-gga` (go get all), `-gmm` (merged main), `-vb` (version bump), `-ut` (updated unit tests), `-fmt` (formatted code) |

### JIRA (jira.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `sync_board` | `sync_board <board_code>` | Sync JIRA issues to local file. Valid boards: `PEOPLE` |
| `peop` | `peop` | Shorthand for `sync_board PEOPLE` |
| `jbr` | `jbr [--move-progress] <ticket_id>` | Create branch from ticket. `--move-progress` moves ticket to In Progress |
| `mvj` | `mvj <ticket_id> <status>` | Move JIRA ticket. Statuses: `Code Review`, `In Progress`, `Done` |
| `jdiff` | `jdiff -t <title> -d <desc> -p <project> [-c <component>]` | Full workflow: create JIRA ticket, branch, commit, and PR. Projects: `PEOPLE`. Components: `Documents`, `Heads Up`. Optional: `--priority`, `--type` |

### PR Review (pr-review.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `stamp` | `stamp` | Approve PR (URL from clipboard) |
| `prd` | `prd <pr_url>` | Show PR diff |
| `rr` | `rr [--approve] <pr_url>` | View PR details + diff. `--approve` auto-approves |
| `review` | `review [-c] <review_text>` | Post or preview review. `-c` posts as PR comment (URL from clipboard) |

### Repository (repository.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `repo` | `repo` | Sync SafetyCulture repo list to `repo.txt` |
| `grc` | `grc` | Clone a repo interactively (fzf) |

### Slate (slate.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `slate up` | `slate up` | Initialize slate tooling |
| `slate ls` | `slate ls` | List existing slates |
| `slate extend` | `slate extend <id> <days>` | Extend slate expiry (1-7 days) |
| `slate delete` | `slate delete <id>` | Delete a slate |
| `slate tp` | `slate tp <ticket> [service]` | Deploy + intercept service |
| `slate tpa` | `slate tpa` | Auto-detect ticket/service from branch + cwd |

### Utilities (utilities.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `cleanpipe` | `cleanpipe <port>` | Kill processes on a port |
| `timezsh` | `timezsh [shell]` | Benchmark shell startup (10 runs) |
| `giffy` | `giffy <file.mov\|mp4>` | Convert video to optimized gif |
| `cdi` | `cdi <dir_name>` | Change to directory |
| `sci` | `sci <dir_name>` | cd to SafetyCulture dir, then into subdirectory |

### Specialized (specialized.sh)

| Function | Usage | Description |
|----------|-------|-------------|
| `s12id` | `s12id <s12id_string>` | Convert S12ID to UUID format |
| `ids12` | `ids12 <uuid> [prefix]` | Convert UUID to S12ID. Prefixes: `role`, `user`, `action`, `audit` |
| `pw` | `pw [-s] <input>` | Generate password from seed. `-s` shows seed only |
| `auto-sql` | `auto-sql` | Generate next SQL migration file (interactive — reads description from stdin) |

### Aliases (aliases.sh)

Key aliases available after sourcing:
- Navigation: `dk` (Desktop), `sc` (safetyculture), `fr` (frontend-reactor)
- Git: `gmm` (merge main), `gfm` (fetch main), `gpod` (push origin delete), `gplink` (set upstream)
- Docker: `docking` (open Docker), `dkc` (list containers), `dki` (list images)
- K8s: `sc-auth` (AWS SSO login), `kubedev`/`kubeslate` (switch context), `tidepods` (get pods)
- Build: `yb` (pnpm build in frontend-reactor), `gga` (go get all), `gmt` (go mod tidy)
