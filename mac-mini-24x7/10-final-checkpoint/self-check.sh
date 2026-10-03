#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$MAC_RUNBOOK_ROOT/scripts/lib.sh"

fixture_result "$1"
fixture_code=$?
if [ "$fixture_code" -ne 64 ]; then
    exit "$fixture_code"
fi

if ! state_exists; then
    fail "local Mac progress state does not exist"
    exit 1
fi

missing_steps=0
for step_id in \
    00-preflight:verified \
    01-macos-update:verified \
    02-power-24x7:verified \
    03-ssh-termius:verified \
    04-anydesk:verified \
    05-tailscale:verified \
    06-recovery-security:verified \
    07-reboot-checkpoint:verified \
    08-power-loss-headless:verified \
    09-development:verified
do
    if state_has_step "$step_id"; then
        pass "$step_id"
    else
        fail "missing step $step_id"
        missing_steps=$((missing_steps + 1))
    fi
done

if [ "$missing_steps" -gt 0 ]; then
    exit 1
fi

selected_mode=$(state_mode 2>/dev/null)
if [ "$selected_mode" != "secure" ] && [ "$selected_mode" != "autonomous" ]; then
    fail "selected mode is missing or invalid"
    exit 1
fi

missing_manual=0
for manual_id in \
    ssh-lan \
    termius-lan \
    anydesk-view \
    anydesk-control \
    anydesk-unattended \
    anydesk-hardened \
    tailscale-peers \
    ssh-over-tailscale \
    lock-recovery \
    logout-recovery \
    reboot-tailscale \
    reboot-ssh \
    reboot-anydesk \
    power-startup \
    power-remote-access \
    headless-access
do
    if state_manual_true "$manual_id"; then
        pass "$manual_id"
    else
        manual "missing manual proof $manual_id"
        missing_manual=$((missing_manual + 1))
    fi
done

if [ "$missing_manual" -gt 0 ]; then
    exit 2
fi

if [ "$selected_mode" = "secure" ]; then
    if state_has_step 10-final-checkpoint:autonomous-ready; then
        fail "autonomous-ready marker conflicts with secure mode"
        exit 1
    fi
    pass "candidate status: secure-ready"
else
    if state_has_step 10-final-checkpoint:secure-ready; then
        fail "secure-ready marker conflicts with autonomous mode"
        exit 1
    fi
    pass "candidate status: autonomous-ready"
fi
exit 0
