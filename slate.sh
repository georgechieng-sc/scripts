#!/bin/sh

# =============================================================================
# SLATE FUNCTIONS (sourced)
# =============================================================================
# These functions mirror the prior CLI subcommands. Source this file to use:
#   slate_up
#   slate_ls
#   slate_create <jira-ticket>
#   slate_session <jira-ticket>
#   slate_extend <slate-id> <days>
#   slate_delete <slate-id>
#   slate_ctx <kubie-context>
#   slate_help
# Optionally use wrapper: slate <command> [args]


# Validate a JIRA ticket pattern (PROJECT-123)
slate_validate_ticket() {
  echo "$1" | grep -Eq '^[A-Z]+-[0-9]+$'
}

slate_up() {
  if ! command -v sc-slate >/dev/null 2>&1; then
    echo "ERROR: sc-slate command not found in PATH" >&2
    return 1
  fi
  echo "Initializing slate tooling..."
  sc-slate
}

slate_ls() {
  scli slate view-slates
}

slate_create() {
  local ticket="$1"
  if [[ -z "$ticket" ]]; then
    echo "ERROR: JIRA ticket ID required" >&2
    echo "Usage: slate create <jira-ticket>" >&2
    return 1
  fi
  if ! slate_validate_ticket "$ticket"; then
    echo "ERROR: Invalid ticket format: $ticket" >&2
    return 1
  fi
  echo "Creating slate for $ticket"
  scli slate create-slate --id "$ticket" || echo "WARN: slate may already exist" >&2
}

slate_session() {
  local ticket="$1"
  if [[ -z "$ticket" ]]; then
    echo "ERROR: JIRA ticket ID required" >&2
    echo "Usage: slate session <jira-ticket>" >&2
    return 1
  fi
  if ! slate_validate_ticket "$ticket"; then
    echo "ERROR: Invalid ticket format: $ticket" >&2
    return 1
  fi
  echo "Initializing slate session for $ticket"
  scli slate create-slate --id "$ticket" 2>/dev/null || echo "(info) slate may already exist"
  local ticket_ns="$(echo "$ticket" | tr '[:upper:]' '[:lower:]')"
  echo "Switching namespace to ${ticket_ns} (kubectl)"
  sc-change "${ticket_ns}" || echo "WARN: namespace switch failed" >&2
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
  local service="$2"
  if [[ -z "$ticket" ]]; then
    echo "Usage: slate tp <ticket-id> [service-name]" >&2
    return 1
  fi
  [[ -z "$service" ]] && service="$(basename "$(pwd)")"
  echo "Deploying '$service' to slate '$ticket'..."
  scli slate deploy --slate "$ticket" --service "$service" || echo "(warn) deploy may have failed or already exists" >&2

  echo "Starting telepresence intercept for service '$service'..."
  tp "$service"
}

slate_tpa() {
  local ticket="$(git_current_branch)"
  local service="$(basename "$(pwd)")"
  echo "Auto slate deploy/intercept: ticket=$ticket service=$service"

  echo "Restarting telepresence session..."
  telepresence quit -s >/dev/null 2>&1 || true
  slate_tp "$ticket" "$service"
}

slate_help() {
  cat <<EOF
Slate Functions:
  slate up                       Initialize slate tooling (kubectl context already set)
  slate ls                       List existing slates
  slate create <jira-ticket>     Create slate for JIRA ticket (e.g. RESM-123)
  slate session <jira-ticket>    Ensure slate exists + switch namespace (kubectl)
  slate extend <slate-id> <days> Extend slate expiry (1-7 days)
  slate delete <slate-id>        Delete a slate
  slate tp <jira-ticket> [svc]   Deploy service to slate then intercept
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
    create)    slate_create "$@" ;;
    session)   slate_session "$@" ;;
    extend)    slate_extend "$@" ;;
    delete|rm) slate_delete "$@" ;;
    tp)        slate_tp "$@" ;;
    tpa)       slate_tpa "$@" ;;
    help|--help|-h|"") slate_help ;;
    *) echo "ERROR: Unknown command: $command" >&2; slate_help; return 1 ;;
  esac
}
