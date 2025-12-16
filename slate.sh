#!/bin/sh

# =============================================================================
# SLATE FUNCTIONS (sourced)
# =============================================================================
# These functions mirror the prior CLI subcommands. Source this file to use:
#   slate_up
#   slate_ls
#   slate_extend <slate-id> <days>
#   slate_delete <slate-id>
#   slate_tp <jira-ticket> [service]
#   slate_tpa
#   slate_help
# Optionally use wrapper: slate <command> [args]


slate_up() {
  if ! command -v sc-slate >/dev/null 2>&1; then
    echo "ERROR: sc-slate command not found in PATH" >&2
    return 1
  fi
  echo "Initializing slate tooling..."
  sc-slate
}

slate_ls() {
  kubectl get slate
}

slate_extend() {
  local slate_id="$1"
  local days="$2"
  if [[ -z "$slate_id" || -z "$days" ]]; then
    echo "ERROR: slate-id and days required" >&2
    echo "Usage: slate extend <slate-id> <days>" >&2
    return 1
  fi
  if ! echo "$days" | grep -Eq '^[1-7]$'; then
    echo "ERROR: days must be between 1 and 7" >&2
    return 1
  fi
  echo "Extending $slate_id by $days day(s)"
  scli slate extend-slate-expiry --id "$slate_id" --days "$days"
}

slate_delete() {
  local slate_id="$1"
  if [[ -z "$slate_id" ]]; then
    echo "ERROR: slate-id required" >&2
    echo "Usage: slate delete <slate-id>" >&2
    return 1
  fi
  echo "Deleting slate $slate_id"
  scli slate delete-slate --id "$slate_id"
}

slate_tp() {
  local ticket="$1"
  local service="${2:-$(basename "$(pwd)")}"
  if [[ -z "$ticket" ]]; then
    echo "Usage: slate tp <ticket-id> [service]" >&2
    return 1
  fi
  
  echo "quitting existing telepresence sessions..."
  telepresence quit -s
  scli dev intercept --slate-id "$ticket" "$service"
}

slate_tpa() {
  local ticket="$(git_current_branch)"
  local service="$(basename "$(pwd)")"
  
  scli dev intercept --slate-id "$ticket" "$service"
}

slate_help() {
  cat <<EOF
Slate Functions:
  slate up                       Initialize slate tooling (kubectl context already set)
  slate ls                       List existing slates
  slate extend <slate-id> <days> Extend slate expiry (1-7 days)
  slate delete <slate-id>        Delete a slate
  slate tp <jira-ticket> [svc]   Create slate, deploy service, and intercept (uses scli dev intercept)
  slate tpa                      Auto ticket/service from branch + cwd; deploy + intercept
  slate help                     Show this help
Wrapper:
  slate <command> [args]         Dispatch to above functions
EOF
}

# Optional wrapper to mimic previous CLI style
slate() {
  local command="$1"; shift || true
  case "$command" in
    up)        slate_up "$@" ;;
    ls|list)   slate_ls "$@" ;;
    extend)    slate_extend "$@" ;;
    delete|rm) slate_delete "$@" ;;
    tp)        slate_tp "$@" ;;
    tpa)       slate_tpa "$@" ;;
    help|--help|-h|"") slate_help ;;
    *) echo "ERROR: Unknown command: $command" >&2; slate_help; return 1 ;;
  esac
}
