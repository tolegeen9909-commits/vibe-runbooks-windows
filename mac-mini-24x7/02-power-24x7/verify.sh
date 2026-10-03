#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$MAC_RUNBOOK_ROOT/scripts/lib.sh"

extract_ac_setting() {
    setting_name=$1
    awk -v wanted="$setting_name" '
        /^AC Power:/ { in_ac = 1; next }
        /^[^[:space:]].*:/ { if (in_ac) exit }
        in_ac && $1 == wanted { print $2; exit }
    '
}

evaluate_power_state() {
    evaluated_state=$1
    sleep_value=$(printf '%s\n' "$evaluated_state" | extract_ac_setting sleep)
    autorestart_value=$(printf '%s\n' "$evaluated_state" | extract_ac_setting autorestart)
    womp_value=$(printf '%s\n' "$evaluated_state" | extract_ac_setting womp)

    failures=0
    manual_checks=0

    if [ "$sleep_value" = "0" ]; then
        pass "system sleep on AC power is disabled"
    else
        fail "system sleep on AC power is not proven disabled"
        failures=$((failures + 1))
    fi

    case "$autorestart_value" in
        1)
            pass "automatic restart after power loss is enabled"
            ;;
        0)
            fail "automatic restart after power loss is disabled"
            failures=$((failures + 1))
            ;;
        *)
            manual "automatic power recovery needs a model-specific check"
            manual_checks=$((manual_checks + 1))
            ;;
    esac

    case "$womp_value" in
        1)
            pass "wake for network access is enabled"
            ;;
        0)
            fail "wake for network access is disabled"
            failures=$((failures + 1))
            ;;
        *)
            manual "wake for network access is unavailable or could not be classified"
            manual_checks=$((manual_checks + 1))
            ;;
    esac

    if [ "$failures" -gt 0 ]; then
        return 1
    fi
    if [ "$manual_checks" -gt 0 ]; then
        return 2
    fi
    return 0
}

if [ "$1" = "--self-test-probes" ]; then
    pass_state='AC Power:
 sleep 0
 autorestart 1
 womp 1'
    womp_off_state='AC Power:
 sleep 0
 autorestart 1
 womp 0'
    autorestart_off_state='AC Power:
 sleep 0
 autorestart 0
 womp 1'
    missing_state='AC Power:
 sleep 0
 autorestart 1'

    evaluate_power_state "$pass_state" >/dev/null 2>&1 || exit 1
    probe_code=0
    evaluate_power_state "$womp_off_state" >/dev/null 2>&1 || probe_code=$?
    [ "$probe_code" -eq 1 ] || exit 1
    probe_code=0
    evaluate_power_state "$autorestart_off_state" >/dev/null 2>&1 || probe_code=$?
    [ "$probe_code" -eq 1 ] || exit 1
    probe_code=0
    evaluate_power_state "$missing_state" >/dev/null 2>&1 || probe_code=$?
    [ "$probe_code" -eq 2 ] || exit 1
    exit 0
fi

fixture_result "$1"
fixture_code=$?
if [ "$fixture_code" -ne 64 ]; then
    exit "$fixture_code"
fi

if ! have_command pmset; then
    fail "pmset is unavailable"
    exit 1
fi

power_state=$(pmset -g custom 2>/dev/null)
if [ -z "$power_state" ]; then
    fail "power settings could not be read"
    exit 1
fi

evaluate_power_state "$power_state"
exit $?
