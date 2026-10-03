#!/bin/bash

if [ -z "$MAC_RUNBOOK_ROOT" ]; then
    MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fi

MAC_RUNBOOK_STATE_TEMPLATE="$MAC_RUNBOOK_ROOT/state/progress-template.json"
if [ -z "$MAC_RUNBOOK_STATE_FILE" ]; then
    MAC_RUNBOOK_STATE_FILE="$MAC_RUNBOOK_ROOT/state/progress.json"
fi

pass() {
    printf 'PASS: %s\n' "$*"
}

warn() {
    printf 'WARN: %s\n' "$*"
}

fail() {
    printf 'FAIL: %s\n' "$*"
}

manual() {
    printf 'MANUAL: %s\n' "$*"
}

have_command() {
    command -v "$1" >/dev/null 2>&1
}

state_exists() {
    [ -f "$MAC_RUNBOOK_STATE_FILE" ] && \
        plutil -convert json -o /dev/null "$MAC_RUNBOOK_STATE_FILE" >/dev/null 2>&1
}

state_mode() {
    if ! state_exists; then
        return 1
    fi
    plutil -extract selectedMode raw -o - "$MAC_RUNBOOK_STATE_FILE" 2>/dev/null
}

state_has_step() {
    wanted_step=$1
    if ! state_exists; then
        return 1
    fi

    step_count=$(plutil -extract completedSteps raw -o - "$MAC_RUNBOOK_STATE_FILE" 2>/dev/null)
    case "$step_count" in
        ''|*[!0-9]*) return 1 ;;
    esac

    step_index=0
    while [ "$step_index" -lt "$step_count" ]; do
        current_step=$(plutil -extract "completedSteps.$step_index" raw -o - "$MAC_RUNBOOK_STATE_FILE" 2>/dev/null)
        if [ "$current_step" = "$wanted_step" ]; then
            return 0
        fi
        step_index=$((step_index + 1))
    done
    return 1
}

state_manual_true() {
    manual_id=$1
    if ! state_exists; then
        return 1
    fi
    manual_value=$(plutil -extract "manualChecks.$manual_id" raw -o - "$MAC_RUNBOOK_STATE_FILE" 2>/dev/null)
    [ "$manual_value" = "true" ] || [ "$manual_value" = "1" ] || [ "$manual_value" = "YES" ]
}

fixture_result() {
    case "$1" in
        --self-test-pass)
            pass "deterministic fixture"
            return 0
            ;;
        --self-test-fail)
            fail "deterministic fixture"
            return 1
            ;;
        --self-test-manual)
            manual "deterministic fixture"
            return 2
            ;;
        *)
            return 64
            ;;
    esac
}
