#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$MAC_RUNBOOK_ROOT/scripts/lib.sh"

evaluate_anydesk_runtime() {
    runtime_installed=$1
    runtime_running=$2

    if [ "$runtime_installed" -ne 1 ]; then
        fail "AnyDesk is not installed"
        return 1
    fi
    pass "AnyDesk is installed"

    if [ "$runtime_running" -ne 1 ]; then
        manual "AnyDesk is not running in the current session"
        return 2
    fi
    pass "AnyDesk is running in the current session"
    return 0
}

if [ "$1" = "--self-test-probes" ]; then
    evaluate_anydesk_runtime 1 1 >/dev/null 2>&1 || exit 1
    probe_code=0
    evaluate_anydesk_runtime 0 0 >/dev/null 2>&1 || probe_code=$?
    [ "$probe_code" -eq 1 ] || exit 1
    probe_code=0
    evaluate_anydesk_runtime 1 0 >/dev/null 2>&1 || probe_code=$?
    [ "$probe_code" -eq 2 ] || exit 1
    exit 0
fi

fixture_result "$1"
fixture_code=$?
if [ "$fixture_code" -ne 64 ]; then
    exit "$fixture_code"
fi

failures=0
manual_checks=0

if [ -d /Applications/AnyDesk.app ] || [ -d "$HOME/Applications/AnyDesk.app" ]; then
    anydesk_installed=1
else
    anydesk_installed=0
fi

if pgrep -x AnyDesk >/dev/null 2>&1; then
    anydesk_running=1
else
    anydesk_running=0
fi

runtime_code=0
evaluate_anydesk_runtime "$anydesk_installed" "$anydesk_running" || runtime_code=$?
case "$runtime_code" in
    1) failures=$((failures + 1)) ;;
    2) manual_checks=$((manual_checks + 1)) ;;
esac

if [ "$runtime_code" -eq 1 ]; then
    exit 1
fi

for manual_id in anydesk-view anydesk-control anydesk-unattended anydesk-hardened; do
    if state_manual_true "$manual_id"; then
        pass "$manual_id was verified remotely"
    else
        manual "$manual_id still needs a remote test"
        manual_checks=$((manual_checks + 1))
    fi
done

if [ "$failures" -gt 0 ]; then
    exit 1
fi
if [ "$manual_checks" -gt 0 ]; then
    exit 2
fi
exit 0
