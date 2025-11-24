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

# Ensure required kubie context is active before slate operations.
# This will attempt to enter the context each time; kubie should handle idempotency.
slate_ensure_context() {
  if ! command -v kubie >/dev/null 2>&1; then
    echo "ERROR: kubie is required for slate operations" >&2
    return 1
  fi
  echo "Ensuring kubie context: ${SLATE_DEV}"
  kubie ctx "${SLATE_DEV}" || {
    echo "ERROR: failed to switch kubie context to ${SLATE_DEV}" >&2
    return 1
  }
}

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
  echo "Switching kubie context to ${SLATE_DEV}"
  kubie ctx ${SLATE_DEV} || echo "WARN: kubie context switch failed"
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
  # Ensure we are inside a kubie context before switching namespace. Without this
  # 'kubie ns' errors: "Not in a kubie shell!".
  echo "Ensuring kubie context ${SLATE_DEV}"
  kubie ctx ${SLATE_DEV} || echo "WARN: kubie context switch failed" >&2
  local ticket_ns="$(echo "$ticket" | tr '[:upper:]' '[:lower:]')"
  echo "Switching kubie namespace to ${ticket_ns} (lowercased)"
  kubie ns "${ticket_ns}" || echo "WARN: kubie namespace switch failed" >&2
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

slate_help() {
  cat <<EOF
Slate Functions:
  slate up                       Initialize slate tooling + default kubie context
  slate ls                       List existing slates
  slate create <jira-ticket>     Create slate for JIRA ticket (e.g. RESM-123)
  slate session <jira-ticket>    Ensure slate exists + switch kubie namespace
  slate extend <slate-id> <days> Extend slate expiry (1-7 days)
  slate delete <slate-id>        Delete a slate
  slate ctx                      Switch kubie context
  slate help                     Show this help
Wrapper:
  slate <command> [args]         Dispatch to above functions
EOF
}

# Optional wrapper to mimic previous CLI style
slate() {
  local command="$1"; shift || true
  # Enforce kubie context before executing any non-help/context command
  case "$command" in
    ctx|help|--help|-h|"") ;; # skip ensure for these commands
    *) slate_ensure_context || return 1 ;;
  esac
  case "$command" in
    up)        slate_up "$@" ;;
    ls|list)   slate_ls "$@" ;;
    create)    slate_create "$@" ;;
    session)   slate_session "$@" ;;
    extend)    slate_extend "$@" ;;
    delete|rm) slate_delete "$@" ;;
    ctx)       kubie ctx "${SLATE_DEV}" ;;
    help|--help|-h|"") slate_help ;;
    *) echo "ERROR: Unknown command: $command" >&2; slate_help; return 1 ;;
  esac
}
