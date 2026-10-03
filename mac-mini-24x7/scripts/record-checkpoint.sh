#!/bin/bash
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$SCRIPT_DIR/lib.sh"

usage() {
    printf 'Usage: bash mac-mini-24x7/scripts/record-checkpoint.sh mode <secure|autonomous>\n'
    printf '       bash mac-mini-24x7/scripts/record-checkpoint.sh step <allowlisted-id>\n'
    printf '       bash mac-mini-24x7/scripts/record-checkpoint.sh manual <allowlisted-id>\n'
}

is_allowed_step() {
    case "$1" in
        00-preflight:verified|01-macos-update:verified|02-power-24x7:verified|03-ssh-termius:verified|04-anydesk:verified|05-tailscale:verified|06-recovery-security:verified|07-reboot-checkpoint:verified|08-power-loss-headless:verified|09-development:verified|10-final-checkpoint:secure-ready|10-final-checkpoint:autonomous-ready) return 0 ;;
        *) return 1 ;;
    esac
}

is_allowed_manual() {
    case "$1" in
        ssh-lan|termius-lan|anydesk-view|anydesk-control|anydesk-unattended|anydesk-hardened|tailscale-peers|ssh-over-tailscale|lock-recovery|logout-recovery|reboot-tailscale|reboot-ssh|reboot-anydesk|power-startup|power-remote-access|headless-access) return 0 ;;
        *) return 1 ;;
    esac
}

manual_ids='ssh-lan termius-lan anydesk-view anydesk-control anydesk-unattended anydesk-hardened tailscale-peers ssh-over-tailscale lock-recovery logout-recovery reboot-tailscale reboot-ssh reboot-anydesk power-startup power-remote-access headless-access'

has_recovery_evidence() {
    state_has_step 06-recovery-security:verified || \
        state_has_step 07-reboot-checkpoint:verified || \
        state_has_step 08-power-loss-headless:verified || \
        state_has_step 09-development:verified || \
        state_has_step 10-final-checkpoint:secure-ready || \
        state_has_step 10-final-checkpoint:autonomous-ready || \
        state_manual_true lock-recovery || \
        state_manual_true logout-recovery || \
        state_manual_true reboot-tailscale || \
        state_manual_true reboot-ssh || \
        state_manual_true reboot-anydesk || \
        state_manual_true power-startup || \
        state_manual_true power-remote-access || \
        state_manual_true headless-access
}

if [ "$#" -ne 2 ]; then
    fail "expected an action and an allowlisted value"
    usage
    exit 1
fi

action=$1
value=$2

if ! have_command plutil; then
    fail "plutil is required"
    exit 1
fi

if [ "$MAC_RUNBOOK_TEST_MODE" = "1" ]; then
    case "$MAC_RUNBOOK_STATE_FILE" in
        /private/tmp/mac-mini-runbook.*/*|/tmp/mac-mini-runbook.*/*) ;;
        *)
            fail "test state must stay inside a dedicated temporary directory"
            exit 1
            ;;
    esac
else
    MAC_RUNBOOK_STATE_FILE="$MAC_RUNBOOK_ROOT/state/progress.json"
fi

state_dir=$(dirname -- "$MAC_RUNBOOK_STATE_FILE")
mkdir -p "$state_dir"
temp_state=$(mktemp "$state_dir/.progress.XXXXXX")
trap 'rm -f "$temp_state"' EXIT

if [ -f "$MAC_RUNBOOK_STATE_FILE" ] && ! state_exists; then
    fail "existing progress file is not valid JSON"
    exit 1
fi

if state_exists; then
    source_state=$MAC_RUNBOOK_STATE_FILE
    cp "$MAC_RUNBOOK_STATE_TEMPLATE" "$temp_state"

    source_schema=$(plutil -extract schemaVersion raw -o - "$source_state" 2>/dev/null || true)
    source_route=$(plutil -extract route raw -o - "$source_state" 2>/dev/null || true)
    if [ "$source_schema" != "1" ] || [ "$source_route" != "mac-mini-24x7" ]; then
        fail "existing progress file has an unsupported schema or route"
        exit 1
    fi

    source_mode=$(plutil -extract selectedMode raw -o - "$source_state" 2>/dev/null || true)
    case "$source_mode" in
        secure|autonomous)
            plutil -replace selectedMode -string "$source_mode" "$temp_state"
            ;;
        '') ;;
        *)
            fail "existing progress file has an invalid selected mode"
            exit 1
            ;;
    esac

    source_step_count=$(plutil -extract completedSteps raw -o - "$source_state" 2>/dev/null || true)
    case "$source_step_count" in
        ''|*[!0-9]*)
            fail "existing progress file has an invalid completedSteps array"
            exit 1
            ;;
    esac
    source_step_index=0
    normalized_step_count=0
    secure_final_seen=0
    autonomous_final_seen=0
    while [ "$source_step_index" -lt "$source_step_count" ]; do
        source_step=$(plutil -extract "completedSteps.$source_step_index" raw -o - "$source_state" 2>/dev/null || true)
        if ! is_allowed_step "$source_step"; then
            fail "existing progress file contains a non-allowlisted step"
            exit 1
        fi
        case "$source_step" in
            10-final-checkpoint:secure-ready) secure_final_seen=1 ;;
            10-final-checkpoint:autonomous-ready) autonomous_final_seen=1 ;;
        esac

        duplicate_step=0
        normalized_index=0
        while [ "$normalized_index" -lt "$normalized_step_count" ]; do
            normalized_step=$(plutil -extract "completedSteps.$normalized_index" raw -o - "$temp_state")
            if [ "$normalized_step" = "$source_step" ]; then
                duplicate_step=1
                break
            fi
            normalized_index=$((normalized_index + 1))
        done
        if [ "$duplicate_step" -eq 0 ]; then
            plutil -insert "completedSteps.$normalized_step_count" -string "$source_step" "$temp_state"
            normalized_step_count=$((normalized_step_count + 1))
        fi
        source_step_index=$((source_step_index + 1))
    done

    if [ "$secure_final_seen" -eq 1 ] && [ "$autonomous_final_seen" -eq 1 ]; then
        fail "existing progress file contains both final readiness markers"
        exit 1
    fi
    if { [ "$secure_final_seen" -eq 1 ] && [ "$source_mode" != "secure" ]; } || \
        { [ "$autonomous_final_seen" -eq 1 ] && [ "$source_mode" != "autonomous" ]; }; then
        fail "existing progress file has a final marker that conflicts with selected mode"
        exit 1
    fi

    for manual_id in $manual_ids; do
        manual_value=$(plutil -extract "manualChecks.$manual_id" raw -o - "$source_state" 2>/dev/null || true)
        case "$manual_value" in
            true|1|YES)
                plutil -replace "manualChecks.$manual_id" -bool true "$temp_state"
                ;;
            false|0|NO) ;;
            *)
                fail "existing progress file has an invalid manual check"
                exit 1
                ;;
        esac
    done
else
    cp "$MAC_RUNBOOK_STATE_TEMPLATE" "$temp_state"
fi

case "$action" in
    mode)
        case "$value" in
            secure|autonomous) ;;
            *)
                fail "mode must be secure or autonomous"
                exit 1
                ;;
        esac

        current_mode=$(plutil -extract selectedMode raw -o - "$temp_state" 2>/dev/null || true)
        if [ "$current_mode" != "$value" ]; then
            if has_recovery_evidence; then
                fail "mode is locked after recovery evidence; a separately approved full progress reset requires repeating the route"
                exit 1
            fi
        fi
        plutil -replace selectedMode -string "$value" "$temp_state"
        checkpoint_value="mode:$value"
        ;;
    step)
        if ! is_allowed_step "$value"; then
            fail "step marker is not allowlisted"
            exit 1
        fi

        case "$value" in
            06-recovery-security:verified|07-reboot-checkpoint:verified|08-power-loss-headless:verified|09-development:verified|10-final-checkpoint:secure-ready|10-final-checkpoint:autonomous-ready)
                recorded_mode=$(plutil -extract selectedMode raw -o - "$temp_state" 2>/dev/null || true)
                case "$recorded_mode" in
                    secure|autonomous) ;;
                    *)
                        fail "recovery and final steps require a selected mode"
                        exit 1
                        ;;
                esac
                ;;
        esac

        expected_mode=
        conflicting_final=
        case "$value" in
            10-final-checkpoint:secure-ready)
                expected_mode=secure
                conflicting_final=10-final-checkpoint:autonomous-ready
                ;;
            10-final-checkpoint:autonomous-ready)
                expected_mode=autonomous
                conflicting_final=10-final-checkpoint:secure-ready
                ;;
        esac

        if [ -n "$expected_mode" ]; then
            recorded_mode=$(plutil -extract selectedMode raw -o - "$temp_state" 2>/dev/null || true)
            if [ "$recorded_mode" != "$expected_mode" ]; then
                fail "final marker does not match selected mode"
                exit 1
            fi
            if ! MAC_RUNBOOK_STATE_FILE="$temp_state" \
                bash "$MAC_RUNBOOK_ROOT/10-final-checkpoint/self-check.sh" >/dev/null 2>&1; then
                fail "final marker requires every prerequisite step and manual proof"
                exit 1
            fi
        fi

        existing_count=$(plutil -extract completedSteps raw -o - "$temp_state")
        already_present=0
        conflicting_present=0
        index=0
        while [ "$index" -lt "$existing_count" ]; do
            existing_value=$(plutil -extract "completedSteps.$index" raw -o - "$temp_state")
            if [ "$existing_value" = "$value" ]; then
                already_present=1
                break
            fi
            if [ -n "$conflicting_final" ] && [ "$existing_value" = "$conflicting_final" ]; then
                conflicting_present=1
            fi
            index=$((index + 1))
        done
        if [ "$conflicting_present" -eq 1 ]; then
            fail "both final readiness markers are forbidden"
            exit 1
        fi
        if [ "$already_present" -eq 0 ]; then
            plutil -insert "completedSteps.$existing_count" -string "$value" "$temp_state"
        fi
        checkpoint_value="$value"
        ;;
    manual)
        if ! is_allowed_manual "$value"; then
            fail "manual check is not allowlisted"
            exit 1
        fi
        case "$value" in
            lock-recovery|logout-recovery|reboot-tailscale|reboot-ssh|reboot-anydesk|power-startup|power-remote-access|headless-access)
                recorded_mode=$(plutil -extract selectedMode raw -o - "$temp_state" 2>/dev/null || true)
                case "$recorded_mode" in
                    secure|autonomous) ;;
                    *)
                        fail "mode-dependent manual proof requires a selected mode"
                        exit 1
                        ;;
                esac
                ;;
        esac
        plutil -replace "manualChecks.$value" -bool true "$temp_state"
        checkpoint_value="manual:$value"
        ;;
    *)
        fail "unknown action"
        usage
        exit 1
        ;;
esac

updated_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
plutil -replace updatedAt -string "$updated_at" "$temp_state"
plutil -replace lastCheckpoint -string "$checkpoint_value" "$temp_state"
plutil -convert json -o /dev/null "$temp_state" >/dev/null
mv "$temp_state" "$MAC_RUNBOOK_STATE_FILE"
chmod 600 "$MAC_RUNBOOK_STATE_FILE"
trap - EXIT

pass "checkpoint saved"
